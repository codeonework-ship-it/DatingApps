package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/postgresdata"
)

func TestParseDatePlanProposalValidation(t *testing.T) {
	now := time.Date(2026, 9, 27, 12, 0, 0, 0, time.UTC)
	match := uuid.NewString()
	valid := map[string]any{
		"window_start": "2026-09-28T16:00:00Z", "window_end": "2026-09-28T18:00:00Z",
		"venue_category": "Coffee", "venue_area": "Indiranagar", "note": "Looking forward",
		"group_ids": []any{uuid.NewString()},
	}
	p, err := parseDatePlanProposal(valid, match, uuid.NewString(), now)
	if err != nil {
		t.Fatalf("valid proposal rejected: %v", err)
	}
	if p.VenueCategory != "coffee" || len(p.GroupIDs) != 1 {
		t.Fatalf("normalised proposal = %+v", p)
	}
	cases := map[string]map[string]any{
		"end before start": {"window_start": "2026-09-28T18:00:00Z", "window_end": "2026-09-28T16:00:00Z", "venue_category": "coffee"},
		"window too long":  {"window_start": "2026-09-28T06:00:00Z", "window_end": "2026-09-28T20:00:00Z", "venue_category": "coffee"},
		"in the past":      {"window_start": "2026-09-20T16:00:00Z", "window_end": "2026-09-20T18:00:00Z", "venue_category": "coffee"},
		"too far ahead":    {"window_start": "2027-03-01T16:00:00Z", "window_end": "2027-03-01T18:00:00Z", "venue_category": "coffee"},
		"bad venue":        {"window_start": "2026-09-28T16:00:00Z", "window_end": "2026-09-28T18:00:00Z", "venue_category": "yacht"},
		"long note":        {"window_start": "2026-09-28T16:00:00Z", "window_end": "2026-09-28T18:00:00Z", "venue_category": "coffee", "note": strings.Repeat("x", 281)},
		"bad group":        {"window_start": "2026-09-28T16:00:00Z", "window_end": "2026-09-28T18:00:00Z", "venue_category": "coffee", "group_ids": []any{"not-a-uuid"}},
	}
	for name, payload := range cases {
		if _, err := parseDatePlanProposal(payload, match, uuid.NewString(), now); err == nil {
			t.Errorf("%s: accepted", name)
		}
	}
}

func TestDatePlanNextAction(t *testing.T) {
	now := time.Date(2026, 9, 27, 12, 0, 0, 0, time.UTC)
	later := now.Add(2 * time.Hour)
	if got := datePlanNextAction("proposed", "invitee", nil, "u", now, later, false); got != "decide" {
		t.Fatalf("invitee on proposed = %q", got)
	}
	if got := datePlanNextAction("proposed", "proposer", nil, "u", now, later, false); got != "await_decision" {
		t.Fatalf("proposer on proposed = %q", got)
	}
	if got := datePlanNextAction("accepted", "proposer", nil, "u", now, later, false); got != "upcoming" {
		t.Fatalf("accepted before window = %q", got)
	}
	if got := datePlanNextAction("accepted", "proposer", nil, "u", later.Add(time.Hour), later, false); got != "checkin" {
		t.Fatalf("accepted after window = %q", got)
	}
	checked := []datePlanCheckin{{UserID: "u", Status: "safe"}}
	if got := datePlanNextAction("accepted", "proposer", checked, "u", later.Add(time.Hour), later, false); got != "debrief" {
		t.Fatalf("after own check-in = %q", got)
	}
	if got := datePlanNextAction("accepted", "proposer", checked, "u", later.Add(time.Hour), later, true); got != "none" {
		t.Fatalf("after check-in and debrief = %q", got)
	}
	if got := datePlanNextAction("cancelled", "proposer", nil, "u", now, later, false); got != "propose" {
		t.Fatalf("resolved plan = %q", got)
	}
}

// ── Postgres lifecycle ───────────────────────────────────────────────────────

type datePlanFixture struct {
	db                                 *sql.DB
	matchID                            string
	proposer, invitee                  string
	proposerFriend, inviteeFriend      string
	blockedFriend, groupMate, stranger string
	groupID                            string
}

