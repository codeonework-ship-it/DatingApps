package postgres

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestEngagementMigrations_ForwardSchemaCoverage(t *testing.T) {
	script014 := mustReadMigrationScript(t, "014_engagement_unlock_tables.sql")
	assertContainsAll(t, script014,
		"create table if not exists matching.match_unlock_states",
		"create table if not exists matching.match_quest_templates",
		"create table if not exists matching.match_quest_workflows",
	)

	script018 := mustReadMigrationScript(t, "018_match_gestures_effort_signals.sql")
	assertContainsAll(t, script018,
		"create table if not exists matching.match_gestures",
	)

	script020 := mustReadMigrationScript(t, "020_engagement_surfaces_tables.sql")
	assertContainsAll(t, script020,
		"create table if not exists matching.activity_sessions",
		"create table if not exists matching.activity_session_responses",
		"create table if not exists matching.user_trust_badges",
		"create table if not exists matching.user_trust_badge_history",
		"create table if not exists matching.conversation_rooms",
		"create table if not exists matching.conversation_room_participants",
		"create table if not exists matching.conversation_room_moderation_actions",
	)
}

func TestEngagementMigrations_IdempotentApplyGuards(t *testing.T) {
	scripts := []string{
		"014_engagement_unlock_tables.sql",
		"018_match_gestures_effort_signals.sql",
		"020_engagement_surfaces_tables.sql",
	}

	for _, name := range scripts {
		script := mustReadMigrationScript(t, name)
		assertNotContainsAny(t, script,
			"create table matching.",
			"create index matching.",
		)
	}
}

func TestEngagementMigrations_RollbackSafety_NoDestructiveStatements(t *testing.T) {
	scripts := []string{
		"014_engagement_unlock_tables.sql",
		"018_match_gestures_effort_signals.sql",
		"020_engagement_surfaces_tables.sql",
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

func TestEngagementMigrations_UnlockWorkflowDataRetentionSafety(t *testing.T) {
	script018 := mustReadMigrationScript(t, "018_match_gestures_effort_signals.sql")
	script020 := mustReadMigrationScript(t, "020_engagement_surfaces_tables.sql")

	for _, script := range []string{script018, script020} {
		assertNotContainsAny(t, script,
			"matching.match_unlock_states",
			"matching.match_quest_templates",
			"matching.match_quest_workflows",
		)
	}
}

func mustReadMigrationScript(t *testing.T, filename string) string {
	t.Helper()

	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatalf("unable to determine caller path")
	}
	root := filepath.Clean(filepath.Join(filepath.Dir(thisFile), "..", "..", ".."))
	path := filepath.Join(root, "scripts", filename)

	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration script %s: %v", filename, err)
	}
	return strings.ToLower(string(content))
}

func assertContainsAll(t *testing.T, text string, fragments ...string) {
	t.Helper()
	for _, fragment := range fragments {
		if !strings.Contains(text, fragment) {
			t.Fatalf("expected fragment %q in migration", fragment)
		}
	}
}

func assertNotContainsAny(t *testing.T, text string, fragments ...string) {
	t.Helper()
	for _, fragment := range fragments {
		if strings.Contains(text, fragment) {
			t.Fatalf("unexpected fragment %q in migration", fragment)
		}
	}
}
