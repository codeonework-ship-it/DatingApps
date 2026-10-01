package mobile

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

// The moderation SLA is a commitment to a user waiting on a decision about
// their own account, so the deadline has to be derived from when they filed —
// not from when a worker happened to look at the row.
func TestModerationSLA_DeadlineIsFortyEightHoursAfterFiling(t *testing.T) {
	created := "2026-03-01T10:00:00Z"

	got := calculateAppealSLADeadline(created)

	want := "2026-03-03T10:00:00Z"
	if got != want {
		t.Fatalf("calculateAppealSLADeadline(%q) = %q, want %q", created, got, want)
	}
}

func TestModerationSLA_DeadlineNormalisesToUTC(t *testing.T) {
	// Same instant as 2026-03-01T10:00:00Z, expressed with an offset.
	created := "2026-03-01T15:30:00+05:30"

	got := calculateAppealSLADeadline(created)

	if !strings.HasSuffix(got, "Z") {
		t.Fatalf("deadline %q is not normalised to UTC", got)
	}
	parsed, err := time.Parse(time.RFC3339, got)
	if err != nil {
		t.Fatalf("deadline %q is not RFC3339: %v", got, err)
	}
	want := time.Date(2026, 3, 3, 10, 0, 0, 0, time.UTC)
	if !parsed.Equal(want) {
		t.Fatalf("deadline = %s, want %s", parsed, want)
	}
}

// An unparseable timestamp must not silently produce a deadline in 1970, which
// would mark every such appeal as already breached and bury the real ones.
func TestModerationSLA_UnparseableFilingTimeFallsForward(t *testing.T) {
	before := time.Now().UTC()

	got := calculateAppealSLADeadline("not-a-timestamp")

	parsed, err := time.Parse(time.RFC3339, got)
	if err != nil {
		t.Fatalf("fallback deadline %q is not RFC3339: %v", got, err)
	}
	if parsed.Before(before.Add(appealSLADuration - time.Minute)) {
		t.Fatalf("fallback deadline %s is in the past relative to now+SLA", parsed)
	}
}

func TestModerationSLA_EmptyFilingTimeFallsForward(t *testing.T) {
	before := time.Now().UTC()

	parsed, err := time.Parse(time.RFC3339, calculateAppealSLADeadline("   "))
	if err != nil {
		t.Fatalf("fallback deadline is not RFC3339: %v", err)
	}
	if parsed.Before(before.Add(appealSLADuration - time.Minute)) {
		t.Fatalf("fallback deadline %s is in the past relative to now+SLA", parsed)
	}
}

// The deadline has to reach the client, otherwise neither the user nor the
// review queue can act on it.
func TestModerationSLA_SubmittedAppealPublishesItsDeadline(t *testing.T) {
	installOperatorPrincipal(t, "user-sla-1", "admin")
	server := newAppealsTestServer(t)
	defer server.Close()

	body := `{"user_id":"user-sla-1","report_id":"rep-sla","reason":"disputed removal"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/moderation/appeals", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("submit appeal code=%d body=%s", rec.Code, rec.Body.String())
	}

	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	appeal, ok := payload["appeal"].(map[string]any)
	if !ok {
		t.Fatalf("response has no appeal object: %s", rec.Body.String())
	}

	deadlineRaw, _ := appeal["sla_deadline_at"].(string)
	if strings.TrimSpace(deadlineRaw) == "" {
		t.Fatalf("appeal does not publish sla_deadline_at: %v", appeal)
	}
	deadline, err := time.Parse(time.RFC3339, deadlineRaw)
	if err != nil {
		t.Fatalf("sla_deadline_at %q is not RFC3339: %v", deadlineRaw, err)
	}

	createdRaw, _ := appeal["created_at"].(string)
	created, err := time.Parse(time.RFC3339, createdRaw)
	if err != nil {
		// Fall back to comparing against now when the fixture omits created_at.
		created = time.Now().UTC()
	}

	gap := deadline.Sub(created)
	if gap < appealSLADuration-time.Minute || gap > appealSLADuration+time.Minute {
		t.Fatalf("sla gap = %s, want ~%s (created=%s deadline=%s)",
			gap, appealSLADuration, created, deadline)
	}
	// The database enforces the same invariant via moderation_appeals_sla_check.
	if deadline.Before(created) {
		t.Fatalf("deadline %s precedes filing time %s", deadline, created)
	}
}