func newDatePlanFixture(t *testing.T) datePlanFixture {
	t.Helper()
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	ctx := context.Background()
	var ready bool
	if err := db.QueryRowContext(ctx, `SELECT to_regclass('matching.match_date_plans') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 091_date_plans_friend_fan_out is not applied")
	}
	f := datePlanFixture{db: db}
	names := []string{"Priya", "Arjun", "Meera", "Dev", "Blocked", "Groupmate", "Stranger"}
	ids := make([]string, len(names))
	for i, name := range names {
		id := uuid.NewString()
		username := "planqa_" + strings.ReplaceAll(id[:8], "-", "")
		if _, err := db.ExecContext(ctx, `INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email)
			VALUES ($1,$2,$3,'1992-01-01','female',$4)`, id, username, name, username+"@example.test"); err != nil {
			t.Fatalf("seed member %s: %v", name, err)
		}
		ids[i] = id
	}
	t.Cleanup(func() {
		for _, id := range ids {
			deleteTestMember(ctx, db, id)
		}
	})
	f.proposer, f.invitee, f.proposerFriend, f.inviteeFriend = ids[0], ids[1], ids[2], ids[3]
	f.blockedFriend, f.groupMate, f.stranger = ids[4], ids[5], ids[6]

	first, second := f.proposer, f.invitee
	if first > second {
		first, second = second, first
	}
	f.matchID = uuid.NewString()
	if _, err := db.ExecContext(ctx, `INSERT INTO matching.matches (id, user_id_1, user_id_2) VALUES ($1,$2,$3)`,
		f.matchID, first, second); err != nil {
		t.Fatalf("seed match: %v", err)
	}
	t.Cleanup(func() { _, _ = db.ExecContext(ctx, `DELETE FROM matching.matches WHERE id=$1`, f.matchID) })

	// Friendships: proposer↔proposerFriend, proposer↔blockedFriend (then blocked),
	// invitee↔inviteeFriend. The stranger is nobody's friend.
	for _, pair := range [][2]string{
		{f.proposer, f.proposerFriend}, {f.proposer, f.blockedFriend}, {f.invitee, f.inviteeFriend},
	} {
		if _, err := db.ExecContext(ctx, `INSERT INTO matching.friend_connections (user_id, friend_user_id, status)
			VALUES ($1,$2,'accepted'),($2,$1,'accepted')`, pair[0], pair[1]); err != nil {
			t.Fatalf("seed friendship: %v", err)
		}
	}
	if _, err := db.ExecContext(ctx, `INSERT INTO user_management.blocked_users (user_id, blocked_user_id, reason)
		VALUES ($1,$2,'test')`, f.blockedFriend, f.proposer); err != nil {
		t.Fatalf("seed block: %v", err)
	}
	// A friend group the proposer and the group mate both belong to.
	f.groupID = uuid.NewString()
	if _, err := db.ExecContext(ctx, `INSERT INTO matching.community_groups (id, name, city, topic, created_by_user_id, visibility)
		VALUES ($1,'Weekend crew','Bengaluru','friends',$2,'private')`, f.groupID, f.proposer); err != nil {
		t.Fatalf("seed group: %v", err)
	}
	t.Cleanup(func() { _, _ = db.ExecContext(ctx, `DELETE FROM matching.community_groups WHERE id=$1`, f.groupID) })
	for _, member := range []string{f.proposer, f.groupMate} {
		if _, err := db.ExecContext(ctx, `INSERT INTO matching.community_group_members (group_id, user_id, status, role, joined_at, updated_at)
			VALUES ($1,$2,'active','member',NOW(),NOW())`, f.groupID, member); err != nil {
			t.Fatalf("seed group member: %v", err)
		}
	}
	return f
}

func (f datePlanFixture) notifications(t *testing.T, recipient, eventType string) int {
	t.Helper()
	var n int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.notification_outbox
		WHERE recipient_user_id=$1 AND event_type=$2`, recipient, eventType).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

