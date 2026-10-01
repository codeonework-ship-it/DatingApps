-- ─────────────────────────────────────────────────────────────────────────────
-- 091: Date plans on a match, shared with the member's friends and friend groups
--
-- A matched pair can turn a conversation into a concrete plan: a time window,
-- a venue category and area, and an optional note. Every status a member sets
-- on a plan (proposed, accepted, cancelled, safe check-in, need-help check-in,
-- missed check-in) is published to that member's accepted friends and to the
-- friend groups the member chose when proposing or accepting. The other member
-- of the match is always told about decisions on the plan.
--
-- Fan-out is done inside the same transaction as the status change through
-- matching.notify_date_plan_status(), so a plan can never be recorded without
-- its notifications, and a retry of the same status never notifies twice
-- (the notification outbox dedupe key carries plan, status and recipient).
--
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ── Notification category for friend plan updates ────────────────────────────
-- Friends' plan updates are their own category so a member can mute them
-- without muting SOS/safety notifications.
ALTER TABLE matching.notification_outbox
  DROP CONSTRAINT IF EXISTS notification_outbox_category_check;
ALTER TABLE matching.notification_outbox
  ADD CONSTRAINT notification_outbox_category_check CHECK (
    category IN ('match','message','like','nudge','call','safety','system','friend_plan')
  );

ALTER TABLE user_management.user_settings
  ADD COLUMN IF NOT EXISTS notify_friend_plans BOOLEAN NOT NULL DEFAULT TRUE;

-- ── Plans ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.match_date_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matching.matches(id) ON DELETE CASCADE,
  proposer_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  invitee_user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'proposed' CHECK (
    status IN ('proposed','accepted','declined','cancelled','expired',
               'completed','did_not_happen','disputed')
  ),
  window_start TIMESTAMPTZ NOT NULL,
  window_end TIMESTAMPTZ NOT NULL,
  venue_category TEXT NOT NULL CHECK (
    venue_category IN ('coffee','meal','drinks','walk','activity','event','video_call','other')
  ),
  venue_name TEXT CHECK (venue_name IS NULL OR char_length(venue_name) <= 120),
  venue_area TEXT CHECK (venue_area IS NULL OR char_length(venue_area) <= 120),
  note TEXT CHECK (note IS NULL OR char_length(note) <= 280),
  -- Friend groups (matching.community_groups) the proposer chose to share with,
  -- in addition to their accepted friends. The invitee adds their own groups on accept.
  proposer_group_ids UUID[] NOT NULL DEFAULT '{}',
  invitee_group_ids UUID[] NOT NULL DEFAULT '{}',
  checkin_due_at TIMESTAMPTZ NOT NULL,
  decided_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancelled_by_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  cancel_reason TEXT CHECK (cancel_reason IS NULL OR char_length(cancel_reason) <= 200),
  resolved_at TIMESTAMPTZ,
  lock_version INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (proposer_user_id <> invitee_user_id),
  CHECK (window_end > window_start),
  CHECK (window_end - window_start <= INTERVAL '12 hours'),
  CHECK (cardinality(proposer_group_ids) <= 10),
  CHECK (cardinality(invitee_group_ids) <= 10)
);

-- One open plan per match at a time.
CREATE UNIQUE INDEX IF NOT EXISTS uq_match_date_plans_open
  ON matching.match_date_plans(match_id)
  WHERE status IN ('proposed','accepted');
