package mobile

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// Client crash/error reporting (client_errors.go, migration 122) and the
// request-telemetry minimisation that shipped with it.

func validClientErrorInput(now time.Time) clientErrorEventInput {
	return clientErrorEventInput{
		ErrorType:   "StateError",
		Message:     "Bad state: no element",
		Stack:       "#0      _DiscoverScreenState.build (package:verified_dating_app/features/discover/discover_screen.dart:120:7)\n#1      StatelessElement.build (package:flutter/src/widgets/framework.dart:5687:49)",
		Fatal:       true,
		Source:      "flutter",
		AppVersion:  "1.4.2",
		BuildNumber: "57",
		Platform:    "android",
		OSVersion:   "Android 14",
		DeviceClass: "phone",
		Locale:      "en_IN",
		Screen:      "/discover",
		OccurredAt:  now.Add(-time.Minute).Format(time.RFC3339),
	}
}

func TestNormaliseClientErrorEventScrubsPersonalData(t *testing.T) {
	now := time.Now().UTC()
	in := validClientErrorInput(now)
	in.Message = "Failed for priya@example.com / +91 98765 43210 token=abcDEF123456 on https://api.example.com/v1/profile/3fa85f64-5717-4562-b3fc-2c963f66afa6?lat=18.52&lng=73.85"
	var stack []string
	for i := 0; i < 80; i++ {
		stack = append(stack, fmt.Sprintf("#%d      frame%d (package:verified_dating_app/a.dart:%d:1)", i, i, i))
	}
	in.Stack = strings.Join(stack, "\n")
	in.Screen = "/profile/3fa85f64-5717-4562-b3fc-2c963f66afa6?tab=photos"
	for i := 0; i < 30; i++ {
		in.Breadcrumbs = append(in.Breadcrumbs, clientErrorBreadcrumbInput{
			At: now.Format(time.RFC3339), Category: "api",
			Message: fmt.Sprintf("GET /v1/matches/%d/messages?cursor=abc -> 200", 1000+i),
		})
	}

	event, reason := normaliseClientErrorEvent(in, now)
	if reason != "" {
		t.Fatalf("valid event rejected: %s", reason)
	}
	blob, _ := json.Marshal(event)
	for _, leak := range []string{"priya@example.com", "98765", "abcDEF123456", "3fa85f64", "lat=18.52", "cursor=abc", "/matches/1029"} {
		if strings.Contains(string(blob), leak) {
			t.Fatalf("scrubbed event still contains %q: %s", leak, blob)
		}
	}
	if got := strings.Count(event.Stack, "\n") + 1; got != clientErrorMaxStackLines {
		t.Fatalf("stack keeps %d lines, want %d", got, clientErrorMaxStackLines)
	}
	if event.Screen != "/profile/{id}" {
		t.Fatalf("screen %q", event.Screen)
	}
	if len(event.Breadcrumbs) != clientErrorMaxBreadcrumbs || !strings.Contains(event.Breadcrumbs[0].Message, "/v1/matches/{id}/messages") {
		t.Fatalf("breadcrumbs not trimmed to the last %d with ids stripped: %+v", clientErrorMaxBreadcrumbs, event.Breadcrumbs[0])
	}
	if event.Fingerprint == "" || event.Culprit == "" || !strings.HasPrefix(event.Title, "StateError: ") {
		t.Fatalf("grouping fields missing: %+v", event)
	}
}

func TestNormaliseClientErrorEventValidation(t *testing.T) {
	now := time.Now().UTC()
	cases := map[string]func(*clientErrorEventInput){
		"missing_error_type":  func(in *clientErrorEventInput) { in.ErrorType = "  " },
		"invalid_platform":    func(in *clientErrorEventInput) { in.Platform = "symbian" },
		"invalid_app_version": func(in *clientErrorEventInput) { in.AppVersion = "1.0 beta; DROP TABLE" },
		"stale":               func(in *clientErrorEventInput) { in.OccurredAt = now.Add(-8 * 24 * time.Hour).Format(time.RFC3339) },
	}
	for want, mutate := range cases {
		in := validClientErrorInput(now)
		mutate(&in)
		if _, reason := normaliseClientErrorEvent(in, now); reason != want {
			t.Errorf("%s: got reason %q", want, reason)
		}
	}

	in := validClientErrorInput(now)
	in.OccurredAt = now.Add(48 * time.Hour).Format(time.RFC3339)
	in.DeviceClass, in.Source, in.Locale, in.BuildNumber = "Pixel 8 Pro", "magic", "not a locale!", "build#1"
	event, reason := normaliseClientErrorEvent(in, now)
	if reason != "" {
		t.Fatal(reason)
	}
	if !event.OccurredAt.Equal(now) {
		t.Fatalf("a future timestamp is clamped to receipt time, got %v", event.OccurredAt)
	}
	if event.DeviceClass != "unknown" || event.Source != "unknown" || event.Locale != "" || event.BuildNumber != "" {
		t.Fatalf("free-form device fields must not be stored: %+v", event)
	}
}

