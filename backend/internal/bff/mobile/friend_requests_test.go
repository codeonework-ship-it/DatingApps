package mobile

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
)

// friendCall runs one friends handler as user with chi params and returns
// the status and decoded body.
func friendCall(t *testing.T, s *Server, handler http.HandlerFunc, method, user, body string, params map[string]string, query url.Values) (int, map[string]any) {
	t.Helper()
	target := "/"
	if query != nil {
		target += "?" + query.Encode()
	}
	r := httptest.NewRequest(method, target, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	rc := chi.NewRouteContext()
	for k, v := range params {
		rc.URLParams.Add(k, v)
	}
	ctx := context.WithValue(r.Context(), chi.RouteCtxKey, rc)
	if user != "" {
		ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{UserID: user, Roles: map[string]bool{"user": true}})
	}
	w := httptest.NewRecorder()
	handler(w, r.WithContext(ctx))
	out := map[string]any{}
	_ = json.Unmarshal(w.Body.Bytes(), &out)
	return w.Code, out
}

func friendRequestPG(t *testing.T, s *Server, from, to, source string) (int, map[string]any) {
	t.Helper()
	body := `{"friend_user_id":"` + to + `","source":"` + source + `"}`
	return friendCall(t, s, s.addFriend, http.MethodPost, from, body, map[string]string{"userID": from}, nil)
}

func friendDecidePG(t *testing.T, s *Server, me, requester, decision string) (int, map[string]any) {
	t.Helper()
	return friendCall(t, s, s.decideFriendRequest, http.MethodPost, me, `{"decision":"`+decision+`"}`,
		map[string]string{"userID": me, "friendUserID": requester}, nil)
}

func friendRows(t *testing.T, f datePlanFixture, a, b string) map[string]string {
	t.Helper()
	rows, err := f.db.Query(`SELECT user_id::text,status||':'||COALESCE(source,'') FROM matching.friend_connections
		WHERE (user_id=$1 AND friend_user_id=$2) OR (user_id=$2 AND friend_user_id=$1)`, a, b)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	out := map[string]string{}
	for rows.Next() {
		var u, v string
		if err = rows.Scan(&u, &v); err != nil {
			t.Fatal(err)
		}
		out[u] = v
	}
	return out
}

func friendListPG(t *testing.T, s *Server, me string) map[string]map[string]any {
	t.Helper()
	code, body := friendCall(t, s, s.listFriends, http.MethodGet, me, "", map[string]string{"userID": me}, nil)
	if code != http.StatusOK {
		t.Fatalf("list friends: %d %v", code, body)
	}
	out := map[string]map[string]any{}
	for _, raw := range body["friends"].([]any) {
		row := raw.(map[string]any)
		out[row["friend_user_id"].(string)] = row
	}
	return out
}

func newFriendFixture(t *testing.T) (datePlanFixture, *Server) {
	t.Helper()
	f := newDatePlanFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.friend_request_declines') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 116_friend_requests is not applied")
	}
	return f, blogServer(f)
}

