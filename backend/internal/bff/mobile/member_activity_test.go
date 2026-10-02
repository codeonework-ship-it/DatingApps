package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// ── Catalog ────────────────────────────────────────────────────────────────

// TestMemberActionCatalogCoversEveryMutatingRoute walks the live router: a
// new member POST/PUT/PATCH/DELETE route without a catalog entry fails the
// build, so no member action goes unrecorded (or unlabelled).
func TestMemberActionCatalogCoversEveryMutatingRoute(t *testing.T) {
	server := newContractTestServer(t)
	router, ok := server.Handler().(chi.Router)
	if !ok {
		t.Fatal("server handler is not a chi.Router")
	}
	coverage := computeMemberActionCoverage(router, server.cfg.APIPrefix)
	if coverage.MutatingRoutes < 200 {
		t.Fatalf("walked only %d mutating member routes; the walk is not seeing the API", coverage.MutatingRoutes)
	}
	if len(coverage.Uncatalogued) > 0 {
		t.Fatalf("%d member routes have no entry in memberActionCatalog (member_action_catalog.go):\n  %s",
			len(coverage.Uncatalogued), strings.Join(coverage.Uncatalogued, "\n  "))
	}
	if coverage.Catalogued != coverage.MutatingRoutes {
		t.Fatalf("catalogued %d of %d", coverage.Catalogued, coverage.MutatingRoutes)
	}
	if len(coverage.Stale) > 0 {
		t.Fatalf("catalog entries for routes that no longer exist:\n  %s", strings.Join(coverage.Stale, "\n  "))
	}
	if server.actionCoverage.MutatingRoutes != coverage.MutatingRoutes || len(server.actionCoverage.Uncatalogued) != 0 {
		t.Fatalf("startup coverage %+v differs from the walk %+v", server.actionCoverage, coverage)
	}
	for _, read := range []string{"GET /profile/{userID}", "GET /chat/{matchID}/messages", "GET /discovery/{userID}", "GET /notifications/{userID}"} {
		if _, ok := memberActionCatalog[read]; !ok {
			t.Fatalf("meaningful read %s is not catalogued", read)
		}
	}
}

func TestMemberActionCatalogEntriesAreWellFormed(t *testing.T) {
	keys := map[string]string{}
	for route, def := range memberActionCatalog {
		method, path, ok := strings.Cut(route, " ")
		if !ok || !strings.HasPrefix(path, "/") || strings.HasPrefix(path, "/admin") {
			t.Fatalf("bad catalog route %q", route)
		}
		if !isMutatingMethod(method) && method != http.MethodGet {
			t.Fatalf("bad catalog method %q", route)
		}
		if !isMemberActionCategory(def.Category) {
			t.Fatalf("%s: unknown category %q", route, def.Category)
		}
		if def.Key == "" || def.Label == "" || strings.ContainsAny(def.Key, " /") {
			t.Fatalf("%s: key %q label %q", route, def.Key, def.Label)
		}
		if other, dup := keys[def.Key]; dup {
			t.Fatalf("key %q used by %s and %s", def.Key, other, route)
		}
		keys[def.Key] = route
	}
	if def, ok := lookupMemberAction("/v1", "post", "/v1/swipe"); !ok || def.Key != "discovery.swipe" {
		t.Fatalf("lookup swipe: %+v %v", def, ok)
	}
	if _, ok := lookupMemberAction("/v1", "GET", "/v1/admin/activity"); ok {
		t.Fatal("admin routes are not member actions")
	}
}

func TestMemberEventCategoriesIgnoreSchemaPrefix(t *testing.T) {
	sql := memberEventCategorySQL("x")
	if !strings.HasPrefix(sql, "CASE WHEN regexp_replace(x,") || !strings.HasSuffix(sql, "ELSE 'Other' END") {
		t.Fatalf("category SQL: %s", sql)
	}
	if got := humaniseEventName("account.deletion_requested"); got != "Requested account deletion" {
		t.Fatalf("mapped label %q", got)
	}
	if got := humaniseEventName("graduation.proposed"); got != "Graduation proposed" {
		t.Fatalf("humanised label %q", got)
	}
}

// ── Capture ────────────────────────────────────────────────────────────────

func activityCaptureServer(db repositoryDB) *Server {
	s := &Server{store: &runtimeStore{activityRepo: &activityRepository{db: db}}, log: zap.NewNop()}
	s.cfg.APIPrefix = "/v1"
	return s
}