func TestClientErrorFingerprintGroupsAcrossBuilds(t *testing.T) {
	a, culpritA := clientErrorFingerprint("RangeError", "Index out of range: index 7, length 3",
		"#0      List.[] (dart:core-patch/growable_array.dart:264:36)\n#1      _ChatState.build (package:verified_dating_app/chat.dart:88:12)")
	b, culpritB := clientErrorFingerprint("RangeError", "Index out of range: index 12, length 4",
		"#0      List.[] (dart:core-patch/growable_array.dart:270:2)\n#1      _ChatState.build (package:verified_dating_app/chat.dart:91:3)")
	if a != b {
		t.Fatal("same fault with different numbers and line numbers must group together")
	}
	if !strings.Contains(culpritA, "_ChatState.build") || culpritA != culpritB {
		t.Fatalf("culprit should be the first app frame, got %q", culpritA)
	}
	c, _ := clientErrorFingerprint("StateError", "Index out of range: index 7, length 3", "")
	if c == a {
		t.Fatal("a different error type is a different issue")
	}
	d, _ := clientErrorFingerprint("RangeError", "Index out of range: index 7, length 3",
		"#0      _ProfileState.build (package:verified_dating_app/profile.dart:10:1)")
	if d == a {
		t.Fatal("a different app frame is a different issue")
	}
}

func TestCompareAppVersions(t *testing.T) {
	cases := []struct {
		a, b string
		want int
	}{
		{"1.10.0", "1.9.3", 1}, {"1.4.2", "1.4.2+58", 0}, {"1.4", "1.4.1", -1}, {"2.0.0", "10.0.0", -1}, {"1.4.2-beta", "1.4.2", 1},
	}
	for _, tc := range cases {
		if got := compareAppVersions(tc.a, tc.b); got != tc.want {
			t.Errorf("compare(%s,%s)=%d want %d", tc.a, tc.b, got, tc.want)
		}
	}
}

func TestClientErrorRateLimiterIsAllOrNothing(t *testing.T) {
	now := time.Date(2026, 10, 1, 12, 0, 0, 0, time.UTC)
	limiter := newClientErrorRateLimiter(func() time.Time { return now })
	install := clientErrorRateRule{key: "install:a", limit: 5, window: 10 * time.Minute}
	ip := clientErrorRateRule{key: "ip:a", limit: 8, window: 10 * time.Minute}
	if ok, _ := limiter.allow([]clientErrorRateRule{install, ip}, 5); !ok {
		t.Fatal("first batch fits")
	}
	ok, wait := limiter.allow([]clientErrorRateRule{install, ip}, 1)
	if ok || wait <= 0 || wait > 10*time.Minute {
		t.Fatalf("install budget exhausted: ok=%v wait=%v", ok, wait)
	}
	// Another install behind the same IP still has the IP's remaining budget
	// (3), and the rejected batch above consumed nothing.
	other := clientErrorRateRule{key: "install:b", limit: 5, window: 10 * time.Minute}
	if ok, _ := limiter.allow([]clientErrorRateRule{other, ip}, 3); !ok {
		t.Fatal("ip budget should have 3 left")
	}
	if ok, _ := limiter.allow([]clientErrorRateRule{other, ip}, 1); ok {
		t.Fatal("ip budget exhausted")
	}
	now = now.Add(11 * time.Minute)
	if ok, _ := limiter.allow([]clientErrorRateRule{install, ip}, 5); !ok {
		t.Fatal("window resets")
	}
}

func clientErrorBody(t *testing.T, installID string, events ...clientErrorEventInput) string {
	t.Helper()
	raw, err := json.Marshal(clientErrorBatchInput{InstallID: installID, Events: events})
	if err != nil {
		t.Fatal(err)
	}
	return string(raw)
}

func postClientErrors(s *Server, body, remoteAddr, authorization string) *httptest.ResponseRecorder {
	r := httptest.NewRequest(http.MethodPost, "/v1/client/errors", strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	r.RemoteAddr = remoteAddr
	if authorization != "" {
		r.Header.Set("Authorization", authorization)
	}
	rec := httptest.NewRecorder()
	s.reportClientErrors(rec, r)
	return rec
}

func TestReportClientErrorsRequestValidation(t *testing.T) {
	s := &Server{}
	now := time.Now().UTC()
	event := validClientErrorInput(now)
	install := "install-" + strings.ReplaceAll(uuid.NewString(), "-", "")
	many := make([]clientErrorEventInput, clientErrorMaxEvents+1)
	for i := range many {
		many[i] = event
	}
	cases := []struct {
		name string
		body string
		want int
	}{
		{"malformed", `{"install_id":`, http.StatusBadRequest},
		{"short install id", clientErrorBody(t, "abc", event), http.StatusBadRequest},
		{"no events", clientErrorBody(t, install), http.StatusBadRequest},
		{"too many events", clientErrorBody(t, install, many...), http.StatusBadRequest},
		{"too large", `{"install_id":"` + install + `","events":[{"message":"` + strings.Repeat("x", clientErrorMaxBodyBytes) + `"}]}`, http.StatusRequestEntityTooLarge},
	}
	for _, tc := range cases {
		if rec := postClientErrors(s, tc.body, "203.0.113.9:4000", ""); rec.Code != tc.want {
			t.Errorf("%s: status %d want %d (%s)", tc.name, rec.Code, tc.want, rec.Body.String())
		}
	}

	// Every event invalid: nothing to store, so no database is needed.
	bad := event
	bad.Platform = "symbian"
	rec := postClientErrors(s, clientErrorBody(t, install, bad), "203.0.113.9:4000", "")
	var out map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	if rec.Code != http.StatusAccepted || out["accepted"] != float64(0) || out["dropped"] != float64(1) {
		t.Fatalf("all-invalid batch: %d %v", rec.Code, out)
	}
	// Valid events without persistence fail closed.
	if rec := postClientErrors(s, clientErrorBody(t, install, event), "203.0.113.9:4000", ""); rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("no persistence: %d", rec.Code)
	}
}

