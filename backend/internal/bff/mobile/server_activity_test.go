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

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus"
	dto "github.com/prometheus/client_model/go"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

func runRecord(worker, status string, processed, failed int64, details map[string]any) observability.WorkerRunRecord {
	finished := time.Now().UTC()
	rec := observability.WorkerRunRecord{
		Worker: worker, Interval: time.Minute, StartedAt: finished.Add(-30 * time.Millisecond), FinishedAt: finished,
		Status: status, ItemsProcessed: processed, ItemsFailed: failed, Details: details,
	}
	if status == observability.WorkerRunFailed {
		rec.Err = errors.New("query failed for alice@example.com")
	}
	return rec
}

func drainRuns(a *serverActivityRecorder) []jobRunRow {
	out := []jobRunRow{}
	for {
		select {
		case row := <-a.runs:
			out = append(out, row)
		default:
			return out
		}
	}
}

// Low-frequency workers store every run; high-frequency workers only runs
// that failed or handled items. Every run reaches the hourly rollup.
func TestJobRunSinkStoresLowFrequencyRunsAndOnlyBusyHighFrequencyRuns(t *testing.T) {
	a := newServerActivityRecorder(nil, zap.NewNop(), observability.ServiceMobileBFF)

	a.RecordWorkerRun(runRecord(workerTrustRetention, observability.WorkerRunSucceeded, 0, 0, nil))
	a.RecordWorkerRun(runRecord(workerAnalyticsSnapshot, observability.WorkerRunBusy, 0, 0, nil))
	a.RecordWorkerRun(runRecord(workerNotificationDelivery, observability.WorkerRunSucceeded, 0, 0, nil))
	a.RecordWorkerRun(runRecord(workerNotificationDelivery, observability.WorkerRunSucceeded, 0, 0, nil))
	a.RecordWorkerRun(runRecord(workerNotificationDelivery, observability.WorkerRunSucceeded, 3, 1, nil))
	a.RecordWorkerRun(runRecord(workerLevelProjection, observability.WorkerRunFailed, 0, 0, nil))

	stored := drainRuns(a)
	var names []string
	for _, row := range stored {
		names = append(names, row.worker+":"+row.status)
	}
	want := []string{"trust_retention:succeeded", "analytics_snapshot:busy", "notification_delivery:succeeded", "level_projection:failed"}
	if strings.Join(names, ",") != strings.Join(want, ",") {
		t.Fatalf("stored runs = %v, want %v", names, want)
	}
	failed := stored[3]
	if failed.errText == "" || strings.Contains(failed.errText, "alice@example.com") {
		t.Fatalf("error must be kept and redacted: %q", failed.errText)
	}
	if stored[2].processed != 3 || stored[2].failed != 1 {
		t.Fatalf("items = %+v", stored[2])
	}

	hour := time.Now().UTC().Truncate(time.Hour)
	notification := a.jobRollups[jobRollupKey{worker: workerNotificationDelivery, hour: hour}]
	if notification == nil || notification.runs != 3 || notification.items != 3 || notification.itemsFailed != 1 || notification.failures != 0 {
		t.Fatalf("every high-frequency run is folded: %+v", notification)
	}
	level := a.jobRollups[jobRollupKey{worker: workerLevelProjection, hour: hour}]
	if level == nil || level.runs != 1 || level.failures != 1 || !level.lastSuccess.IsZero() || level.buckets[jobDurationBucket(30)] != 1 {
		t.Fatalf("failed run rollup: %+v", level)
	}

	events := a.events.Drain()
	if len(events) != 1 || events[0].Kind != observability.EventWorkerFailed || events[0].DedupeKey != workerLevelProjection ||
		events[0].Severity != observability.SeverityError {
		t.Fatalf("worker_failed event: %+v", events)
	}
}

