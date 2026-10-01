-- Group cover photos for community and private groups.
--
-- The group owner can upload, replace and remove a cover photo
-- (PUT/DELETE /v1/engagement/groups/{id}/cover). Bytes live in the media store
-- under group_covers/<group>/<cover>.<ext> (mediastore kind group_covers); the
-- database holds only the key, size, hash and moderation state. cover_emoji and
-- cover_color stay as the fallback whenever no photo is shown.
--
-- One row per upload attempt:
--   * at most one live row (deleted_at IS NULL) per group: the current cover;
--   * moderation_status: approved (shown to everyone who can see the group),
--     pending (provider asked for a human review: shown to the owner only, in
--     the operator queue /v1/admin/moderation/group-covers) or rejected
--     (synchronous rejections are recorded without bytes; operator rejections
--     hide the cover and notify the owner);
--   * replaced, removed, rejected, group-deleted and erased covers keep their
--     row with deleted_at set until the media lifecycle worker has deleted the
--     object (storage_released_at), unless a report holds it as evidence
--     (matching.blog_evidence_photos) or the uploader is on legal hold.
--   * rows also back the upload rate limit (10 per group per day).
--
-- group_id has no foreign key on purpose: a deleted group's cover rows must
-- outlive the group until their objects are released.
BEGIN;

CREATE TABLE IF NOT EXISTS matching.community_group_covers (
 id UUID PRIMARY KEY,
 group_id UUID NOT NULL,
 uploaded_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
 storage_path TEXT NOT NULL DEFAULT '',
 mime_type TEXT NOT NULL DEFAULT '',
 width_px INTEGER NOT NULL DEFAULT 0 CHECK (width_px >= 0),
 height_px INTEGER NOT NULL DEFAULT 0 CHECK (height_px >= 0),
 size_bytes BIGINT NOT NULL DEFAULT 0 CHECK (size_bytes >= 0),
 content_sha256 TEXT NOT NULL DEFAULT '',
 alt_text TEXT NOT NULL DEFAULT 'Group cover photo',
 moderation_status TEXT NOT NULL CHECK (moderation_status IN ('pending','approved','rejected')),
 moderation_reason TEXT NOT NULL DEFAULT '',
 moderation_provider TEXT NOT NULL DEFAULT '',
 reviewed_by UUID,
 reviewed_at TIMESTAMPTZ,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 deleted_at TIMESTAMPTZ,
 delete_reason TEXT CHECK (delete_reason IS NULL OR delete_reason IN ('replaced','removed','rejected','rejected_seen','group_deleted','erased')),
 storage_released_at TIMESTAMPTZ,
 -- Live covers always have bytes; only a synchronous rejection has none.
 CONSTRAINT community_group_covers_live_has_bytes CHECK (deleted_at IS NOT NULL OR storage_path <> ''),
 CONSTRAINT community_group_covers_storage_key CHECK (storage_path = '' OR storage_path LIKE 'group_covers/%')
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_community_group_covers_live
 ON matching.community_group_covers(group_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_community_group_covers_group_recent
 ON matching.community_group_covers(group_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_group_covers_release
 ON matching.community_group_covers(deleted_at)
 WHERE deleted_at IS NOT NULL AND storage_released_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_community_group_covers_review
 ON matching.community_group_covers(created_at)
 WHERE deleted_at IS NULL AND moderation_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_community_group_covers_uploader
 ON matching.community_group_covers(uploaded_by) WHERE uploaded_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_community_group_covers_storage
 ON matching.community_group_covers(storage_path) WHERE storage_path <> '';

COMMIT;
