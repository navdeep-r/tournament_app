const logger = require('../utils/logger');
const { NotFoundError } = require('../errors/HttpErrors');

const notFound = (req, res, next) => {
  next(new NotFoundError(`Route ${req.method} ${req.path} not found`));
};

const errorHandler = (err, req, res, next) => {
  logger.error(err.message, {
    method: req.method,
    path: req.path,
    userId: req.user?.id,
    stack: err.stack,
  });

  // Operational errors (AppError subclasses)
  if (err.isOperational) {
    return res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
        ...(err.details ? { details: err.details } : {}),
      },
    });
  }

  // PostgreSQL unique violation
  if (err.code === '23505') {
    return res.status(409).json({
      success: false,
      error: { code: 'CONFLICT', message: 'Resource already exists' },
    });
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    return res.status(400).json({
      success: false,
      error: { code: 'BAD_REQUEST', message: 'Referenced resource not found' },
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      error: { code: 'UNAUTHORIZED', message: 'Invalid or expired token' },
    });
  }

  // Unknown errors
  const isDev = process.env.NODE_ENV !== 'production';
  return res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: isDev ? err.message : 'Internal server error',
      ...(isDev ? { stack: err.stack } : {}),
    },
  });
};

module.exports = { notFound, errorHandler };
