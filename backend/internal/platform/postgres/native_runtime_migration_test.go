package postgres

import "testing"

func TestNativePostgresRuntimeMigrationIsForwardOnlyAndIndexed(t *testing.T) {
	script053 := mustReadMigrationScript(t, "053_native_postgres_runtime.sql")

	assertContainsAll(t, script053,
		"add column if not exists visibility text not null default 'private'",
		"add column if not exists invited_by_user_id uuid",
		"add column if not exists left_at timestamptz",
		"create index if not exists idx_community_groups_city_topic",
		"create index if not exists idx_community_group_members_user",
		"create index if not exists idx_community_group_invites_invitee",
		"values ('053_native_postgres_runtime')",
	)
	assertNotContainsAny(t, script053,
		"drop table",
		"drop column",
		"truncate table",
		"delete from matching.",
	)
}

func TestCoreDatingRealtimeMigrationIsDurableAndIndexed(t *testing.T) {
	script054 := mustReadMigrationScript(t, "054_core_dating_realtime_outbox.sql")

	assertContainsAll(t, script054,
		"create table if not exists matching.chat_read_cursors",
		"create table if not exists matching.realtime_outbox",
		"generated always as identity primary key",
		"idx_realtime_outbox_recipient_sequence",
		"idx_messages_unread_match_sender",
		"capture_match_realtime_event",
		"capture_message_realtime_event",
		"message.delivered",
		"message.read",
		"match.unmatched",
		"values ('054_core_dating_realtime_outbox')",
	)
	assertNotContainsAny(t, script054,
		"drop table",
		"drop column",
		"truncate table",
		"delete from matching.",
	)
}

func TestSafetyModerationEnforcementMigrationIsDurableAuditedAndSLAIndexed(t *testing.T) {
	script055 := mustReadMigrationScript(t, "055_safety_moderation_enforcement.sql")

	assertContainsAll(t, script055,
		"sla_deadline_at timestamptz",
		"status_change_email_and_inbox",
		"idx_moderation_appeals_open_sla",
		"idx_moderation_reports_open_sla",
		"idx_verification_states_pending_sla",
		"idx_sos_alerts_open_sla",
		"create table if not exists audit.security_events",
		"trg_security_events_immutable",
		"audit.security_events is append-only",
		"values ('055_safety_moderation_enforcement')",
	)
	assertNotContainsAny(t, script055,
		"drop table",
		"drop column",
		"truncate table",
		"delete from matching.",
	)
}
