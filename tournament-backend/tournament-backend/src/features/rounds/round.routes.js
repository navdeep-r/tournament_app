const router = require('express').Router({ mergeParams: true });
const c = require('./round.controller');
const { authenticate } = require('../../core/middleware/auth.middleware');
const { adminOnly } = require('../../core/middleware/admin.middleware');

router.post('/:tournamentId/rounds', authenticate, adminOnly, c.create);
router.get('/:tournamentId/rounds', c.list);
router.get('/:tournamentId/rounds/:rid', c.getById);
router.put('/:tournamentId/rounds/:rid', authenticate, adminOnly, c.update);
router.delete('/:tournamentId/rounds/:rid', authenticate, adminOnly, c.deleteRound);
router.patch('/:tournamentId/rounds/:rid/activate', authenticate, adminOnly, c.activate);
router.patch('/:tournamentId/rounds/:rid/complete', authenticate, adminOnly, c.complete);

module.exports = router;
