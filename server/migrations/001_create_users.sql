CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE TABLE IF NOT EXISTS users (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  google_id       VARCHAR(128) UNIQUE,
  phone           VARCHAR(20) UNIQUE,
  phone_verified  BOOLEAN NOT NULL DEFAULT FALSE,
  name            VARCHAR(255),
  email           VARCHAR(255) UNIQUE,
  profile_image   TEXT,
  role            VARCHAR(20) NOT NULL DEFAULT 'user'
                    CHECK (role IN ('user', 'admin')),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  firebase_uid    VARCHAR(128) UNIQUE,
  refresh_token   TEXT,
  last_login_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