func TestReportClientErrorsAnonymousAndSignedInRateLimits(t *testing.T) {
	s := &Server{}
	now := time.Now().UTC()
	bad := validClientErrorInput(now)
	bad.Platform = "symbian" // rejected after the rate check, so no database is touched
	batch := make([]clientErrorEventInput, 20)
	for i := range batch {
		batch[i] = bad
	}

	// Anonymous: three installs behind one IP share the IP's 60-event budget.
	for i := 0; i < 3; i++ {
		install := fmt.Sprintf("anon-install-%016d", i)
		if rec := postClientErrors(s, clientErrorBody(t, install, batch...), "198.51.100.7:1234", ""); rec.Code != http.StatusAccepted {
			t.Fatalf("anonymous batch %d: %d", i, rec.Code)
		}
	}
	rec := postClientErrors(s, clientErrorBody(t, "anon-install-fourth-0000", batch[:1]...), "198.51.100.7:1234", "")
	if rec.Code != http.StatusTooManyRequests || rec.Header().Get("Retry-After") == "" {
		t.Fatalf("IP budget exhausted: %d retry-after=%q", rec.Code, rec.Header().Get("Retry-After"))
	}
	// The X-Forwarded-For entry our gateway appends is the key, not the hop.
	r := httptest.NewRequest(http.MethodPost, "/v1/client/errors", nil)
	r.RemoteAddr = "10.0.0.2:5555"
	r.Header.Set("X-Forwarded-For", "spoofed, 192.0.2.44")
	if got := clientIPForRateLimit(r); got != "192.0.2.44" {
		t.Fatalf("rate-limit IP %q", got)
	}

	// Signed in: the account budget applies instead of the shared IP budget,
	// and the caller's identity headers are never trusted.
	member := uuid.NewString()
	testPrincipalResolver = func(r *http.Request) (securityPrincipal, error) {
		if r.Header.Get("Authorization") == "Bearer good" {
			return securityPrincipal{UserID: member, Roles: map[string]bool{"user": true}}, nil
		}
		return securityPrincipal{}, fmt.Errorf("invalid session")
	}
	t.Cleanup(func() { testPrincipalResolver = nil })
	for i := 0; i < 3; i++ {
		install := fmt.Sprintf("member-install-%016d", i)
		if rec := postClientErrors(s, clientErrorBody(t, install, batch...), "198.51.100.7:1234", "Bearer good"); rec.Code != http.StatusAccepted {
			t.Fatalf("signed-in batch %d from an exhausted IP: %d", i, rec.Code)
		}
	}
	// An expired session is simply anonymous — and that IP is exhausted.
	if rec := postClientErrors(s, clientErrorBody(t, "member-install-expired-01", batch[:1]...), "198.51.100.7:1234", "Bearer expired"); rec.Code != http.StatusTooManyRequests {
		t.Fatalf("invalid bearer falls back to anonymous limits: %d", rec.Code)
	}
	// One install cannot exceed its own budget even when signed in.
	for i := 0; i < 3; i++ {
		postClientErrors(s, clientErrorBody(t, "member-install-loop-000001", batch...), "192.0.2.1:1", "Bearer good")
	}
	if rec := postClientErrors(s, clientErrorBody(t, "member-install-loop-000001", batch[:1]...), "192.0.2.1:1", "Bearer good"); rec.Code != http.StatusTooManyRequests {
		t.Fatalf("install budget: %d", rec.Code)
	}
}

