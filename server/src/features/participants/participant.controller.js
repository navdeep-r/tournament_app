const db = require('../../config/db');
const ParticipantRepository = require('./participant.repository');
const ParticipantService = require('./participant.service');
const TournamentRepository = require('../tournaments/tournament.repository');

const participantRepo = new ParticipantRepository({ query: db.query, withTransaction: db.withTransaction });
const tournamentRepo = new TournamentRepository({ query: db.query, withTransaction: db.withTransaction });
const participantService = new ParticipantService({
  participantRepo,
  tournamentRepo,
  withTransaction: db.withTransaction,
  query: db.query,
});

const register = async (req, res) => {
  const { phone, referral_code } = req.body;
  if (!phone) {
    return res.status(422).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'phone is required' } });
  }
  const participant = await participantService.register(req.params.id, req.user.id, phone, referral_code);
  res.status(201).json({ success: true, data: participant });
};

const validateReferral = async (req, res) => {
  const { code } = req.body;
  const referral = await participantService.validateReferralCode(req.params.id, code);
  res.json({ success: true, data: referral });
};

const getMyRegistrations = async (req, res) => {
  const registrations = await participantService.getMyRegistrations(req.user.id);
  res.json({ success: true, data: registrations });
};

module.exports = { register, getMyRegistrations, validateReferral };