CREATE INDEX IF NOT EXISTS idx_match_date_plans_match
  ON matching.match_date_plans(match_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_match_date_plans_proposer
  ON matching.match_date_plans(proposer_user_id, window_start DESC);
CREATE INDEX IF NOT EXISTS idx_match_date_plans_invitee
  ON matching.match_date_plans(invitee_user_id, window_start DESC);
CREATE INDEX IF NOT EXISTS idx_match_date_plans_checkin_due
  ON matching.match_date_plans(checkin_due_at)
  WHERE status = 'accepted';
CREATE INDEX IF NOT EXISTS idx_match_date_plans_expiry
  ON matching.match_date_plans(window_end)
  WHERE status = 'proposed';

-- ── Participants: per-member check-in and reminder state ─────────────────────
CREATE TABLE IF NOT EXISTS matching.match_date_plan_participants (
  plan_id UUID NOT NULL REFERENCES matching.match_date_plans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  checkin_status TEXT CHECK (checkin_status IS NULL OR checkin_status IN ('safe','need_help')),
  checkin_at TIMESTAMPTZ,
  checkin_note TEXT CHECK (checkin_note IS NULL OR char_length(checkin_note) <= 200),
  reminder_sent_at TIMESTAMPTZ,
  escalated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (plan_id, user_id),
  CHECK (
    (checkin_status IS NULL AND checkin_at IS NULL)
    OR (checkin_status IS NOT NULL AND checkin_at IS NOT NULL)
  )
);

-- ── Append-only status history ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matching.match_date_plan_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES matching.match_date_plans(id) ON DELETE CASCADE,
  actor_user_id UUID,
  event_type TEXT NOT NULL CHECK (event_type ~ '^[a-z_]+$'),
  from_status TEXT,
  to_status TEXT,
  reason TEXT CHECK (reason IS NULL OR char_length(reason) <= 200),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (jsonb_typeof(metadata) = 'object')
);
CREATE INDEX IF NOT EXISTS idx_match_date_plan_events_plan
  ON matching.match_date_plan_events(plan_id, created_at);

-- History rows never change. They only disappear with their plan (a cascade
-- from member erasure or an operator purge); by then the plan row is gone.
CREATE OR REPLACE FUNCTION matching.date_plan_events_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' AND NOT EXISTS (
    SELECT 1 FROM matching.match_date_plans WHERE id = OLD.plan_id
  ) THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'match_date_plan_events is append-only';
END;
$$;

DROP TRIGGER IF EXISTS trg_date_plan_events_append_only
  ON matching.match_date_plan_events;
CREATE TRIGGER trg_date_plan_events_append_only
BEFORE UPDATE OR DELETE ON matching.match_date_plan_events
FOR EACH ROW EXECUTE FUNCTION matching.date_plan_events_append_only();

-- ── Validation: participants are the matched pair, the match is active ───────
CREATE OR REPLACE FUNCTION matching.validate_match_date_plan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE m matching.matches%ROWTYPE;
BEGIN
  SELECT * INTO m FROM matching.matches WHERE id = NEW.match_id;
  IF m.id IS NULL THEN
    RAISE EXCEPTION 'date plan match not found';
  END IF;
  IF NOT (
    (NEW.proposer_user_id = m.user_id_1 AND NEW.invitee_user_id = m.user_id_2) OR
    (NEW.proposer_user_id = m.user_id_2 AND NEW.invitee_user_id = m.user_id_1)
  ) THEN
    RAISE EXCEPTION 'date plan participants must be the matched pair';
  END IF;
  IF TG_OP = 'INSERT' THEN
    IF m.unmatched_at IS NOT NULL OR m.user_1_status <> 'active' OR m.user_2_status <> 'active'
       OR m.user_1_blocked OR m.user_2_blocked THEN
      RAISE EXCEPTION 'date plans require an active match';
    END IF;
    IF NEW.window_start < NOW() - INTERVAL '1 hour' THEN
      RAISE EXCEPTION 'date plan window must be in the future';
    END IF;
    IF NEW.window_start > NOW() + INTERVAL '90 days' THEN
      RAISE EXCEPTION 'date plan window must be within 90 days';
    END IF;
    NEW.checkin_due_at := COALESCE(NEW.checkin_due_at, NEW.window_end + INTERVAL '1 hour');
  END IF;
  IF TG_OP = 'UPDATE' AND NEW.status <> OLD.status THEN
    NEW.lock_version := OLD.lock_version + 1;
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_match_date_plan ON matching.match_date_plans;
CREATE TRIGGER trg_validate_match_date_plan
BEFORE INSERT OR UPDATE ON matching.match_date_plans
FOR EACH ROW EXECUTE FUNCTION matching.validate_match_date_plan();

