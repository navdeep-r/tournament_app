const db = require('../../config/db');
const { auth: firebaseAuth } = require('../../config/firebase');
const AuthService = require('./auth.service');
const { UserRepository, OtpRepository } = require('./auth.repository');

const userRepo = new UserRepository({ query: db.query });
const otpRepo = new OtpRepository({ query: db.query });
const authService = new AuthService({ userRepo, otpRepo, firebaseAuth });

const googleSignIn = async (req, res) => {
  const data = await authService.googleSignIn(req.body.id_token || req.body.idToken);
  res.json({ success: true, data });
};

const sendOtp = async (req, res) => {
  const data = await authService.sendOtp(req.body.phone);
  res.json({ success: true, data });
};

const verifyOtp = async (req, res) => {
  const data = await authService.verifyOtp(req.body.phone, req.body.otp);
  res.json({ success: true, data });
};

const refresh = async (req, res) => {
  const data = await authService.refreshToken(req.body.refresh_token);
  res.json({ success: true, data: { access_token: data.access_token, refresh_token: data.refresh_token, expires_in: data.expires_in } });
};

const logout = async (req, res) => {
  await authService.logout(req.user.id);
  res.json({ success: true });
};

const getMe = async (req, res) => {
  const user = await authService.getMe(req.user.id);
  res.json({ success: true, data: { user } });
};

module.exports = { googleSignIn, sendOtp, verifyOtp, refresh, logout, getMe };
