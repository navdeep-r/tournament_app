CREATE TABLE IF NOT EXISTS tournaments (
  id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                   VARCHAR(255) NOT NULL,
  description            TEXT,
  rules                  TEXT,
  banner_image_url       TEXT,
  entry_fee_paise        INTEGER NOT NULL DEFAULT 0 CHECK (entry_fee_paise >= 0),
  max_participants       INTEGER NOT NULL DEFAULT 500 CHECK (max_participants > 0),
  registered_count       INTEGER NOT NULL DEFAULT 0,
  active_count           INTEGER NOT NULL DEFAULT 0,
  status                 VARCHAR(30) NOT NULL DEFAULT 'draft'
                           CHECK (status IN (
                             'draft','upcoming','registration_open',
                             'registration_closed','live','completed','cancelled'
                           )),
  starts_at              TIMESTAMPTZ NOT NULL,
  ends_at                TIMESTAMPTZ,
  registration_opens_at  TIMESTAMPTZ,
  registration_closes_at TIMESTAMPTZ,
  location               VARCHAR(255),
  current_round_id       UUID,
  winner_user_id         UUID REFERENCES users(id),
  prize_pool_paise       INTEGER NOT NULL DEFAULT 0,
  created_by             UUID NOT NULL REFERENCES users(id),
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON tournaments(status);
CREATE INDEX IF NOT EXISTS idx_tournaments_starts_at ON tournaments(starts_at);
