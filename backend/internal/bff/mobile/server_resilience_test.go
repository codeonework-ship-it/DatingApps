package mobile

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

func gatheredCounterValue(t *testing.T, registry *prometheus.Registry, name string, labels map[string]string) float64 {
	t.Helper()
	families, err := registry.Gather()
	if err != nil {
		t.Fatal(err)
	}
	for _, family := range families {
		if family.GetName() != name {
			continue
		}
		for _, metric := range family.Metric {
			matched := true
			for key, value := range labels {
				found := false
				for _, pair := range metric.Label {
					if pair.GetName() == key && pair.GetValue() == value {
						found = true
						break
					}
				}
				if !found {
					matched = false
					break
				}
			}
			if matched {
				return metric.GetCounter().GetValue()
			}
		}
	}
	return 0
}

func TestIdempotencyMiddleware_ReplaysCachedResponse(t *testing.T) {
	registry := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(registry)
	s := &Server{
		cfg:         config.Config{APIPrefix: "/v1"},
		idempotency: newIdempotencyStore(time.Minute),
		httpMetrics: metrics,
	}

	calls := 0
	handler := s.idempotencyMiddleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		calls++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(fmt.Sprintf(`{"value":%d}`, calls)))
	}))

	req1 := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	req1.Header.Set("Idempotency-Key", "key-1")
	rec1 := httptest.NewRecorder()
	handler.ServeHTTP(rec1, req1)

	if rec1.Code != http.StatusOK {
		t.Fatalf("expected first status 200, got %d", rec1.Code)
	}
	if got := rec1.Body.String(); got != `{"value":1}` {
		t.Fatalf("unexpected first body: %s", got)
	}

	req2 := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	req2.Header.Set("Idempotency-Key", "key-1")
	rec2 := httptest.NewRecorder()
	handler.ServeHTTP(rec2, req2)

	if rec2.Code != http.StatusOK {
		t.Fatalf("expected replay status 200, got %d", rec2.Code)
	}
	if got := rec2.Body.String(); got != `{"value":1}` {
		t.Fatalf("unexpected replay body: %s", got)
	}
	if rec2.Header().Get("X-Idempotent-Replay") != "true" {
		t.Fatalf("expected replay header true")
	}
	if calls != 1 {
		t.Fatalf("expected single handler invocation, got %d", calls)
	}
	if got := gatheredCounterValue(t, registry, "verified_dating_reliability_idempotency_replays_total", map[string]string{"domain": "matching"}); got != 1 {
		t.Fatalf("expected one replay metric, got %v", got)
	}
}

func TestTimeoutTierMiddleware_ClassifiesAndMeasuresDeadline(t *testing.T) {
	registry := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(registry)
	s := &Server{
		cfg: config.Config{
			APIPrefix:              "/v1",
			BFFFastReadTimeoutMS:   5,
			BFFNormalReadTimeoutMS: 20,
			BFFWriteTimeoutMS:      40,
		},
		httpMetrics: metrics,
	}

	tests := []struct {
		method string
		path   string
		tier   string
	}{
		{http.MethodGet, "/v1/master-data/countries", timeoutTierFastRead},
		{http.MethodGet, "/v1/discovery/user-1", timeoutTierNormalRead},
		{http.MethodPost, "/v1/swipe", timeoutTierWrite},
	}
	for _, test := range tests {
		req := httptest.NewRequest(test.method, test.path, nil)
		tier, _ := s.requestTimeoutTier(req)
		if tier != test.tier {
			t.Fatalf("%s %s tier=%q want %q", test.method, test.path, tier, test.tier)
		}
	}

	handler := s.timeoutTierMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		<-r.Context().Done()
		w.WriteHeader(http.StatusGatewayTimeout)
	}))
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/master-data/countries", nil))
	if rec.Header().Get("X-Timeout-Tier") != timeoutTierFastRead {
		t.Fatalf("unexpected timeout tier header %q", rec.Header().Get("X-Timeout-Tier"))
	}
	if got := gatheredCounterValue(t, registry, "verified_dating_reliability_request_timeouts_total", map[string]string{"tier": timeoutTierFastRead, "domain": "profile"}); got != 1 {
		t.Fatalf("expected one timeout metric, got %v", got)
	}
}

