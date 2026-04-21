class LiveboardService {
  constructor({ query }) {
    this.query = query;
  }

  async getParticipants(tournamentId, roundId = null) {
    const { rows } = await this.query(
      `SELECT
         p.id, p.queue_number, p.status, p.phone,
         u.name, u.profile_image,
         prr.status AS round_status,
         prr.round_id
       FROM participants p
       JOIN users u ON u.id = p.user_id
       LEFT JOIN participant_round_results prr
         ON prr.participant_id = p.id
         AND prr.round_id = COALESCE($2, (
           SELECT id FROM rounds
           WHERE tournament_id = $1 AND status = 'active'
           LIMIT 1
         ))
       WHERE p.tournament_id = $1
       ORDER BY p.queue_number ASC`,
      [tournamentId, roundId || null]
    );
    return rows;
  }

  async getStats(tournamentId) {
    const [statsResult, roundResult] = await Promise.all([
      this.query(
        `SELECT
           COUNT(*) FILTER (WHERE status = 'registered') AS registered,
           COUNT(*) FILTER (WHERE status = 'active')     AS active,
           COUNT(*) FILTER (WHERE status = 'eliminated') AS eliminated,
           COUNT(*) FILTER (WHERE status = 'winner')     AS winners
         FROM participants
         WHERE tournament_id = $1`,
        [tournamentId]
      ),
      this.query(
        `SELECT name FROM rounds
         WHERE tournament_id = $1 AND status = 'active'
         LIMIT 1`,
        [tournamentId]
      ),
    ]);

    const s = statsResult.rows[0];
    return {
      registered: parseInt(s.registered),
      active: parseInt(s.active),
      eliminated: parseInt(s.eliminated),
      winners: parseInt(s.winners),
      current_round_name: roundResult.rows[0]?.name || null,
    };
  }
}

module.exports = LiveboardService;
