package postgres

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestRoseGiftMigrations_ForwardSchemaCoverage(t *testing.T) {
	script032 := mustReadMigrationScript(t, "032_rose_gifts_wallet_tables.sql")
	assertContainsAll(t, script032,
		"create table if not exists matching.gift_catalog",
		"create table if not exists matching.user_wallets",
		"create table if not exists matching.match_gift_sends",
		"price_coins integer not null",
		"coin_balance integer not null",
	)

	script033 := mustReadMigrationScript(t, "033_rose_gifts_model_alignment.sql")
	assertContainsAll(t, script033,
		"alter table if exists matching.gift_catalog",
		"add column if not exists icon_key text",
		"alter table if exists matching.match_gift_sends",
		"add column if not exists idempotency_key text",
		"create unique index if not exists idx_match_gift_sends_idempotency",
	)

	script034 := mustReadMigrationScript(t, "034_gift_spend_activities.sql")
	assertContainsAll(t, script034,
		"create table if not exists matching.gift_spend_activities",
		"sender_user_id uuid not null",
		"receiver_user_id uuid not null",
		"price_coins integer not null",
		"details jsonb not null default '{}'::jsonb",
	)
}

func TestRoseGiftMigrations_IdempotentApplyGuards(t *testing.T) {
	scripts := []string{
		"032_rose_gifts_wallet_tables.sql",
		"033_rose_gifts_model_alignment.sql",
		"034_gift_spend_activities.sql",
	}

	for _, name := range scripts {
		script := mustReadMigrationScript(t, name)
		assertNotContainsAny(t, script,
			"create table matching.",
			"create index matching.",
			"create unique index matching.",
		)
	}
}

func TestRoseGiftMigrations_RollbackSafety_NoDestructiveStatements(t *testing.T) {
	scripts := []string{
		"032_rose_gifts_wallet_tables.sql",
		"033_rose_gifts_model_alignment.sql",
		"034_gift_spend_activities.sql",
	}

	for _, name := range scripts {
		script := mustReadMigrationScript(t, name)
		assertNotContainsAny(t, script,
			"drop table",
			"drop column",
			"truncate table",
			"delete from matching.",
		)
	}
}

func TestRoseGiftMigration_RunOrderIncludesModelAlignmentStep(t *testing.T) {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatalf("unable to determine caller path")
	}
	root := filepath.Clean(filepath.Join(filepath.Dir(thisFile), "..", "..", ".."))
	runOrderPath := filepath.Join(root, "scripts_run_order.txt")

	content, err := os.ReadFile(runOrderPath)
	if err != nil {
		t.Fatalf("read scripts run order: %v", err)
	}
	runOrder := strings.ToLower(string(content))
	if !strings.Contains(runOrder, "033_rose_gifts_model_alignment.sql") {
		t.Fatalf("expected scripts_run_order.txt to include 033_rose_gifts_model_alignment.sql")
	}
	if !strings.Contains(runOrder, "034_gift_spend_activities.sql") {
		t.Fatalf("expected scripts_run_order.txt to include 034_gift_spend_activities.sql")
	}
}
