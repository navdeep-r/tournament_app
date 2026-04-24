const router = require('express').Router();
const c = require('./admin.controller');
const { authenticate } = require('../../core/middleware/auth.middleware');
const { adminOnly } = require('../../core/middleware/admin.middleware');

router.use(authenticate, adminOnly);

router.get('/dashboard', c.getDashboardStats);
router.get('/tournaments', c.listTournaments);
router.post('/uploads/tournament-banner', c.uploadTournamentBanner);
router.get('/tournaments/:id/participants', c.getParticipants);
router.patch('/participants/:id/status', c.updateParticipantStatus);
router.post('/tournaments/:id/rounds/:roundId/activate', c.activateRound);
router.get('/participants/export', c.exportParticipantsCSV);
router.get('/tournaments/:id/participants/search', c.searchParticipants);
router.get('/tournaments/:id/revenue-summary', c.getRevenueSummary);

module.exports = router;
