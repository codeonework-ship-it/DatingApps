package observability

import (
	"context"
	"errors"
	"math"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"
)

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	digits := ""
	for n > 0 {
		digits = string(rune('0'+n%10)) + digits
		n /= 10
	}
	return digits
}

func TestRequestRollupsAggregateBoundedKeysAndBuckets(t *testing.T) {
	rollups := NewRequestRollups()
	clock := time.Date(2026, 10, 2, 10, 59, 0, 0, time.UTC)
	rollups.now = func() time.Time { return clock }

	rollups.Observe(ServiceMobileBFF, "GET", "/v1/profile/{userID}", 200, 3*time.Millisecond, true)
	rollups.Observe(ServiceMobileBFF, "GET", "/v1/profile/{userID}", 204, 40*time.Millisecond, true)
	rollups.Observe(ServiceMobileBFF, "GET", "/v1/profile/{userID}", 400, 2*time.Second, true)
	rollups.Observe(ServiceMobileBFF, "GET", "/v1/profile/{userID}", 401, time.Millisecond, true)
	rollups.Observe(ServiceMobileBFF, "GET", "/v1/profile/{userID}", 503, 20*time.Second, true)
	rollups.Observe(ServiceMobileBFF, "BREW", "", 418, time.Millisecond, true)
	rollups.Observe(ServiceMobileBFF, "GET", "/v1/realtime/chat", 101, time.Hour, false)
	clock = clock.Add(2 * time.Minute) // next hour
	rollups.Observe(ServiceMobileBFF, "GET", "/v1/profile/{userID}", 200, 3*time.Millisecond, true)

	rows := rollups.Drain()
	if len(rollups.Drain()) != 0 {
		t.Fatal("drain must clear")
	}
	if len(rows) != 7 {
		t.Fatalf("rows = %d, want 7: %+v", len(rows), rows)
	}
	byKey := map[string]RequestRollupRow{}
	for _, row := range rows {
		byKey[row.Hour.Format("15")+" "+row.Method+" "+row.Route+" "+row.StatusClass+" "+itoa(row.StatusCode)] = row
	}
	ok := byKey["10 GET /v1/profile/{userID} 2xx 0"]
	if ok.Requests != 2 || ok.TimedRequests != 2 || ok.Buckets[0] != 1 || ok.Buckets[3] != 1 {
		t.Fatalf("2xx row (codes folded to 0, 3ms in le .005, 40ms in le .05) = %+v", ok)
	}
	if math.Abs(ok.SumDurationMS-43) > 0.01 || math.Abs(ok.MaxDurationMS-40) > 0.01 {
		t.Fatalf("2xx durations = %+v", ok)
	}
	if row := byKey["10 GET /v1/profile/{userID} 4xx 0"]; row.Requests != 1 || row.Buckets[8] != 1 {
		t.Fatalf("400 folds to code 0, 2s in le 2.5: %+v", row)
	}
	if row := byKey["10 GET /v1/profile/{userID} 4xx 401"]; row.Requests != 1 {
		t.Fatalf("401 keeps its code: %+v", byKey)
	}
	if row := byKey["10 GET /v1/profile/{userID} 5xx 503"]; row.Requests != 1 || row.Buckets[RequestRollupBucketCount-1] != 1 {
		t.Fatalf("503 keeps its code, 20s in +Inf: %+v", row)
	}
	if row := byKey["10 OTHER unmatched 4xx 0"]; row.Requests != 1 {
		t.Fatalf("unknown method and empty route are bounded: %+v", byKey)
	}
	if row := byKey["10 GET /v1/realtime/chat 1xx 0"]; row.Requests != 1 || row.TimedRequests != 0 || row.SumDurationMS != 0 {
		t.Fatalf("upgraded connection is counted without latency: %+v", row)
	}
	if row := byKey["11 GET /v1/profile/{userID} 2xx 0"]; row.Requests != 1 {
		t.Fatalf("next hour is its own row: %+v", byKey)
	}

	// A failed flush puts rows back and they merge additively.
	rollups.Restore(rows)
	rollups.Restore([]RequestRollupRow{ok})
	again := rollups.Drain()
	merged := map[string]RequestRollupRow{}
	for _, row := range again {
		merged[row.Hour.Format("15")+" "+row.Method+" "+row.Route+" "+row.StatusClass+" "+itoa(row.StatusCode)] = row
	}
	if row := merged["10 GET /v1/profile/{userID} 2xx 0"]; row.Requests != 4 || row.Buckets[0] != 2 {
		t.Fatalf("restore must add: %+v", row)
	}
}

