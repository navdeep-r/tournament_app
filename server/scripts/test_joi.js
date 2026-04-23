const Joi = require('joi');

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
});

console.log('Keys from describe:', Object.keys(createTournament.describe().keys));

try {
  const updateTournament = createTournament.fork(Object.keys(createTournament.describe().keys), (s) => s.optional());

  const data = {
    name: 'Test Tournament',
    description: '',
    max_participants: 500,
    entry_fee_paise: 0,
    rules: '',
    starts_at: '2026-04-24T15:30:00.000'
  };

  const { error, value } = updateTournament.validate(data, { abortEarly: false, stripUnknown: true });
  if (error) {
    console.log('Validation failed:', error.details);
  } else {
    console.log('Validation succeeded:', value);
  }
} catch (e) {
  console.log('Error creating update schema:', e);
}