func TestFriendRequestNoDowngradeMutualAndNotificationsPostgres(t *testing.T) {
	f, s := newFriendFixture(t)

	// Re-sending to an accepted friend keeps the friendship.
	code, body := friendRequestPG(t, s, f.proposer, f.proposerFriend, "search")
	if code != http.StatusOK || body["friend"].(map[string]any)["status"] != "accepted" {
		t.Fatalf("re-request to a friend must stay accepted: %d %v", code, body)
	}
	if rows := friendRows(t, f, f.proposer, f.proposerFriend); rows[f.proposer] != "accepted:" || rows[f.proposerFriend] != "accepted:" {
		t.Fatalf("friendship downgraded: %v", rows)
	}
	if n := f.notifications(t, f.proposerFriend, "friend_request.received"); n != 0 {
		t.Fatalf("no request notification for an existing friend, got %d", n)
	}

	// A pair an older build half-downgraded is repaired by the next request.
	blogExec(t, f, `UPDATE matching.friend_connections SET status='pending' WHERE user_id=$1 AND friend_user_id=$2`, f.invitee, f.inviteeFriend)
	if code, body = friendRequestPG(t, s, f.invitee, f.inviteeFriend, ""); code != http.StatusOK || body["friend"].(map[string]any)["status"] != "accepted" {
		t.Fatalf("half-downgraded pair must be repaired: %d %v", code, body)
	}
	if rows := friendRows(t, f, f.invitee, f.inviteeFriend); rows[f.invitee] != "accepted:" || rows[f.inviteeFriend] != "accepted:" {
		t.Fatalf("pair not repaired: %v", rows)
	}

	// A request is pending, records its source and notifies the recipient once.
	code, body = friendRequestPG(t, s, f.stranger, f.groupMate, "room")
	friend := body["friend"].(map[string]any)
	if code != http.StatusOK || friend["status"] != "pending" || friend["direction"] != "outgoing" || friend["source"] != "room" {
		t.Fatalf("request must be pending/outgoing with source: %d %v", code, body)
	}
	if friend["friend_name"] != "Groupmate" {
		t.Fatalf("request must carry the member's name: %v", friend)
	}
	if code, _ = friendRequestPG(t, s, f.stranger, f.groupMate, "room"); code != http.StatusOK {
		t.Fatalf("repeated request must be idempotent: %d", code)
	}
	if n := f.notifications(t, f.groupMate, "friend_request.received"); n != 1 {
		t.Fatalf("recipient must get one request notification, got %d", n)
	}
	var route, title string
	if err := f.db.QueryRow(`SELECT action_route,title FROM matching.notification_outbox WHERE recipient_user_id=$1 AND event_type='friend_request.received'`, f.groupMate).Scan(&route, &title); err != nil {
		t.Fatal(err)
	}
	if route != "/friends" || title != "Stranger wants to be friends" {
		t.Fatalf("request notification route/title: %q %q", route, title)
	}
	var sends int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.friend_request_sends WHERE requester_id=$1`, f.stranger).Scan(&sends); err != nil {
		t.Fatal(err)
	}
	if sends != 1 {
		t.Fatalf("a repeated request must not count again, got %d sends", sends)
	}
	incoming := friendListPG(t, s, f.groupMate)[f.stranger]
	if incoming == nil || incoming["direction"] != "incoming" || incoming["status"] != "pending" || incoming["source"] != "room" {
		t.Fatalf("recipient must see an incoming request: %v", incoming)
	}

	// Asking back accepts: both rows accepted, activity for both, the first
	// requester hears about it.
	code, body = friendRequestPG(t, s, f.groupMate, f.stranger, "search")
	if code != http.StatusOK || body["friend"].(map[string]any)["status"] != "accepted" {
		t.Fatalf("mutual request must auto-accept: %d %v", code, body)
	}
	if rows := friendRows(t, f, f.stranger, f.groupMate); rows[f.stranger] != "accepted:room" || rows[f.groupMate] != "accepted:room" {
		t.Fatalf("mutual accept rows/source: %v", rows)
	}
	if f.feedRows(t, f.stranger, "friend_connected") != 1 || f.feedRows(t, f.groupMate, "friend_connected") != 1 {
		t.Fatal("both members need a friend_connected activity")
	}
	if n := f.notifications(t, f.stranger, "friend_request.accepted"); n != 1 {
		t.Fatalf("requester must hear the request was accepted, got %d", n)
	}
	if n := f.notifications(t, f.stranger, "friend_request.received"); n != 0 {
		t.Fatalf("a mutual accept must not send a new request, got %d", n)
	}

	// The friendship opens a friend conversation.
	if _, err := ensureFriendChannel(context.Background(), f.db, f.stranger, f.groupMate); err != nil {
		t.Fatalf("accepted friends must be able to chat: %v", err)
	}
}

func TestFriendRequestAcceptAndDeclineCooldownPostgres(t *testing.T) {
	f, s := newFriendFixture(t)

	if code, body := friendRequestPG(t, s, f.stranger, f.invitee, "profile"); code != http.StatusOK {
		t.Fatalf("request: %d %v", code, body)
	}
	if code, body := friendDecidePG(t, s, f.invitee, f.stranger, "decline"); code != http.StatusOK {
		t.Fatalf("decline: %d %v", code, body)
	}
	if rows := friendRows(t, f, f.stranger, f.invitee); len(rows) != 0 {
		t.Fatalf("declined request must be gone: %v", rows)
	}
	if n := f.notifications(t, f.stranger, "friend_request.declined") + f.notifications(t, f.stranger, "friend_request.accepted"); n != 0 {
		t.Fatalf("a decline is silent, got %d notifications", n)
	}
	if code, body := friendDecidePG(t, s, f.invitee, f.stranger, "accept"); code != http.StatusNotFound {
		t.Fatalf("deciding a closed request must 404: %d %v", code, body)
	}
	code, body := friendRequestPG(t, s, f.stranger, f.invitee, "profile")
	if code != http.StatusTooManyRequests {
		t.Fatalf("re-request inside the 7-day cooldown must be refused: %d %v", code, body)
	}
	blogExec(t, f, `UPDATE matching.friend_request_declines SET declined_at=NOW()-interval '8 days' WHERE requester_id=$1`, f.stranger)
	if code, body = friendRequestPG(t, s, f.stranger, f.invitee, "profile"); code != http.StatusOK {
		t.Fatalf("request after the cooldown: %d %v", code, body)
	}
	// The recipient may still ask the requester at any time (it accepts).
	if code, body = friendDecidePG(t, s, f.invitee, f.stranger, "accept"); code != http.StatusOK || body["friend"].(map[string]any)["status"] != "accepted" {
		t.Fatalf("accept: %d %v", code, body)
	}
	if n := f.notifications(t, f.stranger, "friend_request.accepted"); n != 1 {
		t.Fatalf("requester must hear about the accept, got %d", n)
	}
	var declines int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.friend_request_declines WHERE requester_id=$1`, f.stranger).Scan(&declines); err != nil {
		t.Fatal(err)
	}
	if declines != 0 {
		t.Fatal("becoming friends clears earlier declines")
	}

	// Removing an incoming request through DELETE counts as a decline.
	if code, body = friendRequestPG(t, s, f.groupMate, f.invitee, "group"); code != http.StatusOK {
		t.Fatalf("request: %d %v", code, body)
	}
	if code, body = friendCall(t, s, s.removeFriend, http.MethodDelete, f.invitee, "", map[string]string{"userID": f.invitee, "friendUserID": f.groupMate}, nil); code != http.StatusOK {
		t.Fatalf("remove incoming: %d %v", code, body)
	}
	if code, _ = friendRequestPG(t, s, f.groupMate, f.invitee, "group"); code != http.StatusTooManyRequests {
		t.Fatalf("removing an incoming request starts the cooldown, got %d", code)
	}
	// Unfriending removes both rows.
	if code, _ = friendCall(t, s, s.removeFriend, http.MethodDelete, f.invitee, "", map[string]string{"userID": f.invitee, "friendUserID": f.stranger}, nil); code != http.StatusOK {
		t.Fatalf("unfriend: %d", code)
	}
	if rows := friendRows(t, f, f.stranger, f.invitee); len(rows) != 0 {
		t.Fatalf("unfriend must remove both rows: %v", rows)
	}
}

