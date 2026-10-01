-- Optional, member-authored profile stories. Saving privately is the default.
BEGIN;
CREATE TABLE IF NOT EXISTS user_management.profile_stories (
 user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
 stories JSONB NOT NULL DEFAULT '[]' CHECK(jsonb_typeof(stories)='array' AND jsonb_array_length(stories)<=3),
 published BOOLEAN NOT NULL DEFAULT FALSE,
 version INTEGER NOT NULL DEFAULT 0 CHECK(version>=0),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
VALUES('profile_stories','mobile-bff.profile-stories','user_management','profile_stories','single PostgreSQL transaction','versioned replacement; reread after uncertain save')
ON CONFLICT(aggregate_type) DO NOTHING;
INSERT INTO platform.required_aggregates(aggregate_type) VALUES('profile_stories') ON CONFLICT DO NOTHING;
COMMIT;
