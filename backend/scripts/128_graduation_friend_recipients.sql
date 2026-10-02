-- ─────────────────────────────────────────────────────────────────────────────
-- 128: Graduation tells opted-in members' friends again (GO-01)
--
-- 094's matching.notify_graduation() found the friends to tell through
-- matching.date_plan_share_recipients(). Migration 099 made date plans private
-- by default and turned that function into a fail-closed stub for legacy
-- group-based date-plan callers, which silently stopped every graduation
-- friend notification as a side effect.
--
-- Graduation has its own explicit consent: each member chooses
-- share_with_friends on the proposal or the confirmation, per graduation
-- (ENG-010). That choice is the consent 099 required, so graduation gets its
-- own recipient function rather than reviving the group fan-out:
--
--   * the member's accepted friends (their friends list: accepted rows owned
--     by the member in matching.friend_connections);
--   * never the member, never the partner (the friend is not told who);
--   * never inactive or banned accounts;
--   * never a pair blocked in either direction.
--
-- Friend groups are not included: graduation never offered a group choice.
-- date_plan_share_recipients() stays the fail-closed stub from 099.
--
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

CREATE OR REPLACE FUNCTION matching.graduation_share_recipients(
  p_user_id UUID, p_partner_user_id UUID
)
RETURNS TABLE(recipient_user_id UUID, via TEXT)
LANGUAGE sql
STABLE
AS $$
  SELECT DISTINCT f.friend_user_id, 'friend'::text
  FROM matching.friend_connections f
  JOIN user_management.users u ON u.id = f.friend_user_id
  WHERE f.user_id = p_user_id
    AND f.status = 'accepted'
    AND f.friend_user_id <> p_user_id
    AND f.friend_user_id IS DISTINCT FROM p_partner_user_id
    AND u.is_active AND NOT u.is_banned
    AND NOT EXISTS (
      SELECT 1 FROM user_management.blocked_users b
      WHERE (b.user_id = p_user_id AND b.blocked_user_id = f.friend_user_id)
         OR (b.user_id = f.friend_user_id AND b.blocked_user_id = p_user_id)
    )
$$;

-- Same function as 094 except for the recipient source.
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
        SELECT * FROM matching.graduation_share_recipients(member_id, partner_id)
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

COMMIT;
