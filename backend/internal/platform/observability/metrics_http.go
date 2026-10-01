package observability

import (
	"bufio"
	"net"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"
)

// Service names used as the constant "service" label on the HTTP RED metrics.
const (
	ServiceMobileBFF  = "mobile_bff"
	ServiceAPIGateway = "api_gateway"
)

// Route labels that are not chi route templates.
const (
	// RouteUnmatched labels requests that no registered route resolved (404
	// from the router itself, or a method the route does not accept). Raw
	// paths are never used as label values: scanners would explode cardinality.
	RouteUnmatched = "unmatched"
	// RouteOverflow labels requests once maxRouteLabels distinct templates have
	// been seen. Route templates come from code, so reaching it means a router
	// is generating patterns dynamically and needs fixing.
	RouteOverflow = "other"

	maxRouteLabels = 1000
)

// HTTPMetrics holds the Prometheus collectors owned by one HTTP process.
//
// Every process registers only the collectors it actually updates: the edge
// gateway (NewGatewayMetrics) gets the request/realtime RED set, the mobile BFF
// (NewBFFMetrics) additionally gets reliability, queue, notification,
// progression, SOS and worker collectors. A gateway therefore never exposes a
// notification or SOS gauge stuck at zero.
type HTTPMetrics struct {
	Service string

	// RED, labelled {service, method, route, status_class}. route is the chi
	// route template ("/v1/profile/{userID}"), never the raw path.
	RequestCount    *prometheus.CounterVec
	Latency         *prometheus.HistogramVec
	ResponsesByCode *prometheus.CounterVec
	InFlight        prometheus.Gauge

	// Upgraded (WebSocket) connections, tracked by the request middleware when
	// a handler hijacks the connection. Their lifetime is excluded from Latency.
	RealtimeConnections *prometheus.GaugeVec
	RealtimeOpened      *prometheus.CounterVec
	RealtimeDuration    *prometheus.HistogramVec

	// BFF-only collectors. Nil in the gateway.
	TimeoutCount                 *prometheus.CounterVec
	IdempotencyReplays           *prometheus.CounterVec
	IdempotencyConflicts         *prometheus.CounterVec
	IdempotencyProcessing        prometheus.Gauge
	IdempotencyExpiredLeases     prometheus.Gauge
	IdempotencyRetentionBacklog  prometheus.Gauge
	PostgresOpenConnections      prometheus.Gauge
	PostgresInUseConnections     prometheus.Gauge
	ShedCount                    *prometheus.CounterVec
	NotificationQueueDepth       prometheus.Gauge
	NotificationOldestPendingAge prometheus.Gauge
	NotificationDeadLetters      prometheus.Gauge
	NotificationProcessing       prometheus.Gauge
	NotificationPushSuccess      prometheus.Gauge
	NotificationPushAttempts15m  prometheus.Gauge
	NotificationPushP95LatencyMS prometheus.Gauge
	NotificationBatchFailures    prometheus.Counter
	ProgressionQueueDepth        prometheus.Gauge
	ProgressionProcessing        prometheus.Gauge
	ProgressionDeadLetters       prometheus.Gauge
	ProgressionOldestPendingAge  prometheus.Gauge
	ProgressionCompletionP95     prometheus.Gauge
	ProgressionOpenFraudCases    prometheus.Gauge
	ProgressionCapDenials15m     prometheus.Gauge
	SOSDeliveryQueueDepth        prometheus.Gauge
	SOSDeliveryOverdue           prometheus.Gauge
	SOSDeliveryDeadLetters       prometheus.Gauge
	SOSDeliveryOldestPendingAge  prometheus.Gauge
	TrustRetentionRuns           *prometheus.CounterVec
	RealtimeDeliveryLag          *prometheus.HistogramVec
	Workers                      *WorkerMetrics

	queues *queueCollector
	routes *routeLabeler
}

// NewGatewayMetrics registers the edge (api_gateway) collectors only.
func NewGatewayMetrics(reg prometheus.Registerer) *HTTPMetrics {
	return newHTTPServerMetrics(reg, ServiceAPIGateway)
}

// NewHTTPMetrics is the historical constructor; it returns the BFF set.
// Deprecated: use NewBFFMetrics or NewGatewayMetrics so each process registers
// only the collectors it updates.
func NewHTTPMetrics(reg prometheus.Registerer) *HTTPMetrics {
	return NewBFFMetrics(reg)
}

