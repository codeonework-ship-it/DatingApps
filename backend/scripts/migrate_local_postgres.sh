#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
port="${LOCAL_POSTGRES_PORT:-55433}"
db_name="${LOCAL_POSTGRES_DB:-dating_app}"
db_user="${LOCAL_POSTGRES_USER:-dating_app}"
psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
database_url="${LOCAL_DATABASE_URL:-postgresql://$db_user@127.0.0.1:$port/$db_name?sslmode=disable}"

"$script_dir/local_postgres.sh" up >/dev/null

migrations=(
  035_full_drop_all_screens_schema.sql
  036_full_create_all_screens_schema.sql
  019_remove_public_smoke_compat.sql
  021_social_graph_and_tag_filter_indexes.sql
  022_expand_profile_filter_dimensions.sql
  023_india_master_data_and_hookup_filter.sql
  024_lifestyle_master_tables_seed.sql
  025_terms_acceptance_columns.sql
  027_remove_smtp_sender_settings.sql
  031_activity_notifications.sql
  033_rose_gifts_model_alignment.sql
  037_seed_full_screens_100_users_50_matches.sql
  038_voice_and_group_coffee_persistence_alignment.sql
  039_wallet_coin_purchases.sql
  040_gifts_wallet_relationship_constraints.sql
  041_local_photos_storage_path.sql
  042_seed_100_users_25_25_spec.sql
  043_profile_setup_completion_tracking.sql
  044_seed_100_users_rich_matches_spotlight.sql
  045_gift_catalog_expansion.sql
  046_feature_flags_and_admin.sql
  047_coin_package_extras_and_billing_plans.sql
  048_seed_filter_test_female_users.sql
  049_seed_india_states_cities.sql
  050_username_password_identity.sql
  051_signup_workflow_engine.sql
  052_auth_security_foundation.sql
  053_native_postgres_runtime.sql
  054_core_dating_realtime_outbox.sql
  055_safety_moderation_enforcement.sql
  056_profile_media_lifecycle.sql
  057_notification_delivery_engine.sql
  058_reliability_scale_guardrails.sql
  059_admin_control_plane.sql
  060_admin_engagement_controls.sql
  061_notification_production_slos.sql
  062_media_moderation_production.sql
  063_shared_idempotency_and_retention.sql
  064_level_xp_progression.sql
  065_account_lifecycle.sql
  066_account_erasure.sql
  067_username_erasure_carveout.sql
  068_username_length_contract.sql
  069_erasure_storage_release.sql
  070_billing_card_subscriptions.sql
  071_billing_coin_checkout.sql
  072_billing_single_currency_disputes.sql
  073_private_identity_and_voice_media.sql
  074_gift_send_integrity.sql
  075_domain_event_backbone.sql
	076_privacy_safety_trust_operations.sql
	077_calls_identity_voice_providers.sql
	078_correctness_recovery_contracts.sql
	079_progression_production_rollout.sql
	080_deferred_growth_portfolio.sql
	081_trust_retention_and_legal_holds.sql
	082_account_recovery_assistance.sql
	083_gift_receiver_controls.sql
	084_billing_wallet_integrity.sql
	085_money_aggregate_ownership.sql
	086_progression_rollout_enforcement.sql
	087_member_activity_kpis.sql
	088_support_ticketing_foundation_gate.sql
	089_coin_economy_fraud_controls.sql
	090_zero_default_wallets_and_ledger_repair.sql
	091_date_plans_friend_fan_out.sql
	092_date_plan_debriefs_shows_up_badge.sql
	093_member_locale.sql
	094_match_graduation.sql
	095_curated_daily_set.sql
	096_friend_vouches_and_intros.sql
	097_conversation_trust_and_copilot.sql
	098_intentional_dating.sql
	099_date_plan_explicit_sharing.sql
	100_profile_stories.sql
	101_date_plan_preferences.sql
	102_introducer_accounts.sql
	103_city_pilot.sql
	104_first_chapter.sql
	105_member_blogging.sql
	106_blog_connections_and_trust.sql
	107_photo_themes_and_book_film_clubs.sql
	108_blog_likes_comments_featuring.sql
	109_blog_wall_reach_tiers.sql
	110_photo_wall_reach.sql
	111_wall_celebrations.sql
	112_today_wall_and_cover.sql
	113_blog_topics_subscriptions_rewards.sql
	114_empathetic_reactions.sql
	115_social_channels.sql
	116_friend_requests.sql
	117_conversation_rooms_live_chat.sql
	118_lifestyle_groups.sql
	119_chat_mutes.sql
	120_group_reports_friend_search_optout.sql
	121_group_cover_photos.sql
	122_client_error_reporting_and_telemetry_privacy.sql
	123_product_analytics_snapshots.sql
	124_business_reports.sql
	126_support_ticket_system.sql
	127_rich_text_writing_styles.sql
	128_graduation_friend_recipients.sql
	129_capacity_hot_path_indexes.sql
	130_profile_showcase_consent.sql
	131_admin_list_paging.sql
	132_member_activity.sql
	133_server_activity.sql
	134_domain_event_amplification.sql
)

for migration in "${migrations[@]}"; do
  echo "applying $migration"
  "$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 -f "$script_dir/$migration" >/dev/null
  migration_version="${migration%.sql}"
  "$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 -v migration_version="$migration_version" <<'SQL' >/dev/null
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO public.schema_migrations(version)
VALUES (:'migration_version')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;
SQL
done

"$psql_bin" "$database_url" -X -v ON_ERROR_STOP=1 <<'SQL'
-- The baseline fixture migrations run before provider moderation exists. These
-- rows have no content digest and are trusted local-only catalog fixtures, not
-- user uploads. Keep discovery usable without weakening the production delta.
INSERT INTO user_management.media_moderation_events
  (user_id,photo_id,content_sha256,mime_type,provider,model_version,decision,
   reason,labels,duration_ms,actor_type,actor_id)
SELECT p.user_id,p.id,encode(digest(p.photo_url,'sha256'),'hex'),
       COALESCE(NULLIF(p.mime_type,''),'image/jpeg'),'local_seed_fixture','seed-v1',
       'approved','trusted_local_fixture','[]'::jsonb,0,'system','migrate_local_postgres'
FROM user_management.photos p
WHERE p.deleted_at IS NULL
  AND p.moderation_status='review_required'
  AND p.content_sha256 IS NULL;

UPDATE user_management.photos
SET moderation_status='approved',moderation_reason='trusted_local_fixture',
    moderation_provider='local_seed_fixture',moderation_model_version='seed-v1',
    moderation_labels='[]'::jsonb,moderated_at=NOW(),is_moderated=TRUE
WHERE deleted_at IS NULL
  AND moderation_status='review_required'
  AND content_sha256 IS NULL;
SQL

echo "migrations applied to $database_url"
