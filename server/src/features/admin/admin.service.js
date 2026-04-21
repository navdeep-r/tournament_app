const { BadRequestError, NotFoundError } = require('../../core/errors/HttpErrors');
const { getPagination, getPaginationMeta } = require('../../core/utils/pagination');

const VALID_STATUSES = ['registered', 'active', 'eliminated', 'winner', 'no_show', 'disqualified'];

class AdminService {
  constructor({ query, withTransaction, wsManager }) {
    this.query = query;
    this.withTransaction = withTransaction;
    this.wsManager = wsManager;
  }

  async getDashboardStats() {
    const [users, active, today, live, eliminated] = await Promise.all([
      this.query("SELECT COUNT(*) FROM users WHERE is_active=TRUE"),
      this.query("SELECT COUNT(*) FROM tournaments WHERE status IN ('upcoming','registration_open','live')"),
      this.query("SELECT COUNT(*) FROM participants WHERE DATE(registered_at) = CURRENT_DATE"),
      this.query("SELECT COUNT(*) FROM tournaments WHERE status='live'"),
      this.query("SELECT COUNT(*) FROM participants WHERE status='eliminated' AND DATE(updated_at) = CURRENT_DATE"),
    ]);

    return {
      total_active_users: parseInt(users.rows[0].count),
      active_tournaments: parseInt(active.rows[0].count),
      registrations_today: parseInt(today.rows[0].count),
      live_tournaments: parseInt(live.rows[0].count),
      eliminated_today: parseInt(eliminated.rows[0].count),
    };
  }

  async updateParticipantStatus(participantId, { status, round_id }, adminUserId) {
    if (!VALID_STATUSES.includes(status)) {
      throw new BadRequestError(`Invalid status. Must be one of: ${VALID_STATUSES.join(', ')}`);
    }

    const { rows: pRows } = await this.query('SELECT * FROM participants WHERE id=$1', [participantId]);
    const participant = pRows[0];
    if (!participant) throw new NotFoundError('Participant not found');

    const old_status = participant.status;

    await this.withTransaction(async (client) => {
      // Update participant status
      await client.query(
        'UPDATE participants SET status=$1, updated_at=NOW() WHERE id=$2',
        [status, participantId]
      );

      // Upsert round result if round_id provided
      if (round_id) {
        await client.query(
          `INSERT INTO participant_round_results (participant_id, round_id, status, updated_by)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (participant_id, round_id)
           DO UPDATE SET status=$3, updated_by=$4, updated_at=NOW()`,
          [participantId, round_id, status, adminUserId]
        );
      }

      // Decrement active count for terminal statuses
      if (['eliminated', 'no_show', 'disqualified'].includes(status)) {
        await client.query(
          'UPDATE tournaments SET active_count=GREATEST(active_count-1,0), updated_at=NOW() WHERE id=$1',
          [participant.tournament_id]
        );
      }

      // Mark tournament complete if winner declared
      if (status === 'winner') {
        await client.query(
          "UPDATE tournaments SET winner_user_id=$1, status='completed', updated_at=NOW() WHERE id=$2",
          [participant.user_id, participant.tournament_id]
        );
      }

      // Audit log
      await client.query(
        `INSERT INTO audit_log (entity_type, entity_id, action, performed_by, old_value, new_value)
         VALUES ('participant', $1, 'STATUS_CHANGED', $2, $3, $4)`,
        [
          participantId,
          adminUserId,
          JSON.stringify({ status: old_status }),
          JSON.stringify({ status, round_id: round_id || null }),
        ]
      );
    });

    // Broadcast WebSocket update
    if (this.wsManager) {
      await this.wsManager.broadcastUpdate(participant.tournament_id, {
        type: 'PARTICIPANT_UPDATE',
        participant_id: participantId,
        tournament_id: participant.tournament_id,
        queue_number: participant.queue_number,
        status,
        round_id: round_id || null,
        updated_at: new Date().toISOString(),
      });
    }

    const { rows } = await this.query('SELECT * FROM participants WHERE id=$1', [participantId]);
    return rows[0];
  }