func newHTTPServerMetrics(reg prometheus.Registerer, service string) *HTTPMetrics {
	constLabels := prometheus.Labels{"service": service}
	m := &HTTPMetrics{
		Service: service,
		RequestCount: prometheus.NewCounterVec(prometheus.CounterOpts{
			Namespace: "verified_dating", Subsystem: "http", Name: "requests_total",
			Help:        "HTTP requests by method, chi route template and status class.",
			ConstLabels: constLabels,
		}, []string{"method", "route", "status_class"}),
		Latency: prometheus.NewHistogramVec(prometheus.HistogramOpts{
			Namespace: "verified_dating", Subsystem: "http", Name: "request_duration_seconds",
			Help:        "HTTP request latency by method and chi route template (upgraded connections excluded).",
			ConstLabels: constLabels,
			Buckets:     prometheus.DefBuckets,
		}, []string{"method", "route"}),
		ResponsesByCode: prometheus.NewCounterVec(prometheus.CounterOpts{
			Namespace: "verified_dating", Subsystem: "http", Name: "responses_by_code_total",
			Help:        "HTTP responses by exact status code (no route label, bounded by code).",
			ConstLabels: constLabels,
		}, []string{"code"}),
		InFlight: prometheus.NewGauge(prometheus.GaugeOpts{
			Namespace: "verified_dating", Subsystem: "http", Name: "in_flight_requests",
			Help:        "HTTP requests currently being served (upgraded connections excluded).",
			ConstLabels: constLabels,
		}),
		RealtimeConnections: prometheus.NewGaugeVec(prometheus.GaugeOpts{
			Namespace: "verified_dating", Subsystem: "realtime", Name: "connections",
			Help:        "Open upgraded (WebSocket) connections by route template.",
			ConstLabels: constLabels,
		}, []string{"route"}),
		RealtimeOpened: prometheus.NewCounterVec(prometheus.CounterOpts{
			Namespace: "verified_dating", Subsystem: "realtime", Name: "connections_opened_total",
			Help:        "Upgraded (WebSocket) connections accepted by route template.",
			ConstLabels: constLabels,
		}, []string{"route"}),
		RealtimeDuration: prometheus.NewHistogramVec(prometheus.HistogramOpts{
			Namespace: "verified_dating", Subsystem: "realtime", Name: "connection_duration_seconds",
			Help:        "Lifetime of closed upgraded (WebSocket) connections.",
			ConstLabels: constLabels,
			Buckets:     []float64{1, 5, 10, 30, 60, 300, 900, 1800, 3600, 7200},
		}, []string{"route"}),
		routes: newRouteLabeler(maxRouteLabels),
	}
	reg.MustRegister(
		m.RequestCount, m.Latency, m.ResponsesByCode, m.InFlight,
		m.RealtimeConnections, m.RealtimeOpened, m.RealtimeDuration,
	)
	return m
}

// RequestLoggingMiddleware records RED metrics and an access log line. It
// must be mounted with chi's Router.Use on the root router so the route
// template is resolved by the time the handler returns. serviceName is used
// for the log line and as a fallback when metrics is nil.
func RequestLoggingMiddleware(log *zap.Logger, metrics *HTTPMetrics, serviceName string) func(http.Handler) http.Handler {
	if log == nil {
		log = zap.NewNop()
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			wrapped := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
			if metrics != nil && metrics.InFlight != nil {
				metrics.InFlight.Inc()
			}
			inFlight := true
			var realtimeRoute string
			wrapped.onHijack = func() {
				if metrics == nil {
					return
				}
				if inFlight && metrics.InFlight != nil {
					metrics.InFlight.Dec()
					inFlight = false
				}
				realtimeRoute = metrics.routeLabel(r, http.StatusSwitchingProtocols)
				metrics.RealtimeOpened.WithLabelValues(realtimeRoute).Inc()
				metrics.RealtimeConnections.WithLabelValues(realtimeRoute).Inc()
			}
			defer func() {
				if inFlight && metrics != nil && metrics.InFlight != nil {
					metrics.InFlight.Dec()
				}
			}()

			next.ServeHTTP(wrapped, r)

			duration := time.Since(start).Seconds()
			status := wrapped.status
			if wrapped.hijacked {
				status = http.StatusSwitchingProtocols
			}
			method := normalizeMethod(r.Method)
			route := RouteUnmatched
			if metrics != nil {
				route = metrics.routeLabel(r, status)
				metrics.RequestCount.WithLabelValues(method, route, StatusClass(status)).Inc()
				metrics.ResponsesByCode.WithLabelValues(strconv.Itoa(status)).Inc()
				if wrapped.hijacked {
					metrics.RealtimeConnections.WithLabelValues(realtimeRoute).Dec()
					metrics.RealtimeDuration.WithLabelValues(realtimeRoute).Observe(duration)
				} else {
					metrics.Latency.WithLabelValues(method, route).Observe(duration)
				}
			}

			service := serviceName
			if metrics != nil && metrics.Service != "" {
				service = metrics.Service
			}
			log.Info("http_request",
				zap.String("service", service),
				zap.String("method", r.Method),
				zap.String("path", RedactedRequestPath(r)),
				zap.String("route", route),
				zap.Int("status", status),
				zap.Float64("duration_seconds", duration),
				zap.String("correlation_id", CorrelationIDFromContext(r.Context())),
			)
		})
	}
}

