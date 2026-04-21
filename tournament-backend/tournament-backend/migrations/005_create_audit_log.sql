CREATE TABLE IF NOT EXISTS otp_sessions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone       VARCHAR(20) NOT NULL,
  otp_hash    VARCHAR(255) NOT NULL,
  attempts    INTEGER NOT NULL DEFAULT 0,
  is_used     BOOLEAN NOT NULL DEFAULT FALSE,
  is_valid    BOOLEAN NOT NULL DEFAULT TRUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_sessions(phone) WHERE is_valid = TRUE AND is_used = FALSE;

CREATE TABLE IF NOT EXISTS audit_log (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type   VARCHAR(50) NOT NULL,
  entity_id     UUID NOT NULL,
  action        VARCHAR(100) NOT NULL,
  performed_by  UUID REFERENCES users(id),
  old_value     JSONB,
  new_value     JSONB,
  metadata      JSONB NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_log(created_at DESC);