func TestRollupStatusCodeKeepsOnlyDiagnosticCodes(t *testing.T) {
	for status, want := range map[int]int{200: 0, 201: 0, 302: 0, 400: 0, 401: 401, 403: 403, 404: 404, 409: 409, 422: 0, 429: 429, 500: 500, 502: 502, 504: 504} {
		if got := RollupStatusCode(status); got != want {
			t.Errorf("RollupStatusCode(%d) = %d, want %d", status, got, want)
		}
	}
}

func TestHistogramQuantileMatchesPrometheusInterpolation(t *testing.T) {
	bounds := []float64{0.1, 0.5, 1}
	// 10 in (0, .1], 80 in (.1, .5], 10 in (.5, 1].
	counts := []int64{10, 80, 10, 0}
	if got := HistogramQuantile(0.5, bounds, counts); math.Abs(got-0.3) > 1e-9 {
		t.Fatalf("p50 = %v, want 0.3 (rank 50 is 40/80 into the second bucket)", got)
	}
	if got := HistogramQuantile(0.05, bounds, counts); math.Abs(got-0.05) > 1e-9 {
		t.Fatalf("p5 = %v, want 0.05", got)
	}
	if got := HistogramQuantile(0.95, bounds, counts); math.Abs(got-0.75) > 1e-9 {
		t.Fatalf("p95 = %v, want 0.75", got)
	}
	if got := HistogramQuantile(0.99, bounds, []int64{0, 0, 0, 5}); got != 1 {
		t.Fatalf("+Inf bucket = %v, want the highest finite bound", got)
	}
	if got := HistogramQuantile(0.5, bounds, []int64{0, 0, 0, 0}); got != 0 {
		t.Fatalf("no observations = %v", got)
	}
	// The real bounds: a single 30 ms request is in (.025, .05].
	buckets := make([]int64, RequestRollupBucketCount)
	buckets[requestRollupBucket(0.03)]++
	if got := HistogramQuantile(0.99, RequestRollupBucketsSeconds, buckets); got <= 0.025 || got > 0.05 {
		t.Fatalf("p99 of one 30ms request = %v", got)
	}
}

func TestServerEventsAggregatePerKeyAndMinute(t *testing.T) {
	events := NewServerEvents()
	base := time.Date(2026, 10, 2, 10, 0, 5, 0, time.UTC)
	events.Record(ServerEvent{At: base, Kind: EventRefused, DedupeKey: "unauthenticated|GET /v1/x", CorrelationID: "", Message: "m"})
	events.Record(ServerEvent{At: base.Add(30 * time.Second), Kind: EventRefused, DedupeKey: "unauthenticated|GET /v1/x", CorrelationID: "c-2"})
	events.Record(ServerEvent{At: base.Add(10 * time.Second), Kind: EventRefused, DedupeKey: "forbidden_role|GET /v1/x"})
	events.Record(ServerEvent{At: base.Add(61 * time.Second), Kind: EventRefused, DedupeKey: "unauthenticated|GET /v1/x"})
	events.Record(ServerEvent{At: base.Add(5 * time.Minute), Kind: EventWorkerStale, DedupeKey: "w", Window: time.Hour})
	events.Record(ServerEvent{At: base.Add(50 * time.Minute), Kind: EventWorkerStale, DedupeKey: "w", Window: time.Hour})

	rows := events.Drain()
	if len(rows) != 4 {
		t.Fatalf("rows = %d, want 4: %+v", len(rows), rows)
	}
	first := rows[0]
	if first.Kind != EventRefused || first.Count != 2 || !first.FirstAt.Equal(base) || !first.LastAt.Equal(base.Add(30*time.Second)) ||
		!first.BucketAt.Equal(base.Truncate(time.Minute)) || first.CorrelationID != "c-2" || first.Severity != SeverityInfo {
		t.Fatalf("same key and minute aggregate into one row: %+v", first)
	}
	var stale ServerEventRow
	for _, row := range rows {
		if row.Kind == EventWorkerStale {
			stale = row
		}
	}
	if stale.Count != 2 || !stale.BucketAt.Equal(base.Truncate(time.Hour)) {
		t.Fatalf("hour window aggregates: %+v", stale)
	}
	events.Restore(rows)
	if again := events.Drain(); len(again) != 4 {
		t.Fatalf("restore keeps rows: %d", len(again))
	}
}

