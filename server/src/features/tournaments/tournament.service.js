const { BadRequestError, NotFoundError } = require('../../core/errors/HttpErrors');
const { getPagination, getPaginationMeta } = require('../../core/utils/pagination');

const VALID_TRANSITIONS = {
  draft: ['upcoming'],
  upcoming: ['registration_open', 'cancelled'],
  registration_open: ['registration_closed', 'live', 'cancelled'],
  registration_closed: ['live', 'cancelled'],
  live: ['completed', 'cancelled'],
};

class TournamentService {
  constructor({ tournamentRepo }) {
    this.tournamentRepo = tournamentRepo;
  }

  _withEffectiveStatus(tournament) {
    if (!tournament) return tournament;
    if (!tournament.effective_status) return tournament;
    const { effective_status, ...rest } = tournament;
    return { ...rest, status: effective_status };
  }

  async list(queryParams) {
    const { limit, offset, page } = getPagination(queryParams);
    const { status, search } = queryParams;
    const { rows, total } = await this.tournamentRepo.findAll({ status, search, page, limit });
    return { tournaments: rows.map((row) => this._withEffectiveStatus(row)), meta: getPaginationMeta(total, page, limit) };
  }

  async getById(id) {
    const rawTournament = await this.tournamentRepo.findById(id);
    const tournament = this._withEffectiveStatus(rawTournament);
    if (!tournament) throw new NotFoundError('Tournament not found');
    const rounds = await this.tournamentRepo.getRoundsForTournament(id);
    return {
      ...tournament,
      rounds,
      spots_remaining: tournament.max_participants - tournament.registered_count,
    };
  }

  async create(data, adminUserId) {
    if (new Date(data.starts_at) <= new Date()) {
      throw new BadRequestError('Start time must be in the future');
    }
    return this.tournamentRepo.create({
      ...data,
      referral_codes: this._normalizeReferralCodes(data.referral_codes),
      created_by: adminUserId,
    });
  }

  async update(id, data) {
    const tournament = await this.tournamentRepo.findById(id);
    if (!tournament) throw new NotFoundError('Tournament not found');
    const updateData = { ...data };
    if (Object.prototype.hasOwnProperty.call(data, 'referral_codes')) {
      updateData.referral_codes = this._normalizeReferralCodes(data.referral_codes);
    }
    return this.tournamentRepo.update(id, updateData);
  }

  async updateStatus(id, newStatus) {
    const tournament = await this.tournamentRepo.findById(id);
    if (!tournament) throw new NotFoundError('Tournament not found');

    const currentStatus = tournament.effective_status || tournament.status;
    const allowed = VALID_TRANSITIONS[currentStatus] || [];
    if (!allowed.includes(newStatus)) {
      throw new BadRequestError(
        `Cannot transition from '${currentStatus}' to '${newStatus}'. Allowed: ${allowed.join(', ') || 'none'}`
      );
    }
    return this.tournamentRepo.update(id, { status: newStatus });
  }

  async delete(id) {
    const tournament = await this.tournamentRepo.findById(id);
    if (!tournament) throw new NotFoundError('Tournament not found');
    const currentStatus = tournament.effective_status || tournament.status;
    if (['live', 'completed'].includes(currentStatus)) {
      throw new BadRequestError('Cannot delete active or completed tournament');
    }
    return this.tournamentRepo.update(id, { status: 'cancelled' });
  }

  _normalizeReferralCodes(referralCodes) {
    if (!Array.isArray(referralCodes) || referralCodes.length === 0) return [];
    return referralCodes.map((item) => ({
      code: String(item.code || '').trim().toUpperCase(),
      discount_percent: Number(item.discount_percent),
    }));
  }
}

module.exports = TournamentService;
