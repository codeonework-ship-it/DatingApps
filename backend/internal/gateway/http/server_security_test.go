package gatewayhttp

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

func TestGatewayAppliesSecurityHeadersAndDoesNotExposeProfiler(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"ok":true}`))
	}))
	defer upstream.Close()

	router, err := NewRouter(
		zap.NewNop(),
		observability.NewHTTPMetrics(prometheus.NewRegistry()),
		upstream.URL,
		"/v1",
		120,
		time.Second,
		100,
		1,
		2*time.Second,
	)
	if err != nil {
		t.Fatalf("NewRouter() error = %v", err)
	}

	api := httptest.NewRecorder()
	router.ServeHTTP(api, httptest.NewRequest(http.MethodGet, "/v1/profile/user-1", nil))
	if api.Code != http.StatusOK {
		t.Fatalf("expected API status 200, got %d", api.Code)
	}
	for header, want := range map[string]string{
		"Cache-Control":           "no-store",
		"Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
		"Referrer-Policy":         "no-referrer",
		"X-Content-Type-Options":  "nosniff",
		"X-Frame-Options":         "DENY",
	} {
		if got := api.Header().Get(header); got != want {
			t.Errorf("%s = %q, want %q", header, got, want)
		}
	}

	debug := httptest.NewRecorder()
	router.ServeHTTP(debug, httptest.NewRequest(http.MethodGet, "/debug/pprof/", nil))
	if debug.Code != http.StatusNotFound {
		t.Fatalf("public profiler must be absent; got status %d", debug.Code)
	}
}

func TestGatewayRedactsUpstreamServerErrors(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "database password rejected by postgres.internal", http.StatusBadGateway)
	}))
	defer upstream.Close()

	router, err := NewRouter(
		zap.NewNop(), observability.NewHTTPMetrics(prometheus.NewRegistry()),
		upstream.URL, "/v1", 120, time.Second, 100, 1, 2*time.Second,
	)
	if err != nil {
		t.Fatalf("NewRouter() error = %v", err)
	}

	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/v1/profile/user-1", nil))
	if recorder.Code != http.StatusBadGateway {
		t.Fatalf("expected status 502, got %d", recorder.Code)
	}
	if strings.Contains(recorder.Body.String(), "postgres.internal") {
		t.Fatal("upstream implementation detail leaked through public gateway")
	}
	if !strings.Contains(recorder.Body.String(), "UPSTREAM_SERVICE_ERROR") {
		t.Fatalf("expected stable public error code, got %q", recorder.Body.String())
	}
}
