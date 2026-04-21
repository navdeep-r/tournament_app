const router = require('express').Router();
const controller = require('./auth.controller');
const { validate } = require('../../core/middleware/validate.middleware');
const { authenticate } = require('../../core/middleware/auth.middleware');
const { otpLimiter, authLimiter } = require('../../core/middleware/rateLimiter.middleware');
const { googleSignIn, sendOtp, verifyOtp, refreshSchema } = require('./auth.validation');

router.post('/google', authLimiter, validate(googleSignIn), controller.googleSignIn);
router.post('/phone/send-otp', otpLimiter, validate(sendOtp), controller.sendOtp);
router.post('/phone/verify-otp', otpLimiter, validate(verifyOtp), controller.verifyOtp);
router.post('/refresh', validate(refreshSchema), controller.refresh);
router.post('/logout', authenticate, controller.logout);
router.get('/me', authenticate, controller.getMe);

module.exports = router;
