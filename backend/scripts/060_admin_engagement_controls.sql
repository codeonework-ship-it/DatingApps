BEGIN;

INSERT INTO matching.platform_feature_flags(key, value_bool, description, updated_by)
VALUES ('match_nudges_enabled', TRUE, 'Enable match nudge sending', 'migration_060')
ON CONFLICT (key) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_match_nudges_admin_recent
  ON matching.match_nudges(created_at DESC, nudge_type);

INSERT INTO public.schema_migrations(version)
VALUES ('060_admin_engagement_controls')
ON CONFLICT (version) DO UPDATE SET applied_at = NOW();

COMMIT;
