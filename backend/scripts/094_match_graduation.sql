-- ─────────────────────────────────────────────────────────────────────────────
-- 094: Graduation — a matched pair leaves Connect together
--
-- When a matched pair becomes a couple the product celebrates it instead of
-- hiding it. Either member of an active, unlocked match proposes graduation
-- with an optional note; the other member confirms or declines; the proposer
-- can withdraw while the proposal is open. One open proposal per match.
--
-- On confirmation, inside one transaction:
--   * the match is marked ended_reason='graduated' but is NOT unmatched — the
--     conversation stays readable and usable;
--   * both members are hidden from discovery through
--     user_management.discovery_pauses (reason 'graduated'); a member can also
--     pause themselves manually (reason 'manual') and resume at any time;
--   * each member who chose share_with_friends has their accepted friends told
--     "X found someone on Connect" (friend_plan notification + activity feed);
--   * a graduation reward row is recorded per member. Billing has no
--     subscription-pause primitive yet, so rewards are recorded as 'pending'
--     for a later billing worker rather than inventing billing behaviour here.
--
-- Fan-out happens in matching.notify_graduation() so a decision can never be
-- recorded without its notifications, and a retry never notifies twice.
--
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ── Graduations ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.match_graduations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  proposer_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  partner_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'proposed' CHECK (
    status IN ('proposed','confirmed','declined','withdrawn')
  ),
  note TEXT CHECK (note IS NULL OR char_length(note) <= 200),
  proposer_share_with_friends BOOLEAN NOT NULL DEFAULT FALSE,
  partner_share_with_friends BOOLEAN NOT NULL DEFAULT FALSE,
  decided_at TIMESTAMPTZ,
  decided_by_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  lock_version INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (proposer_user_id <> partner_user_id),
  CHECK ((status = 'proposed') = (decided_at IS NULL))
);

-- One open proposal per match at a time.
CREATE UNIQUE INDEX IF NOT EXISTS uq_match_graduations_open
  ON matching.match_graduations(match_id)
  WHERE status = 'proposed';
CREATE INDEX IF NOT EXISTS idx_match_graduations_match
  ON matching.match_graduations(match_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_match_graduations_proposer
  ON matching.match_graduations(proposer_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_match_graduations_partner
  ON matching.match_graduations(partner_user_id, created_at DESC);

-- ── Validation: participants are the matched pair, the match is active ───────
CREATE OR REPLACE FUNCTION matching.validate_match_graduation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE m matching.matches%ROWTYPE;
BEGIN
  SELECT * INTO m FROM matching.matches WHERE id = NEW.match_id;
  IF m.id IS NULL THEN
    RAISE EXCEPTION 'graduation match not found';
  END IF;
  IF NOT (
    (NEW.proposer_user_id = m.user_id_1 AND NEW.partner_user_id = m.user_id_2) OR
    (NEW.proposer_user_id = m.user_id_2 AND NEW.partner_user_id = m.user_id_1)
  ) THEN
    RAISE EXCEPTION 'graduation participants must be the matched pair';
  END IF;
  IF TG_OP = 'INSERT' THEN
    IF m.unmatched_at IS NOT NULL OR m.user_1_status <> 'active' OR m.user_2_status <> 'active'
       OR m.user_1_blocked OR m.user_2_blocked THEN
      RAISE EXCEPTION 'graduation requires an active match';
    END IF;
    IF m.ended_reason = 'graduated' THEN
      RAISE EXCEPTION 'this match has already graduated';
    END IF;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    IF OLD.status <> 'proposed' AND NEW.status <> OLD.status THEN
      RAISE EXCEPTION 'a decided graduation is final';
    END IF;
    IF NEW.status <> OLD.status THEN
      NEW.lock_version := OLD.lock_version + 1;
    END IF;
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_match_graduation ON matching.match_graduations;
CREATE TRIGGER trg_validate_match_graduation
BEFORE INSERT OR UPDATE ON matching.match_graduations
FOR EACH ROW EXECUTE FUNCTION matching.validate_match_graduation();

-- ── Rewards: one row per member, applied later by billing ────────────────────
CREATE TABLE IF NOT EXISTS matching.graduation_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  graduation_id UUID NOT NULL REFERENCES matching.match_graduations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('subscription_pause','referral_credit')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','applied','skipped')),
  detail JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (graduation_id, user_id),
  CHECK (jsonb_typeof(detail) = 'object')
);
CREATE INDEX IF NOT EXISTS idx_graduation_rewards_pending
  ON matching.graduation_rewards(created_at)
  WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_graduation_rewards_user
  ON matching.graduation_rewards(user_id, created_at DESC);

-- ── Discovery pauses ─────────────────────────────────────────────────────────
-- A paused member is dealt to nobody and is dealt nobody. Graduation pauses
-- both members; a member can also pause and resume manually. The row is kept
-- after resume (resumed_at set) so the last pause is auditable; a new pause
-- reactivates the same row.
CREATE TABLE IF NOT EXISTS user_management.discovery_pauses (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN ('graduated','manual')),
  paused_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resumed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (resumed_at IS NULL OR resumed_at >= paused_at)
);
CREATE INDEX IF NOT EXISTS idx_discovery_pauses_active
  ON user_management.discovery_pauses(user_id)
  WHERE resumed_at IS NULL;

