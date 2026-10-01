package gatewayhttp

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httputil"
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
) (http.Handler, error) {
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
	r.Use(httprate.LimitByIP(rateLimitRequests, rateLimitWindow))

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
