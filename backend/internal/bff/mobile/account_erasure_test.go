package mobile

import (
	"errors"
	"regexp"
	"strings"
	"testing"
)

// usernameFormat mirrors user_management.users_username_check.
var usernameFormat = regexp.MustCompile(`^[a-z0-9]([a-z0-9._]{1,28}[a-z0-9])?$`)

// TestErasureTombstoneSatisfiesUsernameConstraint pins the two database rules
// the tombstone has to satisfy at once.
//
// This is the failure that actually happened: the first tombstone was
// 'erased_' plus the full 32-character uuid, which is 39 characters. The
// username format constraint caps it at 30, so the erasure transaction aborted
// after scrubbing had begun. The constraint and the carve-out trigger both
// encode the value, so a change to either has to keep them agreeing.
func TestErasureTombstoneSatisfiesUsernameConstraint(t *testing.T) {
	ids := []string{
		"eeee0000-0000-0000-0000-00000000e001",
		"7cc11134-cfe0-4c5f-97bf-3c32c54a37b4",
		"00000000-0000-0000-0000-000000000000",
		"ffffffff-ffff-ffff-ffff-ffffffffffff",
	}
	for _, id := range ids {
		tombstone := erasureTombstoneUsername(id)
		if len(tombstone) > 30 {
			t.Errorf("tombstone for %s is %d characters; users_username_check caps at 30",
				id, len(tombstone))
		}
		if !usernameFormat.MatchString(tombstone) {
			t.Errorf("tombstone %q for %s fails the username format constraint",
				tombstone, id)
		}
	}
}

// TestErasureTombstonesAreDistinct guards against truncating away uniqueness.
//
// Username is unique. Shortening the derived value to fit the length cap must
// not make two members collide, which would abort the second erasure.
func TestErasureTombstonesAreDistinct(t *testing.T) {
	seen := map[string]string{}
	ids := []string{
		"eeee0000-1111-0000-0000-00000000e001",
		"eeee0000-1111-0000-0000-00000000e002",
		"aaaa1111-2222-3333-4444-555566667777",
		"aaaa1111-2222-3333-4444-555566667778",
	}
	for _, id := range ids {
		tombstone := erasureTombstoneUsername(id)
		if prior, clash := seen[tombstone]; clash {
			t.Fatalf("tombstone %q collides for %s and %s; username is unique so the "+
				"second erasure would fail", tombstone, prior, id)
		}
		seen[tombstone] = id
	}
}

// TestErasureNeverTouchesRetainedTables is the retention boundary.
//
// The XP ledger cannot be deleted at all — append-only trigger plus a RESTRICT
// foreign key — and the audit and moderation records are evidence about conduct
// that outlives the account. A scrub statement reaching any of them would
// either abort every erasure or destroy safety history.
func TestErasureNeverTouchesRetainedTables(t *testing.T) {
	forbidden := []string{
		"xp_ledger",
		"audit.security_events",
		"audit.change_log",
		"media_moderation_events",
		"moderation_reports",
		"moderation_appeals",
	}
	sql := strings.ToLower(accountErasureStepSQL())
	for _, table := range forbidden {
		if strings.Contains(sql, strings.ToLower(table)) {
			t.Errorf(
				"erasure must not modify %s: it is retained deliberately, and "+
					"the ledger cannot be deleted even if it were tried",
				table,
			)
		}
	}
}

// TestErasureCoversMemberContent is the other half: retention must not become
// an excuse for leaving personal data in place.
func TestErasureCoversMemberContent(t *testing.T) {
	sql := strings.ToLower(accountErasureStepSQL())
	for _, required := range []string{
		"photos", "profile_drafts", "preferences", "emergency_contacts",
		"device_push_tokens", "verification_states", "voice_icebreakers",
		"messages", "prompt_answers", "sos_alerts", "sos_delivery_outbox",
	} {
		if !strings.Contains(sql, required) {
			t.Errorf("erasure should remove or scrub %s", required)
		}
	}
}

func TestErasureStepArgumentsMatchQueries(t *testing.T) {
	for _, step := range accountErasureSteps() {
		referencesTombstone := strings.Contains(step.query, "$2")
		if referencesTombstone != step.usesTombstone {
			t.Errorf("erasure step %s tombstone args mismatch: uses=%v query=%q", step.label, step.usesTombstone, step.query)
		}
	}
}

// TestRetainedTablesAreDeclared keeps the retention list honest: whatever
// survives erasure has to be stated, because an undeclared survivor is
// indistinguishable from a bug.
func TestRetainedTablesAreDeclared(t *testing.T) {
	if len(retainedForSafetyAndLedger) == 0 {
		t.Fatal("retained tables must be declared explicitly")
	}
	joined := strings.Join(retainedForSafetyAndLedger, " ")
	if !strings.Contains(joined, "xp_ledger") {
		t.Error("xp_ledger survives erasure by database constraint and must be declared")
	}
	if !strings.Contains(joined, "audit.security_events") {
		t.Error("the audit trail survives erasure and must be declared")
	}
}

// TestReleaseObjectsDeletesEveryPath is the storage-release contract.
//
// Erasure deletes the photo rows, which removes the only pointer the media
// cleanup had to those objects — measured behaviour was that an erased
// member's file survived on disk, and on S3 the orphan sweep does not run at
// all. The worker therefore has to drive the deletion itself.
func TestReleaseObjectsDeletesEveryPath(t *testing.T) {
	var deleted []string
	worker := &accountErasureWorker{
		deleteObject: func(path string) error {
			deleted = append(deleted, path)
			return nil
		},
	}

	failed := worker.releaseObjects("user-1", []string{"a/1.jpg", "", "b/2.jpg"})
	if failed != 0 {
		t.Fatalf("expected no failures, got %d", failed)
	}
	if len(deleted) != 2 || deleted[0] != "a/1.jpg" || deleted[1] != "b/2.jpg" {
		t.Fatalf("every non-empty path must be deleted; got %v", deleted)
	}
}

// TestReleaseObjectsReportsFailuresSoTheyRetry pins the retry rule.
//
// A partial release must not be marked complete: the paths live only in the
// erasure summary, so marking it would strand the surviving objects with
// nothing left pointing at them.
func TestReleaseObjectsReportsFailuresSoTheyRetry(t *testing.T) {
	worker := &accountErasureWorker{
		deleteObject: func(path string) error {
			if path == "b/2.jpg" {
				return errors.New("storage unreachable")
			}
			return nil
		},
	}

	failed := worker.releaseObjects("user-1", []string{"a/1.jpg", "b/2.jpg"})
	if failed != 1 {
		t.Fatalf(
			"a failed object must be reported so the release stays unmarked "+
				"and retries; got %d failures",
			failed,
		)
	}
}

// TestErasureSummaryCarriesStoragePaths guards the field the release pass
// reads. Renaming it silently would leave every erased account's objects
// behind while the sweep reported nothing to do.
func TestErasureSummaryCarriesStoragePaths(t *testing.T) {
	encoded := string(mustJSON(erasureSummary{
		UserID:       "user-1",
		StoragePaths: []string{"a/1.jpg"},
	}))
	if !strings.Contains(encoded, `"storage_paths_released"`) {
		t.Fatalf(
			"the release pass reads erasure_summary->'storage_paths_released'; "+
				"summary encoded as %s",
			encoded,
		)
	}
}
