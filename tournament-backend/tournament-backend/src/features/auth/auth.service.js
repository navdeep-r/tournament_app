const bcrypt = require('bcryptjs');
const axios = require('axios');
const { parsePhoneE164 } = require('../../core/utils/phone');
const { generateOtp } = require('../../core/utils/crypto');
const { signAccess, signRefresh, signPhoneToken, verifyRefresh } = require('../../core/utils/jwt');
const logger = require('../../core/utils/logger');
const {
  BadRequestError,
  ForbiddenError,
  NotFoundError,
  UnauthorizedError,
  TooManyRequestsError,
  ValidationError,
} = require('../../core/errors/HttpErrors');

class AuthService {
  constructor({ userRepo, otpRepo, firebaseAuth }) {
    this.userRepo = userRepo;
    this.otpRepo = otpRepo;
    this.firebaseAuth = firebaseAuth;
  }

  async googleSignIn(idToken) {
    const decoded = await this.firebaseAuth.verifyIdToken(idToken);
    const { uid, email, name, picture } = decoded;

    let user = await this.userRepo.findByGoogleId(uid);
    if (!user) {
      user = await this.userRepo.create({
        google_id: uid,
        firebase_uid: uid,
        email,
        name,
        profile_image: picture,
        phone: null,
      });
    } else if (!user.is_active) {
      throw new ForbiddenError('Account suspended');
    }

    await this.userRepo.updateLastLogin(user.id);
    return this._issueTokenPair(user);
  }

  async sendOtp(rawPhone) {
    const phone = parsePhoneE164(rawPhone);
    if (!phone) throw new BadRequestError('Invalid Indian mobile number');

    const otp = generateOtp();
    const otp_hash = await bcrypt.hash(otp, 10);

    await this.otpRepo.invalidateAllForPhone(phone);
    await this.otpRepo.create({
      phone,
      otp_hash,
      expires_at: new Date(Date.now() + 5 * 60 * 1000),
    });

    if (process.env.MSG91_AUTH_KEY) {
      try {
        await axios.post(
          'https://api.msg91.com/api/v5/otp',
          {
            template_id: process.env.MSG91_TEMPLATE_ID,
            mobile: phone.replace('+', ''),
            otp,
          },
          { headers: { authkey: process.env.MSG91_AUTH_KEY, 'Content-Type': 'application/json' } }
        );
      } catch (err) {
        logger.warn('MSG91 OTP send failed', { phone, err: err.message });
      }
    }

    if (process.env.NODE_ENV !== 'production') {
      logger.info(`OTP for ${phone}: ${otp}`);
    }

    return { success: true, expires_in: 300 };
  }

  async verifyOtp(rawPhone, otp) {
    const phone = parsePhoneE164(rawPhone);
    if (!phone) throw new BadRequestError('Invalid Indian mobile number');

    const session = await this.otpRepo.findActiveByPhone(phone);
    if (!session) throw new ValidationError('OTP expired or not found');

    await this.otpRepo.incrementAttempts(session.id);

    if (session.attempts >= 3) {
      await this.otpRepo.invalidateAllForPhone(phone);
      throw new ValidationError('Max OTP attempts exceeded. Please request a new OTP.');
    }

    const valid = await bcrypt.compare(otp, session.otp_hash);
    if (!valid) throw new ValidationError('Invalid OTP');

    await this.otpRepo.markUsed(session.id);
    await this.userRepo.markPhoneVerified(phone);

    const token = signPhoneToken(phone);
    return { verified: true, token };
  }

  async refreshToken(refreshTokenValue) {
    const decoded = verifyRefresh(refreshTokenValue);
    const user = await this.userRepo.findById(decoded.sub);
    if (!user || !user.is_active) throw new UnauthorizedError('User not found or inactive');
    if (!user.refresh_token) throw new UnauthorizedError('Token revoked');

    const valid = await bcrypt.compare(refreshTokenValue, user.refresh_token);
    if (!valid) throw new UnauthorizedError('Token revoked');

    return this._issueTokenPair(user);
  }

  async logout(userId) {
    await this.userRepo.clearRefreshToken(userId);
    return { success: true };
  }

  async getMe(userId) {
    const user = await this.userRepo.findById(userId);
    if (!user) throw new NotFoundError('User not found');
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      profile_image: user.profile_image,
      role: user.role,
      phone: user.phone,
      phone_verified: user.phone_verified,
    };
  }

  async _issueTokenPair(user) {
    const payload = { sub: user.id, role: user.role, email: user.email };
    const accessToken = signAccess(payload);
    const refreshTokenValue = signRefresh(payload);
    const hashedRefresh = await bcrypt.hash(refreshTokenValue, 10);
    await this.userRepo.updateRefreshToken(user.id, hashedRefresh);

    return {
      access_token: accessToken,
      refresh_token: refreshTokenValue,
      expires_in: 900,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        profile_image: user.profile_image,
        role: user.role,
        phone: user.phone,
        phone_verified: user.phone_verified,
      },
    };
  }
}

module.exports = AuthService;
