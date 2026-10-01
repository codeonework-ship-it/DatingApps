-- Reporting whole community/private groups, and the friend-search opt-out.
--
-- 1. A group can be reported as a whole (case kind 'group') through the shared
--    moderation case queue (POST /v1/blog/reports/group/{id}). A removal
--    decision sets community_groups.moderation_state='removed' and bumps
--    version: the group leaves Discover, nobody can join, accept an invitation
--    or chat, and members see "This group was removed after a review".
--    Restore sets it back to 'active'.
-- 2. user_settings.friend_search_visible (default TRUE): FALSE keeps the member
--    out of /v1/friends/{me}/search results. People who already see them
--    (matches, rooms, groups, profile) can still send a request.
BEGIN;

ALTER TABLE matching.community_groups
 ADD COLUMN IF NOT EXISTS moderation_state TEXT NOT NULL DEFAULT 'active',
 ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;

DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='community_groups_moderation_state_check'
   AND conrelid='matching.community_groups'::regclass) THEN
  ALTER TABLE matching.community_groups ADD CONSTRAINT community_groups_moderation_state_check
   CHECK (moderation_state IN ('active','removed'));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='community_groups_version_check'
   AND conrelid='matching.community_groups'::regclass) THEN
  ALTER TABLE matching.community_groups ADD CONSTRAINT community_groups_version_check CHECK (version > 0);
 END IF;
END $$;

-- Discover reads only active community groups.
DROP INDEX IF EXISTS matching.idx_community_groups_discover;
CREATE INDEX IF NOT EXISTS idx_community_groups_discover_active
 ON matching.community_groups(category_slug, updated_at DESC)
 WHERE kind='community' AND moderation_state='active';

-- Add 'group' to the case kinds while keeping every kind an earlier migration
-- (115, or a later one such as 119) allowed, so the order of parallel
-- migrations cannot drop a kind.
DO $$
DECLARE
 kinds TEXT[];
BEGIN
 -- Works for both ARRAY['post'::text,...] and '{post,...}'::text[] forms.
 SELECT COALESCE(array_agg(DISTINCT m[1]), '{}') INTO kinds
 FROM pg_constraint c, regexp_matches(pg_get_constraintdef(c.oid), '([a-z_]+)', 'g') AS m
 WHERE c.conname='blog_cases_content_type_check' AND c.conrelid='matching.blog_cases'::regclass
  AND m[1] NOT IN ('content_type','text');
 kinds := ARRAY(SELECT DISTINCT k FROM unnest(kinds || ARRAY['post','response','publication','theme_entry','club','club_post',
  'review','list','comment','photo_comment','social_message','group']) AS k ORDER BY k);
 ALTER TABLE matching.blog_cases DROP CONSTRAINT IF EXISTS blog_cases_content_type_check;
 EXECUTE format('ALTER TABLE matching.blog_cases ADD CONSTRAINT blog_cases_content_type_check CHECK (content_type = ANY (%L::text[]))', kinds);
END $$;

ALTER TABLE user_management.user_settings
 ADD COLUMN IF NOT EXISTS friend_search_visible BOOLEAN NOT NULL DEFAULT TRUE;

COMMIT;