func (f datePlanFixture) feedRows(t *testing.T, recipient, activityType string) int {
	t.Helper()
	var n int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.friend_activity_feed
		WHERE user_id=$1 AND activity_type=$2`, recipient, activityType).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

func datePlanRequest(method, path, matchID, planID, userID, body string) *http.Request {
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	routeContext := chi.NewRouteContext()
	routeContext.URLParams.Add("matchID", matchID)
	if planID != "" {
		routeContext.URLParams.Add("planID", planID)
	}
	routeContext.URLParams.Add("userID", userID)
	ctx := context.WithValue(req.Context(), chi.RouteCtxKey, routeContext)
	ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{
		UserID: userID, Roles: map[string]bool{"user": true},
	})
	return req.WithContext(ctx)
}

func decodePlan(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode: %v (%s)", err, rec.Body.String())
	}
	plan, _ := body["plan"].(map[string]any)
	return plan
}

// TestDatePlanLifecycleSharesOnlySelectedContactsPostgres covers the core rule:
// every status reaches only the contacts explicitly chosen by that member,
// never an unselected group, blocked friend, stranger or the date itself
// through the friend channel.
func TestDatePlanLifecycleSharesOnlySelectedContactsPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	server := &Server{
		store:                  &runtimeStore{profileRepo: &profileRepository{pg: f.db}},
		datePlanUnlockOverride: func(string) (bool, string) { return true, "conversation_unlocked" },
	}
	start := time.Now().UTC().Add(-30 * time.Minute).Truncate(time.Second)
	end := start.Add(2 * time.Hour)
	body := `{"window_start":"` + start.Format(time.RFC3339) + `","window_end":"` + end.Format(time.RFC3339) +
		`","venue_category":"coffee","venue_area":"Koramangala","note":"Third Wave?","group_ids":["` + f.groupID + `"]}`

	// A stranger cannot propose on someone else's match.
	forbidden := httptest.NewRecorder()
	server.proposeMatchDatePlan(forbidden, datePlanRequest(http.MethodPost, "/plans", f.matchID, "", f.stranger, body))
	if forbidden.Code != http.StatusForbidden {
		t.Fatalf("stranger propose status=%d body=%s", forbidden.Code, forbidden.Body.String())
	}

	proposed := httptest.NewRecorder()
	server.proposeMatchDatePlan(proposed, datePlanRequest(http.MethodPost, "/plans", f.matchID, "", f.proposer, body))
	if proposed.Code != http.StatusCreated {
		t.Fatalf("propose status=%d body=%s", proposed.Code, proposed.Body.String())
	}
	plan := decodePlan(t, proposed)
	planID := toString(plan["id"])
	if toString(plan["status"]) != "proposed" || toString(plan["next_action"]) != "await_decision" {
		t.Fatalf("proposed plan = %v", plan)
	}
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.match_date_plans WHERE id=$1`, planID) })

	svc := newDatePlanService(f.db)
	for _, id := range []string{f.proposerFriend, f.inviteeFriend, f.groupMate} {
		if got := f.notifications(t, id, "date_plan.proposed"); got != 0 {
			t.Fatalf("private default notified %s", id)
		}
	}
	if err := svc.updateSharing(context.Background(), f.matchID, planID, f.proposer, []string{f.proposerFriend}, 0); err != nil {
		t.Fatal(err)
	}
	// Proposer's friend and group mate hear about the proposal; the blocked
	// friend, the invitee's friend and the stranger do not. The invitee gets a
	// decision request on the match channel.
	if got := f.notifications(t, f.proposerFriend, "date_plan.proposed"); got != 1 {
		t.Fatalf("proposer friend proposed notifications=%d", got)
	}
	if got := f.notifications(t, f.groupMate, "date_plan.proposed"); got != 0 {
		t.Fatalf("group mate proposed notifications=%d", got)
	}
	for _, silent := range []string{f.blockedFriend, f.inviteeFriend, f.stranger} {
		if got := f.notifications(t, silent, "date_plan.proposed"); got != 0 {
			t.Fatalf("unexpected proposed notification for %s: %d", silent, got)
		}
	}
	if got := f.notifications(t, f.invitee, "date_plan.proposed"); got != 1 {
		t.Fatalf("invitee decision request=%d", got)
	}
	if got := f.feedRows(t, f.proposerFriend, "date_plan_proposed"); got != 1 {
		t.Fatalf("proposer friend feed rows=%d", got)
	}

	// Only one open plan per match.
	duplicate := httptest.NewRecorder()
	server.proposeMatchDatePlan(duplicate, datePlanRequest(http.MethodPost, "/plans", f.matchID, "", f.invitee, body))
	if duplicate.Code != http.StatusConflict {
		t.Fatalf("duplicate propose status=%d body=%s", duplicate.Code, duplicate.Body.String())
	}

	// The proposer cannot accept their own proposal.
	selfAccept := httptest.NewRecorder()
	server.decideMatchDatePlan(selfAccept, datePlanRequest(http.MethodPost, "/decision", f.matchID, planID, f.proposer, `{"decision":"accept"}`))
	if selfAccept.Code != http.StatusForbidden {
		t.Fatalf("self accept status=%d body=%s", selfAccept.Code, selfAccept.Body.String())
	}

	accepted := httptest.NewRecorder()
	server.decideMatchDatePlan(accepted, datePlanRequest(http.MethodPost, "/decision", f.matchID, planID, f.invitee, `{"decision":"accept"}`))
	if accepted.Code != http.StatusOK {
		t.Fatalf("accept status=%d body=%s", accepted.Code, accepted.Body.String())
	}
	if toString(decodePlan(t, accepted)["status"]) != "accepted" {
		t.Fatalf("accepted plan = %s", accepted.Body.String())
	}
	if err := svc.updateSharing(context.Background(), f.matchID, planID, f.invitee, []string{f.inviteeFriend}, 0); err != nil {
		t.Fatal(err)
	}
	// Both explicitly selected contacts hear about the accepted plan.
	if got := f.notifications(t, f.proposerFriend, "date_plan.accepted"); got != 1 {
		t.Fatalf("proposer friend accepted notifications=%d", got)
	}
	if got := f.notifications(t, f.inviteeFriend, "date_plan.accepted"); got != 1 {
		t.Fatalf("invitee friend accepted notifications=%d", got)
	}
	if got := f.notifications(t, f.proposer, "date_plan.accepted"); got != 1 {
		t.Fatalf("proposer told about acceptance=%d", got)
	}

	// Replaying the accept is rejected as stale, and never re-notifies.
	replay := httptest.NewRecorder()
	server.decideMatchDatePlan(replay, datePlanRequest(http.MethodPost, "/decision", f.matchID, planID, f.invitee, `{"decision":"accept"}`))
	if replay.Code != http.StatusConflict {
		t.Fatalf("replay accept status=%d body=%s", replay.Code, replay.Body.String())
	}
	if got := f.notifications(t, f.proposerFriend, "date_plan.accepted"); got != 1 {
		t.Fatalf("replay re-notified friends: %d", got)
	}

	// Check-in: the invitee says safe; only the invitee's friend hears it.
	checkin := httptest.NewRecorder()
	server.checkinMatchDatePlan(checkin, datePlanRequest(http.MethodPost, "/checkin", f.matchID, planID, f.invitee, `{"status":"safe"}`))
	if checkin.Code != http.StatusOK {
		t.Fatalf("checkin status=%d body=%s", checkin.Code, checkin.Body.String())
	}
	if got := f.notifications(t, f.inviteeFriend, "date_plan.safe"); got != 1 {
		t.Fatalf("invitee friend safe notifications=%d", got)
	}
	if got := f.notifications(t, f.proposerFriend, "date_plan.safe"); got != 0 {
		t.Fatalf("proposer friend heard the invitee's check-in: %d", got)
	}
	checkinPlan := decodePlan(t, checkin)
	if toString(checkinPlan["next_action"]) != "debrief" {
		t.Fatalf("after check-in next_action=%v", checkinPlan["next_action"])
	}

	// Need-help from the proposer reaches the proposer's friend and group as a
	// safety notification.
	help := httptest.NewRecorder()
	server.checkinMatchDatePlan(help, datePlanRequest(http.MethodPost, "/checkin", f.matchID, planID, f.proposer, `{"status":"need_help","note":"Call me"}`))
	if help.Code != http.StatusOK {
		t.Fatalf("need_help status=%d body=%s", help.Code, help.Body.String())
	}
	var category string
	var priority int
	if err := f.db.QueryRow(`SELECT category, priority FROM matching.notification_outbox
		WHERE recipient_user_id=$1 AND event_type='date_plan.need_help'`, f.proposerFriend).Scan(&category, &priority); err != nil {
		t.Fatalf("group mate need_help notification: %v", err)
	}
	if category != "safety" || priority != 9 {
		t.Fatalf("need_help category=%s priority=%d", category, priority)
	}

	// The friends' plan feed shows the plan to the proposer's friend with only
	// the proposer's check-in.
	feed := httptest.NewRecorder()
	server.listFriendDatePlans(feed, datePlanRequest(http.MethodGet, "/friends/plans", "", "", f.proposerFriend, ""))
	if feed.Code != http.StatusOK {
		t.Fatalf("friend plans status=%d body=%s", feed.Code, feed.Body.String())
	}
	var feedBody struct {
		Plans []friendPlanView `json:"plans"`
	}
	if err := json.Unmarshal(feed.Body.Bytes(), &feedBody); err != nil {
		t.Fatal(err)
	}
	if len(feedBody.Plans) != 1 || feedBody.Plans[0].PlanID != planID {
		t.Fatalf("friend plans = %+v", feedBody.Plans)
	}
	if len(feedBody.Plans[0].Checkins) != 1 || feedBody.Plans[0].Checkins[0].UserID != f.proposer {
		t.Fatalf("friend sees wrong check-ins: %+v", feedBody.Plans[0].Checkins)
	}

	// The match view returns the open plan and history to a member only.
	view := httptest.NewRecorder()
	server.getMatchDatePlans(view, datePlanRequest(http.MethodGet, "/plans", f.matchID, "", f.invitee, ""))
	if view.Code != http.StatusOK {
		t.Fatalf("match plans status=%d body=%s", view.Code, view.Body.String())
	}
	if decodePlan(t, view) == nil {
		t.Fatalf("open plan missing: %s", view.Body.String())
	}
	strangerView := httptest.NewRecorder()
	server.getMatchDatePlans(strangerView, datePlanRequest(http.MethodGet, "/plans", f.matchID, "", f.stranger, ""))
	if strangerView.Code != http.StatusForbidden {
		t.Fatalf("stranger view status=%d", strangerView.Code)
	}

	// Cancel: both circles are told, and the plan is no longer open.
	cancel := httptest.NewRecorder()
	server.cancelMatchDatePlan(cancel, datePlanRequest(http.MethodPost, "/cancel", f.matchID, planID, f.proposer, `{"reason":"Rain check"}`))
	if cancel.Code != http.StatusOK {
		t.Fatalf("cancel status=%d body=%s", cancel.Code, cancel.Body.String())
	}
	if got := f.notifications(t, f.inviteeFriend, "date_plan.cancelled"); got != 1 {
		t.Fatalf("invitee friend cancelled notifications=%d", got)
	}
	var events int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.match_date_plan_events WHERE plan_id=$1`, planID).Scan(&events); err != nil {
		t.Fatal(err)
	}
	if events < 5 {
		t.Fatalf("plan history events=%d, want proposed/accepted/checkins/cancelled", events)
	}
	var domainEvents int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM platform.domain_event_outbox
		WHERE aggregate_type='date_plan' AND aggregate_id=$1 AND producer='mobile-bff.date-plans'`, planID).Scan(&domainEvents); err != nil {
		t.Fatal(err)
	}
	if domainEvents < 4 {
		t.Fatalf("domain events=%d", domainEvents)
	}
}

// TestDatePlanSweepRemindsAndEscalatesPostgres covers the safety net: a member
// who does not check in is reminded an hour after the window and their
// friends are told two hours later. Unanswered proposals expire.
func TestDatePlanSweepRemindsAndEscalatesPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	svc := newDatePlanService(f.db)
	ctx := context.Background()
	// Bypass the future-window guard by inserting the plan directly with a
	// window that closed four hours ago, then run the sweep at "now".
	planID := uuid.NewString()
	if _, err := f.db.ExecContext(ctx, `
		ALTER TABLE matching.match_date_plans DISABLE TRIGGER trg_validate_match_date_plan`); err != nil {
		t.Fatalf("disable trigger: %v", err)
	}
	_, err := f.db.ExecContext(ctx, `
		INSERT INTO matching.match_date_plans(
		  id, match_id, proposer_user_id, invitee_user_id, status, window_start, window_end,
		  venue_category, checkin_due_at, decided_at
		) VALUES ($1,$2,$3,$4,'accepted', NOW()-INTERVAL '6 hours', NOW()-INTERVAL '4 hours',
		          'meal', NOW()-INTERVAL '3 hours', NOW()-INTERVAL '5 hours')`,
		planID, f.matchID, f.proposer, f.invitee)
	_, _ = f.db.ExecContext(ctx, `ALTER TABLE matching.match_date_plans ENABLE TRIGGER trg_validate_match_date_plan`)
	if err != nil {
		t.Fatalf("seed accepted plan: %v", err)
	}
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.match_date_plans WHERE id=$1`, planID) })
	if _, err := f.db.ExecContext(ctx, `INSERT INTO matching.match_date_plan_participants(plan_id, user_id)
		VALUES ($1,$2),($1,$3)`, planID, f.proposer, f.invitee); err != nil {
		t.Fatalf("seed participants: %v", err)
	}
	if err := svc.updateSharing(ctx, f.matchID, planID, f.proposer, []string{f.proposerFriend}, 0); err != nil {
		t.Fatal(err)
	}
	if err := svc.updateSharing(ctx, f.matchID, planID, f.invitee, []string{f.inviteeFriend}, 0); err != nil {
		t.Fatal(err)
	}
	// An unanswered proposal whose window closed.
	staleID := uuid.NewString()
	staleMatch := uuid.NewString()
	first, second := f.proposerFriend, f.inviteeFriend
	if first > second {
		first, second = second, first
	}
	if _, err := f.db.ExecContext(ctx, `INSERT INTO matching.matches (id, user_id_1, user_id_2) VALUES ($1,$2,$3)`,
		staleMatch, first, second); err != nil {
		t.Fatalf("seed stale match: %v", err)
	}
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.matches WHERE id=$1`, staleMatch) })
	_, _ = f.db.ExecContext(ctx, `ALTER TABLE matching.match_date_plans DISABLE TRIGGER trg_validate_match_date_plan`)
	_, err = f.db.ExecContext(ctx, `
		INSERT INTO matching.match_date_plans(
		  id, match_id, proposer_user_id, invitee_user_id, status, window_start, window_end,
		  venue_category, checkin_due_at
		) VALUES ($1,$2,$3,$4,'proposed', NOW()-INTERVAL '3 hours', NOW()-INTERVAL '1 hour', 'walk', NOW())`,
		staleID, staleMatch, f.proposerFriend, f.inviteeFriend)
	_, _ = f.db.ExecContext(ctx, `ALTER TABLE matching.match_date_plans ENABLE TRIGGER trg_validate_match_date_plan`)
	if err != nil {
		t.Fatalf("seed stale proposal: %v", err)
	}

	expired, reminders, escalations, err := svc.sweep(ctx)
	if err != nil {
		t.Fatalf("sweep: %v", err)
	}
	if expired < 1 || reminders < 2 || escalations < 2 {
		t.Fatalf("sweep expired=%d reminders=%d escalations=%d", expired, reminders, escalations)
	}
	if got := f.notifications(t, f.proposer, "date_plan.checkin_reminder"); got != 1 {
		t.Fatalf("proposer reminders=%d", got)
	}
	if got := f.notifications(t, f.proposerFriend, "date_plan.checkin_missed"); got != 1 {
		t.Fatalf("proposer friend escalations=%d", got)
	}
	if got := f.notifications(t, f.inviteeFriend, "date_plan.checkin_missed"); got != 1 {
		t.Fatalf("invitee friend escalations=%d", got)
	}
	var status string
	if err := f.db.QueryRow(`SELECT status FROM matching.match_date_plans WHERE id=$1`, staleID).Scan(&status); err != nil {
		t.Fatal(err)
	}
	if status != "expired" {
		t.Fatalf("stale proposal status=%s", status)
	}
	// A second sweep is a no-op for the same rows.
	expired2, reminders2, escalations2, err := svc.sweep(ctx)
	if err != nil {
		t.Fatalf("second sweep: %v", err)
	}
	if got := f.notifications(t, f.proposer, "date_plan.checkin_reminder"); got != 1 {
		t.Fatalf("second sweep re-reminded: %d (sweep=%d/%d/%d)", got, expired2, reminders2, escalations2)
	}
}

// seedAcceptedPlanInPast inserts an accepted plan whose window closed hours
// ago, bypassing the future-window guard, with participant rows for both.
func (f datePlanFixture) seedAcceptedPlanInPast(t *testing.T, matchID, proposer, invitee string, hoursAgo int) string {
	t.Helper()
	ctx := context.Background()
	planID := uuid.NewString()
	if _, err := f.db.ExecContext(ctx, `ALTER TABLE matching.match_date_plans DISABLE TRIGGER trg_validate_match_date_plan`); err != nil {
		t.Fatalf("disable trigger: %v", err)
	}
	_, err := f.db.ExecContext(ctx, `
		INSERT INTO matching.match_date_plans(
		  id, match_id, proposer_user_id, invitee_user_id, status, window_start, window_end,
		  venue_category, checkin_due_at, decided_at
		) VALUES ($1,$2,$3,$4,'accepted', NOW()-make_interval(hours => $5::int) - INTERVAL '2 hours',
		          NOW()-make_interval(hours => $5::int), 'coffee',
		          NOW()-make_interval(hours => $5::int) + INTERVAL '1 hour', NOW()-make_interval(hours => $5::int) - INTERVAL '3 hours')`,
		planID, matchID, proposer, invitee, hoursAgo)
	_, _ = f.db.ExecContext(ctx, `ALTER TABLE matching.match_date_plans ENABLE TRIGGER trg_validate_match_date_plan`)
	if err != nil {
		t.Fatalf("seed accepted plan: %v", err)
	}
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.match_date_plans WHERE id=$1`, planID) })
	if _, err := f.db.ExecContext(ctx, `INSERT INTO matching.match_date_plan_participants(plan_id, user_id)
		VALUES ($1,$2),($1,$3)`, planID, proposer, invitee); err != nil {
		t.Fatalf("seed participants: %v", err)
	}
	return planID
}

