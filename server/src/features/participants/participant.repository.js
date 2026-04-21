class ParticipantRepository {
  constructor({ query, withTransaction }) {
    this.query = query;
    this.withTransaction = withTransaction;
  }

  async findByTournamentAndUser(tournamentId, userId) {
    const { rows } = await this.query(
      `SELECT p.*, u.name, u.email, u.profile_image
       FROM participants p JOIN users u ON u.id = p.user_id
       WHERE p.tournament_id=$1 AND p.user_id=$2`,
      [tournamentId, userId]
    );
    return rows[0] || null;
  }

  async findByTournament(tournamentId, { status, page = 1, limit = 20 } = {}) {
    const conditions = ['p.tournament_id=$1'];
    const values = [tournamentId];
    let idx = 2;

    if (status) {
      conditions.push(`p.status=$${idx++}`);
      values.push(status);
    }

    const where = 'WHERE ' + conditions.join(' AND ');
    const offset = (page - 1) * limit;

    const countResult = await this.query(
      `SELECT COUNT(*) FROM participants p ${where}`,
      values
    );
    const total = parseInt(countResult.rows[0].count);

    const { rows } = await this.query(
      `SELECT p.*, u.name, u.profile_image
       FROM participants p JOIN users u ON u.id = p.user_id
       ${where}
       ORDER BY p.queue_number ASC
       LIMIT $${idx++} OFFSET $${idx++}`,
      [...values, limit, offset]
    );

    return { rows, total };
  }

  async createWithQueueNumber({ tournamentId, userId, phone }, client) {
    const qResult = await client.query(
      'SELECT COALESCE(MAX(queue_number), 0) + 1 AS next FROM participants WHERE tournament_id=$1 FOR UPDATE',
      [tournamentId]
    );
    const queueNumber = qResult.rows[0].next;

    const { rows } = await client.query(
      `INSERT INTO participants (tournament_id, user_id, phone, queue_number, status)
       VALUES ($1, $2, $3, $4, 'registered') RETURNING *`,
      [tournamentId, userId, phone, queueNumber]
    );
    return rows[0];
  }

  async findById(id) {
    const { rows } = await this.query('SELECT * FROM participants WHERE id=$1', [id]);
    return rows[0] || null;
  }

  async updateStatus(id, { status, current_round_id }) {
    const fields = { status };
    if (current_round_id) fields.current_round_id = current_round_id;
    const keys = Object.keys(fields);
    const setClause = keys.map((k, i) => `${k}=$${i + 2}`).join(', ');
    const { rows } = await this.query(
      `UPDATE participants SET ${setClause}, updated_at=NOW() WHERE id=$1 RETURNING *`,
      [id, ...keys.map((k) => fields[k])]
    );
    return rows[0];
  }
}

module.exports = ParticipantRepository;
