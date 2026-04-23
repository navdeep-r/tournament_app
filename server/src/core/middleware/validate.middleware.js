const { ValidationError } = require('../errors/HttpErrors');

const validate = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
  if (error) {
    const details = error.details.map((d) => ({
      field: d.context?.key || 'unknown',
      message: d.message.replace(/['"]/g, ''),
    }));
    console.error('Validation Error Details:', details, 'Body:', req.body);
    throw new ValidationError('Validation failed', details);
  }
  req.body = value;
  next();
};

const validateQuery = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.query, { abortEarly: false, stripUnknown: true });
  if (error) {
    const details = error.details.map((d) => ({
      field: d.context?.key || 'unknown',
      message: d.message.replace(/['"]/g, ''),
    }));
    throw new ValidationError('Validation failed', details);
  }
  req.query = value;
  next();
};

module.exports = { validate, validateQuery };