func TestBulkheadMiddleware_EmitsShedMetric(t *testing.T) {
	registry := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(registry)
	s := &Server{
		cfg:         config.Config{APIPrefix: "/v1"},
		bulkheads:   map[string]chan struct{}{"matching": make(chan struct{}, 1)},
		httpMetrics: metrics,
	}
	s.bulkheads["matching"] <- struct{}{}
	handler := s.bulkheadMiddleware(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("shed request reached handler")
	}))
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/discovery/user-1", nil))
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("expected 429, got %d", rec.Code)
	}
	if got := gatheredCounterValue(t, registry, "verified_dating_reliability_requests_shed_total", map[string]string{"domain": "matching"}); got != 1 {
		t.Fatalf("expected one shed metric, got %v", got)
	}
}

func TestIdempotencyMiddleware_CoalescesConcurrentEngagementRetries(t *testing.T) {
	s := &Server{
		cfg:         config.Config{APIPrefix: "/v1"},
		idempotency: newIdempotencyStore(time.Minute),
	}

	var calls atomic.Int32
	started := make(chan struct{})
	release := make(chan struct{})
	handler := s.idempotencyMiddleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		if calls.Add(1) == 1 {
			close(started)
		}
		<-release
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"daily_prompt":{"answer":{"id":"answer-1"}}}`))
	}))

	request := func() *httptest.ResponseRecorder {
		req := httptest.NewRequest(
			http.MethodPost,
			"/v1/engagement/daily-prompt/user-1/answer",
			nil,
		)
		req.Header.Set("Idempotency-Key", "engagement-concurrent-1")
		req.Header.Set("X-User-ID", "user-1")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		return rec
	}

	var first, second *httptest.ResponseRecorder
	var wait sync.WaitGroup
	wait.Add(2)
	go func() {
		defer wait.Done()
		first = request()
	}()
	<-started
	go func() {
		defer wait.Done()
		second = request()
	}()
	time.Sleep(20 * time.Millisecond)
	close(release)
	wait.Wait()

	if got := calls.Load(); got != 1 {
		t.Fatalf("expected one engagement mutation, got %d", got)
	}
	if first.Code != http.StatusOK || second.Code != http.StatusOK {
		t.Fatalf("expected both callers to receive 200, got %d and %d", first.Code, second.Code)
	}
	if first.Body.String() != second.Body.String() {
		t.Fatalf("concurrent retry body differs: first=%s second=%s", first.Body.String(), second.Body.String())
	}
	if second.Header().Get("X-Idempotent-Replay") != "true" {
		t.Fatalf("expected concurrent retry to be marked as replay")
	}
}

func TestIdempotencyMiddleware_DoesNotCacheServerErrors(t *testing.T) {
	s := &Server{
		cfg:         config.Config{APIPrefix: "/v1"},
		idempotency: newIdempotencyStore(time.Minute),
	}

	calls := 0
	handler := s.idempotencyMiddleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		calls++
		if calls == 1 {
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte(`{"error":"boom"}`))
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"ok":true}`))
	}))

	req1 := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	req1.Header.Set("Idempotency-Key", "key-2")
	rec1 := httptest.NewRecorder()
	handler.ServeHTTP(rec1, req1)

	req2 := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	req2.Header.Set("Idempotency-Key", "key-2")
	rec2 := httptest.NewRecorder()
	handler.ServeHTTP(rec2, req2)

	if rec1.Code != http.StatusInternalServerError {
		t.Fatalf("expected first status 500, got %d", rec1.Code)
	}
	if rec2.Code != http.StatusOK {
		t.Fatalf("expected second status 200, got %d", rec2.Code)
	}
	if calls != 2 {
		t.Fatalf("expected two handler invocations, got %d", calls)
	}
}
