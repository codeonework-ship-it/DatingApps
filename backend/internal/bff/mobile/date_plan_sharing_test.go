package mobile

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestDatePlanSharingConsentAndRevocationPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	svc := newDatePlanService(f.db)
	plan, err := svc.propose(ctx, datePlanProposal{MatchID: f.matchID, ProposerID: f.proposer, WindowStart: time.Now().UTC().Add(time.Hour), WindowEnd: time.Now().UTC().Add(2 * time.Hour), VenueCategory: "coffee", GroupIDs: []string{f.groupID}, BudgetPreference: "modest"})
	if err != nil {
		t.Fatal(err)
	}
	for _, id := range []string{f.proposerFriend, f.groupMate, f.inviteeFriend} {
		if f.notifications(t, id, "date_plan.proposed") != 0 {
			t.Fatal("automatic share leaked")
		}
	}
	initial, err := svc.sharing(ctx, f.matchID, plan.ID, f.proposer)
	if err != nil || len(initial.ContactIDs) != 0 || initial.Version != 0 {
		t.Fatalf("initial %+v %v", initial, err)
	}
	if len(initial.Contacts) != 1 || initial.Contacts[0].ID != f.proposerFriend {
		t.Fatalf("eligible contacts %+v", initial.Contacts)
	}
	if _, err = svc.sharing(ctx, f.matchID, plan.ID, f.stranger); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("stranger can read sharing")
	}
	for _, id := range []string{f.blockedFriend, f.groupMate, f.stranger, f.invitee} {
		if err = svc.updateSharing(ctx, f.matchID, plan.ID, f.proposer, []string{id}, 0); !errors.Is(err, errDatePlanForbidden) {
			t.Fatalf("invalid recipient %s: %v", id, err)
		}
	}
	if err = svc.updateSharing(ctx, f.matchID, plan.ID, f.proposer, []string{f.proposerFriend}, 0); err != nil {
		t.Fatal(err)
	}
	if err = svc.updateSharing(ctx, f.matchID, plan.ID, f.proposer, []string{}, 0); !errors.Is(err, errDatingConflict) {
		t.Fatalf("stale update allowed: %v", err)
	}
	mine, _ := svc.sharing(ctx, f.matchID, plan.ID, f.proposer)
	other, _ := svc.sharing(ctx, f.matchID, plan.ID, f.invitee)
	if len(mine.ContactIDs) != 1 || len(other.ContactIDs) != 0 {
		t.Fatal("contact choices cross member boundary")
	}
	feed, err := svc.friendPlans(ctx, f.proposerFriend, 10)
	if err != nil || len(feed) != 1 {
		t.Fatalf("shared feed %+v %v", feed, err)
	}
	repo := &notificationRepository{db: f.db}
	job := notificationOutboxJob{ReferenceID: plan.ID, RecipientUserID: f.proposerFriend, EventType: "date_plan.proposed", Payload: map[string]any{"friend_user_id": f.proposer}}
	if ok, err := repo.planSharingAllowed(ctx, job); err != nil || !ok {
		t.Fatalf("allowed %v %v", ok, err)
	}
	if err = svc.updateSharing(ctx, f.matchID, plan.ID, f.proposer, []string{}, 1); err != nil {
		t.Fatal(err)
	}
	feed, err = svc.friendPlans(ctx, f.proposerFriend, 10)
	if err != nil || len(feed) != 0 {
		t.Fatal("revoked feed remains")
	}
	if ok, err := repo.planSharingAllowed(ctx, job); err != nil || ok {
		t.Fatalf("revoked job allowed %v %v", ok, err)
	}
	var pending int
	if err = f.db.QueryRow(`SELECT count(*) FROM matching.notification_outbox WHERE reference_id=$1 AND recipient_user_id=$2 AND status IN ('pending','retry','processing')`, plan.ID, f.proposerFriend).Scan(&pending); err != nil || pending != 0 {
		t.Fatalf("pending revoked deliveries %d %v", pending, err)
	}
	// Restoring consent uses a new version; stale retries cannot overwrite it.
	if err = svc.updateSharing(ctx, f.matchID, plan.ID, f.proposer, []string{f.proposerFriend}, 2); err != nil {
		t.Fatal(err)
	}
	// Blocking after consent also prevents feed access and delivery.
	if _, err = f.db.Exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, f.proposerFriend, f.proposer); err != nil {
		t.Fatal(err)
	}
	feed, err = svc.friendPlans(ctx, f.proposerFriend, 10)
	if err != nil || len(feed) != 0 {
		t.Fatal("blocked feed remains")
	}
	if ok, err := repo.planSharingAllowed(ctx, job); err != nil || ok {
		t.Fatalf("blocked job allowed %v %v", ok, err)
	}
}

func TestDatePlanSharingHTTPRejectsUnversionedUpdatesPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	svc := newDatePlanService(f.db)
	plan, err := svc.propose(context.Background(), datePlanProposal{MatchID: f.matchID, ProposerID: f.proposer, WindowStart: time.Now().Add(time.Hour), WindowEnd: time.Now().Add(2 * time.Hour), VenueCategory: "walk", BudgetPreference: "free"})
	if err != nil {
		t.Fatal(err)
	}
	server := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	for _, body := range []string{`{"contact_ids":[]}`, `{"contact_ids":[],"expected_version":-1}`, `{"contact_ids":["invalid"],"expected_version":0}`} {
		rec := httptest.NewRecorder()
		server.datePlanSharingHandler(rec, datePlanRequest(http.MethodPost, "/sharing", f.matchID, plan.ID, f.proposer, body))
		if rec.Code != 400 {
			t.Fatalf("invalid body accepted %d %s", rec.Code, rec.Body.String())
		}
	}
}

func TestCuratedIntroductionUsesCurrentSharedPreferencesPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	for _, id := range []string{f.proposer, f.invitee} {
		if _, err := f.db.Exec(`INSERT INTO matching.dating_preferences(user_id,activities,share_availability) VALUES($1,'["coffee"]'::jsonb,false)`, id); err != nil {
			t.Fatal(err)
		}
	}
	svc := newCuratedDailySetService(f.db)
	pool := []map[string]any{{"id": f.invitee, "name": "Arjun"}}
	first, err := svc.serve(ctx, f.proposer, pool)
	if err != nil {
		t.Fatal(err)
	}
	activities, ok := first.Candidates[0]["shared_activities"].([]string)
	if !ok || len(activities) != 1 || activities[0] != "coffee" || first.Candidates[0]["availability_overlaps"] != false {
		t.Fatalf("fit %+v", first.Candidates)
	}
	if _, err = f.db.Exec(`UPDATE matching.dating_preferences SET activities='["walk"]'::jsonb WHERE user_id=$1`, f.invitee); err != nil {
		t.Fatal(err)
	}
	next, err := svc.serve(ctx, f.proposer, pool)
	if err != nil {
		t.Fatal(err)
	}
	if len(next.Candidates[0]["shared_activities"].([]string)) != 0 {
		t.Fatal("cached introduction retained a withdrawn activity")
	}
}
