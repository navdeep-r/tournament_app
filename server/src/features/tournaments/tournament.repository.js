const { BadRequestError } = require('../../core/errors/HttpErrors');
const { buildEffectiveTournamentStatusSql } = require('../../core/sql/tournamentStatus');

class TournamentRepository {
  constructor({ query, withTransaction }) {
    this.query = query;
    this.withTransaction = withTransaction;
  }

  async findById(id) {
    const effectiveStatusSql = buildEffectiveTournamentStatusSql('t');
    const { rows } = await this.query(
      `SELECT t.*, u.name AS winner_name,
              ${effectiveStatusSql} AS effective_status
       FROM tournaments t
       LEFT JOIN users u ON u.id = t.winner_user_id
       WHERE t.id = $1`,
      [id]
    );
    return rows[0] || null;
  }

  async findAll({ status, search, page = 1, limit = 20 }) {
    const effectiveStatusSql = buildEffectiveTournamentStatusSql('t');
    const conditions = [];
    const values = [];
    let idx = 1;

    if (status) {
      const statuses = Array.isArray(status) ? status : [status];
      conditions.push(`(${effectiveStatusSql}) = ANY($${idx++})`);
      values.push(statuses);
    }
    if (search) {
      conditions.push(`t.name ILIKE $${idx++}`);
      values.push(`%${search}%`);
    }

    const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
    const offset = (page - 1) * limit;

    const countResult = await this.query(
      `SELECT COUNT(*) FROM tournaments t ${where}`,
      values
    );
    const total = parseInt(countResult.rows[0].count);

    const { rows } = await this.query(
      `SELECT t.*, u.name AS winner_name,
              ${effectiveStatusSql} AS effective_status
       FROM tournaments t
       LEFT JOIN users u ON u.id = t.winner_user_id
       ${where}
       ORDER BY t.starts_at ASC
       LIMIT $${idx++} OFFSET $${idx++}`,
      [...values, limit, offset]
    );

    return { rows, total };
  }

  async create(data) {
    const keys = Object.keys(data);
    const cols = keys.join(', ');
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
    const values = keys.map((k) =>
      k === 'referral_codes' ? JSON.stringify(data[k] ?? []) : data[k]
    );
    try {
      const { rows } = await this.query(
        `INSERT INTO tournaments (${cols}) VALUES (${placeholders}) RETURNING *`,
        values
      );
      return rows[0];
    } catch (err) {
      if (
        err?.code === '42703' &&
        keys.includes('referral_codes')
      ) {
        throw new BadRequestError(
          'Referral system requires DB migration 005_add_referral_support.sql'
        );
      }
      throw err;
    }
  }

  async update(id, fields) {
    const keys = Object.keys(fields);
    if (keys.length === 0) {
      return this.findById(id);
    }
    const setClause = keys.map((k, i) => `${k}=$${i + 2}`).join(', ');
    const values = keys.map((k) =>
      k === 'referral_codes' ? JSON.stringify(fields[k] ?? []) : fields[k]
    );
    try {
      const { rows } = await this.query(
        `UPDATE tournaments SET ${setClause}, updated_at=NOW() WHERE id=$1 RETURNING *`,
        [id, ...values]
      );
      return rows[0];
    } catch (err) {
      if (
        err?.code === '42703' &&
        keys.includes('referral_codes')
      ) {
        throw new BadRequestError(
          'Referral system requires DB migration 005_add_referral_support.sql'
        );
      }
      throw err;
    }
  }

  async getRoundsForTournament(tournamentId) {
    const { rows } = await this.query(
      'SELECT * FROM rounds WHERE tournament_id=$1 ORDER BY round_number ASC',
      [tournamentId]
    );
    return rows;
  }

  async hardDelete(id) {
    const { rowCount } = await this.query(
      'DELETE FROM tournaments WHERE id = $1',
      [id]
    );
    return rowCount > 0;
  }
}

module.exports = TournamentRepository;