func TestJobRunSinkRecordsRetentionSummary(t *testing.T) {
	a := newServerActivityRecorder(nil, zap.NewNop(), observability.ServiceMobileBFF)
	a.RecordWorkerRun(runRecord(workerTrustRetention, observability.WorkerRunSucceeded, 7, 0,
		map[string]any{"purged": map[string]int{"api_request_telemetry": 5, "revoked_sessions": 2, "identity_evidence": 0}}))
	a.RecordWorkerRun(runRecord(workerIdempotencyRetention, observability.WorkerRunSucceeded, 0, 0,
		map[string]any{"purged": map[string]int{"idempotency_archive": 0}}))
	events := a.events.Drain()
	if len(events) != 1 || events[0].Kind != observability.EventRetentionSummary || events[0].Details["total"] != int64(7) {
		t.Fatalf("one summary for the pass that removed rows: %+v", events)
	}
	if stored := drainRuns(a); len(stored) != 2 || stored[0].details["purged"] == nil {
		t.Fatalf("retention runs keep their per-class details: %+v", stored)
	}
}

func TestJobRunSinkNeverBlocksWhenTheQueueIsFull(t *testing.T) {
	a := newServerActivityRecorder(nil, zap.NewNop(), observability.ServiceMobileBFF)
	a.runs = make(chan jobRunRow, 1)
	done := make(chan struct{})
	go func() {
		for i := 0; i < 5; i++ {
			a.RecordWorkerRun(runRecord(workerTrustRetention, observability.WorkerRunSucceeded, 0, 0, nil))
		}
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("sink blocked on a full queue")
	}
	if a.droppedRuns.Load() != 4 {
		t.Fatalf("dropped = %d", a.droppedRuns.Load())
	}
}

func TestWorkerStaleEventAtMostHourly(t *testing.T) {
	worker := "stale_probe_" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	observability.NewHeartbeat(worker, time.Minute).Begin() // registers, never finishes
	a := newServerActivityRecorder(nil, zap.NewNop(), observability.ServiceMobileBFF)
	now := time.Now().UTC()

	a.checkStale(now.Add(2 * time.Minute)) // within 3 x 1m
	a.checkStale(now.Add(4 * time.Minute))
	a.checkStale(now.Add(30 * time.Minute)) // same hour window: no second event
	stale := 0
	for _, row := range a.events.Drain() {
		if row.Kind == observability.EventWorkerStale && row.DedupeKey == worker {
			stale += int(row.Count)
		}
	}
	if stale != 1 {
		t.Fatalf("stale events = %d, want 1", stale)
	}
	// A success clears it; staleness after that is reported again.
	a.RecordWorkerRun(observability.WorkerRunRecord{Worker: worker, Status: observability.WorkerRunSucceeded,
		StartedAt: now.Add(40 * time.Minute), FinishedAt: now.Add(40 * time.Minute)})
	a.checkStale(now.Add(41 * time.Minute))
	a.checkStale(now.Add(50 * time.Minute))
	stale = 0
	for _, row := range a.events.Drain() {
		if row.Kind == observability.EventWorkerStale && row.DedupeKey == worker {
			stale++
		}
	}
	if stale != 1 {
		t.Fatalf("stale after recovery = %d, want 1", stale)
	}
	if workerStaleThreshold(200*time.Millisecond) != workerStaleFloor || workerStaleThreshold(time.Hour) != 3*time.Hour {
		t.Fatal("stale threshold")
	}
}

