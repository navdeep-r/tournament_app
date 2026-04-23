const Joi = require('joi');

const referralCodeItem = Joi.object({
  code: Joi.string().trim().uppercase().pattern(/^[A-Z0-9_-]{3,20}$/).required(),
  discount_percent: Joi.number().integer().min(1).max(100).required(),
});

const referralCodesSchema = Joi.array()
  .items(referralCodeItem)
  .max(50)
  .custom((value, helpers) => {
    const codes = value.map((item) => item.code);
    if (new Set(codes).size !== codes.length) {
      return helpers.error('any.invalid', { message: 'Referral codes must be unique' });
    }
    return value;
  })
  .optional();

const createTournament = Joi.object({
  name: Joi.string().max(255).required(),
  description: Joi.string().optional().allow('', null),
  rules: Joi.string().optional().allow('', null),
  entry_fee_paise: Joi.number().integer().min(0).required(),
  max_participants: Joi.number().integer().min(2).max(10000).required(),
  starts_at: Joi.date().iso().required(),
  ends_at: Joi.date().iso().optional().allow(null),
  registration_opens_at: Joi.date().iso().optional().allow(null),
  registration_closes_at: Joi.date().iso().optional().allow(null),
  location: Joi.string().max(255).optional().allow('', null),
  prize_pool_paise: Joi.number().integer().min(0).optional(),
  banner_image_url: Joi.string().uri().optional().allow('', null),
  status: Joi.string().valid('draft', 'upcoming', 'registration_open', 'registration_closed', 'live', 'completed', 'cancelled').optional(),
  referral_codes: referralCodesSchema,
});

const updateTournament = Joi.object({
  name: Joi.string().max(255).optional(),
  description: Joi.string().optional().allow('', null),
  rules: Joi.string().optional().allow('', null),
  entry_fee_paise: Joi.number().integer().min(0).optional().allow(null),
  max_participants: Joi.number().integer().min(2).max(10000).optional().allow(null),
  starts_at: Joi.date().iso().optional().allow(null),
  ends_at: Joi.date().iso().optional().allow(null),
  registration_opens_at: Joi.date().iso().optional().allow(null),
  registration_closes_at: Joi.date().iso().optional().allow(null),
  location: Joi.string().max(255).optional().allow('', null),
  prize_pool_paise: Joi.number().integer().min(0).optional().allow(null),
  banner_image_url: Joi.string().uri().optional().allow('', null),
  status: Joi.string().valid('draft', 'upcoming', 'registration_open', 'registration_closed', 'live', 'completed', 'cancelled').optional(),
  referral_codes: referralCodesSchema.allow(null),
});

const updateStatus = Joi.object({
  status: Joi.string()
    .valid('upcoming', 'registration_open', 'registration_closed', 'live', 'completed', 'cancelled')
    .required(),
});

module.exports = { createTournament, updateTournament, updateStatus };