// activityCaptureRouter mounts the activity middleware the way NewServer
// does, with a stand-in for the security middleware that installs principal.
func activityCaptureRouter(s *Server, principal *securityPrincipal) http.Handler {
	router := chi.NewRouter()
	router.Use(observability.CorrelationIDMiddleware(zap.NewNop()))
	router.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if principal != nil {
				r = r.WithContext(context.WithValue(r.Context(), securityPrincipalContextKey{}, *principal))
			}
			next.ServeHTTP(w, r)
		})
	})
	router.Use(s.activityMiddleware)
	ok := func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) }
	router.Route("/v1", func(v1 chi.Router) {
		v1.Post("/swipe", ok)
		v1.Get("/profile/{userID}", ok)
		v1.Post("/clubs/{clubID}/members/{userID}", ok)
		v1.Post("/auth/login", func(w http.ResponseWriter, r *http.Request) {
			noteActivityMember(r, r.Header.Get("X-Test-Verified-Member"), "dating")
			w.WriteHeader(http.StatusOK)
		})
		v1.Get("/admin/activity", ok)
	})
	return router
}

func activityDetails(t *testing.T, row map[string]any) map[string]any {
	t.Helper()
	payload, _ := row["payload"].(map[string]any)
	details, _ := payload["details"].(map[string]any)
	if details == nil {
		t.Fatalf("row has no details: %v", row)
	}
	return details
}

func TestMemberPostIsADurableMemberActionWithRequestContext(t *testing.T) {
	member := uuid.NewString()
	db := &capturingActivityDB{}
	s := activityCaptureServer(db)
	principal := securityPrincipal{UserID: member, SessionID: "sess-123", AccountKind: "dating", Roles: map[string]bool{}}
	router := activityCaptureRouter(s, &principal)
	durableBefore := memberActionDurableWrites.Load()

	req := httptest.NewRequest(http.MethodPost, "/v1/swipe?lat=18.5204&lng=73.8567&q=priya%40example.com", strings.NewReader(`{"target_user_id":"x","note":"secret body"}`))
	req.RemoteAddr = "127.0.0.1:51234"
	req.Header.Set("X-Forwarded-For", "203.0.113.77, 127.0.0.1")
	req.Header.Set("X-User-ID", uuid.NewString()) // a spoofed header never becomes the actor
	req.Header.Set("X-Correlation-ID", "corr-abc-123")
	req.Header.Set("X-Client-Platform", "android")
	req.Header.Set("X-Device-ID", "device-42")
	req.Header.Set("X-App-Version", "2.3.1+45")
	req.Header.Set("Idempotency-Key", "idem-1")
	req.Header.Set("User-Agent", "Dart/3.5 (dart:io)\n"+strings.Repeat("x", 400))
	router.ServeHTTP(httptest.NewRecorder(), req)

	if len(db.inserted) != 1 {
		t.Fatalf("expected one row, got %d", len(db.inserted))
	}
	if memberActionDurableWrites.Load() != durableBefore+1 {
		t.Fatal("member action was not written synchronously")
	}
	row := db.inserted[0]
	blob, _ := json.Marshal(row)
	for _, leak := range []string{"lat=", "18.5204", "priya", "secret body", `"query"`, "\\n"} {
		if strings.Contains(string(blob), leak) {
			t.Fatalf("member action stores %q: %s", leak, blob)
		}
	}
	want := map[string]any{
		"event_domain": activityDomainMemberAction, "event_name": "POST /v1/swipe",
		"actor_user_id": member, "user_id": member, "ip_address": "203.0.113.77",
		"source_device_id": "device-42", "source_platform": "android",
		"request_id": "corr-abc-123", "correlation_id": "corr-abc-123", "idempotency_key": "idem-1",
	}
	for column, value := range want {
		if row[column] != value {
			t.Fatalf("%s = %v, want %v (%s)", column, row[column], value, blob)
		}
	}
	details := activityDetails(t, row)
	for key, value := range map[string]any{
		"action_key": "discovery.swipe", "action_label": "Swiped on a profile", "action_category": "Discovery",
		"outcome": "success", "route": "/v1/swipe", "method": "POST", "status_code": 200,
		"actor_role": "member", "account_kind": "dating", "session_id": "sess-123", "attribution": "session",
		"platform": "android", "device_id": "device-42", "app_version": "2.3.1+45",
	} {
		if details[key] != value {
			t.Fatalf("details[%s] = %v, want %v", key, details[key], value)
		}
	}
	if agent := toString(details["user_agent"]); len([]rune(agent)) != activityUserAgentMaxRunes || strings.ContainsAny(agent, "\n\r") {
		t.Fatalf("user agent not truncated/cleaned: %d %q", len(agent), agent[:20])
	}
}

