-- 042_seed_100_users_25_25_spec.sql
--
-- Seeds exactly 100 users split into 4 groups:
--   Group A (i=1..25)   : 25 males  — no seeded match
--   Group B (i=26..50)  : 25 females — no seeded match
--   Group C (i=51..75)  : 25 males  — each has 1 female match (with Group D)
--   Group D (i=76..100) : 25 females — each has 1 male match  (with Group C)
--
-- Total: 25 male-female match pairs (between Group C & D).
-- Photos:  1 picsum photo per user (unique seed from user_id hash).
-- Preferences: males seek female, females seek male.

BEGIN;

SET LOCAL "app.current_user_id"  = 'seed-042';
SET LOCAL "app.current_role"     = 'seed';
SET LOCAL "app.correlation_id"   = 'seed-042-2026-03-29';
SET LOCAL "app.request_id"       = 'seed-042-req';
SET LOCAL "app.device_id"        = 'seed-runner';
SET LOCAL "app.platform"         = 'migration';
SET LOCAL "app.ip_address"       = '127.0.0.1';
SET LOCAL "app.geo_country"      = 'IN';
SET LOCAL "app.geo_state"        = 'Karnataka';
SET LOCAL "app.geo_city"         = 'Bengaluru';
SET LOCAL "app.geo_latitude"     = '12.9715987';
SET LOCAL "app.geo_longitude"    = '77.5945627';

-- ── Helper: deterministic UUID from "seed42-{i}" ─────────────────────────────
-- Using a different hash prefix from script 037 to avoid collisions.

