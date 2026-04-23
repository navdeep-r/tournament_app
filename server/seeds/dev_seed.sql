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


