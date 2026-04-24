const db = require('../../config/db');
const AdminService = require('./admin.service');
const fs = require('fs/promises');
const path = require('path');
const { randomUUID } = require('crypto');
const { BadRequestError } = require('../../core/errors/HttpErrors');

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

const uploadTournamentBanner = async (req, res) => {
  const contentBase64 = req.body?.content_base64;
  const originalFileName = req.body?.filename?.toString() || 'banner';
  if (!contentBase64 || typeof contentBase64 !== 'string') {
    throw new BadRequestError('Image payload is required');
  }

  const match = contentBase64.match(/^data:(image\/(?:jpeg|jpg|png|webp));base64,(.+)$/i);
  if (!match) {
    throw new BadRequestError('Unsupported image format. Use JPG, PNG or WebP.');
  }

  const mimeType = match[1].toLowerCase();
  const base64Body = match[2];
  const imageBuffer = Buffer.from(base64Body, 'base64');
  const maxBytes = 5 * 1024 * 1024;
  if (imageBuffer.length > maxBytes) {
    throw new BadRequestError('Image must be 5 MB or smaller');
  }

  const extMap = {
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp'
  };
  const ext = extMap[mimeType] || 'jpg';
  const safeBaseName = path
    .basename(originalFileName, path.extname(originalFileName))
    .replace(/[^a-zA-Z0-9_-]/g, '_')
    .slice(0, 40);
  const fileName = `${safeBaseName || 'banner'}_${Date.now()}_${randomUUID()}.${ext}`;

  const uploadsDir = path.join(__dirname, '..', '..', '..', 'uploads', 'tournaments');
  await fs.mkdir(uploadsDir, { recursive: true });
  await fs.writeFile(path.join(uploadsDir, fileName), imageBuffer);

  const publicUrl = `${req.protocol}://${req.get('host')}/uploads/tournaments/${fileName}`;
  res.status(201).json({ success: true, data: { url: publicUrl } });
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
  uploadTournamentBanner,
};