  async activateRound(tournamentId, roundId, adminUserId) {
    // Complete current active round
    await this.query(
      "UPDATE rounds SET status='completed', ended_at=NOW() WHERE tournament_id=$1 AND status='active'",
      [tournamentId]
    );

    // Activate new round
    const { rows } = await this.query(
      "UPDATE rounds SET status='active', started_at=NOW() WHERE id=$1 RETURNING *",
      [roundId]
    );
    const round = rows[0];
    if (!round) throw new NotFoundError('Round not found');

    // Update tournament's current round
    await this.query(
      'UPDATE tournaments SET current_round_id=$1, updated_at=NOW() WHERE id=$2',
      [roundId, tournamentId]
    );

    // Broadcast
    if (this.wsManager) {
      await this.wsManager.broadcastUpdate(tournamentId, {
        type: 'ROUND_STARTED',
        round_id: roundId,
        round_name: round.name,
        round_number: round.round_number,
      });
    }

    return round;
  }

  async exportParticipantsCSV(tournamentId, res) {
    const { rows } = await this.query(
      `SELECT p.queue_number, u.name, p.phone, p.status, p.registered_at,
              r.name AS current_round
       FROM participants p
       JOIN users u ON u.id = p.user_id
       LEFT JOIN rounds r ON r.id = p.current_round_id
       WHERE p.tournament_id=$1
       ORDER BY p.queue_number`,
      [tournamentId]
    );

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="participants.csv"');

    const escape = (v) => {
      const s = v == null ? '' : String(v);
      return s.includes(',') || s.includes('"') || s.includes('\n')
        ? `"${s.replace(/"/g, '""')}"` : s;
    };

    res.write('Queue,Name,Phone,Status,Registered At,Current Round\n');
    for (const row of rows) {
      res.write(
        [row.queue_number, row.name, row.phone, row.status, row.registered_at, row.current_round]
          .map(escape).join(',') + '\n'
      );
    }
    res.end();
  }

  async searchParticipants(tournamentId, { search, status, page = 1, limit = 20 }) {
    const conditions = ['p.tournament_id=$1'];
    const values = [tournamentId];
    let idx = 2;

    if (search) {
      conditions.push(`(u.name ILIKE $${idx} OR p.phone ILIKE $${idx} OR CAST(p.queue_number AS text) ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }
    if (status) {
      conditions.push(`p.status=$${idx++}`);
      values.push(status);
    }

    const where = 'WHERE ' + conditions.join(' AND ');
    const offset = (page - 1) * limit;

    const countResult = await this.query(`SELECT COUNT(*) FROM participants p JOIN users u ON u.id=p.user_id ${where}`, values);
    const total = parseInt(countResult.rows[0].count);

    const { rows } = await this.query(
      `SELECT p.*, u.name, u.email, u.profile_image
       FROM participants p JOIN users u ON u.id = p.user_id
       ${where}
       ORDER BY p.queue_number
       LIMIT $${idx++} OFFSET $${idx++}`,
      [...values, limit, offset]
    );

    return { rows, meta: getPaginationMeta(total, page, limit) };
  }

  async getRevenueSummary(tournamentId) {
    const { rows } = await this.query(
      'SELECT status, COUNT(*) AS count FROM participants WHERE tournament_id=$1 GROUP BY status',
      [tournamentId]
    );
    const summary = { total_registered: 0, active_count: 0, eliminated_count: 0, winner_count: 0 };
    for (const row of rows) {
      summary.total_registered += parseInt(row.count);
      if (row.status === 'active') summary.active_count = parseInt(row.count);
      if (row.status === 'eliminated') summary.eliminated_count = parseInt(row.count);
      if (row.status === 'winner') summary.winner_count = parseInt(row.count);
    }
    return summary;
  }

  async listTournaments(queryParams) {
    const { limit, offset, page } = getPagination(queryParams);
    const { rows } = await this.query(
      `SELECT t.*, u.name AS creator_name,
              (SELECT COUNT(*) FROM participants WHERE tournament_id=t.id) AS participant_count
       FROM tournaments t
       LEFT JOIN users u ON u.id = t.created_by
       ORDER BY t.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    const countResult = await this.query('SELECT COUNT(*) FROM tournaments');
    const total = parseInt(countResult.rows[0].count);
    return { rows, meta: getPaginationMeta(total, page, limit) };
  }
}

module.exports = AdminService;
