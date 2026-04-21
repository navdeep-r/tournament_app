const Joi = require('joi');

const googleSignIn = Joi.object({
  id_token: Joi.string(),
  idToken: Joi.string(),
}).or('id_token', 'idToken');
const sendOtp = Joi.object({ phone: Joi.string().required() });
const verifyOtp = Joi.object({
  phone: Joi.string().required(),
  otp: Joi.string().length(6).pattern(/^\d+$/).required(),
});
const refreshSchema = Joi.object({ refresh_token: Joi.string().required() });

module.exports = { googleSignIn, sendOtp, verifyOtp, refreshSchema };
