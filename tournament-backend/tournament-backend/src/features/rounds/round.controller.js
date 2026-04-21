const db = require('../../config/db');
const RoundRepository = require('./round.repository');
const RoundService = require('./round.service');
const TournamentRepository = require('../tournaments/tournament.repository');

const roundRepo = new RoundRepository({ query: db.query });
const tournamentRepo = new TournamentRepository({ query: db.query, withTransaction: db.withTransaction });
const roundService = new RoundService({ roundRepo, tournamentRepo, query: db.query });

const create = async (req, res) => {
  const round = await roundService.create(req.params.tournamentId, req.body);
  res.status(201).json({ success: true, data: round });
};

const list = async (req, res) => {
  const rounds = await roundRepo.findByTournamentId(req.params.tournamentId);
  res.json({ success: true, data: rounds });
};

const getById = async (req, res) => {
  const round = await roundRepo.findById(req.params.rid);
  if (!round) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Round not found' } });
  res.json({ success: true, data: round });
};

const update = async (req, res) => {
  const round = await roundService.update(req.params.rid, req.body);
  res.json({ success: true, data: round });
};

const deleteRound = async (req, res) => {
  await roundService.delete(req.params.rid);
  res.json({ success: true });
};

const activate = async (req, res) => {
  const round = await roundService.activate(req.params.tournamentId, req.params.rid);
  res.json({ success: true, data: round });
};

const complete = async (req, res) => {
  const round = await roundService.complete(req.params.rid);
  res.json({ success: true, data: round });
};

module.exports = { create, list, getById, update, deleteRound, activate, complete };