func TestFriendRequestDailyLimitPostgres(t *testing.T) {
	f, s := newFriendFixture(t)
	blogExec(t, f, `INSERT INTO matching.friend_request_sends (requester_id,recipient_id,created_at)
		SELECT $1,$2,NOW()-interval '1 hour' FROM generate_series(1,30)`, f.stranger, f.invitee)
	if code, body := friendRequestPG(t, s, f.stranger, f.groupMate, "search"); code != http.StatusTooManyRequests {
		t.Fatalf("31st request in 24 hours must be refused: %d %v", code, body)
	}
	// Mutual accepts are not new requests and are never limited.
	if code, body := friendRequestPG(t, s, f.groupMate, f.stranger, "search"); code != http.StatusOK {
		t.Fatalf("request: %d %v", code, body)
	}
	if code, body := friendRequestPG(t, s, f.stranger, f.groupMate, "search"); code != http.StatusOK || body["friend"].(map[string]any)["status"] != "accepted" {
		t.Fatalf("mutual accept must work at the limit: %d %v", code, body)
	}
	blogExec(t, f, `UPDATE matching.friend_request_sends SET created_at=NOW()-interval '25 hours' WHERE requester_id=$1`, f.stranger)
	if code, body := friendRequestPG(t, s, f.stranger, f.inviteeFriend, "search"); code != http.StatusOK {
		t.Fatalf("requests older than 24 hours no longer count: %d %v", code, body)
	}
}

