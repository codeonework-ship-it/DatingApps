-- 068_erasure_storage_release.sql
--
-- Tracks whether the storage objects belonging to an erased account were
-- actually deleted.
--
-- Erasure removed the photo rows, which also removed the only pointer the media
-- cleanup had to those objects. Measured on this database: after an account was
-- erased the file was still on disk, and it survived a second cleanup pass as
-- well, because the orphan scan reads the referenced-path set before erasure
-- deletes the rows. It was released only on the pass after that.
--
-- On S3 it is never released at all: `cleanupUnreferencedLocalFiles` is the only
-- orphan sweep and it is skipped entirely when the storage backend is S3. The
-- product would have told the member their data was erased while their photos
-- stayed in the bucket indefinitely.
--
-- Release is therefore driven from the erasure itself and recorded here, so a
-- failure is retried rather than lost.

BEGIN;

ALTER TABLE user_management.account_lifecycle_requests
  ADD COLUMN IF NOT EXISTS storage_released_at TIMESTAMPTZ;

-- Finds erasures whose objects still need releasing, including retries after a
-- storage backend was briefly unreachable.
CREATE INDEX IF NOT EXISTS idx_lifecycle_storage_release_pending
  ON user_management.account_lifecycle_requests (completed_at)
  WHERE request_type = 'delete'
    AND status = 'completed'
    AND storage_released_at IS NULL;

COMMIT;
