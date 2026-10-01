BEGIN;

CREATE TABLE IF NOT EXISTS matching.voice_moderation_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  icebreaker_id UUID NOT NULL REFERENCES matching.voice_icebreakers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
  content_sha256 TEXT NOT NULL,
  provider TEXT NOT NULL,
  model_version TEXT,
  decision TEXT NOT NULL CHECK (decision IN ('approved','rejected','manual_review')),
  reason TEXT,
  confidence DOUBLE PRECISION CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 100)),
  provider_reference TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(icebreaker_id,content_sha256,provider)
);

CREATE INDEX IF NOT EXISTS idx_voice_moderation_decision_time
  ON matching.voice_moderation_events(decision,created_at DESC);

SELECT platform.register_event_source('matching','voice_moderation_events','engagement.voice_moderation');

INSERT INTO public.schema_migrations(version)
VALUES ('077_calls_identity_voice_providers')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