CREATE OR REPLACE FUNCTION matching.touch_match_date_plan_participant()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE plan_match UUID;
BEGIN
  SELECT match_id INTO plan_match FROM matching.match_date_plans WHERE id = NEW.plan_id;
  IF plan_match IS NULL THEN
    RAISE EXCEPTION 'date plan participant plan not found';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM matching.matches
    WHERE id = plan_match AND NEW.user_id IN (user_id_1, user_id_2)
  ) THEN
    RAISE EXCEPTION 'date plan participant must be a member of the match';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_match_date_plan_participant
  ON matching.match_date_plan_participants;
CREATE TRIGGER trg_touch_match_date_plan_participant
BEFORE INSERT OR UPDATE ON matching.match_date_plan_participants
FOR EACH ROW EXECUTE FUNCTION matching.touch_match_date_plan_participant();

-- ── Who hears about a member's plan ──────────────────────────────────────────
-- Accepted friends of the member, plus active members of the chosen friend
-- groups the member actually belongs to. Blocked pairs (either direction),
-- inactive/banned accounts, the member and their date are never recipients.
CREATE OR REPLACE FUNCTION matching.date_plan_share_recipients(
  p_user_id UUID, p_partner_user_id UUID, p_group_ids UUID[]
)
RETURNS TABLE(recipient_user_id UUID, via TEXT)
LANGUAGE sql
STABLE
AS $$
  WITH candidates AS (
    SELECT f.friend_user_id AS recipient_user_id, 'friend'::text AS via, 0 AS rank
    FROM matching.friend_connections f
    WHERE f.user_id = p_user_id AND f.status = 'accepted'
    UNION ALL
    SELECT gm.user_id, 'group', 1
    FROM matching.community_group_members gm
    JOIN matching.community_group_members me
      ON me.group_id = gm.group_id AND me.user_id = p_user_id AND me.status = 'active'
    WHERE gm.group_id = ANY (COALESCE(p_group_ids, '{}'::uuid[]))
      AND gm.status = 'active'
  ),
  ranked AS (
    SELECT DISTINCT ON (c.recipient_user_id) c.recipient_user_id, c.via
    FROM candidates c
    JOIN user_management.users u ON u.id = c.recipient_user_id
    WHERE c.recipient_user_id <> p_user_id
      AND c.recipient_user_id IS DISTINCT FROM p_partner_user_id
      AND u.is_active AND NOT u.is_banned
      AND NOT EXISTS (
        SELECT 1 FROM user_management.blocked_users b
        WHERE (b.user_id = p_user_id AND b.blocked_user_id = c.recipient_user_id)
           OR (b.user_id = c.recipient_user_id AND b.blocked_user_id = p_user_id)
      )
    ORDER BY c.recipient_user_id, c.rank
  )
  SELECT recipient_user_id, via FROM ranked
$$;

-- ── Human-readable plan summary used in notification bodies ──────────────────
CREATE OR REPLACE FUNCTION matching.date_plan_summary(p matching.match_date_plans)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT to_char(p.window_start AT TIME ZONE 'UTC', 'Dy DD Mon HH24:MI')
         || '–' || to_char(p.window_end AT TIME ZONE 'UTC', 'HH24:MI') || ' UTC · '
         || CASE p.venue_category
              WHEN 'coffee' THEN 'Coffee' WHEN 'meal' THEN 'A meal' WHEN 'drinks' THEN 'Drinks'
              WHEN 'walk' THEN 'A walk' WHEN 'activity' THEN 'An activity' WHEN 'event' THEN 'An event'
              WHEN 'video_call' THEN 'Video call' ELSE 'A date' END
         || COALESCE(' · ' || NULLIF(BTRIM(p.venue_area), ''), '')
$$;

