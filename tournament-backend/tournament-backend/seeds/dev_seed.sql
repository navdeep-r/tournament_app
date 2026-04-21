-- Admin user
INSERT INTO users (id, name, email, role, google_id, firebase_uid, is_active)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Admin User', 'admin@tournament.com', 'admin',
  'admin_google_123', 'admin_firebase_123', TRUE
) ON CONFLICT (google_id) DO NOTHING;

-- Test user with phone
INSERT INTO users (id, name, email, role, google_id, firebase_uid, phone, phone_verified, is_active)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  'Test User', 'user@test.com', 'user',
  'user_google_456', 'user_firebase_456',
  '+919876543210', TRUE, TRUE
) ON CONFLICT (google_id) DO NOTHING;

-- Live tournament
INSERT INTO tournaments (
  id, name, description, entry_fee_paise, max_participants,
  registered_count, active_count, status, starts_at,
  registration_opens_at, registration_closes_at, created_by
) VALUES (
  '00000000-0000-0000-0001-000000000001',
  'Summer Championship 2026',
  'The biggest tournament of the summer! Win exciting prizes.',
  20000, 100, 5, 4, 'live',
  NOW() - INTERVAL '2 hours',
  NOW() - INTERVAL '5 days',
  NOW() - INTERVAL '3 hours',
  '00000000-0000-0000-0000-000000000001'
) ON CONFLICT (id) DO NOTHING;

-- Upcoming tournament
INSERT INTO tournaments (
  id, name, description, entry_fee_paise, max_participants,
  status, starts_at, registration_opens_at, registration_closes_at, created_by
) VALUES (
  '00000000-0000-0000-0001-000000000002',
  'Weekend Warriors Cup',
  'Fast-paced weekend tournament. Register now!',
  10000, 50, 'registration_open',
  NOW() + INTERVAL '2 days',
  NOW() - INTERVAL '1 day',
  NOW() + INTERVAL '1 day',
  '00000000-0000-0000-0000-000000000001'
) ON CONFLICT (id) DO NOTHING;

-- Rounds for live tournament
INSERT INTO rounds (id, tournament_id, round_number, name, status, started_at, ended_at)
VALUES
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 1, 'Qualifying Round', 'completed', NOW()-INTERVAL '90 minutes', NOW()-INTERVAL '30 minutes'),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 2, 'Semi Finals', 'active', NOW()-INTERVAL '20 minutes', NULL),
  ('00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0001-000000000001', 3, 'Grand Final', 'pending', NULL, NULL)
ON CONFLICT (tournament_id, round_number) DO NOTHING;

UPDATE tournaments
SET current_round_id = '00000000-0000-0000-0002-000000000002'
WHERE id = '00000000-0000-0000-0001-000000000001';

-- Participant
INSERT INTO participants (tournament_id, user_id, phone, queue_number, status)
VALUES (
  '00000000-0000-0000-0001-000000000001',
  '00000000-0000-0000-0000-000000000002',
  '+919876543210', 1, 'active'
) ON CONFLICT (tournament_id, user_id) DO NOTHING;
