-- Empathetic reactions on chapters and Photo Themes photos.
--
-- A like now carries how the reader felt: love, "I hear you", "Me too",
-- "I'm with you", "Sending a hug" or "Proud of you". Every reaction still
-- counts as one like for wall tiers, ranking and rewards, and a member has at
-- most one reaction per item (the existing primary key), so changing a
-- reaction never counts twice or re-awards XP.
BEGIN;

ALTER TABLE matching.blog_likes
 ADD COLUMN IF NOT EXISTS reaction TEXT NOT NULL DEFAULT 'love';
ALTER TABLE matching.photo_entry_likes
 ADD COLUMN IF NOT EXISTS reaction TEXT NOT NULL DEFAULT 'love';

DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='blog_likes_reaction_check') THEN
  ALTER TABLE matching.blog_likes ADD CONSTRAINT blog_likes_reaction_check
   CHECK (reaction IN ('love','hear_you','me_too','with_you','hug','proud'));
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='photo_entry_likes_reaction_check') THEN
  ALTER TABLE matching.photo_entry_likes ADD CONSTRAINT photo_entry_likes_reaction_check
   CHECK (reaction IN ('love','hear_you','me_too','with_you','hug','proud'));
 END IF;
END $$;

-- When the reaction last changed, for audits and export.
ALTER TABLE matching.blog_likes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE matching.photo_entry_likes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

INSERT INTO public.schema_migrations(version) VALUES('114_empathetic_reactions') ON CONFLICT DO NOTHING;
COMMIT;