// The security middleware notes why it refused a request; the request
// middleware turns that into a refused event and the reason is counted.
func TestSecurityRefusalsAreRecordedWithReasons(t *testing.T) {
	reg := prometheus.NewRegistry()
	metrics := observability.NewBFFMetrics(reg)
	metrics.ServerEvents = observability.NewServerEvents()
	var resolve func() (securityPrincipal, error)
	testPrincipalResolver = func(*http.Request) (securityPrincipal, error) { return resolve() }
	t.Cleanup(func() { testPrincipalResolver = nil })

	s := &Server{httpMetrics: metrics}
	s.cfg.APIPrefix = "/v1"
	router := chi.NewRouter()
	router.Use(observability.RequestLoggingMiddleware(zap.NewNop(), metrics, metrics.Service))
	router.Use(s.securityMiddleware)
	router.Get("/v1/admin/system/events", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })
	router.Get("/v1/admin/system/requests", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })
	router.Get("/v1/settings/{userID}", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })

	call := func(path string) int {
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
		return rec.Code
	}
	resolve = func() (securityPrincipal, error) { return securityPrincipal{}, errors.New("invalid session") }
	if code := call("/v1/admin/system/events"); code != http.StatusUnauthorized {
		t.Fatalf("no session = %d", code)
	}
	resolve = func() (securityPrincipal, error) { return securityPrincipal{}, errPrincipalAccountState }
	if code := call("/v1/admin/system/events"); code != http.StatusUnauthorized {
		t.Fatalf("suspended = %d", code)
	}
	analyst := securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"user": true, "analyst": true}}
	resolve = func() (securityPrincipal, error) { return analyst, nil }
	if code := call("/v1/admin/system/events"); code != http.StatusForbidden {
		t.Fatalf("analyst reading events = %d", code)
	}
	if code := call("/v1/admin/system/requests"); code != http.StatusOK {
		t.Fatalf("analyst reading requests = %d", code)
	}
	if code := call("/v1/settings/" + uuid.NewString()); code != http.StatusForbidden {
		t.Fatalf("another member's settings = %d", code)
	}

	reasons := map[string]int64{}
	for _, row := range metrics.ServerEvents.Drain() {
		if row.Kind == observability.EventRefused {
			reasons[row.Details["reason"].(string)] += row.Count
		}
	}
	for _, reason := range []string{"unauthenticated", "account_state", "forbidden_role", "forbidden_resource"} {
		if reasons[reason] != 1 {
			t.Fatalf("refused reasons = %v (missing %s)", reasons, reason)
		}
		var metric dto.Metric
		if err := metrics.SecurityRefusals.WithLabelValues(reason).Write(&metric); err != nil || metric.GetCounter().GetValue() != 1 {
			got := metric.GetCounter().GetValue()
			t.Fatalf("security_refusals_total{reason=%s} = %v", reason, got)
		}
	}
}

func TestSystemRoutesRoleMatrix(t *testing.T) {
	type check struct {
		path    string
		method  string
		allowed []string
	}
	every := []string{"admin", "ops_admin", "analyst", "trust_safety", "moderator", "support", "finance", "user"}
	checks := []check{
		{"/v1/admin/system/events", http.MethodGet, []string{"admin", "ops_admin"}},
		{"/v1/admin/system/jobs", http.MethodGet, []string{"admin", "ops_admin"}},
		{"/v1/admin/system/job-runs", http.MethodGet, []string{"admin", "ops_admin"}},
		{"/v1/admin/system/requests", http.MethodGet, []string{"admin", "ops_admin", "analyst"}},
		{"/v1/admin/system/capacity", http.MethodGet, []string{"admin", "ops_admin", "analyst"}},
		{"/v1/admin/system/third-party", http.MethodGet, []string{"admin", "ops_admin", "analyst"}},
		{"/v1/admin/system/events", http.MethodPost, []string{"admin"}},
		{"/v1/admin/system/requests", http.MethodDelete, []string{"admin"}},
	}
	for _, c := range checks {
		for _, role := range every {
			principal := securityPrincipal{Roles: map[string]bool{role: true}}
			got := principalCanAccessAdminRoute(principal, "/v1", c.method, c.path)
			want := false
			for _, allowed := range c.allowed {
				want = want || allowed == role
			}
			if got != want {
				t.Errorf("%s %s %s: got %v, want %v", role, c.method, c.path, got, want)
			}
		}
	}
}