WITH users_src AS (
  SELECT
    i,
    (
      substr(md5('seed42-user-' || i::TEXT), 1,  8) || '-' ||
      substr(md5('seed42-user-' || i::TEXT), 9,  4) || '-' ||
      substr(md5('seed42-user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('seed42-user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('seed42-user-' || i::TEXT), 21, 12)
    )::UUID AS user_id,
    CASE
      WHEN i BETWEEN  1 AND  25 THEN 'male'
      WHEN i BETWEEN 26 AND  50 THEN 'female'
      WHEN i BETWEEN 51 AND  75 THEN 'male'
      ELSE                           'female'
    END AS gender,
    CASE
      WHEN i BETWEEN  1 AND  25 THEN 'MA' || lpad(i::TEXT,       2, '0')
      WHEN i BETWEEN 26 AND  50 THEN 'FB' || lpad((i-25)::TEXT,  2, '0')
      WHEN i BETWEEN 51 AND  75 THEN 'MC' || lpad((i-50)::TEXT,  2, '0')
      ELSE                           'FD' || lpad((i-75)::TEXT,  2, '0')
    END AS short_name,
    '+9188' || lpad(i::TEXT, 8, '0') AS phone,
    'seed42user' || i::TEXT || '@example.com' AS email,
    DATE '1993-01-01' + ((i % 3285)) * INTERVAL '1 day' AS dob
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO user_management.users (
  id, phone_number, email, name, date_of_birth, gender, bio,
  country, state, city, profile_completion, is_verified,
  created_at, last_login_at, updated_at
)
SELECT
  u.user_id,
  u.phone,
  u.email,
  'User ' || u.short_name,
  u.dob,
  u.gender,
  'Bio for ' || u.short_name || '. Loves hiking and good conversation.',
  'India',
  'Karnataka',
  'Bengaluru',
  80,
  (u.i % 4 = 0),
  NOW() - ((u.i % 20) || ' days')::INTERVAL,
  NOW() - ((u.i % 8)  || ' hours')::INTERVAL,
  NOW()
FROM users_src u
ON CONFLICT (id) DO NOTHING;

-- ── profile_drafts ────────────────────────────────────────────────────────────
WITH seeded AS (
  SELECT
    (substr(md5('seed42-user-' || i::TEXT), 1,  8) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 9,  4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 13, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 17, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 21, 12))::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO user_management.profile_drafts (user_id, draft_payload, updated_at)
SELECT
  s.user_id,
  jsonb_build_object(
    'name',           u.name,
    'city',           u.city,
    'intent_tags',    jsonb_build_array('serious', 'friendship'),
    'language_tags',  jsonb_build_array('english', 'hindi')
  ),
  NOW()
FROM seeded s
JOIN user_management.users u ON u.id = s.user_id
ON CONFLICT (user_id) DO UPDATE
  SET draft_payload = EXCLUDED.draft_payload,
      updated_at    = NOW();

-- ── preferences ──────────────────────────────────────────────────────────────
WITH seeded AS (
  SELECT
    (substr(md5('seed42-user-' || i::TEXT), 1,  8) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 9,  4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 13, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 17, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 21, 12))::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO user_management.preferences (
  user_id, seeking_genders, min_age_years, max_age_years,
  max_distance_km, serious_only, verified_only, updated_at
)
SELECT
  s.user_id,
  CASE WHEN u.gender = 'male'
       THEN ARRAY['female']::TEXT[]
       ELSE ARRAY['male']::TEXT[] END,
  22, 35, 50, TRUE, FALSE, NOW()
FROM seeded s
JOIN user_management.users u ON u.id = s.user_id
ON CONFLICT (user_id) DO UPDATE
  SET updated_at = NOW();

-- ── user_settings ─────────────────────────────────────────────────────────────
WITH seeded AS (
  SELECT
    (substr(md5('seed42-user-' || i::TEXT), 1,  8) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 9,  4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 13, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 17, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 21, 12))::UUID AS user_id,
    i
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO user_management.user_settings (
  user_id, show_age, show_exact_distance, show_online_status,
  notify_new_match, notify_new_message, notify_likes, theme, updated_at
)
SELECT
  s.user_id,
  TRUE,
  (s.i % 2 = 0),
  TRUE, TRUE, TRUE, TRUE,
  CASE WHEN s.i % 3 = 0 THEN 'dark' ELSE 'auto' END,
  NOW()
FROM seeded s
ON CONFLICT (user_id) DO UPDATE SET updated_at = NOW();

-- ── photos (1 per user, picsum) ───────────────────────────────────────────────
WITH seeded AS (
  SELECT
    (substr(md5('seed42-user-' || i::TEXT), 1,  8) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 9,  4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 13, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 17, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 21, 12))::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO user_management.photos (user_id, photo_url, storage_path, ordering, uploaded_at)
SELECT
  s.user_id,
  'https://picsum.photos/seed/' || replace(s.user_id::TEXT, '-', '') || '/640/960',
  'user-photos/' || s.user_id::TEXT || '/seed_photo.jpg',
  0,
  NOW()
FROM seeded s
ON CONFLICT (user_id, ordering) DO NOTHING;

-- ── wallets ───────────────────────────────────────────────────────────────────
INSERT INTO matching.user_wallets (user_id, coin_balance, updated_at)
SELECT
  (substr(md5('seed42-user-' || i::TEXT), 1,  8) || '-' ||
   substr(md5('seed42-user-' || i::TEXT), 9,  4) || '-' ||
   substr(md5('seed42-user-' || i::TEXT), 13, 4) || '-' ||
   substr(md5('seed42-user-' || i::TEXT), 17, 4) || '-' ||
   substr(md5('seed42-user-' || i::TEXT), 21, 12))::UUID,
  500,
  NOW()
FROM generate_series(1, 100) AS gs(i)
ON CONFLICT (user_id) DO UPDATE
  SET coin_balance = EXCLUDED.coin_balance, updated_at = NOW();

-- ── matches: Group C (i=51..75) ↔ Group D (i=76..100) ────────────────────────
-- Each Group C male (offset j = 1..25) is matched with the corresponding
-- Group D female (offset j = 1..25).
WITH group_c AS (
  SELECT
    j,
    (substr(md5('seed42-user-' || (j + 50)::TEXT), 1,  8) || '-' ||
     substr(md5('seed42-user-' || (j + 50)::TEXT), 9,  4) || '-' ||
     substr(md5('seed42-user-' || (j + 50)::TEXT), 13, 4) || '-' ||
     substr(md5('seed42-user-' || (j + 50)::TEXT), 17, 4) || '-' ||
     substr(md5('seed42-user-' || (j + 50)::TEXT), 21, 12))::UUID AS male_id
  FROM generate_series(1, 25) AS gs(j)
),
group_d AS (
  SELECT
    j,
    (substr(md5('seed42-user-' || (j + 75)::TEXT), 1,  8) || '-' ||
     substr(md5('seed42-user-' || (j + 75)::TEXT), 9,  4) || '-' ||
     substr(md5('seed42-user-' || (j + 75)::TEXT), 13, 4) || '-' ||
     substr(md5('seed42-user-' || (j + 75)::TEXT), 17, 4) || '-' ||
     substr(md5('seed42-user-' || (j + 75)::TEXT), 21, 12))::UUID AS female_id
  FROM generate_series(1, 25) AS gs(j)
),
pairs AS (
  SELECT
    LEAST   (c.male_id, d.female_id) AS user_id_1,
    GREATEST(c.male_id, d.female_id) AS user_id_2,
    c.j
  FROM group_c c
  JOIN group_d d ON d.j = c.j
)
INSERT INTO matching.matches (user_id_1, user_id_2, created_at, last_message_at, chat_count)
SELECT
  p.user_id_1,
  p.user_id_2,
  NOW() - ((p.j % 14) || ' days')::INTERVAL,
  NOW() - ((p.j % 4)  || ' hours')::INTERVAL,
  (p.j % 6)
FROM pairs p
ON CONFLICT (user_id_1, user_id_2) DO NOTHING;

-- ── match_unlock_states for all new matches ───────────────────────────────────
INSERT INTO matching.match_unlock_states (match_id, unlock_state, updated_at)
SELECT m.id, 'matched', NOW()
FROM matching.matches m
JOIN user_management.users u1 ON u1.id = m.user_id_1
JOIN user_management.users u2 ON u2.id = m.user_id_2
WHERE u1.email LIKE 'seed42user%' OR u2.email LIKE 'seed42user%'
ON CONFLICT (match_id) DO UPDATE
  SET unlock_state = EXCLUDED.unlock_state, updated_at = NOW();

-- ── activity events ───────────────────────────────────────────────────────────
WITH seeded AS (
  SELECT
    (substr(md5('seed42-user-' || i::TEXT), 1,  8) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 9,  4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 13, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 17, 4) || '-' ||
     substr(md5('seed42-user-' || i::TEXT), 21, 12))::UUID AS user_id,
    i
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO matching.activity_events (
  event_name, event_domain, user_id, source_service, source_platform,
  source_device_id, ip_address, geo_country, geo_state, geo_city,
  geo_latitude, geo_longitude, payload, created_at
)
SELECT
  'user_seeded',
  'onboarding',
  s.user_id,
  'seed-042',
  CASE WHEN s.i % 2 = 0 THEN 'android' ELSE 'ios' END,
  'seed42-device-' || s.i,
  ('10.40.' || (s.i % 250)::TEXT || '.' || (s.i % 250)::TEXT)::INET,
  'IN', 'Karnataka', 'Bengaluru',
  12.9715987, 77.5945627,
  jsonb_build_object('seed', true, 'spec', '25M-25F-25M_matched-25F_matched'),
  NOW()
FROM seeded s;

COMMIT;
