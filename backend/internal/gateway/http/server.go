package gatewayhttp

import (
	"encoding/json"
	"net/http"
	"net/http/httputil"
	"net/url"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
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
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		req.Host = target.Host
		req.Header.Set("X-Forwarded-Host", req.Host)
	}

	r := chi.NewRouter()
	r.Use(observability.CorrelationIDMiddleware(log))
	r.Use(observability.GlobalExceptionMiddleware(log))
	r.Use(observability.InflightSheddingMiddleware(log, "api_gateway", maxInFlight, retryAfterSec))
	r.Use(httprate.LimitByIP(rateLimitRequests, rateLimitWindow))
	r.Use(observability.RequestLoggingMiddleware(log, metrics, "api_gateway"))

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
	r.Mount("/debug", middleware.Profiler())
	r.Handle("/openapi.yaml", proxy)
	r.Handle("/docs", proxy)
	r.Handle("/docs/*", proxy)
	r.Handle(apiPrefix+"/*", proxy)
	r.Handle(apiPrefix, proxy)

	return r, nil
}
