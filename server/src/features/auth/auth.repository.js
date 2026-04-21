class UserRepository {
  constructor({ query }) {
    this.query = query;
  }

  async findById(id) {
    const { rows } = await this.query('SELECT * FROM users WHERE id=$1', [id]);
    return rows[0] || null;
  }

  async findByGoogleId(googleId) {
    const { rows } = await this.query('SELECT * FROM users WHERE google_id=$1', [googleId]);
    return rows[0] || null;
  }

  async findByPhone(phone) {
    const { rows } = await this.query('SELECT * FROM users WHERE phone=$1', [phone]);
    return rows[0] || null;
  }

  async findByEmail(email) {
    const { rows } = await this.query('SELECT * FROM users WHERE email=$1', [email]);
    return rows[0] || null;
  }

  async create({ google_id, firebase_uid, email, name, profile_image, phone }) {
    const { rows } = await this.query(
      `INSERT INTO users (google_id, firebase_uid, email, name, profile_image, phone)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [google_id, firebase_uid, email, name, profile_image, phone]
    );
    return rows[0];
  }

  async update(id, fields) {
    const keys = Object.keys(fields);
    const setClause = keys.map((k, i) => `${k}=$${i + 2}`).join(', ');
    const values = keys.map((k) => fields[k]);
    const { rows } = await this.query(
      `UPDATE users SET ${setClause}, updated_at=NOW() WHERE id=$1 RETURNING *`,
      [id, ...values]
    );
    return rows[0];
  }

  async updateLastLogin(id) {
    await this.query('UPDATE users SET last_login_at=NOW(), updated_at=NOW() WHERE id=$1', [id]);
  }

  async updateRefreshToken(id, hashedToken) {
    await this.query('UPDATE users SET refresh_token=$2 WHERE id=$1', [id, hashedToken]);
  }

  async clearRefreshToken(id) {
    await this.query('UPDATE users SET refresh_token=NULL WHERE id=$1', [id]);
  }

  async markPhoneVerified(phone) {
    const { rows } = await this.query(
      `INSERT INTO users (phone, phone_verified) VALUES ($1, TRUE)
       ON CONFLICT (phone) DO UPDATE SET phone_verified=TRUE, updated_at=NOW()
       RETURNING *`,
      [phone]
    );
    return rows[0];
  }
}

class OtpRepository {
  constructor({ query }) {
    this.query = query;
  }

  async create({ phone, otp_hash, expires_at }) {
    const { rows } = await this.query(
      `INSERT INTO otp_sessions (phone, otp_hash, expires_at) VALUES ($1, $2, $3) RETURNING *`,
      [phone, otp_hash, expires_at]
    );
    return rows[0];
  }

  async findActiveByPhone(phone) {
    const { rows } = await this.query(
      `SELECT * FROM otp_sessions
       WHERE phone=$1 AND is_valid=TRUE AND is_used=FALSE AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [phone]
    );
    return rows[0] || null;
  }

  async incrementAttempts(id) {
    await this.query('UPDATE otp_sessions SET attempts=attempts+1 WHERE id=$1', [id]);
  }

  async markUsed(id) {
    await this.query('UPDATE otp_sessions SET is_used=TRUE, is_valid=FALSE WHERE id=$1', [id]);
  }

  async invalidateAllForPhone(phone) {
    await this.query(
      'UPDATE otp_sessions SET is_valid=FALSE WHERE phone=$1 AND is_valid=TRUE',
      [phone]
    );
  }
}

module.exports = { UserRepository, OtpRepository };