func TestClientErrorRoutesSecurityAndReplay(t *testing.T) {
	if !isPublicSecurityPath("/v1", "/v1/client/errors", http.MethodPost) {
		t.Fatal("crash reports must be accepted from signed-out screens")
	}
	if isPublicSecurityPath("/v1", "/v1/client/errors", http.MethodGet) || isPublicSecurityPath("/v1", "/v1/admin/client-errors", http.MethodGet) {
		t.Fatal("only the ingestion POST is public")
	}
	s := &Server{}
	s.cfg.APIPrefix = "/v1"
	if s.shouldApplyIdempotency(httptest.NewRequest(http.MethodPost, "/v1/client/errors", nil)) {
		t.Fatal("anonymous telemetry must not enter the replay ledger")
	}
	if !s.shouldApplyIdempotency(httptest.NewRequest(http.MethodPost, "/v1/admin/client-errors/x/status", nil)) {
		t.Fatal("operator status changes keep replay protection")
	}
	role := func(r string) securityPrincipal {
		return securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{r: true}}
	}
	list, status := "/v1/admin/client-errors", "/v1/admin/client-errors/"+uuid.NewString()+"/status"
	checks := []struct {
		role, method, path string
		want               bool
	}{
		{"admin", http.MethodPost, status, true},
		{"ops_admin", http.MethodPost, status, true},
		{"ops_admin", http.MethodGet, list, true},
		{"analyst", http.MethodGet, list, true},
		{"analyst", http.MethodPost, status, false},
		{"moderator", http.MethodGet, list, false},
		{"trust_safety", http.MethodGet, list, false},
	}
	for _, c := range checks {
		if got := principalCanAccessAdminRoute(role(c.role), "/v1", c.method, c.path); got != c.want {
			t.Errorf("%s %s %s = %v want %v", c.role, c.method, c.path, got, c.want)
		}
	}
}

func TestReportClientErrorsDropsIdentityHeaders(t *testing.T) {
	s := &Server{}
	r := httptest.NewRequest(http.MethodPost, "/v1/client/errors", strings.NewReader(`{}`))
	r.Header.Set("X-User-ID", uuid.NewString())
	r.Header.Set("X-Admin-User", uuid.NewString())
	s.reportClientErrors(httptest.NewRecorder(), r)
	if r.Header.Get("X-User-ID") != "" || r.Header.Get("X-Admin-User") != "" {
		t.Fatal("caller-supplied identity headers must not reach request telemetry")
	}
}

// ── Request telemetry minimisation ───────────────────────────────────────

type capturingActivityDB struct{ inserted []map[string]any }

func (c *capturingActivityDB) Select(context.Context, string, string, url.Values) ([]map[string]any, error) {
	return nil, nil
}
func (c *capturingActivityDB) SelectRead(context.Context, string, string, url.Values) ([]map[string]any, error) {
	return nil, nil
}
func (c *capturingActivityDB) Insert(_ context.Context, _ string, _ string, payload any) ([]map[string]any, error) {
	rows, _ := payload.([]map[string]any)
	c.inserted = append(c.inserted, rows...)
	return nil, nil
}
func (c *capturingActivityDB) Upsert(context.Context, string, string, any, string) ([]map[string]any, error) {
	return nil, nil
}
func (c *capturingActivityDB) Update(context.Context, string, string, any, url.Values) ([]map[string]any, error) {
	return nil, nil
}
func (c *capturingActivityDB) Delete(context.Context, string, string, url.Values) ([]map[string]any, error) {
	return nil, nil
}

func TestActivityMiddlewareStoresRouteTemplateWithoutIPOrQuery(t *testing.T) {
	member := uuid.NewString()
	db := &capturingActivityDB{}
	s := &Server{store: &runtimeStore{activityRepo: &activityRepository{db: db}}}
	s.cfg.APIPrefix = "/v1"

	router := chi.NewRouter()
	router.Use(s.activityMiddleware)
	router.Route("/v1", func(v1 chi.Router) {
		v1.Get("/discovery/{userID}", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })
	})
	req := httptest.NewRequest(http.MethodGet, "/v1/discovery/"+member+"?lat=18.5204&lng=73.8567&q=priya%40example.com", nil)
	req.RemoteAddr = "203.0.113.77:51234"
	req.Header.Set("X-User-ID", member)
	router.ServeHTTP(httptest.NewRecorder(), req)

	if len(db.inserted) != 1 {
		t.Fatalf("expected one activity row, got %d", len(db.inserted))
	}
	row := db.inserted[0]
	blob, _ := json.Marshal(row)
	for _, leak := range []string{"203.0.113.77", "lat=", "18.5204", "priya", "remote_addr", `"query"`, "/v1/discovery/" + member} {
		if strings.Contains(string(blob), leak) {
			t.Fatalf("request telemetry still stores %q: %s", leak, blob)
		}
	}
	if row["event_name"] != "GET /v1/discovery/{userID}" || row["event_domain"] != activityDomainAPIRequest {
		t.Fatalf("route template and api_request domain expected: %s", blob)
	}
	if row["user_id"] != member || row["actor_user_id"] != member {
		t.Fatalf("member columns still identify the request owner: %s", blob)
	}
	payload, _ := row["payload"].(map[string]any)
	if payload["resource"] != "/v1/discovery/{userID}" {
		t.Fatalf("resource %v", payload["resource"])
	}

	// Domain events written elsewhere keep their own domain.
	if _, err := s.store.activityRepo.recordActivityEvent(context.Background(), activityEvent{Action: "wallet.coins.purchase"}); err != nil {
		t.Fatal(err)
	}
	if got := db.inserted[1]["event_domain"]; got != "mobile_bff" {
		t.Fatalf("domain events stay mobile_bff, got %v", got)
	}
}