func TestMemberActionKeepsPathIDsAsEntities(t *testing.T) {
	member, other, club := uuid.NewString(), uuid.NewString(), uuid.NewString()
	db := &capturingActivityDB{}
	s := activityCaptureServer(db)
	router := activityCaptureRouter(s, &securityPrincipal{UserID: member, Roles: map[string]bool{}})
	req := httptest.NewRequest(http.MethodPost, "/v1/clubs/"+strings.ToUpper(club)+"/members/"+other, nil)
	router.ServeHTTP(httptest.NewRecorder(), req)
	row := db.inserted[0]
	if row["user_id"] != other || row["actor_user_id"] != member {
		t.Fatalf("subject %v actor %v", row["user_id"], row["actor_user_id"])
	}
	if row["entity_table"] != "user" || row["entity_id"] != other {
		t.Fatalf("entity %v %v", row["entity_table"], row["entity_id"])
	}
	params, _ := activityDetails(t, row)["path_params"].(map[string]any)
	if params["clubID"] != club || params["userID"] != other {
		t.Fatalf("path params %v", params)
	}
	if strings.Contains(toString(row["event_name"]), club) {
		t.Fatal("the concrete path must not be stored")
	}
}

func TestMemberReadIsTelemetryWithoutIP(t *testing.T) {
	member, viewed := uuid.NewString(), uuid.NewString()
	db := &capturingActivityDB{}
	s := activityCaptureServer(db)
	router := activityCaptureRouter(s, &securityPrincipal{UserID: member, Roles: map[string]bool{}})
	req := httptest.NewRequest(http.MethodGet, "/v1/profile/"+viewed+"?ref=search", nil)
	req.RemoteAddr = "198.51.100.9:4444"
	req.Header.Set("X-Client-Platform", "ios")
	router.ServeHTTP(httptest.NewRecorder(), req)

	if len(db.inserted) != 1 {
		t.Fatalf("expected one row, got %d", len(db.inserted))
	}
	row := db.inserted[0]
	blob, _ := json.Marshal(row)
	if row["event_domain"] != activityDomainAPIRequest || row["ip_address"] != nil || strings.Contains(string(blob), "198.51.100.9") {
		t.Fatalf("reads are api_request telemetry without an IP: %s", blob)
	}
	if row["actor_user_id"] != member || row["user_id"] != viewed || row["source_platform"] != "ios" {
		t.Fatalf("read attribution: %s", blob)
	}
	if activityDetails(t, row)["action_key"] != "profile.view" || strings.Contains(string(blob), "ref=search") {
		t.Fatalf("read catalog/query: %s", blob)
	}
}

func TestAnonymousAndAdminRequestsAreNotMemberActions(t *testing.T) {
	db := &capturingActivityDB{}
	s := activityCaptureServer(db)
	router := activityCaptureRouter(s, nil)
	router.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/v1/swipe", nil))
	operator := securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"admin": true}}
	activityCaptureRouter(s, &operator).ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/v1/admin/activity", nil))
	for _, row := range db.inserted {
		if row["event_domain"] != activityDomainAPIRequest || row["ip_address"] != nil {
			t.Fatalf("not a member action: %v", row)
		}
	}
}

func TestVerifiedSignInIsAttributedToTheMember(t *testing.T) {
	member := uuid.NewString()
	db := &capturingActivityDB{}
	s := activityCaptureServer(db)
	router := activityCaptureRouter(s, nil)
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/login", strings.NewReader(`{"username":"a","password":"b"}`))
	req.Header.Set("X-Test-Verified-Member", member)
	router.ServeHTTP(httptest.NewRecorder(), req)
	row := db.inserted[0]
	details := activityDetails(t, row)
	if row["event_domain"] != activityDomainMemberAction || row["actor_user_id"] != member ||
		details["action_key"] != "auth.login" || details["attribution"] != "credential" {
		t.Fatalf("sign-in row: %v", row)
	}
	if strings.Contains(toString(details), "password") {
		t.Fatal("request body leaked")
	}
}

type failingActivityDB struct {
	capturingActivityDB
	failures int
	err      error
}

