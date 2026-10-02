package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/verified-dating/backend/internal/platform/postgresdata"
)

// Postgres-backed checks for the member action log (migration 132): the
// middleware writes a durable member_action row with the verified actor and
// request context, a read stays api_request without an IP, and the admin
// endpoints filter, scope to a member, include reads on request and page a
// live tail without duplicates or gaps. They skip without
// PROFILE_TEST_DATABASE_URL, e.g.
//
//	PROFILE_TEST_DATABASE_URL='postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable' \
//	  go test ./internal/bff/mobile/ -run MemberActivityPostgres -count=1

func memberActivityPostgresServer(t *testing.T) (*Server, *sql.DB) {
	t.Helper()
	db := trustOpsDB(t)
	var ready bool
	if err := db.QueryRow(`SELECT EXISTS (SELECT 1 FROM platform.retention_policies WHERE policy_name='member_action_history')`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 132 is not applied")
	}
	client, err := postgresdata.Open(context.Background(), os.Getenv("PROFILE_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(client.Close)
	s := adminPagingServer(t, db)
	s.store.activityRepo = &activityRepository{cfg: s.cfg, db: client}
	return s, db
}

func seedMemberActivityMember(t *testing.T, db *sql.DB) string {
	t.Helper()
	member, _ := seedTrustMember(t, db)
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM matching.activity_events WHERE user_id=$1 OR actor_user_id=$1`, member)
	})
	return member
}

func callMemberActivity(t *testing.T, s *Server, handler http.HandlerFunc, target string, roles ...string) map[string]any {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, target, nil)
	if len(roles) == 0 {
		roles = []string{"admin"}
	}
	principal := securityPrincipal{UserID: "00000000-0000-4000-8000-000000000001", Roles: map[string]bool{}}
	for _, role := range roles {
		principal.Roles[role] = true
	}
	req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, principal))
	if strings.Contains(target, "/members/") {
		req = withChiURLParam(req, "userID", strings.Split(strings.Split(target, "/members/")[1], "/")[0])
	}
	rec := httptest.NewRecorder()
	handler(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("%s: status %d %s", target, rec.Code, rec.Body.String())
	}
	body := map[string]any{}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	return body
}

func withChiURLParam(req *http.Request, key, value string) *http.Request {
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add(key, value)
	return req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
}

func memberActions(body map[string]any) []map[string]any {
	raw, _ := body["actions"].([]any)
	out := make([]map[string]any, 0, len(raw))
	for _, item := range raw {
		if row, ok := item.(map[string]any); ok {
			out = append(out, row)
		}
	}
	return out
}

func TestMemberActivityCaptureAndAdminLogPostgres(t *testing.T) {
	s, db := memberActivityPostgresServer(t)
	member := seedMemberActivityMember(t, db)
	viewed := seedMemberActivityMember(t, db)
	router := activityCaptureRouter(s, &securityPrincipal{UserID: member, SessionID: "sess-pg", AccountKind: "dating", Roles: map[string]bool{}})

	post := httptest.NewRequest(http.MethodPost, "/v1/swipe?lat=18.52&token=secret-token", strings.NewReader(`{"note":"body text"}`))
	post.RemoteAddr = "127.0.0.1:50000"
	post.Header.Set("X-Forwarded-For", "203.0.113.44, 127.0.0.1")
	post.Header.Set("X-Correlation-ID", "pg-corr-"+member[:8])
	post.Header.Set("X-Client-Platform", "android")
	post.Header.Set("X-Device-ID", "pg-device-1")
	post.Header.Set("User-Agent", "Dart/3.5 (dart:io)")
	router.ServeHTTP(httptest.NewRecorder(), post)

	// Synchronous: the row is there as soon as the request returned.
	var domain, actor, ip, device, platform, requestID, payload string
	if err := db.QueryRow(`SELECT event_domain, actor_user_id::text, host(ip_address), source_device_id, source_platform,
	                              request_id, payload::text
	                       FROM matching.activity_events WHERE correlation_id=$1`, "pg-corr-"+member[:8]).
		Scan(&domain, &actor, &ip, &device, &platform, &requestID, &payload); err != nil {
		t.Fatalf("member action row: %v", err)
	}
	if domain != activityDomainMemberAction || actor != member || ip != "203.0.113.44" || device != "pg-device-1" ||
		platform != "android" || requestID != "pg-corr-"+member[:8] {
		t.Fatalf("row: %s %s %s %s %s %s", domain, actor, ip, device, platform, requestID)
	}
	for _, leak := range []string{"lat=", "secret-token", "body text", "18.52"} {
		if strings.Contains(payload, leak) {
			t.Fatalf("payload stores %q: %s", leak, payload)
		}
	}
	if !strings.Contains(payload, `"action_key": "discovery.swipe"`) {
		t.Fatalf("payload: %s", payload)
	}

	get := httptest.NewRequest(http.MethodGet, "/v1/profile/"+viewed, nil)
	get.RemoteAddr = "127.0.0.1:50001"
	get.Header.Set("X-Forwarded-For", "203.0.113.44")
	get.Header.Set("X-Correlation-ID", "pg-read-"+member[:8])
	router.ServeHTTP(httptest.NewRecorder(), get)
	var readDomain string
	var readIP sql.NullString
	if err := db.QueryRow(`SELECT event_domain, host(ip_address) FROM matching.activity_events WHERE correlation_id=$1`,
		"pg-read-"+member[:8]).Scan(&readDomain, &readIP); err != nil {
		t.Fatalf("read row: %v", err)
	}
	if readDomain != activityDomainAPIRequest || readIP.Valid {
		t.Fatalf("read row %s ip %v", readDomain, readIP)
	}

	// An explicit named event and a security event about the member.
	if _, err := db.Exec(`INSERT INTO matching.activity_events (event_name, event_domain, user_id, actor_user_id, payload)
		VALUES ('wallet.coins.purchase','mobile_bff',$1,$1,'{"status":"success","details":{"coins":50}}')`, member); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO audit.security_events (event_type, actor_user_id, actor_role, subject_user_id, resource_type, resource_id)
		VALUES ('safety.user.blocked',$1,'user',$1,'user',$2)`, member, viewed); err != nil {
		t.Fatal(err)
	}

	base := "/v1/admin/activity?member=" + member
	all := memberActions(callMemberActivity(t, s, s.adminListMemberActivity, base))
	sources := map[string]int{}
	for _, action := range all {
		sources[toString(action["source"])]++
		if toString(action["action_key"]) == "GET" || toString(action["method"]) == http.MethodGet {
			t.Fatalf("reads must be excluded by default: %v", action)
		}
	}
	for _, source := range []string{"request", "event", "security", "domain"} {
		if sources[source] == 0 {
			t.Fatalf("source %s missing from %v", source, sources)
		}
	}

	swipe := memberActions(callMemberActivity(t, s, s.adminListMemberActivity, base+"&action=discovery.swipe"))
	if len(swipe) != 1 {
		t.Fatalf("action filter: %d", len(swipe))
	}
	row := swipe[0]
	for key, want := range map[string]any{
		"source": "request", "member_id": member, "actor_id": member, "actor_role": "member",
		"category": "Discovery", "action_label": "Swiped on a profile", "method": "POST", "route": "/v1/swipe",
		"status_code": float64(200), "outcome": "success", "ip": "203.0.113.44", "device_id": "pg-device-1",
		"platform": "android", "user_agent": "Dart/3.5 (dart:io)", "session_id": "sess-pg",
	} {
		if row[key] != want {
			t.Fatalf("%s = %v, want %v", key, row[key], want)
		}
	}

	// Analysts read the log without network identifiers.
	analyst := memberActions(callMemberActivity(t, s, s.adminListMemberActivity, base+"&action=discovery.swipe", "analyst"))
	if analyst[0]["ip"] != nil || analyst[0]["device_id"] != nil || analyst[0]["user_agent"] != nil {
		t.Fatalf("analyst sees network context: %v", analyst[0])
	}

	withReads := memberActions(callMemberActivity(t, s, s.adminListMemberActivity, base+"&include_reads=true&method=GET&source=request"))
	if len(withReads) != 1 || withReads[0]["action_key"] != "profile.view" || withReads[0]["ip"] != nil {
		t.Fatalf("include_reads: %v", withReads)
	}

	events := memberActions(callMemberActivity(t, s, s.adminListMemberActivity, base+"&source=event"))
	if len(events) != 1 || events[0]["action_label"] != "Bought coins" || events[0]["category"] != "Billing & coins" {
		t.Fatalf("event source: %v", events)
	}
	security := memberActions(callMemberActivity(t, s, s.adminListMemberActivity, base+"&source=security&category=Safety"))
	if len(security) != 1 || security[0]["action_key"] != "safety.user.blocked" {
		t.Fatalf("security source: %v", security)
	}
	discovery := callMemberActivity(t, s, s.adminListMemberActivity, base+"&category=Discovery&q=swiped")
	if discovery["total"] != float64(1) {
		t.Fatalf("category+q total %v", discovery["total"])
	}

	// The member endpoint is fixed to its member and summarises the window.
	today := time.Now().UTC().Format("2006-01-02")
	scoped := callMemberActivity(t, s, s.adminMemberActivity, "/v1/admin/members/"+member+"/activity?member="+viewed+"&from="+today+"&to="+today)
	if scoped["member_id"] != member || scoped["total"].(float64) < 4 {
		t.Fatalf("member endpoint: %v %v", scoped["member_id"], scoped["total"])
	}
	summary, _ := scoped["summary"].(map[string]any)
	byCategory, _ := summary["by_category"].(map[string]any)
	if byCategory["Discovery"].(float64) < 1 || summary["distinct_ips"].(float64) != 1 || summary["distinct_devices"].(float64) != 1 ||
		summary["first_seen"] == nil || summary["last_seen"] == nil {
		t.Fatalf("summary: %v", summary)
	}

	// The viewed member's log shows the profile view only with reads.
	viewedLog := callMemberActivity(t, s, s.adminMemberActivity, "/v1/admin/members/"+viewed+"/activity?source=request")
	if viewedLog["total"] != float64(0) {
		t.Fatalf("viewed member without reads: %v", viewedLog["total"])
	}
	viewedLog = callMemberActivity(t, s, s.adminMemberActivity, "/v1/admin/members/"+viewed+"/activity?source=request&include_reads=true")
	if viewedLog["total"] != float64(1) {
		t.Fatalf("viewed member with reads: %v", viewedLog["total"])
	}
}

func TestMemberActivityStreamHasNoGapsOrDuplicatesPostgres(t *testing.T) {
	s, db := memberActivityPostgresServer(t)
	member := seedMemberActivityMember(t, db)
	start := time.Now().UTC().Add(-time.Hour).Truncate(time.Second)
	// Five actions; two share a timestamp, so the (at, source, id) cursor
	// has to break the tie.
	offsets := []time.Duration{0, time.Second, time.Second, 2 * time.Second, 3 * time.Second}
	want := map[string]bool{}
	for i, offset := range offsets {
		var id string
		if err := db.QueryRow(`INSERT INTO matching.activity_events (event_name, event_domain, user_id, actor_user_id, payload, created_at)
			VALUES ('POST /v1/swipe','member_action',$1,$1,
			        jsonb_build_object('details', jsonb_build_object('action_key','test.stream','action_category','Discovery','n',$2::int)),$3)
			RETURNING id::text`, member, i, start.Add(offset)).Scan(&id); err != nil {
			t.Fatal(err)
		}
		want[id] = true
	}

	stream := "/v1/admin/activity/stream?member=" + member + "&action=test.stream&limit=2"
	latest := memberActions(callMemberActivity(t, s, s.adminStreamMemberActivity, stream))
	if len(latest) != 2 || toString(latest[0]["at"]) > toString(latest[1]["at"]) {
		t.Fatalf("no cursor: latest two, oldest first: %v", latest)
	}

	cursor := memberActivityCursor{At: start.Add(-time.Minute)}.encode()
	seen := map[string]bool{}
	var order []string
	for call := 0; call < 5; call++ {
		body := callMemberActivity(t, s, s.adminStreamMemberActivity, stream+"&after="+url.QueryEscape(cursor))
		actions := memberActions(body)
		for _, action := range actions {
			id := toString(action["id"])
			if seen[id] {
				t.Fatalf("duplicate %s on call %d", id, call)
			}
			seen[id] = true
			order = append(order, toString(action["at"]))
		}
		next := toString(body["cursor"])
		if len(actions) == 0 && next != cursor {
			t.Fatal("an empty page must keep the cursor")
		}
		cursor = next
	}
	if len(seen) != len(want) {
		t.Fatalf("saw %d of %d actions", len(seen), len(want))
	}
	for id := range want {
		if !seen[id] {
			t.Fatalf("gap: %s never streamed", id)
		}
	}
	for i := 1; i < len(order); i++ {
		if order[i] < order[i-1] {
			t.Fatalf("stream is not ascending: %v", order)
		}
	}

	// A new action after the cursor arrives on the next call, once settled.
	var newID string
	if err := db.QueryRow(`INSERT INTO matching.activity_events (event_name, event_domain, user_id, actor_user_id, payload, created_at)
		VALUES ('POST /v1/swipe','member_action',$1,$1,'{"details":{"action_key":"test.stream"}}',NOW() - INTERVAL '10 seconds')
		RETURNING id::text`, member).Scan(&newID); err != nil {
		t.Fatal(err)
	}
	next := memberActions(callMemberActivity(t, s, s.adminStreamMemberActivity, stream+"&after="+url.QueryEscape(cursor)))
	if len(next) != 1 || toString(next[0]["id"]) != newID {
		t.Fatalf("tail after cursor: %v", next)
	}
}

func TestMemberActionCatalogEndpointPostgres(t *testing.T) {
	s, _ := memberActivityPostgresServer(t)
	server := newContractTestServer(t)
	s.router = server.router
	body := callMemberActivity(t, s, s.adminMemberActionCatalog, "/v1/admin/activity/catalog")
	coverage, _ := body["coverage"].(map[string]any)
	if coverage["mutating_routes"].(float64) < 200 || coverage["catalogued"] != coverage["mutating_routes"] {
		t.Fatalf("coverage: %v", coverage)
	}
	if categories, _ := body["categories"].([]any); len(categories) != len(memberActionCategories) {
		t.Fatalf("categories: %v", body["categories"])
	}
	if _, ok := body["sources_unregistered"].([]any); !ok {
		t.Fatalf("sources_unregistered: %v", body["sources_unregistered"])
	}
}

func TestMemberActionRetentionKeeps400DaysPostgres(t *testing.T) {
	_, db := memberActivityPostgresServer(t)
	member := seedMemberActivityMember(t, db)
	var oldID, recentID string
	insert := func(age string) string {
		var id string
		if err := db.QueryRow(`INSERT INTO matching.activity_events (event_name, event_domain, user_id, actor_user_id, created_at)
			VALUES ('POST /v1/swipe','member_action',$1,$1,NOW() - $2::interval) RETURNING id::text`, member, age).Scan(&id); err != nil {
			t.Fatal(err)
		}
		return id
	}
	oldID, recentID = insert("401 days"), insert("399 days")
	for i := 0; i < 50; i++ {
		_, _, _, removed, err := runActivityTelemetryRetention(context.Background(), db, 1)
		if err != nil {
			t.Fatal(err)
		}
		var exists bool
		_ = db.QueryRow(`SELECT EXISTS (SELECT 1 FROM matching.activity_events WHERE id=$1)`, oldID).Scan(&exists)
		if !exists {
			break
		}
		if removed == 0 {
			t.Fatal("the 401-day member action was not removed")
		}
	}
	var recentExists bool
	_ = db.QueryRow(`SELECT EXISTS (SELECT 1 FROM matching.activity_events WHERE id=$1)`, recentID).Scan(&recentExists)
	if !recentExists {
		t.Fatal("a 399-day member action was removed")
	}
}
