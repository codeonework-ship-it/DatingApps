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

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func TestGraduationValidation(t *testing.T) {
	if note, err := parseGraduationNote("  We are leaving together  "); err != nil || note != "We are leaving together" {
		t.Fatalf("note = %q, %v", note, err)
	}
	if note, err := parseGraduationNote(nil); err != nil || note != "" {
		t.Fatalf("nil note = %q, %v", note, err)
	}
	if _, err := parseGraduationNote(strings.Repeat("x", 201)); err == nil {
		t.Fatal("201-rune note accepted")
	}
	if d, err := parseGraduationDecision(" Confirm "); err != nil || d != "confirm" {
		t.Fatalf("decision = %q, %v", d, err)
	}
	if _, err := parseGraduationDecision("accept"); err == nil {
		t.Fatal("accept is not a graduation decision")
	}
	if reason, err := parseDiscoveryPauseReason(nil); err != nil || reason != "manual" {
		t.Fatalf("default reason = %q, %v", reason, err)
	}
	if _, err := parseDiscoveryPauseReason("graduated"); err == nil {
		t.Fatal("a member cannot write the graduated reason")
	}
}

func TestGraduationNextAction(t *testing.T) {
	cases := []struct{ status, role, want string }{
		{"proposed", "partner", "decide"},
		{"proposed", "proposer", "await_decision"},
		{"proposed", "observer", "none"},
		{"confirmed", "proposer", "celebrate"},
		{"confirmed", "partner", "celebrate"},
		{"declined", "proposer", "propose"},
		{"withdrawn", "partner", "propose"},
	}
	for _, c := range cases {
		if got := graduationNextAction(c.status, c.role); got != c.want {
			t.Errorf("%s/%s = %q, want %q", c.status, c.role, got, c.want)
		}
	}
}

func TestGraduationRoutesMapToFlag(t *testing.T) {
	for _, path := range []string{
		"/v1/matches/abc/graduation",
		"/v1/matches/abc/graduation/def/decision",
		"/v1/matches/abc/graduation/def/withdraw",
		"/v1/account/u1/discovery/pause",
		"/v1/account/u1/discovery/resume",
	} {
		if got := featureFlagForRoute("/v1", path); got != "graduation_enabled" {
			t.Errorf("%s → %q", path, got)
		}
	}
	if got := featureFlagForRoute("/v1", "/v1/account/u1/lifecycle"); got != "" {
		t.Errorf("account lifecycle must stay unflagged, got %q", got)
	}
	if got := featureFlagForRoute("/v1", "/v1/matches/abc/plans"); got != "date_plans_enabled" {
		t.Errorf("plans route changed: %q", got)
	}
}

func TestFilterPausedDiscoveryWithoutPersistenceIsANoOp(t *testing.T) {
	resp := map[string]any{"candidates": []any{map[string]any{"id": uuid.NewString()}}}
	if err := filterPausedDiscovery(context.Background(), nil, uuid.NewString(), resp); err != nil {
		t.Fatal(err)
	}
	if rows, _ := resp["candidates"].([]any); len(rows) != 1 {
		t.Fatalf("candidates = %v", resp["candidates"])
	}
	if _, paused := resp["discovery_paused"]; paused {
		t.Fatal("viewer marked paused without persistence")
	}
}

// ── Postgres lifecycle ───────────────────────────────────────────────────────

type graduationFixture struct {
	db                                      *sql.DB
	matchID                                 string
	proposer, partner                       string
	proposerFriend, partnerFriend, stranger string
}

