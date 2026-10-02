package gatewayhttp

import (
	"encoding/json"
	"io"
	"net"
	"net/http"
	"net/http/httputil"
	"net/netip"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/httprate"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

func NewRouter(
	log *zap.Logger,
	metrics *observability.HTTPMetrics,
	bffURL string,
	apiPrefix string,
	rateLimitRequests int,
	rateLimitWindow time.Duration,
	maxInFlight int,
	retryAfterSec int,
	readyProbeTimeout time.Duration,
	options ...RouterOption,
) (http.Handler, error) {
	settings := routerSettings{trustedProxies: defaultTrustedProxies()}
	for _, option := range options {
		option(&settings)
	}
	target, err := url.Parse(bffURL)
	if err != nil {
		return nil, err
	}
	if rateLimitRequests < 1 {
		rateLimitRequests = 120
	}
	if rateLimitWindow <= 0 {
		rateLimitWindow = 1 * time.Second
	}
	if readyProbeTimeout <= 0 {
		readyProbeTimeout = 2 * time.Second
	}
	if apiPrefix == "" || apiPrefix == "/" {
		apiPrefix = "/v1"
	}

	proxy := httputil.NewSingleHostReverseProxy(target)
	proxy.Transport = newUpstreamTransport()
	proxy.ModifyResponse = func(response *http.Response) error {
		if response.StatusCode < http.StatusInternalServerError {
			return nil
		}
		_ = response.Body.Close()
		body := `{"success":false,"error":"The service is temporarily unavailable. Please try again.","error_code":"UPSTREAM_SERVICE_ERROR"}`
		response.Body = io.NopCloser(strings.NewReader(body))
		response.ContentLength = int64(len(body))
		response.Header.Set("Content-Type", "application/json")
		response.Header.Set("Content-Length", strconv.Itoa(len(body)))
		response.Header.Set("Cache-Control", "no-store")
		return nil
	}
	proxy.ErrorHandler = func(w http.ResponseWriter, _ *http.Request, _ error) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")
		w.WriteHeader(http.StatusBadGateway)
		_, _ = w.Write([]byte(`{"success":false,"error":"The service is temporarily unavailable. Please try again.","error_code":"UPSTREAM_SERVICE_ERROR"}`))
	}
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalHost := strings.TrimSpace(req.Host)
		originalProto := strings.TrimSpace(req.Header.Get("X-Forwarded-Proto"))
		if originalProto == "" {
			if req.TLS != nil {
				originalProto = "https"
			} else {
				originalProto = "http"
			}
		}

		originalDirector(req)
		req.Host = target.Host
		if originalHost != "" {
			req.Header.Set("X-Forwarded-Host", originalHost)
		} else {
			req.Header.Set("X-Forwarded-Host", req.Host)
		}
		req.Header.Set("X-Forwarded-Proto", originalProto)
	}

	r := chi.NewRouter()
	r.Use(securityHeadersMiddleware(apiPrefix))
	r.Use(observability.CorrelationIDMiddleware(log))
	// Before shedding and rate limiting so 429s and recovered panics are counted.
	r.Use(observability.RequestLoggingMiddleware(log, metrics, "api_gateway"))
	r.Use(observability.GlobalExceptionMiddleware(log))
	r.Use(observability.InflightSheddingMiddleware(log, "api_gateway", maxInFlight, retryAfterSec))
	r.Use(httprate.Limit(rateLimitRequests, rateLimitWindow,
		httprate.WithKeyFuncs(clientIPKey(settings.trustedProxies))))

	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"service":"api-gateway","status":"ok"}`))
	})
	r.Get("/readyz", func(w http.ResponseWriter, _ *http.Request) {
		client := &http.Client{Timeout: readyProbeTimeout}
		resp, err := client.Get(target.String() + "/readyz")
		if err != nil || resp.StatusCode != http.StatusOK {
			w.WriteHeader(http.StatusServiceUnavailable)
			_ = json.NewEncoder(w).Encode(map[string]any{
				"service": "api-gateway",
				"status":  "degraded",
			})
			return
		}
		defer resp.Body.Close()
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"service": "api-gateway",
			"status":  "ready",
		})
	})

	r.Handle("/metrics", promhttp.Handler())
	r.Handle("/openapi.yaml", proxy)
	r.Handle("/docs", proxy)
	r.Handle("/docs/*", proxy)
	r.Handle(apiPrefix+"/*", proxy)
	r.Handle(apiPrefix, proxy)

	return r, nil
}

func securityHeadersMiddleware(apiPrefix string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("X-Content-Type-Options", "nosniff")
			w.Header().Set("X-Frame-Options", "DENY")
			w.Header().Set("Referrer-Policy", "no-referrer")
			w.Header().Set("Permissions-Policy", "camera=(), microphone=(), geolocation=(), usb=()")
			w.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
			if r.URL.Path == apiPrefix || strings.HasPrefix(r.URL.Path, apiPrefix+"/") {
				w.Header().Set("Cache-Control", "no-store")
				w.Header().Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
			}
			next.ServeHTTP(w, r)
		})
	}
}

// RouterOption customises NewRouter.
type RouterOption func(*routerSettings)

type routerSettings struct {
	trustedProxies []netip.Prefix
}

// WithTrustedProxies names the reverse proxies (nginx, a load balancer) whose
// X-Real-IP header identifies the real client. Requests from anywhere else are
// keyed by their own address and the header is ignored, so clients cannot
// pick their own rate-limit bucket. Empty keeps the loopback default.
func WithTrustedProxies(prefixes []netip.Prefix) RouterOption {
	return func(s *routerSettings) {
		if len(prefixes) > 0 {
			s.trustedProxies = prefixes
		}
	}
}

func defaultTrustedProxies() []netip.Prefix {
	return []netip.Prefix{netip.MustParsePrefix("127.0.0.0/8"), netip.MustParsePrefix("::1/128")}
}

// ParseTrustedProxies parses a comma-separated list of CIDRs or addresses.
func ParseTrustedProxies(raw string) ([]netip.Prefix, error) {
	var out []netip.Prefix
	for _, part := range strings.Split(raw, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		if !strings.Contains(part, "/") {
			addr, err := netip.ParseAddr(part)
			if err != nil {
				return nil, err
			}
			out = append(out, netip.PrefixFrom(addr.Unmap(), addr.Unmap().BitLen()))
			continue
		}
		prefix, err := netip.ParsePrefix(part)
		if err != nil {
			return nil, err
		}
		out = append(out, prefix.Masked())
	}
	return out, nil
}

// clientIPKey is the per-client rate-limit key. The gateway listens on
// loopback behind nginx (deploy/nginx/connect.conf), so RemoteAddr is always
// 127.0.0.1 there: keying on it (httprate.LimitByIP) put every member in the
// world into ONE bucket of GATEWAY_RATE_LIMIT_REQUESTS per window. nginx sets
// X-Real-IP to $remote_addr; it is honoured only from a trusted proxy. IPv6
// clients are grouped by /64, the smallest block a subscriber usually holds.
func clientIPKey(trusted []netip.Prefix) func(*http.Request) (string, error) {
	return func(r *http.Request) (string, error) {
		host, _, err := net.SplitHostPort(r.RemoteAddr)
		if err != nil {
			host = r.RemoteAddr
		}
		remote, err := netip.ParseAddr(host)
		if err != nil {
			return host, nil
		}
		remote = remote.Unmap()
		client := remote
		if prefixesContain(trusted, remote) {
			if forwarded, err := netip.ParseAddr(strings.TrimSpace(r.Header.Get("X-Real-IP"))); err == nil {
				client = forwarded.Unmap()
			}
		}
		if client.Is6() {
			if block, err := client.Prefix(64); err == nil {
				return block.String(), nil
			}
		}
		return client.String(), nil
	}
}

func prefixesContain(prefixes []netip.Prefix, addr netip.Addr) bool {
	for _, prefix := range prefixes {
		if prefix.Contains(addr) {
			return true
		}
	}
	return false
}

// newUpstreamTransport keeps a warm pool of gateway->BFF connections.
// http.DefaultTransport keeps only 2 idle connections per host, so under
// concurrency nearly every proxied request opened (and later closed) its own
// TCP connection to the BFF, leaving thousands of sockets in TIME_WAIT.
// No response-header timeout: realtime streams are long-lived; the BFF's
// timeout tiers bound ordinary requests.
func newUpstreamTransport() *http.Transport {
	return &http.Transport{
		DialContext: (&net.Dialer{
			Timeout:   5 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		MaxIdleConns:          2048,
		MaxIdleConnsPerHost:   1024,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   5 * time.Second,
		ExpectContinueTimeout: time.Second,
	}
}