-- ── Fan-out ──────────────────────────────────────────────────────────────────
-- p_sides lists which members' circles hear about this status: 'proposer',
-- 'invitee' or both. p_notify_partner tells the other member of the match.
-- Returns the number of friend/group recipients notified.
CREATE OR REPLACE FUNCTION matching.notify_date_plan_status(
  p_plan_id UUID, p_actor_user_id UUID, p_status TEXT,
  p_sides TEXT[], p_notify_partner BOOLEAN DEFAULT TRUE
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  plan matching.match_date_plans%ROWTYPE;
  side TEXT;
  member_id UUID;
  partner_id UUID;
  member_name TEXT;
  partner_name TEXT;
  group_ids UUID[];
  recipient RECORD;
  summary TEXT;
  title TEXT;
  body TEXT;
  priority SMALLINT := 5;
  activity_type TEXT;
  notified INTEGER := 0;
  event_type TEXT := 'date_plan.' || p_status;
  payload JSONB;
BEGIN
  SELECT * INTO plan FROM matching.match_date_plans WHERE id = p_plan_id;
  IF plan.id IS NULL THEN
    RAISE EXCEPTION 'date plan % not found', p_plan_id;
  END IF;
  summary := matching.date_plan_summary(plan);

  -- Tell the other member of the match about the actor's decision.
  IF p_notify_partner AND p_actor_user_id IS NOT NULL THEN
    partner_id := CASE WHEN p_actor_user_id = plan.proposer_user_id
                       THEN plan.invitee_user_id ELSE plan.proposer_user_id END;
    SELECT COALESCE(NULLIF(BTRIM(name), ''), 'Your match') INTO member_name
    FROM user_management.users WHERE id = p_actor_user_id;
    title := CASE p_status
      WHEN 'proposed'  THEN member_name || ' proposed a date'
      WHEN 'accepted'  THEN member_name || ' accepted your date plan'
      WHEN 'declined'  THEN member_name || ' declined the date plan'
      WHEN 'cancelled' THEN member_name || ' cancelled the date plan'
      WHEN 'safe'      THEN member_name || ' checked in safe'
      ELSE NULL END;
    IF title IS NOT NULL THEN
      body := CASE p_status
        WHEN 'proposed' THEN summary || '. Accept or suggest another time.'
        WHEN 'accepted' THEN summary || '. It is a plan.'
        WHEN 'cancelled' THEN summary || COALESCE('. ' || plan.cancel_reason, '')
        ELSE summary END;
      PERFORM matching.enqueue_notification(
        partner_id, p_actor_user_id, event_type, 'match', plan.id,
        'date-plan:' || plan.id::text || ':' || p_status || ':partner:' || partner_id::text,
        title, body, '/matches/' || plan.match_id::text || '/plan',
        jsonb_build_object(
          'plan_id', plan.id, 'match_id', plan.match_id, 'status', p_status,
          'window_start', plan.window_start, 'window_end', plan.window_end,
          'venue_category', plan.venue_category, 'venue_area', plan.venue_area,
          'actor_user_id', p_actor_user_id, 'actor_name', member_name
        ),
        CASE WHEN p_status IN ('proposed','accepted') THEN 7 ELSE 5 END::SMALLINT
      );
    END IF;
  END IF;

  -- Tell each side's friends and chosen groups.
  FOREACH side IN ARRAY COALESCE(p_sides, '{}'::text[]) LOOP
    IF side = 'proposer' THEN
      member_id := plan.proposer_user_id; partner_id := plan.invitee_user_id;
      group_ids := plan.proposer_group_ids;
    ELSIF side = 'invitee' THEN
      member_id := plan.invitee_user_id; partner_id := plan.proposer_user_id;
      group_ids := plan.invitee_group_ids;
    ELSE
      CONTINUE;
    END IF;
    SELECT COALESCE(NULLIF(BTRIM(name), ''), 'A friend') INTO member_name
    FROM user_management.users WHERE id = member_id;
    SELECT COALESCE(NULLIF(BTRIM(name), ''), 'a match') INTO partner_name
    FROM user_management.users WHERE id = partner_id;

    title := CASE p_status
      WHEN 'proposed'       THEN member_name || ' is planning a date'
      WHEN 'accepted'       THEN member_name || ' has a date with ' || partner_name
      WHEN 'cancelled'      THEN member_name || '''s date plan was cancelled'
      WHEN 'safe'           THEN member_name || ' checked in safe'
      WHEN 'need_help'      THEN member_name || ' needs help'
      WHEN 'checkin_missed' THEN member_name || ' has not checked in after a date'
      WHEN 'completed'      THEN member_name || '''s date happened'
      ELSE member_name || ' updated a date plan' END;
    body := CASE p_status
      WHEN 'proposed'       THEN 'Proposed to ' || partner_name || ': ' || summary
      WHEN 'accepted'       THEN summary
      WHEN 'cancelled'      THEN summary
      WHEN 'safe'           THEN 'After: ' || summary
      WHEN 'need_help'      THEN 'Please reach out now. Plan: ' || summary
      WHEN 'checkin_missed' THEN 'Plan: ' || summary || '. Consider checking on them.'
      ELSE summary END;
    priority := CASE p_status
      WHEN 'need_help' THEN 9 WHEN 'checkin_missed' THEN 8
      WHEN 'accepted' THEN 6 ELSE 5 END;
    activity_type := 'date_plan_' || p_status;
    payload := jsonb_build_object(
      'plan_id', plan.id, 'match_id', plan.match_id, 'status', p_status,
      'friend_user_id', member_id, 'friend_name', member_name,
      'partner_name', partner_name,
      'window_start', plan.window_start, 'window_end', plan.window_end,
      'venue_category', plan.venue_category, 'venue_name', plan.venue_name,
      'venue_area', plan.venue_area
    );

    FOR recipient IN
      SELECT * FROM matching.date_plan_share_recipients(member_id, partner_id, group_ids)
    LOOP
      INSERT INTO matching.friend_activity_feed(
        user_id, friend_user_id, activity_type, title, description, metadata, created_at
      ) VALUES (
        recipient.recipient_user_id, member_id, activity_type, title, body,
        payload || jsonb_build_object('via', recipient.via), NOW()
      );
      PERFORM matching.enqueue_notification(
        recipient.recipient_user_id, member_id, event_type,
        CASE WHEN p_status IN ('need_help','checkin_missed') THEN 'safety' ELSE 'friend_plan' END,
        plan.id,
        'date-plan:' || plan.id::text || ':' || p_status || ':' || member_id::text
          || ':' || recipient.recipient_user_id::text,
        title, body, '/friends/plans', payload || jsonb_build_object('via', recipient.via),
        priority
      );
      notified := notified + 1;
    END LOOP;
  END LOOP;

  PERFORM platform.publish_domain_event(
    event_type, 1, 'date_plan', plan.id::text, 'mobile-bff.date-plans',
    p_actor_user_id, p_actor_user_id, NULL, NULL,
    'date-plan:' || event_type || ':' || plan.id::text || ':'
      || COALESCE(p_actor_user_id::text, 'system') || ':' || plan.lock_version::text,
    jsonb_build_object(
      'match_id', plan.match_id, 'status', p_status,
      'proposer_user_id', plan.proposer_user_id, 'invitee_user_id', plan.invitee_user_id,
      'friend_recipients', notified
    ),
    '{}'::jsonb, NOW()
  );
  RETURN notified;
END;
$$;

-- ── Sweep: expire stale proposals, remind and escalate missed check-ins ──────
-- Called by the BFF worker every few minutes. Idempotent per row.
CREATE OR REPLACE FUNCTION matching.date_plan_checkin_sweep(p_now TIMESTAMPTZ DEFAULT NOW())
RETURNS TABLE(expired INTEGER, reminders INTEGER, escalations INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
  plan_row RECORD;
  participant RECORD;
  n_expired INTEGER := 0;
  n_reminders INTEGER := 0;
  n_escalations INTEGER := 0;
  side TEXT;
BEGIN
  -- Proposals nobody answered before the window closed.
  FOR plan_row IN
    SELECT id FROM matching.match_date_plans
    WHERE status = 'proposed' AND window_end < p_now
    FOR UPDATE SKIP LOCKED
  LOOP
    UPDATE matching.match_date_plans
    SET status = 'expired', resolved_at = p_now WHERE id = plan_row.id;
    INSERT INTO matching.match_date_plan_events(plan_id, actor_user_id, event_type, from_status, to_status)
    VALUES (plan_row.id, NULL, 'expired', 'proposed', 'expired');
    n_expired := n_expired + 1;
  END LOOP;

  -- Reminder to each member one hour after the window closes.
  FOR participant IN
    SELECT pp.plan_id, pp.user_id, p.match_id
    FROM matching.match_date_plan_participants pp
    JOIN matching.match_date_plans p ON p.id = pp.plan_id
    WHERE p.status = 'accepted' AND p.checkin_due_at <= p_now
      AND pp.checkin_status IS NULL AND pp.reminder_sent_at IS NULL
    FOR UPDATE OF pp SKIP LOCKED
  LOOP
    PERFORM matching.enqueue_notification(
      participant.user_id, NULL, 'date_plan.checkin_reminder', 'safety', participant.plan_id,
      'date-plan:' || participant.plan_id::text || ':checkin_reminder:' || participant.user_id::text,
      'How did it go?', 'Tap to check in so your friends know you are safe.',
      '/matches/' || participant.match_id::text || '/plan',
      jsonb_build_object('plan_id', participant.plan_id, 'match_id', participant.match_id),
      8::SMALLINT
    );
    UPDATE matching.match_date_plan_participants
    SET reminder_sent_at = p_now
    WHERE plan_id = participant.plan_id AND user_id = participant.user_id;
    n_reminders := n_reminders + 1;
  END LOOP;

  -- Escalate to the member's friends three hours after the window closes.
  FOR participant IN
    SELECT pp.plan_id, pp.user_id, p.proposer_user_id
    FROM matching.match_date_plan_participants pp
    JOIN matching.match_date_plans p ON p.id = pp.plan_id
    WHERE p.status = 'accepted' AND p.checkin_due_at + INTERVAL '2 hours' <= p_now
      AND pp.checkin_status IS NULL AND pp.escalated_at IS NULL
    FOR UPDATE OF pp SKIP LOCKED
  LOOP
    side := CASE WHEN participant.user_id = participant.proposer_user_id
                 THEN 'proposer' ELSE 'invitee' END;
    PERFORM matching.notify_date_plan_status(
      participant.plan_id, participant.user_id, 'checkin_missed', ARRAY[side], FALSE
    );
    INSERT INTO matching.match_date_plan_events(plan_id, actor_user_id, event_type, from_status, to_status)
    VALUES (participant.plan_id, participant.user_id, 'checkin_missed', 'accepted', 'accepted');
    UPDATE matching.match_date_plan_participants
    SET escalated_at = p_now
    WHERE plan_id = participant.plan_id AND user_id = participant.user_id;
    n_escalations := n_escalations + 1;
  END LOOP;

  RETURN QUERY SELECT n_expired, n_reminders, n_escalations;
END;
$$;

-- ── Runtime flag, event registry, ownership ──────────────────────────────────
INSERT INTO matching.platform_feature_flags(key, value_bool, description, updated_by)
VALUES ('date_plans_enabled', TRUE,
        'Date plans on matches, shared with friends and friend groups', 'migration_091')
ON CONFLICT (key) DO NOTHING;

SELECT platform.register_event_source('matching', 'match_date_plans', 'date_plan');
SELECT platform.register_event_source('matching', 'match_date_plan_participants', 'date_plan.participant');
SELECT platform.register_event_source('matching', 'match_date_plan_events', 'date_plan.event');

INSERT INTO platform.aggregate_ownership(
  aggregate_type, owner_component, source_schema, source_table,
  transaction_boundary, recovery_strategy
) VALUES (
  'date_plan', 'mobile-bff.date-plans', 'matching', 'match_date_plans',
  'single PostgreSQL transaction', 'idempotent command replay'
)
ON CONFLICT (aggregate_type) DO UPDATE
SET owner_component = EXCLUDED.owner_component, updated_at = NOW();

INSERT INTO platform.required_aggregates(aggregate_type)
VALUES ('date_plan')
ON CONFLICT DO NOTHING;

COMMIT;
