-- ─────────────────────────────────────────────────────────────────────────────
-- 081: Trust retention jobs and legal holds (PEN-05 / PEN-07 / PEN-37 support)
--
-- Implements the retention classes in documents/contracts/trust_operations.v1.json
-- that had policy text but no job:
--   • revoked_authentication_sessions   90 days after revocation, then purged
--   • moderation_safety_and_security_audit  24 months, then purged
--     (security events, row-change history and activity history)
--   • sos_contact_delivery_snapshot     30 days, redacted (now independent of
--     whether an SOS delivery provider is configured)
--   • disabled push tokens              90 days after being disabled
-- Identity evidence (30 days after a final verification decision) needs its
-- private objects deleted, so the BFF's trust retention worker runs that one.
--
-- Legal holds: every class whose policy says legal_hold_override=true skips a
-- member with an active hold. There was no hold mechanism before this.
--
-- Also adds audit.minimize_member_history, which erasure calls: the row-change
-- audit trigger keeps full before/after copies of member rows (names, phone
-- numbers, dates of birth, verification details, SOS locations). Erasure must
-- not leave those copies behind.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS platform.legal_holds (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
  reason      TEXT NOT NULL CHECK (char_length(BTRIM(reason)) BETWEEN 3 AND 500),
  placed_by   UUID NOT NULL,
  placed_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  released_by UUID,
  released_at TIMESTAMPTZ,
  CHECK ((released_at IS NULL) = (released_by IS NULL))
);

CREATE INDEX IF NOT EXISTS idx_legal_holds_active
  ON platform.legal_holds(user_id) WHERE released_at IS NULL;

CREATE OR REPLACE FUNCTION platform.member_on_legal_hold(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT p_user_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM platform.legal_holds
    WHERE user_id = p_user_id AND released_at IS NULL
  )
$$;

INSERT INTO platform.retention_policies (policy_name, relation_name, retention_interval, batch_size)
VALUES
  ('revoked_sessions',         'user_management.auth_sessions',     INTERVAL '90 days',  1000),
  ('disabled_push_tokens',     'user_management.device_push_tokens', INTERVAL '90 days',  1000),
  ('sos_delivery_snapshots',   'matching.sos_delivery_outbox',       INTERVAL '30 days',  1000),
  ('identity_evidence',        'matching.verification_states',       INTERVAL '30 days',  100),
  ('security_audit_history',   'audit.security_events',              INTERVAL '24 months', 1000),
  ('row_change_history',       'audit.change_log',                   INTERVAL '24 months', 1000),
  ('activity_history',         'audit.activity_log',                 INTERVAL '24 months', 1000)
ON CONFLICT (policy_name) DO NOTHING;

-- security_events stays append-only. The single exception is the retention
-- purge below, which marks its own transaction and may only remove rows past
-- the configured retention window. Updates remain impossible.
CREATE OR REPLACE FUNCTION audit.reject_security_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  window_interval INTERVAL;
BEGIN
  IF TG_OP = 'DELETE' AND current_setting('audit.retention_purge', true) = 'on' THEN
    SELECT retention_interval INTO window_interval
    FROM platform.retention_policies
    WHERE policy_name = 'security_audit_history' AND enabled;
    IF window_interval IS NOT NULL AND OLD.occurred_at < NOW() - window_interval THEN
      RETURN OLD;
    END IF;
  END IF;
  RAISE EXCEPTION 'audit.security_events is append-only';
END;
$function$;

CREATE OR REPLACE FUNCTION platform.run_trust_retention(p_batch_size INTEGER DEFAULT 1000)
RETURNS TABLE(
  revoked_sessions INTEGER,
  disabled_push_tokens INTEGER,
  sos_delivery_snapshots INTEGER,
  security_events INTEGER,
  row_changes INTEGER,
  activity_events INTEGER
)
LANGUAGE plpgsql
AS $function$
DECLARE
  batch INTEGER := LEAST(GREATEST(COALESCE(p_batch_size, 1000), 1), 10000);
  window_interval INTERVAL;
