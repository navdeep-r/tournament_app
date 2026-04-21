class RoundRepository {
  constructor({ query }) {
    this.query = query;
  }

  async findById(id) {
    const { rows } = await this.query('SELECT * FROM rounds WHERE id=$1', [id]);
    return rows[0] || null;
  }

  async findByTournamentId(tournamentId) {
    const { rows } = await this.query(
      'SELECT * FROM rounds WHERE tournament_id=$1 ORDER BY round_number',
      [tournamentId]
    );
    return rows;
  }

  async create(data) {
    const keys = Object.keys(data);
    const cols = keys.join(', ');
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
    const values = keys.map((k) => data[k]);
    const { rows } = await this.query(
      `INSERT INTO rounds (${cols}) VALUES (${placeholders}) RETURNING *`,
      values
    );
    return rows[0];
  }

  async update(id, fields) {
    const keys = Object.keys(fields);
    const setClause = keys.map((k, i) => `${k}=$${i + 2}`).join(', ');
    const values = keys.map((k) => fields[k]);
    const { rows } = await this.query(
      `UPDATE rounds SET ${setClause}, updated_at=NOW() WHERE id=$1 RETURNING *`,
      [id, ...values]
    );
    return rows[0];
  }

  async findDuplicate(tournamentId, roundNumber) {
    const { rows } = await this.query(
      'SELECT id FROM rounds WHERE tournament_id=$1 AND round_number=$2',
      [tournamentId, roundNumber]
    );
    return rows[0] || null;
  }

  async findActiveRound(tournamentId) {
    const { rows } = await this.query(
      "SELECT id FROM rounds WHERE tournament_id=$1 AND status='active'",
      [tournamentId]
    );
    return rows[0] || null;
  }
}

module.exports = RoundRepository;
