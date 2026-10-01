package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestDatingPreferencesConsentAndExpiry(t *testing.T) {
	now := time.Now().UTC()
	window := map[string]any{"start": now.Add(time.Hour).Format(time.RFC3339), "end": now.Add(3 * time.Hour).Format(time.RFC3339)}
	body := map[string]any{"intent": "relationship", "pace": "slow", "activities": []string{"coffee", "coffee"}, "availability": []any{window}, "version": 0}
	p, err := parseDatingPreferences(body, now)
	if err != nil {
		t.Fatal(err)
	}
	if len(p.Availability) != 0 || len(p.Activities) != 1 {
		t.Fatal("unconsented windows persisted or duplicate activities retained")
	}
	body["share_availability"] = true
	p, err = parseDatingPreferences(body, now)
	if err != nil || len(p.Availability) != 1 {
		t.Fatalf("consented availability: %+v %v", p, err)
	}
	other := p
	other.ShareAvailability = false
	if len(datingOverlap(p, other, now)) != 0 {
		t.Fatal("availability disclosed without both consents")
	}
	other.ShareAvailability = true
	if len(datingOverlap(p, other, now)) != 1 {
		t.Fatal("real overlap missing")
	}
	if len(datingOverlap(p, other, now.Add(4*time.Hour))) != 0 {
		t.Fatal("expired window used")
	}
	body["pace"] = "always_online"
	if _, err = parseDatingPreferences(body, now); err == nil {
		t.Fatal("invented pace accepted")
	}
	body["pace"] = "slow"
	body["availability"] = []any{window, window}
	if _, err = parseDatingPreferences(body, now); err == nil {
		t.Fatal("overlapping windows accepted")
	}
}
func TestSecondYesRequiresBothExplicitConsents(t *testing.T) {
	yes, no := true, false
	a := datePlanDebrief{Happened: true, WouldMeetAgain: &yes, ShareMutualInterest: true}
	b := a
	if !mutualSecondYes(a, b) {
		t.Fatal("mutual yes missing")
	}
	b.ShareMutualInterest = false
	if mutualSecondYes(a, b) {
		t.Fatal("private answer disclosed")
	}
	b.ShareMutualInterest = true
	b.WouldMeetAgain = &no
	if mutualSecondYes(a, b) {
		t.Fatal("one-sided interest disclosed")
	}
	b.WouldMeetAgain = nil
	if mutualSecondYes(a, b) {
		t.Fatal("missing feedback treated as yes")
	}
	b = a
	b.Happened = false
	if mutualSecondYes(a, b) {
		t.Fatal("date did not happen")
	}
}
func TestDatingPreferencesVersionAndErasePostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	p := emptyDatingPreferences()
	p.Intent = "relationship"
	p.ShareAvailability = true
	p.Availability = []datingWindow{{time.Now().Add(time.Hour), time.Now().Add(3 * time.Hour)}}
	saved, err := saveDatingPreferences(ctx, f.db, f.proposer, p)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = saveDatingPreferences(ctx, f.db, f.proposer, p); !errors.Is(err, errDatingConflict) {
		t.Fatalf("stale save accepted: %v", err)
	}
	saved.ShareAvailability = false
	saved.Availability = []datingWindow{}
	saved, err = saveDatingPreferences(ctx, f.db, f.proposer, saved)
	if err != nil {
		t.Fatal(err)
	}
	read, err := loadDatingPreferences(ctx, f.db, f.proposer, time.Now())
	if err != nil || len(read.Availability) != 0 || read.Version != 2 {
		t.Fatalf("consent withdrawal failed: %+v %v", read, err)
	}
	server := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	rec := httptest.NewRecorder()
	req := socialRequest(http.MethodGet, "/prefs", f.invitee, "userID", f.proposer, "")
	server.datingPreferencesHandler(rec, req)
	if rec.Code != 403 {
		t.Fatalf("foreign preferences returned %d", rec.Code)
	}
	var payload string
	if err = f.db.QueryRow(`SELECT payload::text FROM platform.domain_event_outbox WHERE aggregate_id=$1 AND aggregate_type='dating.preferences' ORDER BY sequence_id DESC LIMIT 1`, f.proposer).Scan(&payload); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(payload, "relationship") || strings.Contains(payload, p.Availability[0].Start.Format("2006-01-02T15")) {
		t.Fatal("private values leaked into domain event")
	}
}
func TestChemistrySealedAnswersAndRetryPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	id := uuid.NewString()
	v, err := mutateChemistry(ctx, f.db, f.matchID, f.proposer, id, "sunday", "")
	if err != nil {
		t.Fatal(err)
	}
	retry, err := mutateChemistry(ctx, f.db, f.matchID, f.proposer, id, "sunday", "")
	if err != nil || retry.ID != v.ID {
		t.Fatalf("retry duplicated moment: %v", err)
	}
	if _, err = mutateChemistry(ctx, f.db, f.matchID, f.stranger, id, "", "food"); !errors.Is(err, errDatePlanForbidden) {
		t.Fatalf("outsider answer: %v", err)
	}
	if _, err = mutateChemistry(ctx, f.db, f.matchID, f.proposer, id, "", "food"); err != nil {
		t.Fatal(err)
	}
	hidden, err := loadChemistry(ctx, f.db, f.matchID, f.invitee, f.proposer)
	if err != nil {
		t.Fatal(err)
	}
	if hidden.PartnerAnswer != "" || hidden.Status != "open" {
		t.Fatalf("answer exposed early: %+v", hidden)
	}
	if _, err = mutateChemistry(ctx, f.db, f.matchID, f.proposer, id, "", "outdoors"); !errors.Is(err, errDatingConflict) {
		t.Fatalf("answer was mutable: %v", err)
	}
	revealed, err := mutateChemistry(ctx, f.db, f.matchID, f.invitee, id, "", "bookstore")
	if err != nil {
		t.Fatal(err)
	}
	if revealed.Status != "revealed" || revealed.PartnerAnswer != "food" {
		t.Fatalf("reveal failed %+v", revealed)
	}
	if _, err = f.db.Exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, f.proposer, f.invitee); err != nil {
		t.Fatal(err)
	}
	if _, err = activeDatingPair(ctx, f.db, f.matchID, f.invitee, false); err == nil {
		t.Fatal("blocked pair retained access")
	}
}
func TestCounterproposalRequiresCurrentVersionPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	svc := newDatePlanService(f.db)
	p := datePlanProposal{MatchID: f.matchID, ProposerID: f.proposer, WindowStart: time.Now().Add(24 * time.Hour), WindowEnd: time.Now().Add(25 * time.Hour), VenueCategory: "coffee", BudgetPreference: "modest"}
	plan, err := svc.propose(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	p.ProposerID = f.invitee
	p.VenueCategory = "walk"
	p.BudgetPreference = "free"
	changed, err := svc.counter(ctx, plan.ID, p, plan.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	if changed.NextAction != "await_decision" || changed.LockVersion <= plan.LockVersion {
		t.Fatalf("counter state: %+v", changed)
	}
	if _, err = svc.counter(ctx, plan.ID, p, plan.LockVersion); !errors.Is(err, errDatingConflict) {
		t.Fatalf("stale counter: %v", err)
	}
	if _, err = svc.decide(ctx, f.matchID, plan.ID, f.invitee, "accept", nil, changed.LockVersion); !errors.Is(err, errDatePlanNotInvitee) {
		t.Fatalf("self accept: %v", err)
	}
	if _, err = svc.decide(ctx, f.matchID, plan.ID, f.proposer, "accept", nil, plan.LockVersion); !errors.Is(err, errDatingConflict) {
		t.Fatalf("stale acceptance: %v", err)
	}
	if _, err = svc.decide(ctx, f.matchID, plan.ID, f.proposer, "accept", nil); !errors.Is(err, errDatingConflict) {
		t.Fatalf("unversioned acceptance: %v", err)
	}
	if _, err = f.db.ExecContext(ctx, `UPDATE matching.match_date_plans SET invitee_group_ids=ARRAY[$2::uuid] WHERE id=$1::uuid`, plan.ID, f.groupID); err != nil {
		t.Fatal(err)
	}
	accepted, err := svc.decide(ctx, f.matchID, plan.ID, f.proposer, "accept", nil, changed.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	var preserved bool
	if err = f.db.QueryRowContext(ctx, `SELECT $2::uuid=ANY(invitee_group_ids) FROM matching.match_date_plans WHERE id=$1::uuid`, plan.ID, f.groupID).Scan(&preserved); err != nil || !preserved {
		t.Fatalf("counter acceptance changed partner sharing: %v", err)
	}
	if accepted.Status != "accepted" || accepted.BudgetPreference != "free" || accepted.VenueCategory != "walk" {
		t.Fatalf("wrong revision accepted: %+v", accepted)
	}
}
func TestPrivateSecondYesProjectionPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	svc := newDatePlanService(f.db)
	now := time.Now()
	p := datePlanProposal{MatchID: f.matchID, ProposerID: f.proposer, WindowStart: now.Add(-30 * time.Minute), WindowEnd: now.Add(30 * time.Minute), VenueCategory: "walk"}
	plan, err := svc.propose(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = svc.decide(ctx, f.matchID, plan.ID, f.invitee, "accept", nil, plan.LockVersion); err != nil {
		t.Fatal(err)
	}
	svc.now = func() time.Time { return now.Add(3 * time.Hour) }
	yes := true
	first, err := svc.debrief(ctx, f.matchID, plan.ID, f.proposer, true, &yes, &yes, "My private note", true)
	if err != nil {
		t.Fatal(err)
	}
	if first.MutualSecondYes {
		t.Fatal("one-sided interest revealed")
	}
	second, err := svc.debrief(ctx, f.matchID, plan.ID, f.invitee, true, &yes, &yes, "Their private note", true)
	if err != nil {
		t.Fatal(err)
	}
	if !second.MutualSecondYes {
		t.Fatal("two consensual yeses not revealed")
	}
	raw, _ := json.Marshal(second)
	if strings.Contains(string(raw), "My private note") {
		t.Fatal("other member's feedback leaked")
	}
}
func TestFriendIntroConsentAndPrivateOutcomePostgres(t *testing.T) {
	f := newFriendSocialFixture(t)
	ctx := context.Background()
	svc := newFriendSocialService(f.db)
	if _, err := svc.makeIntro(ctx, f.introducer, f.alice, f.bob, "You both enjoy books."); !errors.Is(err, errIntroUnavailable) {
		t.Fatalf("default-off introductions allowed: %v", err)
	}
	for _, id := range []string{f.alice, f.bob} {
		p := emptyDatingPreferences()
		p.AllowFriendIntros = true
		if _, err := saveDatingPreferences(ctx, f.db, id, p); err != nil {
			t.Fatal(err)
		}
	}
	intro, err := svc.makeIntro(ctx, f.introducer, f.alice, f.bob, "You both enjoy books.")
	if err != nil {
		t.Fatal(err)
	}
	received, _, err := svc.listIntros(ctx, f.alice)
	if err != nil {
		t.Fatal(err)
	}
	if len(received) != 1 || len(received[0].Other.PhotoURLs) != 0 || received[0].Other.City != "" {
		t.Fatalf("unconsented preview fields: %+v", received)
	}
	p, err := loadDatingPreferences(ctx, f.db, f.bob, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	p.AllowFriendIntros = false
	if _, err = saveDatingPreferences(ctx, f.db, f.bob, p); err != nil {
		t.Fatal(err)
	}
	received, _, err = svc.listIntros(ctx, f.alice)
	if err != nil {
		t.Fatal(err)
	}
	if received[0].Other != nil || received[0].Message != "" {
		t.Fatal("withdrawn sharing still visible")
	}
	if _, err = svc.decideIntro(ctx, f.alice, intro.ID, "decline"); err != nil {
		t.Fatal(err)
	}
	_, made, err := svc.listIntros(ctx, f.introducer)
	if err != nil {
		t.Fatal(err)
	}
	if made[0].Status != "sent" || made[0].MatchID != "" {
		t.Fatal("outcome exposed to introducer")
	}
	if f.notifications(t, f.introducer, "friend_intro.declined") != 0 {
		t.Fatal("decline sent to introducer")
	}
}
