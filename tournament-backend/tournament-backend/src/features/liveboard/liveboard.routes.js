const router = require('express').Router();
const c = require('./liveboard.controller');
const { optionalAuthenticate } = require('../../core/middleware/auth.middleware');

router.get('/:tournamentId', optionalAuthenticate, c.getBoard);
router.get('/:tournamentId/stats', c.getStats);
router.get('/:tournamentId/round/:roundId', optionalAuthenticate, c.getBoardByRound);

module.exports = router;