func (f *failingActivityDB) Insert(ctx context.Context, schema, table string, payload any) ([]map[string]any, error) {
	if f.failures > 0 {
		f.failures--
		return nil, f.err
	}
	return f.capturingActivityDB.Insert(ctx, schema, table, payload)
}

func TestMemberActionFallsBackToTheQueueWhenTheSyncWriteFails(t *testing.T) {
	db := &failingActivityDB{failures: 1, err: errors.New("context deadline exceeded")}
	s := activityCaptureServer(db)
	before := memberActionFallbackWrites.Load()
	member := uuid.NewString()
	activityCaptureRouter(s, &securityPrincipal{UserID: member, Roles: map[string]bool{}}).
		ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/v1/swipe", nil))
	if memberActionFallbackWrites.Load() != before+1 {
		t.Fatal("fallback was not counted")
	}
	// No fanout: the queue path writes through the store, which retries.
	if len(db.inserted) != 1 || db.inserted[0]["event_domain"] != activityDomainMemberAction {
		t.Fatalf("fallback row: %v", db.inserted)
	}
}

func TestMemberActionRetriesUnderTheActorOnForeignKeyFailure(t *testing.T) {
	db := &failingActivityDB{failures: 1, err: errors.New(`ERROR: insert violates foreign key constraint "activity_events_user_id_fkey" (SQLSTATE 23503)`)}
	s := activityCaptureServer(db)
	member, ghost := uuid.NewString(), uuid.NewString()
	activityCaptureRouter(s, &securityPrincipal{UserID: member, Roles: map[string]bool{}}).
		ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/v1/clubs/c1/members/"+ghost, nil))
	if len(db.inserted) != 1 || db.inserted[0]["user_id"] != member {
		t.Fatalf("retry row: %v", db.inserted)
	}
}

func TestActivityClientIPHonoursOnlyTrustedProxies(t *testing.T) {
	s := &Server{}
	cases := []struct {
		remote, xff, real, want string
	}{
		{"127.0.0.1:1", "203.0.113.5, 127.0.0.1", "", "203.0.113.5"},
		{"127.0.0.1:1", "127.0.0.1", "198.51.100.2", "198.51.100.2"},
		{"127.0.0.1:1", "", "", "127.0.0.1"},
		{"192.0.2.10:1", "203.0.113.5", "198.51.100.2", "192.0.2.10"}, // untrusted peer: headers ignored
		{"[::ffff:127.0.0.1]:1", "2001:db8::1", "", "2001:db8::1"},
		{"127.0.0.1:1", "not-an-ip, 127.0.0.1", "", "127.0.0.1"},
	}
	for _, c := range cases {
		req := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
		req.RemoteAddr = c.remote
		if c.xff != "" {
			req.Header.Set("X-Forwarded-For", c.xff)
		}
		if c.real != "" {
			req.Header.Set("X-Real-IP", c.real)
		}
		if got := s.activityClientIP(req); got != c.want {
			t.Errorf("%+v: got %q", c, got)
		}
	}
}

// ── Admin API contract ─────────────────────────────────────────────────────

func TestMemberActivityAdminRoutesAreRoleGated(t *testing.T) {
	member := uuid.NewString()
	paths := []string{"/v1/admin/activity", "/v1/admin/activity/stream", "/v1/admin/activity/catalog", "/v1/admin/members/" + member + "/activity"}
	for _, role := range []string{"admin", "ops_admin", "trust_safety", "moderator", "analyst"} {
		for _, path := range paths {
			principal := securityPrincipal{Roles: map[string]bool{role: true}}
			if !principalCanAccessAdminRoute(principal, "/v1", http.MethodGet, path) {
				t.Errorf("%s cannot read %s", role, path)
			}
		}
	}
	for _, role := range []string{"support", "finance", "member", ""} {
		for _, path := range paths {
			principal := securityPrincipal{Roles: map[string]bool{role: true}}
			if principalCanAccessAdminRoute(principal, "/v1", http.MethodGet, path) {
				t.Errorf("%q can read %s", role, path)
			}
		}
	}
	if principalCanAccessAdminRoute(securityPrincipal{Roles: map[string]bool{"analyst": true}}, "/v1", http.MethodPost, "/v1/admin/activity") {
		t.Error("analysts must not write")
	}
	if isMemberActivityAdminPath("members/x/activity/extra") || isMemberActivityAdminPath("activityz") {
		t.Error("path matcher too loose")
	}
}