// TestDatePlanDebriefResolvesAndAwardsShowsUpPostgres covers migration 092:
// two mutually confirmed dates award "Shows up" to both members; a disputed
// date takes it away again; a "did not feel safe" answer leaves an audit row.
func TestDatePlanDebriefResolvesAndAwardsShowsUpPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.match_date_plan_debriefs') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 092_date_plan_debriefs_shows_up_badge is not applied")
	}
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	client, err := postgresdata.Open(context.Background(), dsn)
	if err != nil {
		t.Fatalf("open data client: %v", err)
	}
	t.Cleanup(client.Close)
	trust := newTrustRepository(config.Config{
		MatchingSchema: "matching", UserSchema: "user_management", UsersTable: "users",
	}, client)
	server := &Server{
		store:                  &runtimeStore{profileRepo: &profileRepository{pg: f.db}},
		trust:                  trust,
		datePlanUnlockOverride: func(string) (bool, string) { return true, "conversation_unlocked" },
	}

	debrief := func(planID, userID, body string) *httptest.ResponseRecorder {
		rec := httptest.NewRecorder()
		server.debriefMatchDatePlan(rec, datePlanRequest(http.MethodPost, "/debrief", f.matchID, planID, userID, body))
		return rec
	}

	// First confirmed date.
	first := f.seedAcceptedPlanInPast(t, f.matchID, f.proposer, f.invitee, 5)
	early := debrief(first, f.stranger, `{"happened":true}`)
	if early.Code != http.StatusForbidden {
		t.Fatalf("stranger debrief status=%d body=%s", early.Code, early.Body.String())
	}
	one := debrief(first, f.proposer, `{"happened":true,"would_meet_again":true,"felt_safe":true}`)
	if one.Code != http.StatusOK {
		t.Fatalf("first debrief status=%d body=%s", one.Code, one.Body.String())
	}
	plan := decodePlan(t, one)
	if toString(plan["status"]) != "accepted" || plan["resolved_status"] != nil {
		t.Fatalf("plan resolved after one answer: %v", plan)
	}
	if toString(plan["next_action"]) != "checkin" {
		// Check-in comes before the debrief in the suggested order, but the
		// debrief itself is never gated on it.
		t.Fatalf("next_action after own debrief without check-in = %v", plan["next_action"])
	}
	two := debrief(first, f.invitee, `{"happened":true,"felt_safe":false,"note":"Fine but pushy"}`)
	if two.Code != http.StatusOK {
		t.Fatalf("second debrief status=%d body=%s", two.Code, two.Body.String())
	}
	plan = decodePlan(t, two)
	if toString(plan["status"]) != "completed" || toString(plan["resolved_status"]) != "completed" {
		t.Fatalf("plan not completed after both answers: %v", plan)
	}
	// The invitee sees their own answers, not the proposer's.
	own, _ := plan["debrief"].(map[string]any)
	if own == nil || toString(own["note"]) != "Fine but pushy" || plan["partner_debriefed"] != true {
		t.Fatalf("debrief visibility = %v", plan)
	}
	// Both circles hear the date happened.
	if got := f.notifications(t, f.proposerFriend, "date_plan.completed"); got != 0 {
		t.Fatalf("proposer friend completed notifications=%d", got)
	}
	if got := f.notifications(t, f.inviteeFriend, "date_plan.completed"); got != 0 {
		t.Fatalf("invitee friend completed notifications=%d", got)
	}
	// "Did not feel safe" is recorded for trust and safety about the partner.
	var unsafeEvents int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM audit.security_events
		WHERE event_type='date_plan.felt_unsafe' AND actor_user_id=$1 AND subject_user_id=$2`, f.invitee, f.proposer).Scan(&unsafeEvents); err != nil {
		t.Fatalf("security events: %v", err)
	}
	if unsafeEvents != 1 {
		t.Fatalf("felt_unsafe security events=%d", unsafeEvents)
	}
	// Answers are final once resolved.
	late := debrief(first, f.invitee, `{"happened":false}`)
	if late.Code != http.StatusConflict {
		t.Fatalf("post-resolution debrief status=%d body=%s", late.Code, late.Body.String())
	}

	// One confirmed date is not enough for the badge.
	_, badges, err := trust.recomputeUserTrustBadges(context.Background(), f.proposer)
	if err != nil {
		t.Fatalf("recompute after one date: %v", err)
	}
	if status := badgeStatus(badges, trustBadgeShowsUp); status == "active" {
		t.Fatalf("shows_up active after a single date: %v", badges)
	}

	// Second confirmed date awards it to both members.
	second := f.seedAcceptedPlanInPast(t, f.matchID, f.invitee, f.proposer, 3)
	if rec := debrief(second, f.proposer, `{"happened":true}`); rec.Code != http.StatusOK {
		t.Fatalf("second plan proposer debrief: %d %s", rec.Code, rec.Body.String())
	}
	if rec := debrief(second, f.invitee, `{"happened":true}`); rec.Code != http.StatusOK {
		t.Fatalf("second plan invitee debrief: %d %s", rec.Code, rec.Body.String())
	}
	for _, member := range []string{f.proposer, f.invitee} {
		_, badges, err = trust.recomputeUserTrustBadges(context.Background(), member)
		if err != nil {
			t.Fatalf("recompute: %v", err)
		}
		if status := badgeStatus(badges, trustBadgeShowsUp); status != "active" {
			t.Fatalf("shows_up for %s = %q after two confirmed dates: %v", member, status, badges)
		}
	}

	// A disputed date holds the badge back.
	third := f.seedAcceptedPlanInPast(t, f.matchID, f.proposer, f.invitee, 1)
	if rec := debrief(third, f.proposer, `{"happened":true}`); rec.Code != http.StatusOK {
		t.Fatalf("third plan proposer debrief: %d %s", rec.Code, rec.Body.String())
	}
	disputed := debrief(third, f.invitee, `{"happened":false}`)
	if disputed.Code != http.StatusOK || toString(decodePlan(t, disputed)["status"]) != "disputed" {
		t.Fatalf("disputed resolution: %d %s", disputed.Code, disputed.Body.String())
	}
	if got := f.notifications(t, f.proposerFriend, "date_plan.disputed"); got != 0 {
		t.Fatalf("disputes must stay private, friend notifications=%d", got)
	}
	_, badges, err = trust.recomputeUserTrustBadges(context.Background(), f.proposer)
	if err != nil {
		t.Fatalf("recompute after dispute: %v", err)
	}
	if status := badgeStatus(badges, trustBadgeShowsUp); status != "revoked" {
		t.Fatalf("shows_up after a dispute = %q: %v", status, badges)
	}
}

func badgeStatus(badges []trustBadge, code string) string {
	for _, b := range badges {
		if b.BadgeCode == code {
			return b.Status
		}
	}
	return ""
}

// deleteTestMember removes a seeded member and the outbox rows whose cascade
// would otherwise trip platform.capture_pruned_replay_cursor and leave the
// user behind.
func deleteTestMember(ctx context.Context, db *sql.DB, id string) {
	for _, stmt := range []string{
		`DELETE FROM matching.notification_outbox WHERE recipient_user_id=$1 OR actor_user_id=$1`,
		`DELETE FROM matching.realtime_outbox WHERE recipient_user_id=$1`,
		`DELETE FROM platform.replay_cursor_checkpoints WHERE recipient_user_id=$1`,
		`DELETE FROM matching.friend_activity_feed WHERE user_id=$1 OR friend_user_id=$1`,
		`DELETE FROM user_management.users WHERE id=$1`,
	} {
		_, _ = db.ExecContext(ctx, stmt, id)
	}
}