func TestAccountErasureAndExportCoverRequestTelemetry(t *testing.T) {
	steps := accountErasureStepSQL()
	if !strings.Contains(steps, "api_request_telemetry DELETE FROM matching.activity_events WHERE event_domain='api_request'") {
		t.Fatal("erasure must delete the member's request telemetry")
	}
	if !strings.Contains(steps, "activity_event_context") {
		t.Fatal("erasure must strip network context from the member's other activity events")
	}
	var section string
	for _, s := range accountExportSections() {
		if s.name == "api_activity_summary" {
			section = strings.ToLower(s.query)
		}
	}
	if section == "" {
		t.Fatal("export has no api_activity_summary section")
	}
	for _, forbidden := range []string{"payload", "ip_address", "remote_addr", "event_name"} {
		if strings.Contains(section, forbidden) {
			t.Fatalf("the export summary must be counts only, found %q", forbidden)
		}
	}
}

// ── Postgres ──────────────────────────────────────────────────────────────

func clientErrorTestDB(t *testing.T) *sql.DB {
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
	var ready bool
	if err := db.QueryRow(`SELECT to_regclass('platform.client_error_issues') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 122_client_error_reporting_and_telemetry_privacy is not applied")
	}
	return db
}

func clientErrorServer(db *sql.DB) *Server {
	return &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: db}}}
}

func operatorRoleRequest(method, target, body, role string, params map[string]string) *http.Request {
	r := httptest.NewRequest(method, target, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	rc := chi.NewRouteContext()
	for k, v := range params {
		rc.URLParams.Add(k, v)
	}
	ctx := context.WithValue(r.Context(), chi.RouteCtxKey, rc)
	ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{role: true}})
	return r.WithContext(ctx)
}

func decodeRecorder(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	out := map[string]any{}
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatalf("decode %d %s: %v", rec.Code, rec.Body.String(), err)
	}
	return out
}

func TestClientErrorIngestionGroupingAndAdminPostgres(t *testing.T) {
	db := clientErrorTestDB(t)
	s := clientErrorServer(db)
	now := time.Now().UTC()
	marker := strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	errorType := "QaGroupingError" + marker
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM platform.client_error_issues WHERE error_type LIKE 'QaGroupingError'||$1||'%'`, marker)
	})

	event := validClientErrorInput(now)
	event.ErrorType = errorType
	event.AppVersion = "9.1." + marker[:4]
	event.Message = "Failed loading match 42 for someone@example.com"
	second := event
	second.Message = "Failed loading match 97 for other@example.com"
	second.Stack = strings.ReplaceAll(event.Stack, ":120:7", ":133:2")
	second.Platform, second.Fatal = "ios", false
	installA, installB := "qa-install-a-"+marker, "qa-install-b-"+marker

	if rec := postClientErrors(s, clientErrorBody(t, installA, event, second), "192.0.2.10:1", ""); rec.Code != http.StatusAccepted {
		t.Fatalf("ingest: %d %s", rec.Code, rec.Body.String())
	}
	if rec := postClientErrors(s, clientErrorBody(t, installB, event), "192.0.2.11:1", ""); rec.Code != http.StatusAccepted {
		t.Fatalf("ingest b: %d %s", rec.Code, rec.Body.String())
	}

	var issueID string
	var count, users int64
	var fatal bool
	var platforms string
	if err := db.QueryRow(`SELECT id::text, occurrence_count, affected_users, fatal, array_to_string(platforms,',')
		FROM platform.client_error_issues WHERE error_type=$1`, errorType).Scan(&issueID, &count, &users, &fatal, &platforms); err != nil {
		t.Fatalf("one grouped issue expected: %v", err)
	}
	if count != 3 || users != 2 || !fatal || platforms != "android,ios" {
		t.Fatalf("issue counts=%d users=%d fatal=%v platforms=%s", count, users, fatal, platforms)
	}
	// Install A's second event is the same issue within the crash-loop window:
	// counted, but only one occurrence stored per install.
	var stored int
	var leaked bool
	if err := db.QueryRow(`SELECT COUNT(*), bool_or(message LIKE '%@example.com%' OR reporter_key LIKE 'qa-install%')
		FROM platform.client_error_occurrences WHERE issue_id=$1::uuid`, issueID).Scan(&stored, &leaked); err != nil {
		t.Fatal(err)
	}
	if stored != 2 || leaked {
		t.Fatalf("stored occurrences=%d leaked=%v", stored, leaked)
	}

	// Admin list: filtered by this run's version, sorted by count.
	rec := httptest.NewRecorder()
	s.adminListClientErrors(rec, operatorRoleRequest(http.MethodGet, "/v1/admin/client-errors?status=all&sort=count&platform=ios&version="+event.AppVersion, "", "ops_admin", nil))
	list := decodeRecorder(t, rec)
	issues, _ := list["issues"].([]any)
	if rec.Code != http.StatusOK || len(issues) != 1 || list["total"] != float64(1) {
		t.Fatalf("list: %d %v", rec.Code, list)
	}
	first := issues[0].(map[string]any)
	if first["id"] != issueID || first["affected_users"] != float64(2) || first["status"] != "open" {
		t.Fatalf("listed issue %v", first)
	}
	rec = httptest.NewRecorder()
	s.adminListClientErrors(rec, operatorRoleRequest(http.MethodGet, "/v1/admin/client-errors?status=all&fatal=false&version="+event.AppVersion+"&platform=android", "", "ops_admin", nil))
	if got := decodeRecorder(t, rec)["issues"].([]any); len(got) != 0 {
		t.Fatalf("fatal=false must exclude a fatal issue: %v", got)
	}
	for _, bad := range []string{"status=nope", "platform=symbian", "sort=random", "fatal=maybe"} {
		rec = httptest.NewRecorder()
		s.adminListClientErrors(rec, operatorRoleRequest(http.MethodGet, "/v1/admin/client-errors?"+bad, "", "ops_admin", nil))
		if rec.Code != http.StatusBadRequest {
			t.Errorf("%s: %d", bad, rec.Code)
		}
	}

	// Detail.
	rec = httptest.NewRecorder()
	s.adminGetClientError(rec, operatorRoleRequest(http.MethodGet, "/", "", "analyst", map[string]string{"issueID": issueID}))
	detail := decodeRecorder(t, rec)
	if rec.Code != http.StatusOK || len(detail["occurrences"].([]any)) != 2 || len(detail["versions"].([]any)) != 2 {
		t.Fatalf("detail: %d %v", rec.Code, detail)
	}
	occ := detail["occurrences"].([]any)[0].(map[string]any)
	for _, key := range []string{"stack", "breadcrumbs", "device_class", "screen", "signed_in"} {
		if _, ok := occ[key]; !ok {
			t.Fatalf("occurrence missing %s: %v", key, occ)
		}
	}
	rec = httptest.NewRecorder()
	s.adminGetClientError(rec, operatorRoleRequest(http.MethodGet, "/", "", "analyst", map[string]string{"issueID": uuid.NewString()}))
	if rec.Code != http.StatusNotFound {
		t.Fatalf("missing issue: %d", rec.Code)
	}

	// Status changes.
	setStatus := func(body string) (int, map[string]any) {
		rec := httptest.NewRecorder()
		s.adminSetClientErrorStatus(rec, operatorRoleRequest(http.MethodPost, "/", body, "ops_admin", map[string]string{"issueID": issueID}))
		return rec.Code, decodeRecorder(t, rec)
	}
	if code, _ := setStatus(`{"status":"closed"}`); code != http.StatusBadRequest {
		t.Fatalf("unknown status: %d", code)
	}
	if code, _ := setStatus(`{"status":"ignored","resolved_in_version":"1.0.0"}`); code != http.StatusBadRequest {
		t.Fatalf("a fix version only accompanies resolved: %d", code)
	}
	code, out := setStatus(`{"status":"ignored","note":"Known emulator-only fault"}`)
	if code != http.StatusOK || out["issue"].(map[string]any)["status"] != "ignored" {
		t.Fatalf("ignore: %d %v", code, out)
	}
	// Ignored issues keep counting but store nothing new.
	if rec := postClientErrors(s, clientErrorBody(t, "qa-install-c-"+marker, event), "192.0.2.12:1", ""); rec.Code != http.StatusAccepted {
		t.Fatal(rec.Body.String())
	}
	if err := db.QueryRow(`SELECT COUNT(*) FROM platform.client_error_occurrences WHERE issue_id=$1::uuid`, issueID).Scan(&stored); err != nil || stored != 2 {
		t.Fatalf("ignored issue stored a new occurrence: %d %v", stored, err)
	}
}

