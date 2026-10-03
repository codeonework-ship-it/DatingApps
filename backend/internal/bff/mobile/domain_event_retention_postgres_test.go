package mobile

import (
	"context"
	"database/sql"
	"testing"
)

// Postgres-backed checks for migration 134 (domain-event and audit write
// amplification, outbox retention). Every check runs in a transaction that is
// rolled back. They skip without PROFILE_TEST_DATABASE_URL, e.g.
//
//	PROFILE_TEST_DATABASE_URL='postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable' \
//	  go test ./internal/bff/mobile/ -run DomainEventRetention -count=1

func amplificationTx(t *testing.T) *sql.Tx {
	t.Helper()
	db := trustOpsDB(t)
	var ready bool
	if err := db.QueryRow(`SELECT to_regprocedure('platform.run_domain_event_retention(integer)') IS NOT NULL
		AND to_regclass('audit.trigger_exclusions') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 134 is not applied")
	}
	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = tx.Rollback() })
	return tx
}

func countTriggers(t *testing.T, tx *sql.Tx) int {
	t.Helper()
	var n int
	if err := tx.QueryRow(`SELECT count(*) FROM pg_trigger WHERE NOT tgisinternal AND tgrelid IN
		('matching.activity_events'::regclass,'audit.change_log'::regclass,'audit.activity_log'::regclass)`).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

// case: platform.domain_events.amplification.excluded_sources_stay_excluded
func TestDomainEventRetentionExcludedSourcesSurviveMigrationReruns(t *testing.T) {
	tx := amplificationTx(t)
	if n := countTriggers(t, tx); n != 0 {
		t.Fatalf("excluded tables still have %d triggers", n)
	}
	// What re-running 036 and 075 does: it must not re-attach anything.
	for _, stmt := range []string{
		`SELECT audit.attach_audit_triggers('matching')`,
		`SELECT platform.register_event_source('matching','activity_events')`,
		`SELECT platform.register_event_source('audit','change_log')`,
		`SELECT platform.register_event_source('audit','activity_log')`,
	} {
		if _, err := tx.Exec(stmt); err != nil {
			t.Fatalf("%s: %v", stmt, err)
		}
	}
	if n := countTriggers(t, tx); n != 0 {
		t.Fatalf("re-running migrations re-attached %d triggers to excluded tables", n)
	}
	var excluded bool
	if err := tx.QueryRow(`SELECT excluded_reason IS NOT NULL AND NOT enabled FROM platform.event_source_registry
		WHERE source_schema='matching' AND source_table='activity_events'`).Scan(&excluded); err != nil || !excluded {
		t.Fatalf("activity_events is no longer excluded (err=%v)", err)
	}
	// A request row no longer emits a domain event.
	var before, after int64
	_ = tx.QueryRow(`SELECT count(*) FROM platform.domain_event_outbox WHERE aggregate_type='matching.activity_events'`).Scan(&before)
	if _, err := tx.Exec(`INSERT INTO matching.activity_events(event_name, event_domain, payload)
		VALUES ('GET /v1/qa', 'api_request', '{}'::jsonb)`); err != nil {
		t.Fatalf("insert request row: %v", err)
	}
	_ = tx.QueryRow(`SELECT count(*) FROM platform.domain_event_outbox WHERE aggregate_type='matching.activity_events'`).Scan(&after)
	if after != before {
		t.Fatalf("a request row emitted %d domain events", after-before)
	}
}

// case: platform.domain_events.outbox.append_only_and_retention
func TestDomainEventRetentionRemovesOnlyExpiredUnneededEvents(t *testing.T) {
	tx := amplificationTx(t)
	publish := func(key string) {
		t.Helper()
		if _, err := tx.Exec(`SELECT platform.publish_domain_event('qa.retention', 1::smallint, 'qa', $1, 'qa',
			NULL, NULL, NULL, NULL, $1, '{}'::jsonb, '{}'::jsonb, now() - interval '100 days')`, key); err != nil {
			t.Fatalf("publish %s: %v", key, err)
		}
	}
	publish("qa-retention-expired")
	publish("qa-retention-pending")
	if _, err := tx.Exec(`INSERT INTO platform.event_deliveries(consumer_name, event_id, sequence_id, status, max_attempts)
		SELECT 'qa-consumer', event_id, sequence_id, 'pending', 5 FROM platform.domain_event_outbox
		WHERE idempotency_key='qa-retention-pending'`); err != nil {
		t.Fatalf("pending delivery: %v", err)
	}
	var removed int
	if err := tx.QueryRow(`SELECT platform.run_domain_event_retention(20000)`).Scan(&removed); err != nil {
		t.Fatalf("retention: %v", err)
	}
	if removed < 1 {
		t.Fatalf("retention removed %d events, want at least the expired one", removed)
	}
	exists := func(key string) bool {
		var n int
		_ = tx.QueryRow(`SELECT count(*) FROM platform.domain_event_outbox WHERE idempotency_key=$1`, key).Scan(&n)
		return n > 0
	}
	if exists("qa-retention-expired") {
		t.Fatal("expired event was kept")
	}
	if !exists("qa-retention-pending") {
		t.Fatal("event a consumer still needs was deleted")
	}
	// Outside the retention function the outbox stays append-only.
	if _, err := tx.Exec(`SAVEPOINT s1`); err != nil {
		t.Fatal(err)
	}
	if _, err := tx.Exec(`DELETE FROM platform.domain_event_outbox WHERE idempotency_key='qa-retention-pending'`); err == nil {
		t.Fatal("a plain DELETE on the outbox succeeded")
	}
	_, _ = tx.Exec(`ROLLBACK TO SAVEPOINT s1`)
}
