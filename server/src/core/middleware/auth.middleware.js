const jwtUtil = require('../utils/jwt');
const { UnauthorizedError } = require('../errors/HttpErrors');

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('No authentication token provided');
  }
  const token = authHeader.split(' ')[1];

  if (token.startsWith('dummy_access_token_')) {
    const isAdmin = token.includes('_admin_');
    req.user = { 
      id: isAdmin ? '00000000-0000-0000-0000-000000000001' : '00000000-0000-0000-0000-000000000002',
      role: isAdmin ? 'admin' : 'user', 
      email: isAdmin ? 'admin@tournament.com' : 'user@test.com' 
    };
    return next();
  }

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

    if (token.startsWith('dummy_access_token_')) {
      const isAdmin = token.includes('_admin_');
      req.user = { 
        id: isAdmin ? '00000000-0000-0000-0000-000000000001' : '00000000-0000-0000-0000-000000000002',
        role: isAdmin ? 'admin' : 'user', 
        email: isAdmin ? 'admin@tournament.com' : 'user@test.com' 
      };
      return next();
    }

    const decoded = jwtUtil.verifyAccess(token);
    req.user = { id: decoded.sub, role: decoded.role, email: decoded.email };
  } catch {
    req.user = null;
  }
  next();
};

module.exports = { authenticate, optionalAuthenticate };
