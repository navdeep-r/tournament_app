const jwt = require('jsonwebtoken');
const { UnauthorizedError } = require('../errors/HttpErrors');

const signAccess = (payload) => {
  return jwt.sign(
    { ...payload, iss: 'tournament-hub' },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m' }
  );
};

const signRefresh = (payload) => {
  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  });
};

const signPhoneToken = (phone) => {
  return jwt.sign(
    { phone, type: 'phone_verified' },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: '15m' }
  );
};

const verifyAccess = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_ACCESS_SECRET);
  } catch (err) {
    throw new UnauthorizedError('Invalid or expired access token');
  }
};

const verifyRefresh = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
  } catch (err) {
    throw new UnauthorizedError('Invalid or expired refresh token');
  }
};

const verifyPhoneToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    if (decoded.type !== 'phone_verified') {
      throw new UnauthorizedError('Invalid phone verification token');
    }
    return { phone: decoded.phone };
  } catch (err) {
    if (err.isOperational) throw err;
    throw new UnauthorizedError('Invalid or expired phone token');
  }
};

module.exports = { signAccess, signRefresh, signPhoneToken, verifyAccess, verifyRefresh, verifyPhoneToken };