func TestFriendRequestBlocksAndOwnershipPostgres(t *testing.T) {
	f, s := newFriendFixture(t)

	// blockedFriend blocked the proposer: no request either way, and the
	// friendship disappears from both lists.
	if code, _ := friendRequestPG(t, s, f.stranger, f.stranger, ""); code != http.StatusBadRequest {
		t.Fatalf("self request must be 400, got %d", code)
	}
	blogExec(t, f, `DELETE FROM matching.friend_connections WHERE user_id IN ($1,$2) AND friend_user_id IN ($1,$2)`, f.proposer, f.blockedFriend)
	if code, _ := friendRequestPG(t, s, f.proposer, f.blockedFriend, ""); code != http.StatusNotFound {
		t.Fatalf("request to someone who blocked you must be unavailable, got %d", code)
	}
	if code, _ := friendRequestPG(t, s, f.blockedFriend, f.proposer, ""); code != http.StatusNotFound {
		t.Fatalf("request to someone you blocked must be unavailable, got %d", code)
	}

	// A block after the request stops the accept and hides the request.
	if code, body := friendRequestPG(t, s, f.invitee, f.groupMate, "match"); code != http.StatusOK {
		t.Fatalf("request: %d %v", code, body)
	}
	blogExec(t, f, `INSERT INTO user_management.blocked_users (user_id,blocked_user_id,reason) VALUES ($1,$2,'test')`, f.groupMate, f.invitee)
	if _, ok := friendListPG(t, s, f.groupMate)[f.invitee]; ok {
		t.Fatal("blocked member's request must be hidden")
	}
	if code, _ := friendDecidePG(t, s, f.groupMate, f.invitee, "accept"); code != http.StatusNotFound {
		t.Fatalf("accepting a blocked member must be unavailable, got %d", code)
	}
	if rows := friendRows(t, f, f.invitee, f.groupMate); rows[f.groupMate] != "" {
		t.Fatalf("no friendship after a refused accept: %v", rows)
	}

	// An accepted friend who blocked shows in neither list.
	seedPair := func(a, b string) {
		blogExec(t, f, `INSERT INTO matching.friend_connections (user_id,friend_user_id,status) VALUES ($1,$2,'accepted'),($2,$1,'accepted')`, a, b)
	}
	seedPair(f.stranger, f.inviteeFriend)
	blogExec(t, f, `INSERT INTO user_management.blocked_users (user_id,blocked_user_id,reason) VALUES ($1,$2,'test')`, f.stranger, f.inviteeFriend)
	if _, ok := friendListPG(t, s, f.inviteeFriend)[f.stranger]; ok {
		t.Fatal("a friend who blocked you must not be listed")
	}

	// The list carries the member card.
	list := friendListPG(t, s, f.proposer)
	meera := list[f.proposerFriend]
	if meera == nil || meera["friend_name"] != "Meera" || meera["status"] != "accepted" || !strings.HasPrefix(toString(meera["friend_username"]), "planqa_") {
		t.Fatalf("friend row must carry name and username: %v", meera)
	}

	// Paths belong to the signed-in member.
	if code, _ := friendCall(t, s, s.listFriends, http.MethodGet, f.stranger, "", map[string]string{"userID": f.proposer}, nil); code != http.StatusForbidden {
		t.Fatalf("another member's friends must be forbidden, got %d", code)
	}
	if code, _ := friendCall(t, s, s.listFriends, http.MethodGet, "", "", map[string]string{"userID": f.proposer}, nil); code != http.StatusUnauthorized {
		t.Fatalf("signed-out list must be 401, got %d", code)
	}
	if code, _ := friendRequestPG(t, s, f.stranger, f.invitee, "carrier-pigeon"); code != http.StatusBadRequest {
		t.Fatalf("unknown source must be 400, got %d", code)
	}
}