func newGraduationFixture(t *testing.T) graduationFixture {
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
	if err := db.QueryRowContext(ctx, `SELECT to_regclass('matching.match_graduations') IS NOT NULL
		AND to_regclass('user_management.discovery_pauses') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 094_match_graduation is not applied")
	}
	f := graduationFixture{db: db}
	names := []string{"Priya", "Arjun", "Meera", "Dev", "Stranger"}
	ids := make([]string, len(names))
	for i, name := range names {
		id := uuid.NewString()
		username := "gradqa_" + strings.ReplaceAll(id[:8], "-", "")
		if _, err := db.ExecContext(ctx, `INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email)
			VALUES ($1,$2,$3,'1992-01-01','female',$4)`, id, username, name, username+"@example.test"); err != nil {
			t.Fatalf("seed member %s: %v", name, err)
		}
		ids[i] = id
	}
	t.Cleanup(func() {
		for _, id := range ids {
			// A member's outbox rows must go before the member: deleting them
			// records a replay checkpoint against the recipient, which the
			// cascade from users cannot satisfy. Pauses are keyed by member and
			// would otherwise outlive a failed member delete.
			_, _ = db.ExecContext(ctx, `DELETE FROM user_management.discovery_pauses WHERE user_id=$1`, id)
			_, _ = db.ExecContext(ctx, `DELETE FROM matching.notification_outbox WHERE recipient_user_id=$1`, id)
			_, _ = db.ExecContext(ctx, `DELETE FROM platform.replay_cursor_checkpoints WHERE recipient_user_id=$1`, id)
			_, _ = db.ExecContext(ctx, `DELETE FROM user_management.users WHERE id=$1`, id)
		}
	})
	f.proposer, f.partner, f.proposerFriend, f.partnerFriend, f.stranger = ids[0], ids[1], ids[2], ids[3], ids[4]
	f.matchID = uuid.NewString()
	if _, err := db.ExecContext(ctx, `INSERT INTO matching.matches (id, user_id_1, user_id_2)
		VALUES ($1, LEAST($2::uuid,$3::uuid), GREATEST($2::uuid,$3::uuid))`, f.matchID, f.proposer, f.partner); err != nil {
		t.Fatalf("seed match: %v", err)
	}
	t.Cleanup(func() { _, _ = db.ExecContext(ctx, `DELETE FROM matching.matches WHERE id=$1`, f.matchID) })
	for _, pair := range [][2]string{{f.proposer, f.proposerFriend}, {f.partner, f.partnerFriend}} {
		if _, err := db.ExecContext(ctx, `INSERT INTO matching.friend_connections (user_id, friend_user_id, status)
			VALUES ($1,$2,'accepted'),($2,$1,'accepted')`, pair[0], pair[1]); err != nil {
			t.Fatalf("seed friendship: %v", err)
		}
	}
	return f
}

func (f graduationFixture) server() *Server {
	return &Server{
		store:                  &runtimeStore{profileRepo: &profileRepository{pg: f.db}},
		datePlanUnlockOverride: func(string) (bool, string) { return true, "conversation_unlocked" },
	}
}

func (f graduationFixture) notifications(t *testing.T, recipient, eventType string) int {
	t.Helper()
	var n int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.notification_outbox
		WHERE recipient_user_id=$1 AND event_type=$2`, recipient, eventType).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

func (f graduationFixture) pause(t *testing.T, userID string) (reason string, active bool, found bool) {
	t.Helper()
	var resumed sql.NullTime
	err := f.db.QueryRow(`SELECT reason, resumed_at FROM user_management.discovery_pauses WHERE user_id=$1`, userID).
		Scan(&reason, &resumed)
	if err == sql.ErrNoRows {
		return "", false, false
	}
	if err != nil {
		t.Fatal(err)
	}
	return reason, !resumed.Valid, true
}

func graduationRequest(method, path, matchID, graduationID, userID, body string) *http.Request {
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	if body != "" {
		req.ContentLength = int64(len(body))
	}
	routeContext := chi.NewRouteContext()
	if matchID != "" {
		routeContext.URLParams.Add("matchID", matchID)
	}
	if graduationID != "" {
		routeContext.URLParams.Add("graduationID", graduationID)
	}
	routeContext.URLParams.Add("userID", userID)
	ctx := context.WithValue(req.Context(), chi.RouteCtxKey, routeContext)
	ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{
		UserID: userID, Roles: map[string]bool{"user": true},
	})
	return req.WithContext(ctx)
}

func decodeGraduation(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode: %v (%s)", err, rec.Body.String())
	}
	g, _ := body["graduation"].(map[string]any)
	return g
}