// The middleware records refusals noted by inner layers, 401/429 without a
// note, panics with a code-only stack, and 5xx with the handler's excerpt.
func TestRequestLoggingMiddlewareRecordsServerActivity(t *testing.T) {
	metrics := NewBFFMetrics(prometheus.NewRegistry())
	metrics.RequestRollups = NewRequestRollups()
	metrics.ServerEvents = NewServerEvents()

	r := chi.NewRouter()
	r.Use(CorrelationIDMiddleware(zap.NewNop()))
	r.Use(RequestLoggingMiddleware(zap.NewNop(), metrics, metrics.Service))
	r.Use(GlobalExceptionMiddleware(zap.NewNop()))
	r.Get("/v1/panic/{id}", func(http.ResponseWriter, *http.Request) {
		var items []int
		_ = items[3] // index out of range
	})
	r.Get("/v1/forbidden", func(w http.ResponseWriter, r *http.Request) {
		NoteRefusal(r.Context(), RefusalForbiddenRole)
		w.WriteHeader(http.StatusForbidden)
	})
	r.Get("/v1/login", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusUnauthorized) })
	r.Get("/v1/business-403", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusForbidden) })
	r.Get("/v1/broken", func(w http.ResponseWriter, _ *http.Request) {
		NoteServerError(w.Header().Get(CorrelationIDHeader), "lookup failed for alice@example.com")
		w.WriteHeader(http.StatusBadGateway)
	})

	serve := func(path, correlation string) int {
		req := httptest.NewRequest(http.MethodGet, path, nil)
		if correlation != "" {
			req.Header.Set(CorrelationIDHeader, correlation)
		}
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)
		return rec.Code
	}
	for i := 0; i < 2; i++ {
		if code := serve("/v1/panic/abc", "corr-panic"); code != 500 {
			t.Fatalf("panic answered %d", code)
		}
	}
	serve("/v1/forbidden", "")
	serve("/v1/login", "")
	serve("/v1/business-403", "")
	serve("/v1/broken", "corr-broken")
	serve("/nope", "")

	rows := metrics.ServerEvents.Drain()
	byKind := map[string][]ServerEventRow{}
	for _, row := range rows {
		byKind[row.Kind] = append(byKind[row.Kind], row)
	}
	panics := byKind[EventPanic]
	if len(panics) != 1 || panics[0].Count != 2 || panics[0].Severity != SeverityCritical || panics[0].Route != "/v1/panic/{id}" ||
		panics[0].CorrelationID != "corr-panic" {
		t.Fatalf("two panics in a minute aggregate: %+v", panics)
	}
	frames, _ := panics[0].Details["stack"].([]string)
	if len(frames) == 0 || panics[0].Details["stack_hash"] == "" || !strings.Contains(strings.Join(frames, "\n"), "TestRequestLoggingMiddlewareRecordsServerActivity") {
		t.Fatalf("panic stack excerpt: %+v", panics[0].Details)
	}
	if strings.Contains(panics[0].Message, "abc") {
		t.Fatalf("panic message must not carry the raw path: %q", panics[0].Message)
	}

	var serverErrors []string
	for _, row := range byKind[EventServerError] {
		serverErrors = append(serverErrors, row.DedupeKey)
		if row.Route == "/v1/broken" {
			excerpt, _ := row.Details["error_excerpt"].(string)
			if excerpt == "" || strings.Contains(excerpt, "alice@example.com") {
				t.Fatalf("5xx excerpt must be present and redacted: %q", excerpt)
			}
		}
	}
	if len(serverErrors) != 2 {
		t.Fatalf("server_error rows (panic route + broken): %v", serverErrors)
	}
	refusals := map[string]int64{}
	for _, row := range byKind[EventRefused] {
		refusals[row.Details["reason"].(string)+" "+row.Route] += row.Count
	}
	if refusals["forbidden_role /v1/forbidden"] != 1 || refusals["unauthenticated /v1/login"] != 1 || len(refusals) != 2 {
		t.Fatalf("refusals (a plain handler 403 is not a refusal): %v", refusals)
	}

	byRoute := map[string]int64{}
	for _, row := range metrics.RequestRollups.Drain() {
		byRoute[row.Route] += row.Requests
	}
	if byRoute["/v1/panic/{id}"] != 2 || byRoute[RouteUnmatched] != 1 {
		t.Fatalf("panicking and unmatched requests are counted: %v", byRoute)
	}
}