func TestFriendSearchPrivacyPostgres(t *testing.T) {
	f, s := newFriendFixture(t)
	username := func(id string) string {
		var u string
		if err := f.db.QueryRow(`SELECT username FROM user_management.users WHERE id=$1`, id).Scan(&u); err != nil {
			t.Fatal(err)
		}
		return u
	}
	search := func(me, q string) (int, []map[string]any) {
		code, body := friendCall(t, s, s.searchFriendCandidates, http.MethodGet, me, "", map[string]string{"userID": me}, url.Values{"q": {q}})
		out := []map[string]any{}
		if raw, ok := body["results"].([]any); ok {
			for _, r := range raw {
				out = append(out, r.(map[string]any))
			}
		}
		return code, out
	}
	blogExec(t, f, `UPDATE user_management.users SET city='Pune', bio='secret bio' WHERE id=$1`, f.stranger)

	code, results := search(f.proposer, "@"+strings.ToUpper(username(f.stranger)))
	if code != http.StatusOK || len(results) != 1 {
		t.Fatalf("exact username search: %d %v", code, results)
	}
	got := results[0]
	if got["user_id"] != f.stranger || got["name"] != "Stranger" || got["city"] != "Pune" || got["relationship"] != "none" {
		t.Fatalf("search result: %v", got)
	}
	for key := range got {
		switch key {
		case "user_id", "name", "username", "city", "photo_url", "relationship":
		default:
			t.Fatalf("search must expose only the member card, got %q in %v", key, got)
		}
	}
	if _, results = search(f.proposer, username(f.proposerFriend)); len(results) != 1 || results[0]["relationship"] != "friends" {
		t.Fatalf("friend relationship: %v", results)
	}
	if _, results = search(f.proposer, username(f.blockedFriend)); len(results) != 0 {
		t.Fatalf("blocked either way must be hidden: %v", results)
	}
	if _, results = search(f.blockedFriend, username(f.proposer)); len(results) != 0 {
		t.Fatalf("blocked either way must be hidden: %v", results)
	}
	if _, results = search(f.proposer, username(f.proposer)); len(results) != 0 {
		t.Fatalf("self must be hidden: %v", results)
	}
	friendRequestPG(t, s, f.stranger, f.proposer, "search")
	if _, results = search(f.proposer, username(f.stranger)); len(results) != 1 || results[0]["relationship"] != "incoming" {
		t.Fatalf("incoming relationship: %v", results)
	}
	if _, results = search(f.stranger, username(f.proposer)); len(results) != 1 || results[0]["relationship"] != "outgoing" {
		t.Fatalf("outgoing relationship: %v", results)
	}
	blogExec(t, f, `UPDATE user_management.users SET is_active=false WHERE id=$1`, f.groupMate)
	if _, results = search(f.proposer, username(f.groupMate)); len(results) != 0 {
		t.Fatalf("inactive members must be hidden: %v", results)
	}
	if code, _ = search(f.proposer, "ab"); code != http.StatusBadRequest {
		t.Fatalf("queries under 3 letters must be 400, got %d", code)
	}
	if _, results = search(f.proposer, "%%%"); len(results) != 0 {
		t.Fatalf("LIKE wildcards must be literal: %v", results)
	}
	if code, results = search(f.proposer, "pla"); code != http.StatusOK || len(results) > friendSearchLimit {
		t.Fatalf("search returns at most %d: %d %d", friendSearchLimit, code, len(results))
	}
}

// ---------------------------------------------------------------------------
// In-memory store
// ---------------------------------------------------------------------------

