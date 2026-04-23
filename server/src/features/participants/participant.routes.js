const router = require('express').Router();
const c = require('./participant.controller');
const { authenticate } = require('../../core/middleware/auth.middleware');

// Mounted at /api/participants
router.get('/my', authenticate, c.getMyRegistrations);

// Also handles /api/tournaments/:id/register (mounted at /api/tournaments)
router.post('/:id/referral/validate', authenticate, c.validateReferral);
router.post('/:id/register', authenticate, c.register);

module.exports = router;