CREATE OR REPLACE FUNCTION user_management.touch_discovery_pause()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_discovery_pause ON user_management.discovery_pauses;
CREATE TRIGGER trg_touch_discovery_pause
BEFORE INSERT OR UPDATE ON user_management.discovery_pauses
FOR EACH ROW EXECUTE FUNCTION user_management.touch_discovery_pause();

-- ── Fan-out ──────────────────────────────────────────────────────────────────
-- Tells the other member of the match about the actor's decision (category
-- 'match'), and — for a confirmed graduation — each opted-in member's accepted
-- friends (category 'friend_plan', activity 'graduation_confirmed'). Publishes
-- the graduation.<status> domain event. Returns the number of friends told.
CREATE OR REPLACE FUNCTION matching.notify_graduation(
  p_graduation_id UUID, p_actor_user_id UUID, p_status TEXT, p_share_sides TEXT[]
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  g matching.match_graduations%ROWTYPE;
  other_id UUID;
  actor_name TEXT;
  side TEXT;
  member_id UUID;
  partner_id UUID;
  member_name TEXT;
  recipient RECORD;
  title TEXT;
  body TEXT;
  payload JSONB;
  notified INTEGER := 0;
  event_type TEXT := 'graduation.' || p_status;
BEGIN
  SELECT * INTO g FROM matching.match_graduations WHERE id = p_graduation_id;
  IF g.id IS NULL THEN
    RAISE EXCEPTION 'graduation % not found', p_graduation_id;
  END IF;

  -- The other member always hears about a decision.
  IF p_actor_user_id IS NOT NULL THEN
    other_id := CASE WHEN p_actor_user_id = g.proposer_user_id
                     THEN g.partner_user_id ELSE g.proposer_user_id END;
    SELECT COALESCE(NULLIF(BTRIM(name), ''), 'Your match') INTO actor_name
    FROM user_management.users WHERE id = p_actor_user_id;
    title := CASE p_status
      WHEN 'proposed'  THEN actor_name || ' wants to leave Connect together'
      WHEN 'confirmed' THEN actor_name || ' said yes — you found each other'
      WHEN 'declined'  THEN actor_name || ' is not ready to leave yet'
      WHEN 'withdrawn' THEN actor_name || ' withdrew the graduation proposal'
      ELSE NULL END;
    body := CASE p_status
      WHEN 'proposed'  THEN COALESCE('“' || g.note || '” ', '')
                            || 'Confirm and you both leave discovery; your chat stays.'
      WHEN 'confirmed' THEN 'You are both hidden from discovery now. Your chat stays open.'
      WHEN 'declined'  THEN 'Nothing changes — you both stay on Connect.'
      WHEN 'withdrawn' THEN 'Nothing changes — you both stay on Connect.'
      ELSE NULL END;
    IF title IS NOT NULL THEN
      PERFORM matching.enqueue_notification(
        other_id, p_actor_user_id, event_type, 'match', g.id,
        'graduation:' || g.id::text || ':' || p_status || ':partner:' || other_id::text,
        title, body, '/matches/' || g.match_id::text || '/graduation',
        jsonb_build_object(
          'graduation_id', g.id, 'match_id', g.match_id, 'status', p_status,
          'actor_user_id', p_actor_user_id, 'actor_name', actor_name
        ),
        CASE WHEN p_status IN ('proposed','confirmed') THEN 7 ELSE 5 END::SMALLINT
      );
    END IF;
  END IF;

  -- Each opted-in member's accepted friends hear that they found someone.
  -- The friend is never told who: the partner may not have opted in.
  IF p_status = 'confirmed' THEN
    FOREACH side IN ARRAY COALESCE(p_share_sides, '{}'::text[]) LOOP
      IF side = 'proposer' THEN
        member_id := g.proposer_user_id; partner_id := g.partner_user_id;
      ELSIF side = 'partner' THEN
        member_id := g.partner_user_id; partner_id := g.proposer_user_id;
      ELSE
        CONTINUE;
      END IF;
      SELECT COALESCE(NULLIF(BTRIM(name), ''), 'A friend') INTO member_name
      FROM user_management.users WHERE id = member_id;
      title := member_name || ' found someone on Connect';
      body := member_name || ' matched with someone and they are leaving Connect together. '
              || 'Send your congratulations.';
      payload := jsonb_build_object(
        'graduation_id', g.id, 'match_id', g.match_id, 'status', p_status,
        'friend_user_id', member_id, 'friend_name', member_name
      );
      FOR recipient IN
        SELECT * FROM matching.date_plan_share_recipients(member_id, partner_id, '{}'::uuid[])
      LOOP
        INSERT INTO matching.friend_activity_feed(
          user_id, friend_user_id, activity_type, title, description, metadata, created_at
        ) VALUES (
          recipient.recipient_user_id, member_id, 'graduation_confirmed', title, body,
          payload || jsonb_build_object('via', recipient.via), NOW()
        );
        PERFORM matching.enqueue_notification(
          recipient.recipient_user_id, member_id, event_type, 'friend_plan', g.id,
          'graduation:' || g.id::text || ':confirmed:' || member_id::text
            || ':' || recipient.recipient_user_id::text,
          title, body, '/friends', payload || jsonb_build_object('via', recipient.via),
          6::SMALLINT
        );
        notified := notified + 1;
      END LOOP;
    END LOOP;
  END IF;

  PERFORM platform.publish_domain_event(
    event_type, 1, 'graduation', g.id::text, 'mobile-bff.graduation',
    p_actor_user_id, p_actor_user_id, NULL, NULL,
    'graduation:' || event_type || ':' || g.id::text || ':'
      || COALESCE(p_actor_user_id::text, 'system') || ':' || g.lock_version::text,
    jsonb_build_object(
      'match_id', g.match_id, 'status', p_status,
      'proposer_user_id', g.proposer_user_id, 'partner_user_id', g.partner_user_id,
      'proposer_share_with_friends', g.proposer_share_with_friends,
      'partner_share_with_friends', g.partner_share_with_friends,
      'friend_recipients', notified
    ),
    '{}'::jsonb, NOW()
  );
  RETURN notified;
END;
$$;

-- ── Runtime flag, event registry, ownership ──────────────────────────────────
INSERT INTO matching.platform_feature_flags(key, value_bool, description, updated_by)
VALUES ('graduation_enabled', TRUE,
        'Graduation: a matched pair leaves Connect together, friends celebrate, discovery pauses',
        'migration_094')
ON CONFLICT (key) DO NOTHING;

SELECT platform.register_event_source('matching', 'match_graduations', 'graduation');
SELECT platform.register_event_source('matching', 'graduation_rewards', 'graduation.reward');
SELECT platform.register_event_source('user_management', 'discovery_pauses', 'discovery.pause');

INSERT INTO platform.aggregate_ownership(
  aggregate_type, owner_component, source_schema, source_table,
  transaction_boundary, recovery_strategy
) VALUES (
  'graduation', 'mobile-bff.graduation', 'matching', 'match_graduations',
  'single PostgreSQL transaction', 'idempotent command replay'
)
ON CONFLICT (aggregate_type) DO UPDATE
SET owner_component = EXCLUDED.owner_component, updated_at = NOW();

INSERT INTO platform.required_aggregates(aggregate_type)
VALUES ('graduation')
ON CONFLICT DO NOTHING;

COMMIT;
