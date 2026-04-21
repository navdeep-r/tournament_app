const jwtUtil = require('../utils/jwt');
const { UnauthorizedError } = require('../errors/HttpErrors');

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('No authentication token provided');
  }
  const token = authHeader.split(' ')[1];
  const decoded = jwtUtil.verifyAccess(token);
  req.user = { id: decoded.sub, role: decoded.role, email: decoded.email };
  next();
};

const optionalAuthenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      req.user = null;
      return next();
    }
    const token = authHeader.split(' ')[1];
    const decoded = jwtUtil.verifyAccess(token);
    req.user = { id: decoded.sub, role: decoded.role, email: decoded.email };
  } catch {
    req.user = null;
  }
  next();
};

module.exports = { authenticate, optionalAuthenticate };
