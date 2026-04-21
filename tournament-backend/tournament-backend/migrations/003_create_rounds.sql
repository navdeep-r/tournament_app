CREATE TABLE IF NOT EXISTS rounds (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id    UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  round_number     INTEGER NOT NULL CHECK (round_number > 0),
  name             VARCHAR(255) NOT NULL,
  description      TEXT,
  max_participants INTEGER,
  scheduled_at     TIMESTAMPTZ,
  started_at       TIMESTAMPTZ,
  ended_at         TIMESTAMPTZ,
  status           VARCHAR(20) NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending','active','completed','cancelled')),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tournament_id, round_number)
);
ALTER TABLE tournaments ADD CONSTRAINT fk_current_round
  FOREIGN KEY (current_round_id) REFERENCES rounds(id) DEFERRABLE INITIALLY DEFERRED;
CREATE INDEX IF NOT EXISTS idx_rounds_tournament ON rounds(tournament_id);
CREATE INDEX IF NOT EXISTS idx_rounds_status ON rounds(status);