func TestSystemEndpointsRefuseWithoutOperatorAndValidateFilters(t *testing.T) {
	s := &Server{}
	for _, handler := range []http.HandlerFunc{s.adminSystemEvents, s.adminSystemJobs, s.adminSystemJobRuns,
		s.adminSystemRequests, s.adminSystemCapacity, s.adminSystemThirdParty} {
		rec := httptest.NewRecorder()
		handler(rec, httptest.NewRequest(http.MethodGet, "/v1/admin/system/x", nil))
		if rec.Code != http.StatusUnauthorized {
			t.Fatalf("no principal = %d", rec.Code)
		}
	}
	window := func(query string) (time.Time, time.Time, error) {
		req := httptest.NewRequest(http.MethodGet, "/x?"+query, nil)
		_, from, to, err := parseSystemWindow(req, adminListSpec{DefaultLimit: 10, MaxLimit: 10}, 24*time.Hour,
			time.Date(2026, 10, 2, 12, 0, 0, 0, time.UTC))
		return from, to, err
	}
	if from, to, err := window(""); err != nil || !from.Equal(time.Date(2026, 10, 1, 12, 0, 0, 0, time.UTC)) || !to.IsZero() {
		t.Fatalf("default window = %v %v %v", from, to, err)
	}
	if from, to, err := window("from=2026-09-01&to=2026-09-02"); err != nil || !from.Equal(time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)) ||
		!to.Equal(time.Date(2026, 9, 3, 0, 0, 0, 0, time.UTC)) {
		t.Fatalf("date window = %v %v %v", from, to, err)
	}
	if from, _, err := window("from=2026-10-02T06:30:00Z"); err != nil || !from.Equal(time.Date(2026, 10, 2, 6, 30, 0, 0, time.UTC)) {
		t.Fatalf("timestamp window = %v %v", from, err)
	}
	for _, bad := range []string{"from=yesterday", "from=2026-10-02T06:30", "from=2026-10-03&to=2026-10-01"} {
		if _, _, err := window(bad); err == nil {
			t.Fatalf("%s must be rejected", bad)
		}
	}
}

func decodeSystemBody(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	body := map[string]any{}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode %s: %v", rec.Body.String(), err)
	}
	return body
}

func callSystem(t *testing.T, handler http.HandlerFunc, target string, roles ...string) (int, map[string]any) {
	t.Helper()
	if len(roles) == 0 {
		roles = []string{"admin"}
	}
	principal := securityPrincipal{UserID: "00000000-0000-4000-8000-000000000001", Roles: map[string]bool{}}
	for _, role := range roles {
		principal.Roles[role] = true
	}
	req := httptest.NewRequest(http.MethodGet, target, nil)
	req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, principal))
	rec := httptest.NewRecorder()
	handler(rec, req)
	if rec.Code != http.StatusOK {
		return rec.Code, map[string]any{"raw": rec.Body.String()}
	}
	return rec.Code, decodeSystemBody(t, rec)
}

// writeError logs every 5xx with its correlation id and leaves a redacted
// excerpt for the per-route-per-minute server_error event.
func TestWriteErrorServerErrorsBecomeEventsWithExcerpt(t *testing.T) {
	metrics := observability.NewBFFMetrics(prometheus.NewRegistry())
	metrics.ServerEvents = observability.NewServerEvents()
	router := chi.NewRouter()
	router.Use(observability.CorrelationIDMiddleware(zap.NewNop()))
	router.Use(observability.RequestLoggingMiddleware(zap.NewNop(), metrics, metrics.Service))
	router.Get("/v1/thing/{id}", func(w http.ResponseWriter, _ *http.Request) {
		writeError(w, http.StatusBadGateway, errors.New("upstream rejected bob@example.com"))
	})
	for i := 0; i < 3; i++ {
		req := httptest.NewRequest(http.MethodGet, "/v1/thing/"+uuid.NewString(), nil)
		req.Header.Set(observability.CorrelationIDHeader, "corr-"+strings.Repeat("x", i+1))
		router.ServeHTTP(httptest.NewRecorder(), req)
	}
	rows := metrics.ServerEvents.Drain()
	if len(rows) != 1 || rows[0].Kind != observability.EventServerError || rows[0].Count != 3 || rows[0].Route != "/v1/thing/{id}" ||
		rows[0].CorrelationID != "corr-x" {
		t.Fatalf("one aggregated server_error row: %+v", rows)
	}
	excerpt, _ := rows[0].Details["error_excerpt"].(string)
	if !strings.Contains(excerpt, "upstream rejected") || strings.Contains(excerpt, "bob@example.com") {
		t.Fatalf("excerpt = %q", excerpt)
	}
}
