const { BadRequestError, NotFoundError, ConflictError } = require('../../core/errors/HttpErrors');

class ParticipantService {
  constructor({ participantRepo, tournamentRepo, withTransaction, query }) {
    this.participantRepo = participantRepo;
    this.tournamentRepo = tournamentRepo;
    this.withTransaction = withTransaction;
    this.query = query;
  }

  async register(tournamentId, userId, phone) {
    const tournament = await this.tournamentRepo.findById(tournamentId);
    if (!tournament) throw new NotFoundError('Tournament not found');

    if (!['registration_open', 'upcoming'].includes(tournament.status)) {
      throw new BadRequestError('Registration is not open for this tournament');
    }

    if (tournament.registered_count >= tournament.max_participants) {
      throw new BadRequestError('Tournament is full');
    }

    const existing = await this.participantRepo.findByTournamentAndUser(tournamentId, userId);
    if (existing) throw new ConflictError('Already registered for this tournament');

    const participant = await this.withTransaction(async (client) => {
      const p = await this.participantRepo.createWithQueueNumber(
        { tournamentId, userId, phone },
        client
      );
      await client.query(
        `UPDATE tournaments
         SET registered_count = registered_count + 1,
             active_count = active_count + 1,
             updated_at = NOW()
         WHERE id = $1`,
        [tournamentId]
      );
      return p;
    });

    return { ...participant, tournament_name: tournament.name };
  }

  async getMyRegistrations(userId) {
    const { rows } = await this.query(
      `SELECT p.*, t.name AS tournament_name, t.status AS tournament_status,
              t.starts_at, t.entry_fee_paise
       FROM participants p
       JOIN tournaments t ON t.id = p.tournament_id
       WHERE p.user_id = $1
       ORDER BY p.registered_at DESC`,
      [userId]
    );
    return rows;
  }
}

module.exports = ParticipantService;