func (m *HTTPMetrics) routeLabel(r *http.Request, status int) string {
	if m == nil || m.routes == nil {
		return RouteLabel(r, status)
	}
	return m.routes.admit(RouteLabel(r, status))
}

// RouteLabel returns the bounded route label for a request that chi has
// already routed: the route template, or RouteUnmatched when no registered
// route resolved it.
func RouteLabel(r *http.Request, status int) string {
	rctx := chi.RouteContext(r.Context())
	if rctx == nil {
		return RouteUnmatched
	}
	pattern := rctx.RoutePattern()
	// Resolve the template ourselves when routing never ran (a middleware
	// answered first: shedding 429, auth 401) or when a 404/405 may have come
	// from the router itself - mounted sub-routers leave a partial "/v1/*"
	// pattern behind when nothing inside them matched.
	if pattern == "" || status == http.StatusNotFound || status == http.StatusMethodNotAllowed {
		if rctx.Routes == nil {
			if pattern == "" {
				return RouteUnmatched
			}
			return pattern
		}
		path := r.URL.RawPath
		if path == "" {
			path = r.URL.Path
		}
		probe := chi.NewRouteContext()
		if !rctx.Routes.Match(probe, r.Method, path) {
			return RouteUnmatched
		}
		if resolved := probe.RoutePattern(); resolved != "" {
			return resolved
		}
		if pattern == "" {
			return RouteUnmatched
		}
	}
	return pattern
}

// StatusClass maps a status code onto "1xx".."5xx".
func StatusClass(status int) string {
	switch {
	case status >= 100 && status < 200:
		return "1xx"
	case status >= 200 && status < 300:
		return "2xx"
	case status >= 300 && status < 400:
		return "3xx"
	case status >= 400 && status < 500:
		return "4xx"
	case status >= 500 && status < 600:
		return "5xx"
	default:
		return "unknown"
	}
}

func normalizeMethod(method string) string {
	switch method {
	case http.MethodGet, http.MethodPost, http.MethodPut, http.MethodPatch,
		http.MethodDelete, http.MethodHead, http.MethodOptions:
		return method
	default:
		return "OTHER"
	}
}

type routeLabeler struct {
	max  int
	mu   sync.RWMutex
	seen map[string]struct{}
}

func newRouteLabeler(max int) *routeLabeler {
	return &routeLabeler{max: max, seen: map[string]struct{}{}}
}

func (l *routeLabeler) admit(route string) string {
	if route == RouteUnmatched {
		return route
	}
	l.mu.RLock()
	_, ok := l.seen[route]
	l.mu.RUnlock()
	if ok {
		return route
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	if _, ok := l.seen[route]; ok {
		return route
	}
	if len(l.seen) >= l.max {
		return RouteOverflow
	}
	l.seen[route] = struct{}{}
	return route
}

type statusRecorder struct {
	http.ResponseWriter
	status      int
	wroteHeader bool
	hijacked    bool
	onHijack    func()
}

func (s *statusRecorder) WriteHeader(statusCode int) {
	if !s.wroteHeader {
		s.status = statusCode
		s.wroteHeader = true
	}
	s.ResponseWriter.WriteHeader(statusCode)
}

func (s *statusRecorder) Write(b []byte) (int, error) {
	if !s.wroteHeader {
		s.wroteHeader = true
	}
	return s.ResponseWriter.Write(b)
}

func (s *statusRecorder) Flush() {
	if flusher, ok := s.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
}

// Unwrap lets http.ResponseController reach the underlying writer.
func (s *statusRecorder) Unwrap() http.ResponseWriter {
	return s.ResponseWriter
}

func (s *statusRecorder) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	hijacker, ok := s.ResponseWriter.(http.Hijacker)
	if !ok {
		return nil, nil, http.ErrNotSupported
	}
	conn, rw, err := hijacker.Hijack()
	if err == nil && !s.hijacked {
		s.hijacked = true
		if s.onHijack != nil {
			s.onHijack()
		}
	}
	return conn, rw, err
}
