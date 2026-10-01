-- Plans are private by default. Existing friendships/group membership are not consent.
BEGIN;
CREATE TABLE IF NOT EXISTS matching.date_plan_sharing (
  plan_id UUID NOT NULL REFERENCES matching.match_date_plans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  contact_ids UUID[] NOT NULL DEFAULT '{}',
  version INTEGER NOT NULL DEFAULT 0 CHECK (version >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (plan_id, user_id),
  CHECK (cardinality(contact_ids) <= 10)
);

CREATE OR REPLACE FUNCTION matching.date_plan_trusted_recipients(
  p_plan_id UUID, p_user_id UUID, p_partner_user_id UUID
) RETURNS TABLE(recipient_user_id UUID, via TEXT)
LANGUAGE sql STABLE AS $$
  SELECT f.friend_user_id, 'trusted_contact'::text
  FROM matching.date_plan_sharing s
  JOIN matching.match_date_plans p ON p.id=s.plan_id
  JOIN matching.friend_connections f ON f.user_id=s.user_id
    AND f.friend_user_id=ANY(s.contact_ids) AND f.status='accepted'
  JOIN user_management.users u ON u.id=f.friend_user_id
  WHERE s.plan_id=p_plan_id AND s.user_id=p_user_id
    AND p_user_id IN (p.proposer_user_id,p.invitee_user_id)
    AND u.is_active AND NOT u.is_banned
    AND u.id<>p_user_id AND u.id IS DISTINCT FROM p_partner_user_id
    AND NOT EXISTS (SELECT 1 FROM user_management.blocked_users b
      WHERE (b.user_id=p_user_id AND b.blocked_user_id=u.id)
         OR (b.user_id=u.id AND b.blocked_user_id=p_user_id))
$$;

-- Legacy group-based callers fail closed. New callers must supply the plan ID.
CREATE OR REPLACE FUNCTION matching.date_plan_share_recipients(
  p_user_id UUID,p_partner_user_id UUID,p_group_ids UUID[]
) RETURNS TABLE(recipient_user_id UUID, via TEXT)
LANGUAGE sql STABLE AS $$ SELECT NULL::uuid,NULL::text WHERE FALSE $$;

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

  -- Tell only the contacts explicitly selected by each member.
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
      SELECT * FROM matching.date_plan_trusted_recipients(plan.id, member_id, partner_id)
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
      || COALESCE(p_actor_user_id::text, 'system') || ':' || plan.lock_version::text
      || ':sharing:' || (SELECT COALESCE(SUM(version),0)::text FROM matching.date_plan_sharing WHERE plan_id=plan.id),
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

-- Withdraw historical automatic shares and suppress pending deliveries.
-- Already delivered device pushes cannot be retracted.
DELETE FROM matching.friend_activity_feed f WHERE f.activity_type LIKE 'date_plan_%'
AND NOT EXISTS (
  SELECT 1 FROM matching.match_date_plans p
  CROSS JOIN LATERAL matching.date_plan_trusted_recipients(p.id,f.friend_user_id,
    CASE WHEN p.proposer_user_id=f.friend_user_id THEN p.invitee_user_id ELSE p.proposer_user_id END) r
  WHERE p.id::text=f.metadata->>'plan_id' AND r.recipient_user_id=f.user_id
);
DELETE FROM matching.user_notifications n WHERE n.event_type LIKE 'date_plan.%'
  AND n.payload ? 'friend_user_id' AND NOT EXISTS (
    SELECT 1 FROM matching.match_date_plans p
    CROSS JOIN LATERAL matching.date_plan_trusted_recipients(p.id,(n.payload->>'friend_user_id')::uuid,
      CASE WHEN p.proposer_user_id::text=n.payload->>'friend_user_id' THEN p.invitee_user_id ELSE p.proposer_user_id END) r
    WHERE p.id=n.reference_id AND r.recipient_user_id=n.recipient_user_id
  );
UPDATE matching.notification_outbox n SET status='suppressed', processed_at=NOW(),
  last_error='Explicit per-plan contact consent required', updated_at=NOW()
WHERE n.event_type LIKE 'date_plan.%' AND n.payload ? 'friend_user_id'
  AND n.status IN ('pending','retry','processing') AND NOT EXISTS (
    SELECT 1 FROM matching.match_date_plans p
    CROSS JOIN LATERAL matching.date_plan_trusted_recipients(p.id,(n.payload->>'friend_user_id')::uuid,
      CASE WHEN p.proposer_user_id::text=n.payload->>'friend_user_id' THEN p.invitee_user_id ELSE p.proposer_user_id END) r
    WHERE p.id=n.reference_id AND r.recipient_user_id=n.recipient_user_id
  );
COMMIT;
