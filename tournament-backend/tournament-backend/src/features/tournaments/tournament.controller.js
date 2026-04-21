const db = require('../../config/db');
const TournamentRepository = require('./tournament.repository');
const TournamentService = require('./tournament.service');
const { getPagination, getPaginationMeta } = require('../../core/utils/pagination');

const tournamentRepo = new TournamentRepository({ query: db.query, withTransaction: db.withTransaction });
const tournamentService = new TournamentService({ tournamentRepo });

const list = async (req, res) => {
  const { tournaments, meta } = await tournamentService.list(req.query);
  res.json({ success: true, data: tournaments, meta });
};

const getById = async (req, res) => {
  const tournament = await tournamentService.getById(req.params.id);
  res.json({ success: true, data: tournament });
};

const create = async (req, res) => {
  const tournament = await tournamentService.create(req.body, req.user.id);
  res.status(201).json({ success: true, data: tournament });
};

const update = async (req, res) => {
  const tournament = await tournamentService.update(req.params.id, req.body);
  res.json({ success: true, data: tournament });
};

const updateStatus = async (req, res) => {
  const tournament = await tournamentService.updateStatus(req.params.id, req.body.status);
  res.json({ success: true, data: tournament });
};

const deleteTournament = async (req, res) => {
  await tournamentService.delete(req.params.id);
  res.json({ success: true });
};

const getRounds = async (req, res) => {
  const rounds = await tournamentRepo.getRoundsForTournament(req.params.id);
  res.json({ success: true, data: rounds });
};

const getParticipants = async (req, res) => {
  const { limit, offset, page } = getPagination(req.query);
  const { rows } = await db.query(
    `SELECT p.*, u.name, u.email, u.profile_image
     FROM participants p JOIN users u ON u.id = p.user_id
     WHERE p.tournament_id=$1
     ORDER BY p.queue_number ASC
     LIMIT $2 OFFSET $3`,
    [req.params.id, limit, offset]
  );
  const countResult = await db.query(
    'SELECT COUNT(*) FROM participants WHERE tournament_id=$1',
    [req.params.id]
  );
  const total = parseInt(countResult.rows[0].count);
  res.json({ success: true, data: rows, meta: getPaginationMeta(total, page, limit) });
};

const getMyRegistration = async (req, res) => {
  const { rows } = await db.query(
    `SELECT p.*, t.name AS tournament_name
     FROM participants p JOIN tournaments t ON t.id = p.tournament_id
     WHERE p.tournament_id=$1 AND p.user_id=$2`,
    [req.params.id, req.user.id]
  );
  if (!rows[0]) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Registration not found' } });
  res.json({ success: true, data: rows[0] });
};

module.exports = { list, getById, create, update, updateStatus, deleteTournament, getRounds, getParticipants, getMyRegistration };
