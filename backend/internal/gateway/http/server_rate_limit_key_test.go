package gatewayhttp

import (
	"net/http"
	"net/http/httptest"
	"net/netip"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

func newRateLimitedRouter(t *testing.T, limit int, options ...RouterOption) http.Handler {
	t.Helper()
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	t.Cleanup(upstream.Close)
	router, err := NewRouter(zap.NewNop(), observability.NewHTTPMetrics(prometheus.NewRegistry()),
		upstream.URL, "/v1", limit, time.Minute, 100, 1, time.Second, options...)
	if err != nil {
		t.Fatal(err)
	}
	return router
}

func gatewayStatus(router http.Handler, remoteAddr, realIP string) int {
	req := httptest.NewRequest(http.MethodGet, "/v1/config/flags", nil)
	req.RemoteAddr = remoteAddr
	if realIP != "" {
		req.Header.Set("X-Real-IP", realIP)
	}
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	return rec.Code
}

// Behind nginx every request arrives from 127.0.0.1. Keying the limit on the
// socket address put all members into one shared bucket.
func TestGatewayRateLimitKeysOnClientBehindLoopbackProxy(t *testing.T) {
	router := newRateLimitedRouter(t, 1)
	if code := gatewayStatus(router, "127.0.0.1:50000", "203.0.113.10"); code != http.StatusOK {
		t.Fatalf("first client: status %d", code)
	}
	if code := gatewayStatus(router, "127.0.0.1:50001", "203.0.113.11"); code != http.StatusOK {
		t.Fatalf("a different client behind the same proxy was throttled (status %d)", code)
	}
	if code := gatewayStatus(router, "127.0.0.1:50002", "203.0.113.10"); code != http.StatusTooManyRequests {
		t.Fatalf("the same client over its limit got %d, want 429", code)
	}
}

func TestGatewayRateLimitIgnoresRealIPFromUntrustedPeers(t *testing.T) {
	router := newRateLimitedRouter(t, 1)
	if code := gatewayStatus(router, "198.51.100.7:4000", "203.0.113.20"); code != http.StatusOK {
		t.Fatalf("first request: status %d", code)
	}
	// A direct client cannot escape its bucket by inventing X-Real-IP values.
	if code := gatewayStatus(router, "198.51.100.7:4001", "203.0.113.21"); code != http.StatusTooManyRequests {
		t.Fatalf("spoofed X-Real-IP from an untrusted peer got %d, want 429", code)
	}
}

func TestGatewayRateLimitHonoursConfiguredLoadBalancer(t *testing.T) {
	lb, err := ParseTrustedProxies("10.0.0.0/8, 192.0.2.5")
	if err != nil {
		t.Fatal(err)
	}
	router := newRateLimitedRouter(t, 1, WithTrustedProxies(lb))
	if code := gatewayStatus(router, "10.1.2.3:443", "203.0.113.30"); code != http.StatusOK {
		t.Fatalf("status %d", code)
	}
	if code := gatewayStatus(router, "192.0.2.5:443", "203.0.113.31"); code != http.StatusOK {
		t.Fatalf("second client via a trusted single-address proxy was throttled (status %d)", code)
	}
}

func TestClientIPKeyGroupsIPv6ByPrefix(t *testing.T) {
	key := clientIPKey([]netip.Prefix{netip.MustParsePrefix("127.0.0.0/8")})
	a := httptest.NewRequest(http.MethodGet, "/", nil)
	a.RemoteAddr = "[2001:db8:1:2:aaaa::1]:443"
	b := httptest.NewRequest(http.MethodGet, "/", nil)
	b.RemoteAddr = "[2001:db8:1:2:bbbb::9]:443"
	ka, _ := key(a)
	kb, _ := key(b)
	if ka != kb || ka != "2001:db8:1:2::/64" {
		t.Fatalf("IPv6 keys %q and %q, want one /64 bucket", ka, kb)
	}
}

func TestParseTrustedProxiesRejectsGarbage(t *testing.T) {
	if _, err := ParseTrustedProxies("10.0.0.0/8,not-an-ip"); err == nil {
		t.Fatal("expected an error for an invalid proxy entry")
	}
}

func TestUpstreamTransportKeepsWarmConnections(t *testing.T) {
	transport := newUpstreamTransport()
	if transport.MaxIdleConnsPerHost < 256 {
		t.Fatalf("MaxIdleConnsPerHost=%d; http.DefaultTransport's 2 churns a TCP connection per proxied request", transport.MaxIdleConnsPerHost)
	}
	if transport.ResponseHeaderTimeout != 0 {
		t.Fatal("realtime streams must not be cut by a response-header timeout")
	}
}
