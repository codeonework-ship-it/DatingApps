BEGIN;

-- One durable delivery per trusted contact. The contact snapshot is required
-- because a user may edit the address book immediately after triggering SOS;
-- successful alert creation must not lose the committed targets.
CREATE TABLE IF NOT EXISTS matching.sos_delivery_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_id UUID NOT NULL REFERENCES matching.sos_alerts(id) ON DELETE CASCADE,
  contact_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
  contact_name TEXT NOT NULL,
  contact_phone TEXT NOT NULL,
  level TEXT NOT NULL CHECK (level IN ('low','medium','high','critical')),
  message TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  response_deadline_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','retry','delivered','dead_letter','cancelled')),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  max_attempts INTEGER NOT NULL DEFAULT 8 CHECK (max_attempts BETWEEN 1 AND 25),
  available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  locked_at TIMESTAMPTZ,
  worker_id TEXT,
  last_error TEXT,
  delivered_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW()+INTERVAL '30 days'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(alert_id,contact_id)
);

CREATE INDEX IF NOT EXISTS idx_sos_delivery_claim
  ON matching.sos_delivery_outbox(response_deadline_at,available_at,created_at)
  WHERE status IN ('pending','retry','processing');
CREATE INDEX IF NOT EXISTS idx_sos_delivery_dead_letter
  ON matching.sos_delivery_outbox(created_at DESC)
  WHERE status='dead_letter';

CREATE OR REPLACE VIEW matching.sos_delivery_metrics AS
SELECT
  COUNT(*) FILTER (WHERE status IN ('pending','retry')) AS queue_depth,
  COUNT(*) FILTER (WHERE status='processing') AS processing,
  COUNT(*) FILTER (WHERE status='dead_letter') AS dead_letters,
  COUNT(*) FILTER (WHERE status='delivered') AS delivered,
  COUNT(*) FILTER (WHERE status IN ('pending','retry','processing') AND response_deadline_at<NOW()) AS overdue,
  COALESCE(EXTRACT(EPOCH FROM NOW()-MIN(created_at) FILTER (WHERE status IN ('pending','retry'))),0)::BIGINT
    AS oldest_pending_age_seconds
FROM matching.sos_delivery_outbox;

UPDATE matching.moderation_appeals
SET notification_policy='status_change_in_app_and_configured_push'
WHERE notification_policy='status_change_email_and_inbox';
ALTER TABLE matching.moderation_appeals
  ALTER COLUMN notification_policy SET DEFAULT 'status_change_in_app_and_configured_push';

SELECT platform.register_event_source('matching','sos_delivery_outbox','safety.sos_delivery');

INSERT INTO public.schema_migrations(version)
VALUES ('076_privacy_safety_trust_operations')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
