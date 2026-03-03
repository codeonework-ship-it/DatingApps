-- Expand advanced profile filtering dimensions
-- Run after 021_social_graph_and_tag_filter_indexes.sql

ALTER TABLE matching.user_profile_tag_filters
  ADD COLUMN IF NOT EXISTS religion TEXT,
  ADD COLUMN IF NOT EXISTS mother_tongue TEXT,
  ADD COLUMN IF NOT EXISTS relationship_status TEXT,
  ADD COLUMN IF NOT EXISTS smoking TEXT,
  ADD COLUMN IF NOT EXISTS drinking TEXT,
  ADD COLUMN IF NOT EXISTS personality_type TEXT,
  ADD COLUMN IF NOT EXISTS party_lover BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_religion
  ON matching.user_profile_tag_filters(religion);

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_mother_tongue
  ON matching.user_profile_tag_filters(mother_tongue);

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_relationship
  ON matching.user_profile_tag_filters(relationship_status);

CREATE INDEX IF NOT EXISTS idx_profile_tag_filters_lifestyle
  ON matching.user_profile_tag_filters(smoking, drinking, personality_type, party_lover);
