CREATE TABLE IF NOT EXISTS participants (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id      UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id            UUID NOT NULL REFERENCES users(id),
  phone              VARCHAR(20) NOT NULL,
  queue_number       INTEGER NOT NULL CHECK (queue_number > 0),
  status             VARCHAR(30) NOT NULL DEFAULT 'registered'
                       CHECK (status IN (
                         'registered','active','eliminated',
                         'winner','no_show','disqualified'
                       )),
  current_round_id   UUID REFERENCES rounds(id),
  registered_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tournament_id, user_id),
  UNIQUE(tournament_id, queue_number)
);
CREATE TABLE IF NOT EXISTS participant_round_results (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_id UUID NOT NULL REFERENCES participants(id) ON DELETE CASCADE,
  round_id       UUID NOT NULL REFERENCES rounds(id) ON DELETE CASCADE,
  status         VARCHAR(30) NOT NULL DEFAULT 'active'
                   CHECK (status IN ('active','advanced','eliminated','no_show','disqualified')),
  updated_by     UUID REFERENCES users(id),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(participant_id, round_id)
);
CREATE INDEX IF NOT EXISTS idx_participants_tournament ON participants(tournament_id);
CREATE INDEX IF NOT EXISTS idx_participants_user ON participants(user_id);
CREATE INDEX IF NOT EXISTS idx_participants_status ON participants(status);
CREATE INDEX IF NOT EXISTS idx_participants_queue ON participants(tournament_id, queue_number);
