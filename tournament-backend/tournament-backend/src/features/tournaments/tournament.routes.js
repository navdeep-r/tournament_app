const router = require('express').Router();
const c = require('./tournament.controller');
const { authenticate, optionalAuthenticate } = require('../../core/middleware/auth.middleware');
const { adminOnly } = require('../../core/middleware/admin.middleware');
const { validate } = require('../../core/middleware/validate.middleware');
const { createTournament, updateTournament, updateStatus } = require('./tournament.validation');

router.get('/', optionalAuthenticate, c.list);
router.get('/:id', optionalAuthenticate, c.getById);
router.get('/:id/rounds', c.getRounds);
router.get('/:id/participants', authenticate, c.getParticipants);
router.get('/:id/my-registration', authenticate, c.getMyRegistration);
router.post('/', authenticate, adminOnly, validate(createTournament), c.create);
router.put('/:id', authenticate, adminOnly, validate(updateTournament), c.update);
router.patch('/:id/status', authenticate, adminOnly, validate(updateStatus), c.updateStatus);
router.delete('/:id', authenticate, adminOnly, c.deleteTournament);

module.exports = router;