BEGIN
  revoked_sessions := 0; disabled_push_tokens := 0; sos_delivery_snapshots := 0;
  security_events := 0; row_changes := 0; activity_events := 0;

  -- Revoked sessions: no legal-hold override in the policy.
  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'revoked_sessions' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (
      SELECT id FROM user_management.auth_sessions
      WHERE revoked_at IS NOT NULL AND revoked_at < NOW() - window_interval
      ORDER BY revoked_at LIMIT batch FOR UPDATE SKIP LOCKED
    )
    DELETE FROM user_management.auth_sessions s USING c WHERE s.id = c.id;
    GET DIAGNOSTICS revoked_sessions = ROW_COUNT;
  END IF;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'disabled_push_tokens' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (
      SELECT id FROM user_management.device_push_tokens
      WHERE NOT enabled AND updated_at < NOW() - window_interval
      ORDER BY updated_at LIMIT batch FOR UPDATE SKIP LOCKED
    )
    DELETE FROM user_management.device_push_tokens t USING c WHERE t.id = c.id;
    GET DIAGNOSTICS disabled_push_tokens = ROW_COUNT;
  END IF;

  -- SOS snapshots: redact contact, location and message; keep delivery status.
  -- Rows whose sender is on legal hold are left intact.
  WITH c AS (
    SELECT id FROM matching.sos_delivery_outbox
    WHERE expires_at <= NOW() AND contact_phone <> '[expired]'
      AND NOT platform.member_on_legal_hold(user_id)
    ORDER BY expires_at LIMIT batch FOR UPDATE SKIP LOCKED
  )
  UPDATE matching.sos_delivery_outbox o
  SET contact_name = '[expired]', contact_phone = '[expired]', message = NULL,
      latitude = NULL, longitude = NULL,
      status = CASE WHEN o.status IN ('pending','retry','processing') THEN 'cancelled' ELSE o.status END,
      last_error = CASE WHEN o.status IN ('pending','retry','processing') THEN 'delivery retention expired' ELSE o.last_error END,
      locked_at = NULL, worker_id = NULL, updated_at = NOW()
  FROM c WHERE o.id = c.id;
  GET DIAGNOSTICS sos_delivery_snapshots = ROW_COUNT;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'security_audit_history' AND enabled;
  IF window_interval IS NOT NULL THEN
    PERFORM set_config('audit.retention_purge', 'on', true);
    WITH c AS (
      SELECT id FROM audit.security_events
      WHERE occurred_at < NOW() - window_interval
        AND NOT platform.member_on_legal_hold(subject_user_id)
        AND NOT platform.member_on_legal_hold(actor_user_id)
      ORDER BY occurred_at LIMIT batch
    )
    DELETE FROM audit.security_events e USING c WHERE e.id = c.id;
    GET DIAGNOSTICS security_events = ROW_COUNT;
    PERFORM set_config('audit.retention_purge', 'off', true);
  END IF;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'row_change_history' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (
      SELECT id FROM audit.change_log
      WHERE changed_at < NOW() - window_interval
        AND NOT platform.member_on_legal_hold(
          CASE WHEN COALESCE(old_data->>'user_id', new_data->>'user_id', '') ~*
                    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
               THEN COALESCE(old_data->>'user_id', new_data->>'user_id')::UUID END)
      ORDER BY changed_at LIMIT batch
    )
    DELETE FROM audit.change_log l USING c WHERE l.id = c.id;
    GET DIAGNOSTICS row_changes = ROW_COUNT;
  END IF;

  SELECT retention_interval INTO window_interval FROM platform.retention_policies
  WHERE policy_name = 'activity_history' AND enabled;
  IF window_interval IS NOT NULL THEN
    WITH c AS (
      SELECT id FROM audit.activity_log
      WHERE occurred_at < NOW() - window_interval
        AND NOT platform.member_on_legal_hold(
          CASE WHEN COALESCE(actor_user_id, '') ~*
                    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
               THEN actor_user_id::UUID END)
      ORDER BY occurred_at LIMIT batch
    )
    DELETE FROM audit.activity_log a USING c WHERE a.id = c.id;
    GET DIAGNOSTICS activity_events = ROW_COUNT;
  END IF;

  RETURN NEXT;
END;
$function$;

-- Erasure support: replace the stored before/after copies of a member's rows
-- with the list of field names that changed, and drop network/location
-- context. The fact that a change happened survives; the personal data does
-- not. Returns the number of history rows minimised.
CREATE OR REPLACE FUNCTION audit.minimize_member_history(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
DECLARE
  member TEXT := p_user_id::TEXT;
  minimised INTEGER;
BEGIN
  UPDATE audit.change_log
  SET old_data = CASE WHEN old_data IS NULL THEN NULL ELSE jsonb_build_object(
        'redacted', 'account_erased',
        'id', old_data->'id',
        'fields', (SELECT COALESCE(jsonb_agg(k ORDER BY k), '[]'::jsonb) FROM jsonb_object_keys(old_data) k)) END,
      new_data = CASE WHEN new_data IS NULL THEN NULL ELSE jsonb_build_object(
        'redacted', 'account_erased',
        'id', new_data->'id',
        'fields', (SELECT COALESCE(jsonb_agg(k ORDER BY k), '[]'::jsonb) FROM jsonb_object_keys(new_data) k)) END,
      ip_address = NULL, source_device_id = NULL,
      geo_country = NULL, geo_state = NULL, geo_city = NULL,
      geo_latitude = NULL, geo_longitude = NULL
  WHERE COALESCE(old_data->>'redacted', new_data->>'redacted', '') <> 'account_erased'
    AND (
      old_data->>'user_id' = member OR new_data->>'user_id' = member OR
      old_data->>'sender_id' = member OR new_data->>'sender_id' = member OR
      old_data->>'sender_user_id' = member OR new_data->>'sender_user_id' = member OR
      (table_schema = 'user_management' AND table_name = 'users'
        AND row_identity->>'id' = member)
    );
  GET DIAGNOSTICS minimised = ROW_COUNT;

  UPDATE audit.activity_log
  SET ip_address = NULL, device_id = NULL, user_agent = NULL,
      geo_country = NULL, geo_state = NULL, geo_city = NULL,
      geo_latitude = NULL, geo_longitude = NULL
  WHERE actor_user_id = member
    AND (ip_address IS NOT NULL OR device_id IS NOT NULL OR user_agent IS NOT NULL
         OR geo_latitude IS NOT NULL OR geo_city IS NOT NULL);
  RETURN minimised;
END;
$function$;
