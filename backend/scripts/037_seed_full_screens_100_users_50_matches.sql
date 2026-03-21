-- 037_seed_full_screens_100_users_50_matches.sql
-- Seeds 100 users (50 male, 50 female), 50 matches (25 + 25 split),
-- and baseline records across key module tables.

BEGIN;

-- Context for audit/activity triggers
SET LOCAL "app.current_user_id" = 'seed-system';
SET LOCAL "app.current_role" = 'seed';
SET LOCAL "app.correlation_id" = 'seed-correlation-2026-03-21';
SET LOCAL "app.request_id" = 'seed-request-2026-03-21';
SET LOCAL "app.device_id" = 'seed-runner';
SET LOCAL "app.platform" = 'migration';
SET LOCAL "app.ip_address" = '127.0.0.1';
SET LOCAL "app.geo_country" = 'IN';
SET LOCAL "app.geo_state" = 'Karnataka';
SET LOCAL "app.geo_city" = 'Bengaluru';
SET LOCAL "app.geo_latitude" = '12.9715987';
SET LOCAL "app.geo_longitude" = '77.5945627';

WITH users_src AS (
  SELECT
    i,
    (
      substr(md5('user-' || i::TEXT), 1, 8) || '-' ||
      substr(md5('user-' || i::TEXT), 9, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 21, 12)
    )::UUID AS user_id,
    CASE WHEN i <= 50 THEN 'male' ELSE 'female' END AS gender,
    CASE WHEN i <= 50 THEN 'M' || lpad(i::TEXT, 2, '0') ELSE 'F' || lpad((i - 50)::TEXT, 2, '0') END AS short_name,
    '+9199' || lpad(i::TEXT, 8, '0') AS phone,
    'user' || i::TEXT || '@example.com' AS email,
    DATE '1990-01-01' + ((i % 3650)) * INTERVAL '1 day' AS dob
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
  'Seed bio for ' || u.short_name,
  'India',
  'Karnataka',
  'Bengaluru',
  85,
  (u.i % 3 = 0),
  NOW() - ((u.i % 30) || ' days')::INTERVAL,
  NOW() - ((u.i % 10) || ' hours')::INTERVAL,
  NOW()
FROM users_src u
ON CONFLICT (id) DO NOTHING;

WITH seeded_users AS (
  SELECT (
      substr(md5('user-' || i::TEXT), 1, 8) || '-' ||
      substr(md5('user-' || i::TEXT), 9, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 21, 12)
    )::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO user_management.profile_drafts (user_id, draft_payload, updated_at)
SELECT
  su.user_id,
  jsonb_build_object(
    'name', u.name,
    'city', u.city,
    'intent_tags', jsonb_build_array('serious','friendship'),
    'language_tags', jsonb_build_array('english','hindi')
  ),
  NOW()
FROM seeded_users su
JOIN user_management.users u ON u.id = su.user_id
ON CONFLICT (user_id) DO UPDATE
SET draft_payload = EXCLUDED.draft_payload,
    updated_at = NOW();

WITH seeded_users AS (
  SELECT (
      substr(md5('user-' || i::TEXT), 1, 8) || '-' ||
      substr(md5('user-' || i::TEXT), 9, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 21, 12)
    )::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
),
seeded_users_ranked AS (
  SELECT su.user_id, row_number() OVER (ORDER BY su.user_id) AS rn
  FROM seeded_users su
)
INSERT INTO user_management.user_settings (
  user_id, show_age, show_exact_distance, show_online_status,
  notify_new_match, notify_new_message, notify_likes, theme, updated_at
)
SELECT
  sur.user_id,
  TRUE,
  (sur.rn % 2 = 0),
  TRUE,
  TRUE,
  TRUE,
  TRUE,
  CASE WHEN sur.rn % 3 = 0 THEN 'dark' ELSE 'auto' END,
  NOW()
FROM seeded_users_ranked sur
ON CONFLICT (user_id) DO UPDATE
SET updated_at = NOW();

WITH seeded_users AS (
  SELECT (
      substr(md5('user-' || i::TEXT), 1, 8) || '-' ||
      substr(md5('user-' || i::TEXT), 9, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 21, 12)
    )::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO user_management.preferences (
  user_id, seeking_genders, min_age_years, max_age_years,
  max_distance_km, serious_only, verified_only, updated_at
)
SELECT
  su.user_id,
  CASE WHEN u.gender = 'male' THEN ARRAY['female']::TEXT[] ELSE ARRAY['male']::TEXT[] END,
  22,
  36,
  50,
  TRUE,
  FALSE,
  NOW()
FROM seeded_users su
JOIN user_management.users u ON u.id = su.user_id
ON CONFLICT (user_id) DO UPDATE
SET updated_at = NOW();

WITH seeded_users AS (
  SELECT (
      substr(md5('user-' || i::TEXT), 1, 8) || '-' ||
      substr(md5('user-' || i::TEXT), 9, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 21, 12)
    )::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
)
INSERT INTO user_management.photos (user_id, photo_url, ordering, uploaded_at)
SELECT su.user_id, 'https://picsum.photos/seed/' || replace(su.user_id::TEXT, '-', '') || '/640/960', 0, NOW()
FROM seeded_users su
ON CONFLICT (user_id, ordering) DO NOTHING;

WITH seeded_users AS (
  SELECT (
      substr(md5('user-' || i::TEXT), 1, 8) || '-' ||
      substr(md5('user-' || i::TEXT), 9, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 21, 12)
    )::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
),
seeded_users_ranked AS (
  SELECT su.user_id, row_number() OVER (ORDER BY su.user_id) AS rn
  FROM seeded_users su
)
INSERT INTO user_management.user_login_sessions (
  user_id, request_id, correlation_id, device_id, device_platform,
  device_model, app_version, ip_address, user_agent,
  geo_country, geo_state, geo_city, geo_latitude, geo_longitude,
  login_at, is_active
)
SELECT
  sur.user_id,
  'seed-login-' || sur.rn,
  'seed-corr-' || sur.rn,
  'device-' || sur.rn,
  CASE WHEN sur.rn % 2 = 0 THEN 'android' ELSE 'ios' END,
  CASE WHEN sur.rn % 2 = 0 THEN 'Pixel' ELSE 'iPhone' END,
  '1.0.0',
  ('10.20.' || ((sur.rn % 250)::TEXT) || '.' || ((sur.rn % 250)::TEXT))::INET,
  'SeedAgent/1.0',
  'IN',
  'Karnataka',
  'Bengaluru',
  12.9715987,
  77.5945627,
  NOW() - ((sur.rn % 7) || ' days')::INTERVAL,
  TRUE
FROM seeded_users_ranked sur;

INSERT INTO matching.gift_catalog (id, name, gif_url, icon_key, tier, price_coins, is_limited, is_active, sort_order)
VALUES
  ('rose_red_single', 'Single Red Rose', 'https://media.giphy.com/media/26xBwdIuRJiAIqHwA/giphy.gif', 'rose_red', 'free', 0, FALSE, TRUE, 10),
  ('rose_pink_soft', 'Pink Rose', 'https://media.giphy.com/media/fVtcfEXWQJQUbsF1sH/giphy.gif', 'rose_pink', 'free', 0, FALSE, TRUE, 20),
  ('rose_white_pure', 'White Rose', 'https://media.giphy.com/media/xT1XGzAnABSXy8DPCU/giphy.gif', 'rose_white', 'free', 0, FALSE, TRUE, 30),
  ('rose_yellow_friendship', 'Yellow Rose', 'https://media.giphy.com/media/l0Iy5tjhyfU1xL9wQ/giphy.gif', 'rose_yellow', 'free', 0, FALSE, TRUE, 40),
  ('rose_lavender_crush', 'Lavender Rose', 'https://media.giphy.com/media/26xBukhL8Y5H9P9VS/giphy.gif', 'rose_lavender', 'free', 0, FALSE, TRUE, 50),
  ('rose_blue_rare', 'Blue Rose', 'https://media.giphy.com/media/3oz8xAFtqoOUUrsh7W/giphy.gif', 'rose_blue', 'premium_common', 1, FALSE, TRUE, 60),
  ('rose_black_mystery', 'Black Rose', 'https://media.giphy.com/media/l0ExncehJzexFpRHq/giphy.gif', 'rose_black', 'premium_common', 1, FALSE, TRUE, 70),
  ('rose_sparkle', 'Sparkle Rose', 'https://media.giphy.com/media/3o7TKz9b9NQwQ2N8hW/giphy.gif', 'rose_sparkle', 'premium_rare', 3, FALSE, TRUE, 80),
  ('rose_heart_petal', 'Heart-Petal Rose', 'https://media.giphy.com/media/l41YvpiA9uMWw5AMU/giphy.gif', 'rose_heart', 'premium_rare', 3, FALSE, TRUE, 90),
  ('rose_neon_glow', 'Neon Rose', 'https://media.giphy.com/media/l0Ex7d6Q5V3sz9N16/giphy.gif', 'rose_neon', 'premium_rare', 3, FALSE, TRUE, 95),
  ('rose_rain', 'Rose Rain', 'https://media.giphy.com/media/l41YB9N3dM2P8xTzG/giphy.gif', 'rose_rain', 'premium_epic', 5, FALSE, TRUE, 100),
  ('rose_burning_flame', 'Burning Rose', 'https://media.giphy.com/media/3o6Zt481isNVuQI1l6/giphy.gif', 'rose_burning', 'premium_epic', 5, FALSE, TRUE, 105),
  ('rose_golden', 'Golden Rose', 'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif', 'rose_gold', 'premium_legendary', 8, TRUE, TRUE, 110),
  ('rose_crystal', 'Crystal Rose', 'https://media.giphy.com/media/3o7aD2saalBwwftBIY/giphy.gif', 'rose_crystal', 'premium_legendary', 10, TRUE, TRUE, 120),
  ('rose_bouquet_12', 'Rose Bouquet (12)', 'https://media.giphy.com/media/xTiTnMhJTwNHChdTZS/giphy.gif', 'rose_bouquet', 'premium_legendary', 8, TRUE, TRUE, 125),
  ('rose_bouquet_24', 'Rose Bouquet (24)', 'https://media.giphy.com/media/26xBydxfjxsRQggh2/giphy.gif', 'rose_bouquet', 'premium_legendary', 10, TRUE, TRUE, 130),
  ('rose_seasonal_weekly', 'Seasonal Limited Rose', 'https://media.giphy.com/media/l0MYAs5E2oIDCq9So/giphy.gif', 'rose_seasonal', 'seasonal_limited', 6, TRUE, TRUE, 140)
ON CONFLICT (id) DO NOTHING;

INSERT INTO matching.user_wallets (user_id, coin_balance, updated_at)
SELECT (
      substr(md5('user-' || i::TEXT), 1, 8) || '-' ||
      substr(md5('user-' || i::TEXT), 9, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 21, 12)
    )::UUID,
    1000,
    NOW()
FROM generate_series(1, 100) AS gs(i)
ON CONFLICT (user_id) DO UPDATE SET coin_balance = EXCLUDED.coin_balance, updated_at = NOW();

WITH male AS (
  SELECT id, row_number() OVER (ORDER BY id) AS rn
  FROM user_management.users
  WHERE gender = 'male'
  LIMIT 50
),
female AS (
  SELECT id, row_number() OVER (ORDER BY id) AS rn
  FROM user_management.users
  WHERE gender = 'female'
  LIMIT 50
),
pairs AS (
  -- 25 male-driven pairs (male 1-25 with female 1-25)
  SELECT m.id AS a, f.id AS b
  FROM male m
  JOIN female f ON f.rn = m.rn
  WHERE m.rn BETWEEN 1 AND 25

  UNION ALL

  -- 25 female-driven pairs (female 26-50 with male 26-50)
  SELECT f.id AS a, m.id AS b
  FROM female f
  JOIN male m ON m.rn = f.rn
  WHERE f.rn BETWEEN 26 AND 50
),
normalized AS (
  SELECT
    LEAST(a, b) AS user_id_1,
    GREATEST(a, b) AS user_id_2
  FROM pairs
)
INSERT INTO matching.matches (user_id_1, user_id_2, created_at, last_message_at, chat_count)
SELECT
  n.user_id_1,
  n.user_id_2,
  NOW() - ((row_number() OVER (ORDER BY n.user_id_1, n.user_id_2) % 20) || ' days')::INTERVAL,
  NOW() - ((row_number() OVER (ORDER BY n.user_id_1, n.user_id_2) % 5) || ' hours')::INTERVAL,
  (row_number() OVER (ORDER BY n.user_id_1, n.user_id_2) % 10)
FROM normalized n
ON CONFLICT (user_id_1, user_id_2) DO NOTHING;

INSERT INTO matching.match_unlock_states (match_id, unlock_state, updated_at)
SELECT m.id, 'matched', NOW()
FROM matching.matches m
ON CONFLICT (match_id) DO UPDATE SET unlock_state = EXCLUDED.unlock_state, updated_at = NOW();

INSERT INTO matching.daily_prompts (prompt_date, prompt_text, domain, created_at)
VALUES
  (CURRENT_DATE, 'What made you smile today?', 'connection', NOW()),
  (CURRENT_DATE + INTERVAL '1 day', 'What is one value you never compromise on?', 'values', NOW())
ON CONFLICT (prompt_date) DO NOTHING;

WITH seeded_users AS (
  SELECT (
      substr(md5('user-' || i::TEXT), 1, 8) || '-' ||
      substr(md5('user-' || i::TEXT), 9, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 13, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 17, 4) || '-' ||
      substr(md5('user-' || i::TEXT), 21, 12)
    )::UUID AS user_id
  FROM generate_series(1, 100) AS gs(i)
),
seeded_users_ranked AS (
  SELECT su.user_id, row_number() OVER (ORDER BY su.user_id) AS rn
  FROM seeded_users su
)
INSERT INTO matching.activity_events (
  event_name, event_domain, user_id, source_service, source_platform,
  source_device_id, ip_address, geo_country, geo_state, geo_city,
  geo_latitude, geo_longitude, payload, created_at
)
SELECT
  'user_seeded',
  'onboarding',
  sur.user_id,
  'seed-script',
  CASE WHEN sur.rn % 2 = 0 THEN 'android' ELSE 'ios' END,
  'seed-device-' || sur.rn,
  ('10.30.' || ((sur.rn % 250)::TEXT) || '.' || ((sur.rn % 250)::TEXT))::INET,
  'IN',
  'Karnataka',
  'Bengaluru',
  12.9715987,
  77.5945627,
  jsonb_build_object('seed', true),
  NOW()
FROM seeded_users_ranked sur;

COMMIT;