func graduationDeckIDs(resp map[string]any) []string {
	rows, _ := resp["candidates"].([]any)
	out := []string{}
	for _, raw := range rows {
		row, _ := raw.(map[string]any)
		out = append(out, candidateIdentity(row))
	}
	return out
}

// TestGraduationConfirmHidesBothAndTellsOptedInFriendsPostgres covers the
// core rule: a confirmed graduation marks the match graduated without
// unmatching it, pauses both members from discovery, tells only the friends
// of members who opted in, records pending rewards, and resume undoes the
// pause.
func TestGraduationConfirmHidesBothAndTellsOptedInFriendsPostgres(t *testing.T) {
	f := newGraduationFixture(t)
	server := f.server()
	ctx := context.Background()

	// A stranger cannot propose on someone else's match.
	forbidden := httptest.NewRecorder()
	server.proposeMatchGraduation(forbidden, graduationRequest(http.MethodPost, "/graduation", f.matchID, "", f.stranger, `{"note":"hi"}`))
	if forbidden.Code != http.StatusForbidden {
		t.Fatalf("stranger propose status=%d body=%s", forbidden.Code, forbidden.Body.String())
	}
	long := httptest.NewRecorder()
	server.proposeMatchGraduation(long, graduationRequest(http.MethodPost, "/graduation", f.matchID, "", f.proposer,
		`{"note":"`+strings.Repeat("x", 201)+`"}`))
	if long.Code != http.StatusBadRequest {
		t.Fatalf("long note status=%d", long.Code)
	}

	proposed := httptest.NewRecorder()
	server.proposeMatchGraduation(proposed, graduationRequest(http.MethodPost, "/graduation", f.matchID, "", f.proposer,
		`{"note":"Let us leave together","share_with_friends":true}`))
	if proposed.Code != http.StatusCreated {
		t.Fatalf("propose status=%d body=%s", proposed.Code, proposed.Body.String())
	}
	g := decodeGraduation(t, proposed)
	graduationID := toString(g["id"])
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.match_graduations WHERE match_id=$1`, f.matchID) })
	if toString(g["status"]) != "proposed" || toString(g["next_action"]) != "await_decision" || g["share_with_friends"] != true {
		t.Fatalf("proposed graduation = %v", g)
	}
	if got := f.notifications(t, f.partner, "graduation.proposed"); got != 1 {
		t.Fatalf("partner decision request=%d", got)
	}
	if got := f.notifications(t, f.proposerFriend, "graduation.proposed"); got != 0 {
		t.Fatalf("friends told about a proposal: %d", got)
	}

	// One open proposal per match.
	duplicate := httptest.NewRecorder()
	server.proposeMatchGraduation(duplicate, graduationRequest(http.MethodPost, "/graduation", f.matchID, "", f.partner, `{}`))
	if duplicate.Code != http.StatusConflict {
		t.Fatalf("duplicate propose status=%d body=%s", duplicate.Code, duplicate.Body.String())
	}

	// The partner sees a decision to make; the proposer cannot confirm.
	view := httptest.NewRecorder()
	server.getMatchGraduation(view, graduationRequest(http.MethodGet, "/graduation", f.matchID, "", f.partner, ""))
	if view.Code != http.StatusOK {
		t.Fatalf("view status=%d body=%s", view.Code, view.Body.String())
	}
	if pv := decodeGraduation(t, view); toString(pv["next_action"]) != "decide" || toString(pv["other_name"]) != "Priya" {
		t.Fatalf("partner view = %v", pv)
	}
	strangerView := httptest.NewRecorder()
	server.getMatchGraduation(strangerView, graduationRequest(http.MethodGet, "/graduation", f.matchID, "", f.stranger, ""))
	if strangerView.Code != http.StatusForbidden {
		t.Fatalf("stranger view status=%d", strangerView.Code)
	}
	selfConfirm := httptest.NewRecorder()
	server.decideMatchGraduation(selfConfirm, graduationRequest(http.MethodPost, "/decision", f.matchID, graduationID, f.proposer, `{"decision":"confirm"}`))
	if selfConfirm.Code != http.StatusForbidden {
		t.Fatalf("self confirm status=%d body=%s", selfConfirm.Code, selfConfirm.Body.String())
	}

	// Partner confirms without sharing: only the proposer's friend is told.
	confirmed := httptest.NewRecorder()
	server.decideMatchGraduation(confirmed, graduationRequest(http.MethodPost, "/decision", f.matchID, graduationID, f.partner,
		`{"decision":"confirm","share_with_friends":false}`))
	if confirmed.Code != http.StatusOK {
		t.Fatalf("confirm status=%d body=%s", confirmed.Code, confirmed.Body.String())
	}
	cg := decodeGraduation(t, confirmed)
	if toString(cg["status"]) != "confirmed" || toString(cg["next_action"]) != "celebrate" {
		t.Fatalf("confirmed graduation = %v", cg)
	}
	if rewards, _ := cg["rewards"].([]any); len(rewards) != 2 {
		t.Fatalf("rewards = %v", cg["rewards"])
	}
	// The match is graduated, not unmatched.
	var endedReason sql.NullString
	var unmatched sql.NullTime
	var s1, s2 string
	if err := f.db.QueryRow(`SELECT ended_reason, unmatched_at, user_1_status, user_2_status FROM matching.matches WHERE id=$1`, f.matchID).
		Scan(&endedReason, &unmatched, &s1, &s2); err != nil {
		t.Fatal(err)
	}
	if endedReason.String != "graduated" || unmatched.Valid || s1 != "active" || s2 != "active" {
		t.Fatalf("match after graduation: reason=%v unmatched=%v statuses=%s/%s", endedReason, unmatched, s1, s2)
	}
	// Both members are paused from discovery.
	for _, member := range []string{f.proposer, f.partner} {
		reason, active, found := f.pause(t, member)
		if !found || !active || reason != "graduated" {
			t.Fatalf("pause for %s: found=%v active=%v reason=%s", member, found, active, reason)
		}
	}
	// Friends: proposer opted in, partner did not.
	if got := f.notifications(t, f.proposerFriend, "graduation.confirmed"); got != 1 {
		t.Fatalf("proposer friend confirmed notifications=%d", got)
	}
	if got := f.notifications(t, f.partnerFriend, "graduation.confirmed"); got != 0 {
		t.Fatalf("partner friend told without consent: %d", got)
	}
	if got := f.notifications(t, f.stranger, "graduation.confirmed"); got != 0 {
		t.Fatalf("stranger told: %d", got)
	}
	var category, title string
	if err := f.db.QueryRow(`SELECT category, title FROM matching.notification_outbox
		WHERE recipient_user_id=$1 AND event_type='graduation.confirmed'`, f.proposerFriend).Scan(&category, &title); err != nil {
		t.Fatal(err)
	}
	if category != "friend_plan" || title != "Priya found someone on Connect" {
		t.Fatalf("friend notification category=%s title=%q", category, title)
	}
	var feedRows int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.friend_activity_feed
		WHERE user_id=$1 AND activity_type='graduation_confirmed'`, f.proposerFriend).Scan(&feedRows); err != nil {
		t.Fatal(err)
	}
	if feedRows != 1 {
		t.Fatalf("friend feed rows=%d", feedRows)
	}
	// The proposer is told the partner said yes.
	if got := f.notifications(t, f.proposer, "graduation.confirmed"); got != 1 {
		t.Fatalf("proposer told about confirmation=%d", got)
	}
	// Rewards are pending for both members; nothing is invented in billing.
	var pending int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.graduation_rewards
		WHERE graduation_id=$1 AND status='pending' AND kind='referral_credit'`, graduationID).Scan(&pending); err != nil {
		t.Fatal(err)
	}
	if pending != 2 {
		t.Fatalf("pending referral_credit rewards=%d", pending)
	}
	// Domain events and audit rows were written in the same transaction.
	var domainEvents, securityEvents int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM platform.domain_event_outbox
		WHERE aggregate_type='graduation' AND aggregate_id=$1 AND producer='mobile-bff.graduation'`, graduationID).Scan(&domainEvents); err != nil {
		t.Fatal(err)
	}
	if domainEvents != 2 {
		t.Fatalf("domain events=%d, want proposed+confirmed", domainEvents)
	}
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM audit.security_events
		WHERE resource_type='graduation' AND resource_id=$1`, graduationID).Scan(&securityEvents); err != nil {
		t.Fatal(err)
	}
	if securityEvents != 2 {
		t.Fatalf("security events=%d", securityEvents)
	}

	// Discovery: a third member no longer sees either of them.
	deck := map[string]any{"candidates": []any{
		map[string]any{"id": f.proposer}, map[string]any{"id": f.partner}, map[string]any{"id": f.proposerFriend},
	}}
	if err := filterPausedDiscovery(ctx, f.db, f.stranger, deck); err != nil {
		t.Fatal(err)
	}
	if ids := graduationDeckIDs(deck); len(ids) != 1 || ids[0] != f.proposerFriend {
		t.Fatalf("stranger deck after graduation = %v", ids)
	}
	// A graduated member's own deck is empty and explained.
	own := map[string]any{"candidates": []any{map[string]any{"id": f.stranger}}}
	if err := filterPausedDiscovery(ctx, f.db, f.proposer, own); err != nil {
		t.Fatal(err)
	}
	pausedInfo, _ := own["discovery_paused"].(map[string]any)
	if len(graduationDeckIDs(own)) != 0 || toString(pausedInfo["reason"]) != "graduated" {
		t.Fatalf("graduated member's deck = %v", own)
	}
	// The same filter runs on the discovery endpoint response path.
	endpoint := map[string]any{"candidates": []any{map[string]any{"id": f.partner}, map[string]any{"id": f.stranger}}}
	server.attachPausedFilteredDiscovery(ctx, endpoint, f.proposerFriend)
	if ids := graduationDeckIDs(endpoint); len(ids) != 1 || ids[0] != f.stranger {
		t.Fatalf("endpoint deck = %v (%v)", ids, endpoint["pause_filter"])
	}

	// Replaying the confirmation is stale, and nobody is re-notified.
	replay := httptest.NewRecorder()
	server.decideMatchGraduation(replay, graduationRequest(http.MethodPost, "/decision", f.matchID, graduationID, f.partner, `{"decision":"confirm"}`))
	if replay.Code != http.StatusConflict {
		t.Fatalf("replay confirm status=%d body=%s", replay.Code, replay.Body.String())
	}
	if got := f.notifications(t, f.proposerFriend, "graduation.confirmed"); got != 1 {
		t.Fatalf("replay re-notified friends: %d", got)
	}
	// A graduated match cannot be proposed on again.
	again := httptest.NewRecorder()
	server.proposeMatchGraduation(again, graduationRequest(http.MethodPost, "/graduation", f.matchID, "", f.proposer, `{}`))
	if again.Code != http.StatusConflict || !strings.Contains(again.Body.String(), "GRADUATION_ALREADY_CONFIRMED") {
		t.Fatalf("propose after graduation status=%d body=%s", again.Code, again.Body.String())
	}
	after := httptest.NewRecorder()
	server.getMatchGraduation(after, graduationRequest(http.MethodGet, "/graduation", f.matchID, "", f.proposer, ""))
	var afterBody map[string]any
	_ = json.Unmarshal(after.Body.Bytes(), &afterBody)
	if afterBody["graduated"] != true || afterBody["can_propose"] != false || afterBody["discovery_paused"] != true {
		t.Fatalf("view after graduation = %v", afterBody)
	}

	// Resume: the proposer returns to discovery; the partner stays paused.
	state := httptest.NewRecorder()
	server.getDiscoveryPause(state, graduationRequest(http.MethodGet, "/discovery/pause", "", "", f.proposer, ""))
	if state.Code != http.StatusOK || !strings.Contains(state.Body.String(), `"paused":true`) {
		t.Fatalf("pause state status=%d body=%s", state.Code, state.Body.String())
	}
	resumed := httptest.NewRecorder()
	server.resumeDiscovery(resumed, graduationRequest(http.MethodPost, "/discovery/resume", "", "", f.proposer, ""))
	if resumed.Code != http.StatusOK || !strings.Contains(resumed.Body.String(), `"paused":false`) {
		t.Fatalf("resume status=%d body=%s", resumed.Code, resumed.Body.String())
	}
	if _, active, found := f.pause(t, f.proposer); !found || active {
		t.Fatalf("proposer pause after resume: found=%v active=%v", found, active)
	}
	if _, active, _ := f.pause(t, f.partner); !active {
		t.Fatal("partner pause cleared by the proposer's resume")
	}
	deck = map[string]any{"candidates": []any{map[string]any{"id": f.proposer}, map[string]any{"id": f.partner}}}
	if err := filterPausedDiscovery(ctx, f.db, f.stranger, deck); err != nil {
		t.Fatal(err)
	}
	if ids := graduationDeckIDs(deck); len(ids) != 1 || ids[0] != f.proposer {
		t.Fatalf("deck after resume = %v", ids)
	}
	resumeAgain := httptest.NewRecorder()
	server.resumeDiscovery(resumeAgain, graduationRequest(http.MethodPost, "/discovery/resume", "", "", f.proposer, ""))
	if resumeAgain.Code != http.StatusNotFound {
		t.Fatalf("second resume status=%d", resumeAgain.Code)
	}

	// Manual pause and resume.
	manual := httptest.NewRecorder()
	server.pauseDiscovery(manual, graduationRequest(http.MethodPost, "/discovery/pause", "", "", f.proposer, `{"reason":"manual"}`))
	if manual.Code != http.StatusOK {
		t.Fatalf("manual pause status=%d body=%s", manual.Code, manual.Body.String())
	}
	if reason, active, _ := f.pause(t, f.proposer); !active || reason != "manual" {
		t.Fatalf("manual pause reason=%s active=%v", reason, active)
	}
	badReason := httptest.NewRecorder()
	server.pauseDiscovery(badReason, graduationRequest(http.MethodPost, "/discovery/pause", "", "", f.proposer, `{"reason":"graduated"}`))
	if badReason.Code != http.StatusBadRequest {
		t.Fatalf("graduated reason from a member status=%d", badReason.Code)
	}
	emptyBody := httptest.NewRecorder()
	server.pauseDiscovery(emptyBody, graduationRequest(http.MethodPost, "/discovery/pause", "", "", f.partnerFriend, ""))
	if emptyBody.Code != http.StatusOK {
		t.Fatalf("pause without body status=%d body=%s", emptyBody.Code, emptyBody.Body.String())
	}
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM user_management.discovery_pauses WHERE user_id=$1`, f.partnerFriend)
	})
}

