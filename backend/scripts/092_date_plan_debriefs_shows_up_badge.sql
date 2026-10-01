-- ─────────────────────────────────────────────────────────────────────────────
-- 092: Post-date debrief and the "Shows up" trust badge
--
-- After an accepted plan's window closes, each member answers a ten-second
-- debrief: did it happen, would you meet again, did you feel safe, and an
-- optional note. Answers are private to the member who gave them; the other
-- member only learns whether a debrief was given. When both have answered
-- the plan resolves: both say it happened → completed (and both members'
-- friends are told the date happened); both say it did not → did_not_happen;
-- disagreement → disputed. Completed dates feed the "Shows up" badge through
-- matching.member_date_plan_signals; disputes and no-shows hold it back.
--
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

CREATE TABLE IF NOT EXISTS matching.match_date_plan_debriefs (
  plan_id UUID NOT NULL REFERENCES matching.match_date_plans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  happened BOOLEAN NOT NULL,
  would_meet_again BOOLEAN,
  felt_safe BOOLEAN,
  note TEXT CHECK (note IS NULL OR char_length(note) <= 280),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (plan_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_match_date_plan_debriefs_member
  ON matching.match_date_plan_debriefs(user_id, created_at DESC);

ALTER TABLE matching.match_date_plan_participants
  ADD COLUMN IF NOT EXISTS debrief_reminder_sent_at TIMESTAMPTZ;

-- A debrief must come from a participant of an accepted (or already resolved)
-- plan whose window has started; it is immutable once the plan resolves.
CREATE OR REPLACE FUNCTION matching.validate_match_date_plan_debrief()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE plan matching.match_date_plans%ROWTYPE;
BEGIN
  SELECT * INTO plan FROM matching.match_date_plans WHERE id = NEW.plan_id;
  IF plan.id IS NULL THEN
    RAISE EXCEPTION 'debrief plan not found';
  END IF;
  IF NEW.user_id NOT IN (plan.proposer_user_id, plan.invitee_user_id) THEN
    RAISE EXCEPTION 'debrief must come from a member of the plan';
  END IF;
  IF plan.status NOT IN ('accepted','completed','did_not_happen','disputed') THEN
    RAISE EXCEPTION 'debriefs require an accepted plan';
  END IF;
  IF plan.status <> 'accepted' AND TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'debrief is final once the plan is resolved';
  END IF;
  IF plan.window_start > NOW() THEN
    RAISE EXCEPTION 'debrief opens once the plan starts';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_match_date_plan_debrief
  ON matching.match_date_plan_debriefs;
CREATE TRIGGER trg_validate_match_date_plan_debrief
BEFORE INSERT OR UPDATE ON matching.match_date_plan_debriefs
FOR EACH ROW EXECUTE FUNCTION matching.validate_match_date_plan_debrief();

-- Resolve the plan once both members have answered. Returns the resulting
-- status, or NULL when the plan is still waiting for the other member.
CREATE OR REPLACE FUNCTION matching.resolve_date_plan_from_debriefs(
  p_plan_id UUID, p_actor_user_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  plan matching.match_date_plans%ROWTYPE;
  answers INTEGER;
  happened_count INTEGER;
  resolved TEXT;
BEGIN
  SELECT * INTO plan FROM matching.match_date_plans WHERE id = p_plan_id FOR UPDATE;
  IF plan.id IS NULL OR plan.status <> 'accepted' THEN
    RETURN plan.status;
  END IF;
  SELECT COUNT(*), COUNT(*) FILTER (WHERE happened)
  INTO answers, happened_count
  FROM matching.match_date_plan_debriefs WHERE plan_id = p_plan_id;
  IF answers < 2 THEN
    RETURN NULL;
  END IF;
  resolved := CASE happened_count
    WHEN 2 THEN 'completed'
    WHEN 0 THEN 'did_not_happen'
    ELSE 'disputed' END;
  UPDATE matching.match_date_plans
  SET status = resolved, resolved_at = NOW()
  WHERE id = p_plan_id;
  INSERT INTO matching.match_date_plan_events(plan_id, actor_user_id, event_type, from_status, to_status)
  VALUES (p_plan_id, p_actor_user_id, resolved, 'accepted', resolved);
  IF resolved = 'completed' THEN
    -- The date happened: both members' friends and chosen groups hear it.
    PERFORM matching.notify_date_plan_status(
      p_plan_id, p_actor_user_id, 'completed', ARRAY['proposer','invitee'], FALSE
    );
  ELSE
    PERFORM platform.publish_domain_event(
      'date_plan.' || resolved, 1, 'date_plan', p_plan_id::text, 'mobile-bff.date-plans',
      p_actor_user_id, p_actor_user_id, NULL, NULL,
      'date-plan:resolve:' || p_plan_id::text,
      jsonb_build_object('match_id', plan.match_id, 'status', resolved), '{}'::jsonb, NOW()
    );
  END IF;
  RETURN resolved;
END;
$$;

-- Signals for the "Shows up" badge, over a rolling 180-day window.
CREATE OR REPLACE VIEW matching.member_date_plan_signals AS
WITH member_plans AS (
  SELECT p.id, p.status, p.resolved_at, p.window_end, m.user_id
  FROM matching.match_date_plans p
  CROSS JOIN LATERAL (VALUES (p.proposer_user_id), (p.invitee_user_id)) AS m(user_id)
  WHERE p.status IN ('completed','did_not_happen','disputed')
    AND COALESCE(p.resolved_at, p.window_end) >= NOW() - INTERVAL '180 days'
)
SELECT
  mp.user_id,
  COUNT(*) FILTER (WHERE mp.status = 'completed')::INTEGER AS confirmed_dates,
  COUNT(*) FILTER (WHERE mp.status = 'disputed')::INTEGER AS disputed_dates,
  -- A no-show against this member: the other member said it happened while
  -- this member's own debrief said it did not, or this member never answered.
  COUNT(*) FILTER (
    WHERE mp.status = 'disputed' AND NOT EXISTS (
      SELECT 1 FROM matching.match_date_plan_debriefs d
      WHERE d.plan_id = mp.id AND d.user_id = mp.user_id AND d.happened
    )
  )::INTEGER AS no_show_reports,
  MAX(mp.resolved_at) FILTER (WHERE mp.status = 'completed') AS last_confirmed_at
FROM member_plans mp
GROUP BY mp.user_id;

-- Debrief reminder: a day after the window closes, ask each member who has
-- not answered. Runs inside the existing sweep cadence.
CREATE OR REPLACE FUNCTION matching.date_plan_debrief_sweep(p_now TIMESTAMPTZ DEFAULT NOW())
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  participant RECORD;
  n INTEGER := 0;
BEGIN
  FOR participant IN
    SELECT pp.plan_id, pp.user_id, p.match_id
    FROM matching.match_date_plan_participants pp
    JOIN matching.match_date_plans p ON p.id = pp.plan_id
    WHERE p.status = 'accepted' AND p.window_end + INTERVAL '24 hours' <= p_now
      AND pp.debrief_reminder_sent_at IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM matching.match_date_plan_debriefs d
        WHERE d.plan_id = pp.plan_id AND d.user_id = pp.user_id
      )
    FOR UPDATE OF pp SKIP LOCKED
  LOOP
    PERFORM matching.enqueue_notification(
      participant.user_id, NULL, 'date_plan.debrief_reminder', 'match', participant.plan_id,
      'date-plan:' || participant.plan_id::text || ':debrief_reminder:' || participant.user_id::text,
      'How was your date?', 'A ten-second debrief helps keep Connect honest.',
      '/matches/' || participant.match_id::text || '/plan',
      jsonb_build_object('plan_id', participant.plan_id, 'match_id', participant.match_id),
      4::SMALLINT
    );
    UPDATE matching.match_date_plan_participants
    SET debrief_reminder_sent_at = p_now
    WHERE plan_id = participant.plan_id AND user_id = participant.user_id;
    n := n + 1;
  END LOOP;
  RETURN n;
END;
$$;

SELECT platform.register_event_source('matching', 'match_date_plan_debriefs', 'date_plan.debrief');

COMMIT;
