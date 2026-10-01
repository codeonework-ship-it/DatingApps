BEGIN;

-- Persist the documented appeal workflow rather than collapsing distinct API
-- states into the legacy pending/approved/rejected values.
ALTER TABLE matching.moderation_appeals
  DROP CONSTRAINT IF EXISTS moderation_appeals_status_check;

UPDATE matching.moderation_appeals
SET status = CASE status
  WHEN 'pending' THEN 'submitted'
  WHEN 'approved' THEN 'resolved_upheld'
  WHEN 'rejected' THEN 'resolved_reversed'
  ELSE status
END;

ALTER TABLE matching.moderation_appeals
  ALTER COLUMN status SET DEFAULT 'submitted',
  ADD COLUMN IF NOT EXISTS sla_deadline_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS notification_policy TEXT,
  ADD COLUMN IF NOT EXISTS claimed_at TIMESTAMPTZ;

UPDATE matching.moderation_appeals
SET sla_deadline_at = COALESCE(sla_deadline_at, created_at + INTERVAL '48 hours'),
    notification_policy = COALESCE(NULLIF(notification_policy, ''), 'status_change_email_and_inbox');

ALTER TABLE matching.moderation_appeals
  ALTER COLUMN sla_deadline_at SET DEFAULT (NOW() + INTERVAL '48 hours'),
  ALTER COLUMN sla_deadline_at SET NOT NULL,
  ALTER COLUMN notification_policy SET DEFAULT 'status_change_email_and_inbox',
  ALTER COLUMN notification_policy SET NOT NULL;

ALTER TABLE matching.moderation_appeals
  DROP CONSTRAINT IF EXISTS moderation_appeals_sla_check;

ALTER TABLE matching.moderation_appeals
  ADD CONSTRAINT moderation_appeals_status_check
    CHECK (status IN ('submitted','under_review','resolved_upheld','resolved_reversed')),
  ADD CONSTRAINT moderation_appeals_sla_check
    CHECK (sla_deadline_at >= created_at);

ALTER TABLE matching.moderation_reports
  ADD COLUMN IF NOT EXISTS review_deadline_at TIMESTAMPTZ;

UPDATE matching.moderation_reports
SET review_deadline_at = COALESCE(review_deadline_at, created_at + INTERVAL '24 hours');

ALTER TABLE matching.moderation_reports
  ALTER COLUMN review_deadline_at SET DEFAULT (NOW() + INTERVAL '24 hours'),
  ALTER COLUMN review_deadline_at SET NOT NULL;

ALTER TABLE matching.verification_states
  ADD COLUMN IF NOT EXISTS review_deadline_at TIMESTAMPTZ;

UPDATE matching.verification_states
SET review_deadline_at = COALESCE(review_deadline_at, submitted_at + INTERVAL '24 hours')
WHERE submitted_at IS NOT NULL;

ALTER TABLE matching.sos_alerts
  ADD COLUMN IF NOT EXISTS response_deadline_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS acknowledged_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL;

UPDATE matching.sos_alerts
SET response_deadline_at = COALESCE(
  response_deadline_at,
  created_at + CASE level
    WHEN 'critical' THEN INTERVAL '2 minutes'
    WHEN 'high' THEN INTERVAL '5 minutes'
    WHEN 'medium' THEN INTERVAL '15 minutes'
    ELSE INTERVAL '30 minutes'
  END
);

CREATE INDEX IF NOT EXISTS idx_moderation_reports_open_sla
  ON matching.moderation_reports(review_deadline_at, created_at)
  WHERE status IN ('pending','reviewed');

CREATE INDEX IF NOT EXISTS idx_moderation_appeals_open_sla
  ON matching.moderation_appeals(sla_deadline_at, created_at)
  WHERE status IN ('submitted','under_review');

CREATE INDEX IF NOT EXISTS idx_verification_states_pending_sla
  ON matching.verification_states(review_deadline_at, submitted_at)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_sos_alerts_open_sla
  ON matching.sos_alerts(response_deadline_at, created_at)
  WHERE status IN ('open','acknowledged');

CREATE INDEX IF NOT EXISTS idx_users_enforcement_state
  ON user_management.users(is_banned, suspended_until, suspended_at)
  WHERE is_banned OR suspended_at IS NOT NULL;

CREATE TABLE IF NOT EXISTS audit.security_events (
  id BIGSERIAL PRIMARY KEY,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  txid BIGINT NOT NULL DEFAULT txid_current(),
  event_type TEXT NOT NULL,
  actor_user_id UUID,
  actor_role TEXT NOT NULL,
  subject_user_id UUID,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  correlation_id TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB
);

-- Audit identities intentionally outlive account deletion and therefore must
-- not use foreign keys that would mutate historical rows through ON DELETE.
ALTER TABLE audit.security_events
  DROP CONSTRAINT IF EXISTS security_events_actor_user_id_fkey,
  DROP CONSTRAINT IF EXISTS security_events_subject_user_id_fkey;

CREATE INDEX IF NOT EXISTS idx_security_events_subject_time
  ON audit.security_events(subject_user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_events_type_time
  ON audit.security_events(event_type, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_events_resource
  ON audit.security_events(resource_type, resource_id, occurred_at DESC);

CREATE OR REPLACE FUNCTION audit.reject_security_event_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'audit.security_events is append-only';
END;
$$;

DROP TRIGGER IF EXISTS trg_security_events_immutable ON audit.security_events;
CREATE TRIGGER trg_security_events_immutable
BEFORE UPDATE OR DELETE ON audit.security_events
FOR EACH ROW EXECUTE FUNCTION audit.reject_security_event_mutation();

INSERT INTO public.schema_migrations(version)
VALUES ('055_safety_moderation_enforcement')
ON CONFLICT (version) DO UPDATE SET applied_at = EXCLUDED.applied_at;

COMMIT;
