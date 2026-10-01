package postgres

import "testing"

func TestDomainEventBackboneIsTransactionalReplayableAndPrivacySafe(t *testing.T) {
	script := mustReadMigrationScript(t, "075_domain_event_backbone.sql")

	assertContainsAll(t, script,
		"create table if not exists platform.domain_event_outbox",
		"create or replace function platform.publish_domain_event",
		"create or replace function platform.capture_row_change",
		"payload_policy text not null default 'field_names_only'",
		"create table if not exists platform.event_subscriptions",
		"create table if not exists platform.event_deliveries",
		"create or replace function platform.claim_domain_events",
		"for update skip locked",
		"create or replace function platform.ack_domain_event",
		"create or replace function platform.nack_domain_event",
		"domain event idempotency key reused with different content",
		"domain_event_outbox is append-only",
		"values ('075_domain_event_backbone')",
	)
	assertNotContainsAny(t, script,
		"drop table",
		"drop column",
		"truncate table",
		"delete from platform.domain_event_outbox",
	)
}