// TestGraduationDeclineAndWithdrawPostgres covers the negative paths: a
// declined proposal changes nothing, a withdrawn one likewise, and a new
// proposal can follow either.
func TestGraduationDeclineAndWithdrawPostgres(t *testing.T) {
	f := newGraduationFixture(t)
	server := f.server()
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.match_graduations WHERE match_id=$1`, f.matchID) })

	proposed := httptest.NewRecorder()
	server.proposeMatchGraduation(proposed, graduationRequest(http.MethodPost, "/graduation", f.matchID, "", f.partner, `{"share_with_friends":true}`))
	if proposed.Code != http.StatusCreated {
		t.Fatalf("propose status=%d body=%s", proposed.Code, proposed.Body.String())
	}
	firstID := toString(decodeGraduation(t, proposed)["id"])

	declined := httptest.NewRecorder()
	server.decideMatchGraduation(declined, graduationRequest(http.MethodPost, "/decision", f.matchID, firstID, f.proposer, `{"decision":"decline","share_with_friends":true}`))
	if declined.Code != http.StatusOK {
		t.Fatalf("decline status=%d body=%s", declined.Code, declined.Body.String())
	}
	if dg := decodeGraduation(t, declined); toString(dg["status"]) != "declined" || toString(dg["next_action"]) != "propose" {
		t.Fatalf("declined graduation = %v", dg)
	}
	if got := f.notifications(t, f.partner, "graduation.declined"); got != 1 {
		t.Fatalf("proposer told about decline=%d", got)
	}
	for _, member := range []string{f.proposer, f.partner} {
		if _, _, found := f.pause(t, member); found {
			t.Fatalf("decline paused %s", member)
		}
	}
	for _, friend := range []string{f.proposerFriend, f.partnerFriend} {
		if got := f.notifications(t, friend, "graduation.confirmed"); got != 0 {
			t.Fatalf("decline told friends: %d", got)
		}
	}
	var endedReason sql.NullString
	if err := f.db.QueryRow(`SELECT ended_reason FROM matching.matches WHERE id=$1`, f.matchID).Scan(&endedReason); err != nil {
		t.Fatal(err)
	}
	if endedReason.Valid {
		t.Fatalf("decline ended the match: %s", endedReason.String)
	}

	// A new proposal follows the decline; the other member cannot withdraw it.
	second := httptest.NewRecorder()
	server.proposeMatchGraduation(second, graduationRequest(http.MethodPost, "/graduation", f.matchID, "", f.proposer, `{"note":"Sure?"}`))
	if second.Code != http.StatusCreated {
		t.Fatalf("second propose status=%d body=%s", second.Code, second.Body.String())
	}
	secondID := toString(decodeGraduation(t, second)["id"])
	notProposer := httptest.NewRecorder()
	server.withdrawMatchGraduation(notProposer, graduationRequest(http.MethodPost, "/withdraw", f.matchID, secondID, f.partner, ""))
	if notProposer.Code != http.StatusForbidden {
		t.Fatalf("partner withdraw status=%d", notProposer.Code)
	}
	strangerWithdraw := httptest.NewRecorder()
	server.withdrawMatchGraduation(strangerWithdraw, graduationRequest(http.MethodPost, "/withdraw", f.matchID, secondID, f.stranger, ""))
	if strangerWithdraw.Code != http.StatusForbidden {
		t.Fatalf("stranger withdraw status=%d", strangerWithdraw.Code)
	}
	withdrawn := httptest.NewRecorder()
	server.withdrawMatchGraduation(withdrawn, graduationRequest(http.MethodPost, "/withdraw", f.matchID, secondID, f.proposer, ""))
	if withdrawn.Code != http.StatusOK || toString(decodeGraduation(t, withdrawn)["status"]) != "withdrawn" {
		t.Fatalf("withdraw status=%d body=%s", withdrawn.Code, withdrawn.Body.String())
	}
	if got := f.notifications(t, f.partner, "graduation.withdrawn"); got != 1 {
		t.Fatalf("partner told about withdrawal=%d", got)
	}
	stale := httptest.NewRecorder()
	server.withdrawMatchGraduation(stale, graduationRequest(http.MethodPost, "/withdraw", f.matchID, secondID, f.proposer, ""))
	if stale.Code != http.StatusConflict {
		t.Fatalf("second withdraw status=%d", stale.Code)
	}
	lateDecision := httptest.NewRecorder()
	server.decideMatchGraduation(lateDecision, graduationRequest(http.MethodPost, "/decision", f.matchID, secondID, f.partner, `{"decision":"confirm"}`))
	if lateDecision.Code != http.StatusConflict {
		t.Fatalf("decision on withdrawn proposal status=%d", lateDecision.Code)
	}

	view := httptest.NewRecorder()
	server.getMatchGraduation(view, graduationRequest(http.MethodGet, "/graduation", f.matchID, "", f.proposer, ""))
	var body map[string]any
	if err := json.Unmarshal(view.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if body["graduation"] != nil || body["can_propose"] != true || body["graduated"] != false {
		t.Fatalf("view after withdraw = %v", body)
	}
	if history, _ := body["history"].([]any); len(history) != 2 {
		t.Fatalf("history = %v", body["history"])
	}
}