func TestClientErrorRegressionReopensResolvedIssuePostgres(t *testing.T) {
	db := clientErrorTestDB(t)
	s := clientErrorServer(db)
	now := time.Now().UTC()
	marker := strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM platform.client_error_issues WHERE error_type LIKE 'QaRegression%'||$1`, marker)
	})
	ingest := func(errorType, version, install string) {
		t.Helper()
		event := validClientErrorInput(now)
		event.ErrorType, event.AppVersion = errorType, version
		if rec := postClientErrors(s, clientErrorBody(t, install, event), "192.0.2.20:1", ""); rec.Code != http.StatusAccepted {
			t.Fatalf("ingest %s: %d %s", version, rec.Code, rec.Body.String())
		}
	}
	state := func(errorType string) (string, bool) {
		t.Helper()
		var status string
		var regressed bool
		if err := db.QueryRow(`SELECT status, regressed FROM platform.client_error_issues WHERE error_type=$1`, errorType).Scan(&status, &regressed); err != nil {
			t.Fatal(err)
		}
		return status, regressed
	}
	resolve := func(errorType, body string) {
		t.Helper()
		var id string
		if err := db.QueryRow(`SELECT id::text FROM platform.client_error_issues WHERE error_type=$1`, errorType).Scan(&id); err != nil {
			t.Fatal(err)
		}
		rec := httptest.NewRecorder()
		s.adminSetClientErrorStatus(rec, operatorRoleRequest(http.MethodPost, "/", body, "admin", map[string]string{"issueID": id}))
		if rec.Code != http.StatusOK {
			t.Fatalf("resolve: %d %s", rec.Code, rec.Body.String())
		}
	}

	// With a fix version: older builds still in the field do not reopen it;
	// the fix version (or later) does.
	withFix := "QaRegressionFix" + marker
	ingest(withFix, "2.0.0", "qa-reg-install-1-"+marker)
	resolve(withFix, `{"status":"resolved","resolved_in_version":"2.1.0"}`)
	ingest(withFix, "2.0.0", "qa-reg-install-2-"+marker)
	if status, _ := state(withFix); status != "resolved" {
		t.Fatalf("an older build must not reopen a fixed issue, status %s", status)
	}
	ingest(withFix, "2.1.3", "qa-reg-install-3-"+marker)
	if status, regressed := state(withFix); status != "open" || !regressed {
		t.Fatalf("the fixed version reporting it is a regression: %s %v", status, regressed)
	}

	// Without a fix version: a version not seen before resolution reopens it.
	noFix := "QaRegressionNoFix" + marker
	ingest(noFix, "3.0.0", "qa-reg-install-4-"+marker)
	resolve(noFix, `{"status":"resolved"}`)
	ingest(noFix, "3.0.0", "qa-reg-install-5-"+marker)
	if status, _ := state(noFix); status != "resolved" {
		t.Fatalf("an already-known version does not reopen: %s", status)
	}
	ingest(noFix, "3.0.1", "qa-reg-install-6-"+marker)
	if status, regressed := state(noFix); status != "open" || !regressed {
		t.Fatalf("a new version reporting it reopens: %s %v", status, regressed)
	}
}

func TestClientErrorOccurrenceCapPostgres(t *testing.T) {
	db := clientErrorTestDB(t)
	marker := strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM platform.client_error_issues WHERE error_type=$1`, "QaCap"+marker)
	})
	now := time.Now().UTC()
	input := validClientErrorInput(now)
	input.ErrorType = "QaCap" + marker
	event, reason := normaliseClientErrorEvent(input, now)
	if reason != "" {
		t.Fatal(reason)
	}
	for i := 0; i < clientErrorMaxStoredOccurrences+7; i++ {
		key := fmt.Sprintf("%064x", i+1)
		if err := ingestClientErrors(context.Background(), db, []clientErrorEvent{event}, key, false, now.Add(time.Duration(i)*time.Second)); err != nil {
			t.Fatal(err)
		}
	}
	var stored int
	var total, users int64
	if err := db.QueryRow(`SELECT (SELECT COUNT(*) FROM platform.client_error_occurrences o WHERE o.issue_id=i.id), i.occurrence_count, i.affected_users
		FROM platform.client_error_issues i WHERE i.error_type=$1`, "QaCap"+marker).Scan(&stored, &total, &users); err != nil {
		t.Fatal(err)
	}
	if stored != clientErrorMaxStoredOccurrences || total != int64(clientErrorMaxStoredOccurrences+7) || users != total {
		t.Fatalf("stored=%d total=%d users=%d", stored, total, users)
	}
}

