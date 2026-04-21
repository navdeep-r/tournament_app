const { ForbiddenError, UnauthorizedError } = require('../errors/HttpErrors');

const adminOnly = (req, res, next) => {
  if (!req.user) throw new UnauthorizedError('Authentication required');
  if (req.user.role !== 'admin') throw new ForbiddenError('Admin access required');
  next();
};

module.exports = { adminOnly };
