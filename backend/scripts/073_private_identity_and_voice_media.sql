-- Private member evidence and voice-media references.
-- Object bytes remain in the configured private file store; the database keeps
-- integrity metadata and never exposes storage keys in the public API.

ALTER TABLE IF EXISTS matching.voice_icebreakers
  ADD COLUMN IF NOT EXISTS audio_storage_path TEXT,
  ADD COLUMN IF NOT EXISTS audio_mime_type TEXT,
  ADD COLUMN IF NOT EXISTS audio_size_bytes BIGINT,
  ADD COLUMN IF NOT EXISTS audio_content_sha256 TEXT;

CREATE INDEX IF NOT EXISTS idx_voice_icebreakers_audio_cleanup
  ON matching.voice_icebreakers(created_at)
  WHERE audio_storage_path IS NOT NULL;
