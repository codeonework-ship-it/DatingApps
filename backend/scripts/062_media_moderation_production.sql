-- 062_media_moderation_production.sql
-- Durable provider decisions, review queue, and append-only evidence for media.

BEGIN;

ALTER TABLE user_management.photos
  ADD COLUMN IF NOT EXISTS moderation_provider TEXT,
  ADD COLUMN IF NOT EXISTS moderation_model_version TEXT,
  ADD COLUMN IF NOT EXISTS moderation_labels JSONB NOT NULL DEFAULT '[]'::JSONB,
  ADD COLUMN IF NOT EXISTS moderation_confidence NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ;

ALTER TABLE user_management.photos
  DROP CONSTRAINT IF EXISTS photos_moderation_status_check;

ALTER TABLE user_management.photos
  ADD CONSTRAINT photos_moderation_status_check
  CHECK (moderation_status IN (
    'pending', 'approved', 'review_required', 'provider_error', 'rejected'
  ));

ALTER TABLE user_management.photos
  DROP CONSTRAINT IF EXISTS photos_moderation_confidence_check;

ALTER TABLE user_management.photos
  ADD CONSTRAINT photos_moderation_confidence_check
  CHECK (moderation_confidence IS NULL OR moderation_confidence BETWEEN 0 AND 100);

-- Rows accepted before provider integration cannot be assumed safe.
UPDATE user_management.photos
SET moderation_status='review_required',
    moderation_reason=COALESCE(NULLIF(moderation_reason,''),'legacy_unreviewed'),
    moderation_provider=COALESCE(NULLIF(moderation_provider,''),'migration_062')
WHERE deleted_at IS NULL AND moderation_status='pending';

CREATE TABLE IF NOT EXISTS user_management.media_moderation_events (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  -- Audit identities intentionally outlive account/media deletion. Foreign-key
  -- cascades would mutate this append-only evidence, so UUIDs are retained as
  -- historical identifiers without mutable FK actions.
  user_id UUID NOT NULL,
  photo_id UUID,
  content_sha256 TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  provider TEXT NOT NULL,
  model_version TEXT,
  decision TEXT NOT NULL,
  reason TEXT,
  labels JSONB NOT NULL DEFAULT '[]'::JSONB,
  duration_ms INTEGER NOT NULL DEFAULT 0,
  actor_type TEXT NOT NULL,
  actor_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT media_moderation_events_decision_check
    CHECK (decision IN ('approved','review_required','provider_error','rejected')),
  CONSTRAINT media_moderation_events_actor_type_check
    CHECK (actor_type IN ('provider','operator','system')),
  CONSTRAINT media_moderation_events_duration_check
    CHECK (duration_ms >= 0)
);

CREATE INDEX IF NOT EXISTS idx_media_moderation_events_user_time
  ON user_management.media_moderation_events (user_id, created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS idx_media_moderation_events_photo_time
  ON user_management.media_moderation_events (photo_id, created_at DESC, id DESC)
  WHERE photo_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_photos_moderation_review_queue
  ON user_management.photos (uploaded_at, id)
  WHERE deleted_at IS NULL AND moderation_status IN ('review_required','provider_error');

CREATE INDEX IF NOT EXISTS idx_photos_approved_user_order
  ON user_management.photos (user_id, ordering, id)
  WHERE deleted_at IS NULL AND moderation_status='approved';

CREATE OR REPLACE FUNCTION user_management.reject_media_moderation_event_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'user_management.media_moderation_events is append-only';
END;
$$;

DROP TRIGGER IF EXISTS trg_media_moderation_events_immutable
  ON user_management.media_moderation_events;
CREATE TRIGGER trg_media_moderation_events_immutable
BEFORE UPDATE OR DELETE ON user_management.media_moderation_events
FOR EACH ROW EXECUTE FUNCTION user_management.reject_media_moderation_event_mutation();

INSERT INTO public.schema_migrations(version)
VALUES ('062_media_moderation_production')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