// The security middleware refuses a role without access before the handler;
// an allowed role reaches it (503 here: no database in this test).
func TestMemberActivityRefusesRoleWithoutAccess(t *testing.T) {
	role := "support"
	testPrincipalResolver = func(*http.Request) (securityPrincipal, error) {
		return securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{role: true}}, nil
	}
	t.Cleanup(func() { testPrincipalResolver = nil })
	s := &Server{}
	s.cfg.APIPrefix = "/v1"
	router := chi.NewRouter()
	router.Use(s.securityMiddleware)
	router.Get("/v1/admin/activity", s.adminListMemberActivity)

	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/admin/activity", nil))
	if rec.Code != http.StatusForbidden {
		t.Fatalf("support: status %d", rec.Code)
	}
	role = "analyst"
	rec = httptest.NewRecorder()
	router.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/admin/activity", nil))
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("analyst: status %d %s", rec.Code, rec.Body.String())
	}
}

func TestMemberActivityFilterValidation(t *testing.T) {
	parse := func(query string) (memberActivityFilter, error) {
		return parseMemberActivityFilter(httptest.NewRequest(http.MethodGet, "/v1/admin/activity?"+query, nil))
	}
	f, err := parse("")
	if err != nil || len(f.Sources) != 4 || f.IncludeReads {
		t.Fatalf("defaults: %+v %v", f, err)
	}
	f, err = parse("source=request,security&include_reads=true&method=post&outcome=client_error&category=" + url.QueryEscape("Matches & chat"))
	if err != nil || len(f.Sources) != 2 || !f.Sources["security"] || !f.IncludeReads || f.Method != "POST" || f.Category != "Matches & chat" {
		t.Fatalf("parsed: %+v %v", f, err)
	}
	for _, bad := range []string{"member=nope", "source=web", "method=TRACE", "outcome=ok", "category=Fun", "include_reads=maybe"} {
		if _, err := parse(bad); err == nil {
			t.Errorf("%s accepted", bad)
		}
	}
}

func TestMemberActivityCursorRoundTrip(t *testing.T) {
	at := time.Date(2026, 10, 2, 9, 30, 1, 123456000, time.UTC)
	cursor := memberActivityCursor{At: at, Source: "request", ID: uuid.NewString()}
	decoded, err := decodeMemberActivityCursor(cursor.encode())
	if err != nil || !decoded.At.Equal(at) || decoded.Source != cursor.Source || decoded.ID != cursor.ID {
		t.Fatalf("round trip: %+v %v", decoded, err)
	}
	for _, bad := range []string{"%%%", "e30", "bm90LWpzb24"} {
		if _, err := decodeMemberActivityCursor(bad); err == nil {
			t.Errorf("cursor %q accepted", bad)
		}
	}
}

func TestMemberActivityUnionAppliesFiltersInsideEveryBranch(t *testing.T) {
	f := memberActivityFilter{Member: uuid.NewString(), Category: "Discovery", Sources: map[string]bool{}}
	for _, source := range memberActivitySources {
		f.Sources[source] = true
	}
	filter := newSQLFilter()
	union := buildMemberActivityUnion(f, memberActivityQueryOptions{
		From: time.Now().Add(-time.Hour), To: time.Now(), Q: "swipe",
	}, filter)
	// Four sources, each split into "member as subject" and "member as actor".
	if got := strings.Count(union, "UNION ALL"); got != 7 {
		t.Fatalf("expected 8 branches, got %d", got+1)
	}
	for _, column := range []string{"e.created_at >= $1", "s.occurred_at >= $1", "o.occurred_at >= $1",
		"e.user_id = $3", "e.actor_user_id = $3 AND (e.user_id IS NULL OR e.user_id <> $3)",
		"s.subject_user_id = $3", "s.actor_user_id = $3 AND (s.subject_user_id IS NULL OR s.subject_user_id <> $3)",
		"o.subject_user_id = $3", "o.actor_user_id = $3 AND (o.subject_user_id IS NULL OR o.subject_user_id <> $3)"} {
		if !strings.Contains(union, column) {
			t.Fatalf("missing per-branch condition %q", column)
		}
	}
	if strings.Count(union, "category = $4") != 8 {
		t.Fatal("category must be applied to each branch")
	}
	if !strings.Contains(union, "e.event_domain = 'member_action'") || strings.Contains(union, "e.event_domain IN ('member_action','api_request')") {
		t.Fatal("reads are excluded unless include_reads")
	}
}
