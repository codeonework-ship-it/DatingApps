package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestPlanPreferencesValidation(t *testing.T) {
	now := time.Now().UTC()
	start := now.Add(24 * time.Hour).Truncate(time.Minute)
	body := func() map[string]any {
		return map[string]any{"window_start": start.Format(time.RFC3339), "window_end": start.Add(90 * time.Minute).Format(time.RFC3339), "venue_category": "coffee", "budget_preference": "modest", "atmosphere_preferences": []any{"quiet", "relaxed"}, "accessibility_preferences": []any{"step_free", "seating"}, "shared_window": map[string]any{"start": start.Format(time.RFC3339), "end": start.Add(90 * time.Minute).Format(time.RFC3339)}}
	}
	p, err := parseDatePlanProposal(body(), uuid.NewString(), uuid.NewString(), now)
	if err != nil || p.WindowEnd.Sub(p.WindowStart) != 90*time.Minute || len(p.AccessibilityPreferences) != 2 || p.SharedWindow == nil {
		t.Fatalf("valid: %+v %v", p, err)
	}
	for _, name := range []string{"unknown atmosphere", "too many", "bad type", "unknown access", "outside shared", "budget"} {
		t.Run(name, func(t *testing.T) {
			b := body()
			switch name {
			case "unknown atmosphere":
				b["atmosphere_preferences"] = []any{"romantic_score"}
			case "too many":
				b["atmosphere_preferences"] = []any{"quiet", "relaxed", "indoors", "outdoors"}
			case "bad type":
				b["accessibility_preferences"] = "step_free"
			case "unknown access":
				b["accessibility_preferences"] = []any{"diagnosis"}
			case "outside shared":
				b["window_end"] = start.Add(2 * time.Hour).Format(time.RFC3339)
			case "budget":
				b["budget_preference"] = "spend_anything"
			}
			if _, err := parseDatePlanProposal(b, uuid.NewString(), uuid.NewString(), now); err == nil {
				t.Fatal("invalid choices accepted")
			}
		})
	}
	b := body()
	b["accessibility_preferences"] = []any{"seating", "seating"}
	p, err = parseDatePlanProposal(b, uuid.NewString(), uuid.NewString(), now)
	if err != nil || len(p.AccessibilityPreferences) != 1 {
		t.Fatal("duplicates not normalized")
	}
	delete(b, "accessibility_preferences")
	p, err = parseDatePlanProposal(b, uuid.NewString(), uuid.NewString(), now)
	if err != nil || p.AccessibilityPreferences != nil {
		t.Fatal("legacy omission must remain distinguishable from explicit empty")
	}
}

func TestPlanPreferencesRoundTripAndPrivateFanoutPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	svc := newDatePlanService(f.db)
	start := time.Now().Add(24 * time.Hour).Truncate(time.Minute)
	p := datePlanProposal{MatchID: f.matchID, ProposerID: f.proposer, WindowStart: start, WindowEnd: start.Add(90 * time.Minute), VenueCategory: "coffee", BudgetPreference: "modest", AtmospherePreferences: []string{"quiet", "indoors"}, AccessibilityPreferences: []string{"step_free", "seating"}}
	plan, err := svc.propose(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	if plan.WindowEnd != p.WindowEnd.UTC().Format(time.RFC3339) || len(plan.AccessibilityPreferences) != 2 || len(plan.AtmospherePreferences) != 2 || plan.BudgetPreference != "modest" {
		t.Fatalf("fields dropped: %+v", plan)
	}
	open, _, _, err := svc.matchPlans(ctx, f.matchID, f.invitee)
	if err != nil || len(open.AccessibilityPreferences) != 2 {
		t.Fatalf("partner view: %+v %v", open, err)
	}
	if _, _, _, err = svc.matchPlans(ctx, f.matchID, f.stranger); !errors.Is(err, errDatePlanForbidden) {
		t.Fatalf("outsider read: %v", err)
	}
	if err = svc.updateSharing(ctx, f.matchID, plan.ID, f.proposer, []string{f.proposerFriend}, 0); err != nil {
		t.Fatal(err)
	}
	var exposed int
	if err = f.db.QueryRow(`SELECT COUNT(*) FROM matching.notification_outbox WHERE payload->>'plan_id'=$1 AND (payload::text LIKE '%step_free%' OR payload::text LIKE '%accessibility_preferences%')`, plan.ID).Scan(&exposed); err != nil {
		t.Fatal(err)
	}
	if exposed != 0 {
		t.Fatal("accessibility leaked to push")
	}
	if err = f.db.QueryRow(`SELECT COUNT(*) FROM matching.friend_activity_feed WHERE metadata->>'plan_id'=$1 AND (metadata::text LIKE '%step_free%' OR metadata::text LIKE '%accessibility_preferences%')`, plan.ID).Scan(&exposed); err != nil {
		t.Fatal(err)
	}
	if exposed != 0 {
		t.Fatal("accessibility leaked to friends")
	}
	var eventPayload string
	if err = f.db.QueryRow(`SELECT string_agg(payload::text,' ') FROM platform.domain_event_outbox WHERE aggregate_id=$1`, plan.ID).Scan(&eventPayload); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(eventPayload, "step_free") || strings.Contains(eventPayload, "indoors") {
		t.Fatal("private choice values leaked into events")
	}
	// Shared preference content is removed if either participant is erased.
	for _, step := range accountErasureSteps() {
		if step.label == "date_plan_preferences" {
			if _, err = f.db.Exec(step.query, f.invitee); err != nil {
				t.Fatal(err)
			}
		}
	}
	open, _, _, err = svc.matchPlans(ctx, f.matchID, f.proposer)
	if err != nil || len(open.AccessibilityPreferences) != 0 || len(open.AtmospherePreferences) != 0 || open.BudgetPreference != "flexible" {
		t.Fatalf("erasure: %+v %v", open, err)
	}
}

