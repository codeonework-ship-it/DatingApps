package gatewayhttp

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

func TestGatewayProxyPreservesOriginalForwardedHost(t *testing.T) {
	type capturedRequest struct {
		host           string
		forwardedHost  string
		forwardedProto string
	}

	captured := make(chan capturedRequest, 1)
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		captured <- capturedRequest{
			host:           r.Host,
			forwardedHost:  r.Header.Get("X-Forwarded-Host"),
			forwardedProto: r.Header.Get("X-Forwarded-Proto"),
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
	}))
	defer upstream.Close()

	metrics := observability.NewHTTPMetrics(prometheus.NewRegistry())
	router, err := NewRouter(
		zap.NewNop(),
		metrics,
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

	req := httptest.NewRequest(http.MethodGet, "http://10.0.2.2:8080/v1/discovery/user-1", nil)
	req.Host = "10.0.2.2:8080"
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}

	select {
	case got := <-captured:
		if got.forwardedHost != "10.0.2.2:8080" {
			t.Fatalf("expected X-Forwarded-Host 10.0.2.2:8080, got %q", got.forwardedHost)
		}
		if got.forwardedProto != "http" {
			t.Fatalf("expected X-Forwarded-Proto http, got %q", got.forwardedProto)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for upstream request")
	}
}
