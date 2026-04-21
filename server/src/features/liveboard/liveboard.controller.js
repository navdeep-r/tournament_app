const db = require('../../config/db');
const LiveboardService = require('./liveboard.service');

const liveboardService = new LiveboardService({ query: db.query });

const getBoard = async (req, res) => {
  const participants = await liveboardService.getParticipants(req.params.tournamentId);
  res.json({ success: true, data: participants });
};

const getStats = async (req, res) => {
  const stats = await liveboardService.getStats(req.params.tournamentId);
  res.json({ success: true, data: stats });
};

const getBoardByRound = async (req, res) => {
  const participants = await liveboardService.getParticipants(
    req.params.tournamentId,
    req.params.roundId
  );
  res.json({ success: true, data: participants });
};

module.exports = { getBoard, getStats, getBoardByRound };