func TestSharedPlanWindowRechecksConsentAndExactBoundsPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	svc := newDatePlanService(f.db)
	start := time.Now().Add(24 * time.Hour).Truncate(time.Minute)
	a := emptyDatingPreferences()
	a.ShareAvailability = true
	a.Availability = []datingWindow{{start, start.Add(3 * time.Hour)}}
	b := a
	b.Availability = []datingWindow{{start.Add(30 * time.Minute), start.Add(2 * time.Hour)}}
	var err error
	a, err = saveDatingPreferences(ctx, f.db, f.proposer, a)
	if err != nil {
		t.Fatal(err)
	}
	b, err = saveDatingPreferences(ctx, f.db, f.invitee, b)
	if err != nil {
		t.Fatal(err)
	}
	p := datePlanProposal{MatchID: f.matchID, ProposerID: f.proposer, WindowStart: start.Add(30 * time.Minute), WindowEnd: start.Add(2 * time.Hour), VenueCategory: "coffee", SharedWindow: &datingWindow{start.Add(30 * time.Minute), start.Add(2 * time.Hour)}}
	b.ShareAvailability = false
	b.Availability = []datingWindow{}
	b, err = saveDatingPreferences(ctx, f.db, f.invitee, b)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = svc.propose(ctx, p); !errors.Is(err, errDatePlanAvailabilityChanged) {
		t.Fatalf("revoked availability used: %v", err)
	}
	rec := httptest.NewRecorder()
	writeDatePlanError(rec, err)
	if rec.Code != 409 || !strings.Contains(rec.Body.String(), "SHARED_AVAILABILITY_CHANGED") {
		t.Fatalf("conflict response: %s", rec.Body.String())
	}
	b.ShareAvailability = true
	b.Availability = []datingWindow{{start.Add(30 * time.Minute), start.Add(2 * time.Hour)}}
	if _, err = saveDatingPreferences(ctx, f.db, f.invitee, b); err != nil {
		t.Fatal(err)
	}
	overflow := p
	overflow.WindowEnd = start.Add(121 * time.Minute)
	if _, err = svc.propose(ctx, overflow); !errors.Is(err, errDatePlanAvailabilityChanged) {
		t.Fatalf("window expanded outside overlap: %v", err)
	}
	plan, err := svc.propose(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	if plan.WindowStart != p.WindowStart.UTC().Format(time.RFC3339) || plan.WindowEnd != p.WindowEnd.UTC().Format(time.RFC3339) {
		t.Fatal("90-minute selection rounded")
	}
}

func TestPlanPreferencesCountersRequireReviewAndKeepLegacyChoicesPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	svc := newDatePlanService(f.db)
	start := time.Now().Add(24 * time.Hour).Truncate(time.Minute)
	p := datePlanProposal{MatchID: f.matchID, ProposerID: f.proposer, WindowStart: start, WindowEnd: start.Add(90 * time.Minute), VenueCategory: "coffee", BudgetPreference: "modest", AtmospherePreferences: []string{"quiet"}, AccessibilityPreferences: []string{"step_free"}}
	original, err := svc.propose(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	p.ProposerID = f.invitee
	p.AtmospherePreferences = []string{"outdoors"}
	p.AccessibilityPreferences = nil
	current, err := svc.counter(ctx, original.ID, p, original.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	if current.Status != "proposed" || current.AccessibilityPreferences[0] != "step_free" {
		t.Fatal("counter silently accepted or legacy client cleared requests")
	}
	if _, err = svc.decide(ctx, f.matchID, original.ID, f.proposer, "accept", nil, original.LockVersion); !errors.Is(err, errDatingConflict) {
		t.Fatalf("stale accept: %v", err)
	}
	p.ProposerID = f.proposer
	p.AccessibilityPreferences = []string{}
	current, err = svc.counter(ctx, original.ID, p, current.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	if len(current.AccessibilityPreferences) != 0 {
		t.Fatal("explicit clearing was ignored")
	}
	p.ProposerID = f.invitee
	current, err = svc.counter(ctx, original.ID, p, current.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	var count int
	if err = f.db.QueryRow(`SELECT COUNT(*) FROM matching.notification_outbox WHERE payload->>'plan_id'=$1 AND event_type='date_plan.counterproposed'`, original.ID).Scan(&count); err != nil || count != 3 {
		t.Fatalf("counter notifications collapsed: %d %v", count, err)
	}
	accepted, err := svc.decide(ctx, f.matchID, original.ID, f.proposer, "accept", nil, current.LockVersion)
	if err != nil || accepted.Status != "accepted" || accepted.AtmospherePreferences[0] != "outdoors" {
		t.Fatalf("acceptance did not cover latest choices: %+v %v", accepted, err)
	}
	raw, _ := json.Marshal(accepted)
	if strings.Contains(string(raw), "shared_window") {
		t.Fatal("raw availability stored on plan")
	}
}
