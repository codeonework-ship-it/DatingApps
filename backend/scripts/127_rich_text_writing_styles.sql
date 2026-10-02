-- Rich writing for Open Chapters and profile stories (2026-10-01).
--
-- Members can format chapters and stories (bold, italic, underline,
-- strikethrough, highlight, https links, headings, quotes, lists, dividers,
-- callouts, alignment) and pick a writing style (classic, modern, journal,
-- typewriter, poetic). See documents/RICH_TEXT_WRITING_STYLES_2026-10-01.md.
--
-- Formatting is a constrained JSON block model validated by the mobile BFF
-- (internal/bff/mobile/rich_text.go), never HTML. The existing body column
-- keeps the derived plain text, so search, excerpts, notifications,
-- moderation snapshots, wall cards and older clients are unchanged. NULL
-- content means a plain-text chapter, which renders exactly as before.
--
-- Profile stories need no column: each story object in
-- user_management.profile_stories.stories gains an optional "content" key.
-- Account export already serialises both tables whole (to_jsonb), and erasure
-- deletes the rows, so neither needs changes.
BEGIN;

ALTER TABLE matching.blog_posts ADD COLUMN IF NOT EXISTS content JSONB;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'blog_posts_content_shape'
       AND conrelid = 'matching.blog_posts'::regclass
  ) THEN
    ALTER TABLE matching.blog_posts ADD CONSTRAINT blog_posts_content_shape CHECK (
      content IS NULL OR (
        jsonb_typeof(content) = 'object'
        AND content->>'version' = '1'
        AND content->>'style' IN ('classic','modern','journal','typewriter','poetic')
        AND jsonb_typeof(content->'blocks') = 'array'
        AND jsonb_array_length(content->'blocks') <= 400
        AND octet_length(content::text) <= 131072
      )
    );
  END IF;
END $$;

COMMENT ON COLUMN matching.blog_posts.content IS
  'Formatted chapter {version,style,blocks}; validated by the mobile BFF. body holds its derived plain text. NULL = plain-text chapter.';

COMMIT;