func TestInflightSheddingCountsAndNotesRefusal(t *testing.T) {
	reg := prometheus.NewRegistry()
	metrics := NewBFFMetrics(reg)
	metrics.ServerEvents = NewServerEvents()
	release := make(chan struct{})
	entered := make(chan struct{})
	r := chi.NewRouter()
	r.Use(RequestLoggingMiddleware(zap.NewNop(), metrics, metrics.Service))
	r.Use(InflightSheddingMiddlewareWithMetrics(zap.NewNop(), metrics, "test", 1, 1))
	r.Get("/v1/slow", func(w http.ResponseWriter, _ *http.Request) {
		close(entered)
		<-release
	})
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		r.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/v1/slow", nil))
	}()
	<-entered
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/slow", nil))
	close(release)
	wg.Wait()
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("second request = %d", rec.Code)
	}
	if got := counterValues(t, reg, "verified_dating_reliability_requests_shed_total")["domain=inflight"]; got != 1 {
		t.Fatalf("requests_shed_total{domain=inflight} = %v", got)
	}
	rows := metrics.ServerEvents.Drain()
	if len(rows) != 1 || rows[0].Details["reason"] != RefusalShedInflight {
		t.Fatalf("shed refusal event: %+v", rows)
	}
}

type captureSink struct {
	mu      sync.Mutex
	records []WorkerRunRecord
}

func (c *captureSink) RecordWorkerRun(rec WorkerRunRecord) {
	c.mu.Lock()
	c.records = append(c.records, rec)
	c.mu.Unlock()
}

func TestWorkerRunSinkReceivesStatusItemsDetailsAndBacklog(t *testing.T) {
	sink := &captureSink{}
	SetWorkerRunSink(sink)
	defer SetWorkerRunSink(nil)
	workers := NewWorkerMetrics(prometheus.NewRegistry())
	heartbeat := workers.Heartbeat("sink_test_worker", time.Minute)

	heartbeat.SetBacklog(12)
	run := heartbeat.Begin()
	run.Items("processed", 4)
	run.Items("days_built", 2)
	run.Items("failed", 1)
	run.Detail("purged", map[string]int{"a": 3})
	run.End(nil)

	busy := heartbeat.Begin()
	busy.MarkBusy()
	busy.End(nil)

	failed := heartbeat.Begin()
	failed.End(errors.New("boom"))

	cancelled := heartbeat.Begin()
	cancelled.End(context.Canceled)

	// Without Prometheus collectors the sink still sees runs.
	previous := DefaultWorkerMetrics()
	SetDefaultWorkerMetrics(nil)
	NewHeartbeat("sink_test_unregistered", 0).Begin().End(nil)
	SetDefaultWorkerMetrics(previous)

	if len(sink.records) != 4 {
		t.Fatalf("records = %d, want 4 (cancellation records nothing)", len(sink.records))
	}
	first := sink.records[0]
	if first.Status != WorkerRunSucceeded || first.ItemsProcessed != 6 || first.ItemsFailed != 1 || first.Items["days_built"] != 2 ||
		first.Backlog == nil || *first.Backlog != 12 || first.Interval != time.Minute || first.Details["purged"] == nil {
		t.Fatalf("first record = %+v", first)
	}
	if sink.records[1].Status != WorkerRunBusy || sink.records[2].Status != WorkerRunFailed || sink.records[2].Err == nil {
		t.Fatalf("statuses = %s, %s", sink.records[1].Status, sink.records[2].Status)
	}
	if sink.records[3].Worker != "sink_test_unregistered" {
		t.Fatalf("unregistered heartbeat record = %+v", sink.records[3])
	}
	found := false
	for _, info := range WorkerRegistry() {
		if info.Worker == "sink_test_worker" && info.Interval == time.Minute && !info.FirstSeen.IsZero() {
			found = true
		}
	}
	if !found {
		t.Fatal("worker registry must list the heartbeat with its interval")
	}
}
