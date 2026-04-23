const { BadRequestError, NotFoundError, ConflictError } = require('../../core/errors/HttpErrors');

class ParticipantService {
  constructor({ participantRepo, tournamentRepo, withTransaction, query }) {
    this.participantRepo = participantRepo;
    this.tournamentRepo = tournamentRepo;
    this.withTransaction = withTransaction;
    this.query = query;
  }

  _extractReferralCode(referralCodes, code) {
    if (!code || !code.trim()) return null;
    const normalized = code.trim().toUpperCase();
    const source = Array.isArray(referralCodes) ? referralCodes : [];
    return source.find((item) => String(item.code || '').toUpperCase() === normalized) || null;
  }

  _calculatePricing(entryFeePaise, referral) {
    const originalAmountPaise = Number(entryFeePaise || 0);
    const discountPercent = referral ? Number(referral.discount_percent || 0) : 0;
    const discountAmountPaise = Math.min(
      originalAmountPaise,
      Math.round((originalAmountPaise * discountPercent) / 100)
    );
    const amountPaidPaise = Math.max(0, originalAmountPaise - discountAmountPaise);
    return { originalAmountPaise, discountPercent, discountAmountPaise, amountPaidPaise };
  }

  async validateReferralCode(tournamentId, code) {
    if (!code || !code.trim()) {
      throw new BadRequestError('Referral code is required');
    }
    const tournament = await this.tournamentRepo.findById(tournamentId);
    if (!tournament) throw new NotFoundError('Tournament not found');

    const referral = this._extractReferralCode(tournament.referral_codes, code);
    if (!referral) {
      throw new NotFoundError('Referral code does not exist');
    }

    const pricing = this._calculatePricing(tournament.entry_fee_paise, referral);
    return {
      code: String(referral.code).toUpperCase(),
      discount_type: 'percent',
      discount_value: pricing.discountPercent,
      is_valid: true,
      original_amount_paise: pricing.originalAmountPaise,
      discount_amount_paise: pricing.discountAmountPaise,
      final_amount_paise: pricing.amountPaidPaise,
    };
  }

  async register(tournamentId, userId, phone, referralCode) {
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

    const referral = this._extractReferralCode(tournament.referral_codes, referralCode || '');
    if (referralCode && !referral) {
      throw new BadRequestError('Invalid referral code');
    }
    const pricing = this._calculatePricing(tournament.entry_fee_paise, referral);

    const participant = await this.withTransaction(async (client) => {
      const p = await this.participantRepo.createWithQueueNumber(
        {
          tournamentId,
          userId,
          phone,
          referralCode: referral ? String(referral.code).toUpperCase() : null,
          discountPercent: pricing.discountPercent,
          discountAmountPaise: pricing.discountAmountPaise,
          amountPaidPaise: pricing.amountPaidPaise,
        },
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

    return {
      ...participant,
      tournament_name: tournament.name,
      original_amount_paise: pricing.originalAmountPaise,
      discount_paise: pricing.discountAmountPaise,
      amount_paise: pricing.amountPaidPaise,
      applied_referral_code: referral ? String(referral.code).toUpperCase() : null,
    };
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
