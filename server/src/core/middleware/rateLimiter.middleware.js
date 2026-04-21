const rateLimit = require('express-rate-limit');

const otpLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 3,
  keyGenerator: (req) => req.body?.phone || req.ip,
  message: { success: false, error: { code: 'TOO_MANY_REQUESTS', message: 'Too many OTP requests. Wait 1 minute.' } },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, error: { code: 'TOO_MANY_REQUESTS', message: 'Too many auth attempts.' } },
  standardHeaders: true,
  legacyHeaders: false,
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  message: { success: false, error: { code: 'TOO_MANY_REQUESTS', message: 'Rate limit exceeded.' } },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = { otpLimiter, authLimiter, apiLimiter };
