-- ─────────────────────────────────────────────────────────────────────────────
-- 095: Curated daily set, fair-exposure counters and reply signals (DISC-003)
--
-- Every member gets a small curated set (up to five candidates) per UTC day.
-- The set is generated lazily on the first request of the day from the
-- member's ordinary eligible deck — after every safety, block, preference,
-- trust and publication filter — and persisted so it is stable across
-- reloads. Ranking is a weighted sum of the candidate's 24-hour reply rate,
-- active trust badges, recency of activity and tags shared with the viewer,
-- with a fair-exposure adjustment: members who already received more than a
-- daily like cap are down-weighted, members with almost no impressions today
-- get a small boost. Paid spotlight is untouched; nothing here bypasses
-- eligibility.
--
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ── Curated set per member per UTC day ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.daily_candidate_sets (
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  set_date DATE NOT NULL,
  candidate_user_ids UUID[] NOT NULL DEFAULT '{}',
  -- {"<candidate_user_id>": {"reasons": [..], "why": "..", "score": 0.71}}
  reasons JSONB NOT NULL DEFAULT '{}'::jsonb,
  model_version TEXT NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, set_date),
  CHECK (cardinality(candidate_user_ids) <= 5),
  CHECK (jsonb_typeof(reasons) = 'object')
);
CREATE INDEX IF NOT EXISTS idx_daily_candidate_sets_date
  ON matching.daily_candidate_sets(set_date);

-- ── Fair-exposure counters per member per UTC day ────────────────────────────
-- impressions: how many times the member was served in a curated set today.
-- likes_received: likes recorded against the member today (mirrored from
-- matching.swipes when a set is served; matching.swipes stays the source).
CREATE TABLE IF NOT EXISTS matching.member_exposure_counters (
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  counter_date DATE NOT NULL,
  impressions INTEGER NOT NULL DEFAULT 0 CHECK (impressions >= 0),
  likes_received INTEGER NOT NULL DEFAULT 0 CHECK (likes_received >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, counter_date)
);
CREATE INDEX IF NOT EXISTS idx_member_exposure_counters_date
  ON matching.member_exposure_counters(counter_date, impressions);

-- ── Reply signals: 24-hour reply rate over matches in the last 30 days ──────
-- For every match created in the last 30 days and each member of it, the
-- first message the other member sent is an "inbound conversation"; the
-- member replied within a day when they sent a message in that match within
-- 24 hours of it. Members with no inbound conversations have no row, and the
-- ranker gives them the population median rather than zero.
CREATE OR REPLACE VIEW matching.member_reply_signals AS
WITH sides AS (
  SELECT m.id AS match_id, s.user_id, s.other_id
  FROM matching.matches m
  CROSS JOIN LATERAL (
    VALUES (m.user_id_1, m.user_id_2), (m.user_id_2, m.user_id_1)
  ) AS s(user_id, other_id)
  WHERE m.created_at >= NOW() - INTERVAL '30 days'
),
inbound AS (
  SELECT s.match_id, s.user_id,
         (SELECT MIN(i.created_at) FROM matching.messages i
           WHERE i.match_id = s.match_id AND i.sender_id = s.other_id) AS first_inbound_at
  FROM sides s
),
answered AS (
  SELECT i.user_id,
         EXISTS (
           SELECT 1 FROM matching.messages r
           WHERE r.match_id = i.match_id AND r.sender_id = i.user_id
             AND r.created_at > i.first_inbound_at
             AND r.created_at <= i.first_inbound_at + INTERVAL '24 hours'
         ) AS replied_within_day
  FROM inbound i
  WHERE i.first_inbound_at IS NOT NULL
)
SELECT
  a.user_id,
  COUNT(*)::INTEGER AS inbound_conversations,
  COUNT(*) FILTER (WHERE a.replied_within_day)::INTEGER AS replied_within_day,
  ROUND((COUNT(*) FILTER (WHERE a.replied_within_day))::NUMERIC / COUNT(*), 4) AS reply_rate
FROM answered a
GROUP BY a.user_id;

-- ── Runtime flag and event registry ──────────────────────────────────────────
INSERT INTO matching.platform_feature_flags(key, value_bool, description, updated_by)
VALUES ('curated_daily_set_enabled', TRUE,
        'Curated daily candidate set with fair-exposure ranking and reasons', 'migration_095')
ON CONFLICT (key) DO NOTHING;

SELECT platform.register_event_source('matching', 'daily_candidate_sets', 'discovery.daily_set');
SELECT platform.register_event_source('matching', 'member_exposure_counters', 'discovery.exposure');

COMMIT;
