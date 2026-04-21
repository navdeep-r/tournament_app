const { BadRequestError, NotFoundError, ConflictError } = require('../../core/errors/HttpErrors');

class RoundService {
  constructor({ roundRepo, tournamentRepo, query }) {
    this.roundRepo = roundRepo;
    this.tournamentRepo = tournamentRepo;
    this.query = query;
  }

  async create(tournamentId, data) {
    const tournament = await this.tournamentRepo.findById(tournamentId);
    if (!tournament) throw new NotFoundError('Tournament not found');

    const duplicate = await this.roundRepo.findDuplicate(tournamentId, data.round_number);
    if (duplicate) throw new ConflictError(`Round number ${data.round_number} already exists`);

    return this.roundRepo.create({ ...data, tournament_id: tournamentId });
  }

  async update(roundId, data) {
    const round = await this.roundRepo.findById(roundId);
    if (!round) throw new NotFoundError('Round not found');
    return this.roundRepo.update(roundId, data);
  }

  async activate(tournamentId, roundId) {
    const active = await this.roundRepo.findActiveRound(tournamentId);
    if (active) {
      await this.roundRepo.update(active.id, { status: 'completed', ended_at: new Date() });
    }
    const round = await this.roundRepo.update(roundId, { status: 'active', started_at: new Date() });
    await this.tournamentRepo.update(tournamentId, { current_round_id: roundId });
    return round;
  }

  async complete(roundId) {
    const round = await this.roundRepo.findById(roundId);
    if (!round) throw new NotFoundError('Round not found');
    return this.roundRepo.update(roundId, { status: 'completed', ended_at: new Date() });
  }

  async delete(roundId) {
    const round = await this.roundRepo.findById(roundId);
    if (!round) throw new NotFoundError('Round not found');
    if (round.status === 'active') throw new BadRequestError('Cannot delete active round');
    await this.query('DELETE FROM rounds WHERE id=$1', [roundId]);
  }
}

module.exports = RoundService;