func TestClientTelemetryRetentionPostgres(t *testing.T) {
	db := clientErrorTestDB(t)
	ctx := context.Background()
	member, held := uuid.NewString(), uuid.NewString()
	for _, id := range []string{member, held} {
		if _, err := db.ExecContext(ctx, `INSERT INTO user_management.users (id,username,name,date_of_birth,gender,email)
			VALUES ($1,$2,'Retention QA','1990-01-01','female',$3)`, id, "retqa_"+strings.ReplaceAll(id[:8], "-", ""), id+"@example.test"); err != nil {
			t.Fatal(err)
		}
	}
	operator := uuid.NewString()
	if _, err := db.ExecContext(ctx, `INSERT INTO platform.legal_holds (user_id,reason,placed_by) VALUES ($1,'Retention QA hold',$2)`, held, operator); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM matching.activity_events WHERE user_id IN ($1,$2)`, member, held)
		_, _ = db.Exec(`DELETE FROM platform.legal_holds WHERE user_id=$1`, held)
		_, _ = db.Exec(`DELETE FROM user_management.users WHERE id IN ($1,$2)`, member, held)
	})
	insertEvent := func(user, createdAt string) string {
		var id string
		if err := db.QueryRowContext(ctx, `INSERT INTO matching.activity_events (event_name,event_domain,user_id,payload,created_at)
			VALUES ('GET /v1/profile/{userID}','api_request',$1,'{}'::jsonb,$2::timestamptz) RETURNING id::text`, user, createdAt).Scan(&id); err != nil {
			t.Fatal(err)
		}
		return id
	}
	// The oldest rows in the table, so a batch of one reaches them first.
	heldOld := insertEvent(held, "1999-01-01T00:00:00Z")
	expired := insertEvent(member, "2000-01-01T00:00:00Z")
	recent := insertEvent(member, time.Now().UTC().Format(time.RFC3339))

	marker := strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	var issueID string
	if err := db.QueryRowContext(ctx, `INSERT INTO platform.client_error_issues (fingerprint,error_type,title,first_seen_at,last_seen_at)
		VALUES ($1,'QaRetention','QaRetention','2000-01-01','2000-01-01') RETURNING id::text`, "qa-retention-"+marker).Scan(&issueID); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _, _ = db.Exec(`DELETE FROM platform.client_error_issues WHERE id=$1::uuid`, issueID) })
	if _, err := db.ExecContext(ctx, `INSERT INTO platform.client_error_occurrences (issue_id,occurred_at,received_at,app_version,platform,reporter_key)
		VALUES ($1::uuid,'2000-01-01','2000-01-01','1.0.0','android',$2)`, issueID, fmt.Sprintf("%064d", 7)); err != nil {
		t.Fatal(err)
	}

	apiRows, occurrences, issues, err := runClientTelemetryRetention(ctx, db, 1)
	if err != nil {
		t.Fatal(err)
	}
	if apiRows != 1 || occurrences != 1 || issues != 1 {
		t.Fatalf("retention removed api=%d occurrences=%d issues=%d", apiRows, occurrences, issues)
	}
	exists := func(id string) bool {
		var ok bool
		_ = db.QueryRow(`SELECT EXISTS(SELECT 1 FROM matching.activity_events WHERE id=$1::uuid)`, id).Scan(&ok)
		return ok
	}
	if exists(expired) || !exists(recent) || !exists(heldOld) {
		t.Fatalf("expired gone=%v recent kept=%v held kept=%v", !exists(expired), exists(recent), exists(heldOld))
	}
	var issueLeft bool
	_ = db.QueryRow(`SELECT EXISTS(SELECT 1 FROM platform.client_error_issues WHERE id=$1::uuid)`, issueID).Scan(&issueLeft)
	if issueLeft {
		t.Fatal("an issue not seen for 90 days is removed")
	}
}

func TestAccountErasureMinimisesActivityEventsPostgres(t *testing.T) {
	db := clientErrorTestDB(t)
	ctx := context.Background()
	member, other := uuid.NewString(), uuid.NewString()
	for _, id := range []string{member, other} {
		if _, err := db.ExecContext(ctx, `INSERT INTO user_management.users (id,username,name,date_of_birth,gender,email)
			VALUES ($1,$2,'Erasure QA','1990-01-01','female',$3)`, id, "erqa_"+strings.ReplaceAll(id[:8], "-", ""), id+"@example.test"); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM matching.activity_events WHERE user_id IN ($1,$2) OR actor_user_id IN ($1,$2)`, member, other)
		_, _ = db.Exec(`DELETE FROM user_management.users WHERE id IN ($1,$2)`, member, other)
	})
	insert := func(domain, user, actor string, payload string) string {
		var id string
		if err := db.QueryRowContext(ctx, `INSERT INTO matching.activity_events (event_name,event_domain,user_id,actor_user_id,payload,ip_address)
			VALUES ('evt',$1,$2,$3,$4::jsonb,'203.0.113.5') RETURNING id::text`, domain, user, actor, payload).Scan(&id); err != nil {
			t.Fatal(err)
		}
		return id
	}
	ownRequest := insert("api_request", member, member, `{}`)
	actorRequest := insert("api_request", other, member, `{}`)
	otherRequest := insert("api_request", other, other, `{}`)
	domainEvent := insert("mobile_bff", member, member, `{"details":{"remote_addr":"203.0.113.5:443","query":"lat=1","coins":5}}`)

	// Export before erasure: daily counts only.
	var raw []byte
	for _, section := range accountExportSections() {
		if section.name == "api_activity_summary" {
			if err := db.QueryRowContext(ctx, section.query, member).Scan(&raw); err != nil {
				t.Fatal(err)
			}
		}
	}
	var summary []map[string]any
	if err := json.Unmarshal(raw, &summary); err != nil || len(summary) != 1 || summary[0]["requests"] != float64(2) {
		t.Fatalf("export summary %s %v", raw, err)
	}

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, step := range accountErasureSteps() {
		if step.label != "api_request_telemetry" && step.label != "activity_event_context" {
			continue
		}
		if _, err := tx.ExecContext(ctx, step.query, member); err != nil {
			_ = tx.Rollback()
			t.Fatal(step.label, err)
		}
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	exists := func(id string) bool {
		var ok bool
		_ = db.QueryRow(`SELECT EXISTS(SELECT 1 FROM matching.activity_events WHERE id=$1::uuid)`, id).Scan(&ok)
		return ok
	}
	if exists(ownRequest) || exists(actorRequest) || !exists(otherRequest) || !exists(domainEvent) {
		t.Fatalf("own=%v actor=%v other=%v domain=%v", exists(ownRequest), exists(actorRequest), exists(otherRequest), exists(domainEvent))
	}
	var payload []byte
	var ip sql.NullString
	if err := db.QueryRow(`SELECT payload, host(ip_address) FROM matching.activity_events WHERE id=$1::uuid`, domainEvent).Scan(&payload, &ip); err != nil {
		t.Fatal(err)
	}
	if ip.Valid || bytes.Contains(payload, []byte("remote_addr")) || bytes.Contains(payload, []byte("lat=1")) || !bytes.Contains(payload, []byte(`"coins": 5`)) {
		t.Fatalf("domain event keeps the fact but not the network context: ip=%v %s", ip, payload)
	}
}