func TestFriendRequestRulesInMemory(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	store := server.store

	// Mutual auto-accept with source, and no downgrade on re-request.
	if c, err := store.addFriendFrom("user-a", "user-b", "match"); err != nil || c.Status != "pending" || c.Source != "match" {
		t.Fatalf("request: %v %v", c, err)
	}
	c, err := store.addFriendFrom("user-b", "user-a", "search")
	if err != nil || c.Status != "accepted" {
		t.Fatalf("mutual request must accept: %v %v", c, err)
	}
	if c, err = store.addFriendFrom("user-a", "user-b", ""); err != nil || c.Status != "accepted" {
		t.Fatalf("re-request must not downgrade: %v %v", c, err)
	}
	if store.friends["user-a"]["user-b"].Status != "accepted" || store.friends["user-b"]["user-a"].Status != "accepted" {
		t.Fatalf("both sides accepted: %v", store.friends)
	}
	if _, err = store.addFriendFrom("user-a", "user-c", "carrier-pigeon"); err == nil {
		t.Fatal("unknown source must fail")
	}

	// Decline cooldown.
	if _, err = store.addFriendFrom("user-c", "user-d", ""); err != nil {
		t.Fatal(err)
	}
	if _, err = store.decideFriendRequest("user-d", "user-c", "decline"); err != nil {
		t.Fatal(err)
	}
	if _, err = store.addFriendFrom("user-c", "user-d", ""); err == nil {
		t.Fatal("re-request inside the cooldown must fail")
	}
	store.friendDeclines["user-c|user-d"] = time.Now().Add(-8 * 24 * time.Hour)
	if _, err = store.addFriendFrom("user-c", "user-d", ""); err != nil {
		t.Fatalf("request after cooldown: %v", err)
	}

	// Daily limit.
	for i := 0; i < friendRequestsPerDay; i++ {
		store.friendSends["user-e"] = append(store.friendSends["user-e"], time.Now())
	}
	if _, err = store.addFriendFrom("user-e", "user-f", ""); err == nil {
		t.Fatal("31st request in a day must fail")
	}

	// HTTP: a rule error keeps its status; source is validated.
	req := httptest.NewRequest(http.MethodPost, "/v1/friends/user-e", bytes.NewBufferString(`{"friend_user_id":"user-g"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("daily limit must be 429, got %d %s", rec.Code, rec.Body.String())
	}
	req = httptest.NewRequest(http.MethodPost, "/v1/friends/user-a", bytes.NewBufferString(`{"friend_user_id":"user-g","source":"nope"}`))
	req.Header.Set("Content-Type", "application/json")
	rec = httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("bad source must be 400, got %d", rec.Code)
	}
}

func TestFriendSearchInMemory(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	store := server.store
	for id, name := range map[string]string{"user-a": "Asha", "user-b": "Ashwin Rao", "user-c": "Ravi Ashok", "user-d": "Ashley"} {
		d := defaultDraft(id)
		d.Name = name
		d.Username = strings.ToLower(strings.ReplaceAll(name, " ", "")) + "_x"
		store.profiles[id] = d
	}
	if err := store.blockUser("user-d", "user-a"); err != nil {
		t.Fatal(err)
	}
	if _, err := store.addFriendFrom("user-a", "user-b", "search"); err != nil {
		t.Fatal(err)
	}
	results, err := store.searchFriendCandidates("user-a", "ash")
	if err != nil {
		t.Fatal(err)
	}
	got := map[string]string{}
	for _, r := range results {
		got[r.UserID] = r.Relationship
	}
	if len(got) != 2 || got["user-b"] != "outgoing" || got["user-c"] != "none" {
		t.Fatalf("search must find name and word prefixes, skip self and blocked: %v", got)
	}
	if _, err = store.searchFriendCandidates("user-a", "as"); err == nil {
		t.Fatal("short query must fail")
	}

	req := httptest.NewRequest(http.MethodGet, "/v1/friends/user-a/search?q=ash", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"results"`) {
		t.Fatalf("search route: %d %s", rec.Code, rec.Body.String())
	}
}

// "Let people find me in friend search" (migration 120).
func TestFriendSearchOptOutPostgres(t *testing.T) {
	f, s := newFriendFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='user_management' AND table_name='user_settings' AND column_name='friend_search_visible')`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 120_group_reports_friend_search_optout is not applied")
	}
	var strangerName string
	if err := f.db.QueryRow(`SELECT username FROM user_management.users WHERE id=$1`, f.stranger).Scan(&strangerName); err != nil {
		t.Fatal(err)
	}
	visibility := func(user, method, body string) (int, map[string]any) {
		return friendCall(t, s, s.friendSearchVisibilityHandler, method, user, body, map[string]string{"userID": f.stranger}, nil)
	}
	found := func() int {
		code, body := friendCall(t, s, s.searchFriendCandidates, http.MethodGet, f.proposer, "", map[string]string{"userID": f.proposer}, url.Values{"q": {strangerName}})
		if code != http.StatusOK {
			t.Fatalf("search: %d %v", code, body)
		}
		return len(body["results"].([]any))
	}
	if code, body := visibility(f.stranger, http.MethodGet, ""); code != 200 || body["visible"] != true {
		t.Fatalf("default visibility: %d %v", code, body)
	}
	if found() != 1 {
		t.Fatal("a findable member is missing from search")
	}
	// Someone else cannot read or change it.
	if code, _ := visibility(f.proposer, http.MethodPut, `{"visible":false}`); code != http.StatusForbidden {
		t.Fatalf("another member changed the setting: %d", code)
	}
	if code, _ := visibility(f.stranger, http.MethodPut, `{"visible":"no"}`); code != http.StatusBadRequest {
		t.Fatalf("non-boolean accepted: %d", code)
	}
	if code, body := visibility(f.stranger, http.MethodPut, `{"visible":false}`); code != 200 || body["visible"] != false {
		t.Fatalf("opt out: %d %v", code, body)
	}
	if code, body := visibility(f.stranger, http.MethodGet, ""); code != 200 || body["visible"] != false {
		t.Fatalf("opt-out not stored: %d %v", code, body)
	}
	if found() != 0 {
		t.Fatal("an opted-out member still appears in friend search")
	}
	// The other settings keep their values and the member can still be added
	// from where people already see them, and can still search.
	var showAge bool
	if err := f.db.QueryRow(`SELECT show_age FROM user_management.user_settings WHERE user_id=$1`, f.stranger).Scan(&showAge); err != nil || !showAge {
		t.Fatalf("settings row defaults: show_age=%v err=%v", showAge, err)
	}
	if code, body := friendRequestPG(t, s, f.proposer, f.stranger, "match"); code != 200 {
		t.Fatalf("request to an opted-out member from a match: %d %v", code, body)
	}
	var proposerName string
	if err := f.db.QueryRow(`SELECT username FROM user_management.users WHERE id=$1`, f.proposer).Scan(&proposerName); err != nil {
		t.Fatal(err)
	}
	if code, body := friendCall(t, s, s.searchFriendCandidates, http.MethodGet, f.stranger, "", map[string]string{"userID": f.stranger}, url.Values{"q": {proposerName}}); code != 200 || len(body["results"].([]any)) != 1 {
		t.Fatalf("an opted-out member can still search: %d %v", code, body)
	}
	if code, body := visibility(f.stranger, http.MethodPut, `{"visible":true}`); code != 200 || body["visible"] != true {
		t.Fatalf("opt back in: %d %v", code, body)
	}
	if found() != 1 {
		t.Fatal("opting back in did not restore search")
	}
}

func TestFriendSearchOptOutInMemory(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	store := server.store
	for id, name := range map[string]string{"user-a": "Asha", "user-b": "Ashwin Rao"} {
		d := defaultDraft(id)
		d.Name = name
		d.Username = strings.ToLower(strings.ReplaceAll(name, " ", "")) + "_x"
		store.profiles[id] = d
	}
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPut, "/v1/friends/user-b/search-visibility", strings.NewReader(`{"visible":false}`)))
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"visible":false`) {
		t.Fatalf("opt out route: %d %s", rec.Code, rec.Body.String())
	}
	results, err := store.searchFriendCandidates("user-a", "ash")
	if err != nil || len(results) != 0 {
		t.Fatalf("opted-out member found in memory: %v %v", results, err)
	}
	rec = httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/friends/user-b/search-visibility", nil))
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"visible":false`) {
		t.Fatalf("read route: %d %s", rec.Code, rec.Body.String())
	}
	store.setFriendSearchVisible("user-b", true)
	if results, _ = store.searchFriendCandidates("user-a", "ash"); len(results) != 1 {
		t.Fatalf("opted back in: %v", results)
	}
}
