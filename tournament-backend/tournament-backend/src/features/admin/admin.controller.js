const db = require('../../config/db');
const AdminService = require('./admin.service');

// wsManager injected lazily from app.locals to avoid circular deps at boot time
const getAdminService = (req) => {
  const wsManager = req.app.get('wsManager');
  return new AdminService({ query: db.query, withTransaction: db.withTransaction, wsManager });
};

const getDashboardStats = async (req, res) => {
  const svc = getAdminService(req);
  const data = await svc.getDashboardStats();
  res.json({ success: true, data });
};

const listTournaments = async (req, res) => {
  const svc = getAdminService(req);
  const { rows, meta } = await svc.listTournaments(req.query);
  res.json({ success: true, data: rows, meta });
};

const getParticipants = async (req, res) => {
  const svc = getAdminService(req);
  const { rows, meta } = await svc.searchParticipants(req.params.id, req.query);
  res.json({ success: true, data: rows, meta });
};

const updateParticipantStatus = async (req, res) => {
  const svc = getAdminService(req);
  const participant = await svc.updateParticipantStatus(
    req.params.id,
    req.body,
    req.user.id
  );
  res.json({ success: true, data: participant });
};

const activateRound = async (req, res) => {
  const svc = getAdminService(req);
  const round = await svc.activateRound(req.params.id, req.params.roundId, req.user.id);
  res.json({ success: true, data: round });
};

const exportParticipantsCSV = async (req, res) => {
  const svc = getAdminService(req);
  await svc.exportParticipantsCSV(req.query.tournament_id, res);
};

const searchParticipants = async (req, res) => {
  const svc = getAdminService(req);
  const { rows, meta } = await svc.searchParticipants(req.params.id, req.query);
  res.json({ success: true, data: rows, meta });
};

const getRevenueSummary = async (req, res) => {
  const svc = getAdminService(req);
  const data = await svc.getRevenueSummary(req.params.id);
  res.json({ success: true, data });
};

module.exports = {
  getDashboardStats,
  listTournaments,
  getParticipants,
  updateParticipantStatus,
  activateRound,
  exportParticipantsCSV,
  searchParticipants,
  getRevenueSummary,
};
