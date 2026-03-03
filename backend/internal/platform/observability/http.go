package observability

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"
)

const CorrelationIDHeader = "X-Correlation-ID"

type correlationIDContextKey struct{}

func CorrelationIDFromContext(ctx context.Context) string {
	value, _ := ctx.Value(correlationIDContextKey{}).(string)
	return value
}

func CorrelationIDMiddleware(log *zap.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			correlationID := r.Header.Get(CorrelationIDHeader)
			if correlationID == "" {
				correlationID = uuid.NewString()
			}

			ctx := context.WithValue(r.Context(), correlationIDContextKey{}, correlationID)
			r = r.WithContext(ctx)

			w.Header().Set(CorrelationIDHeader, correlationID)
			next.ServeHTTP(w, r)

			log.Debug("correlation_id_assigned",
				zap.String("correlation_id", correlationID),
				zap.String("path", r.URL.Path),
			)
		})
	}
}

func GlobalExceptionMiddleware(log *zap.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if recovered := recover(); recovered != nil {
					correlationID := CorrelationIDFromContext(r.Context())

					log.Error("http_unhandled_exception",
						zap.Any("panic", recovered),
						zap.String("correlation_id", correlationID),
						zap.String("method", r.Method),
						zap.String("path", r.URL.Path),
						zap.Stack("stacktrace"),
					)

					w.Header().Set("Content-Type", "application/json")
					if correlationID != "" {
						w.Header().Set(CorrelationIDHeader, correlationID)
					}
					w.WriteHeader(http.StatusInternalServerError)
					_ = json.NewEncoder(w).Encode(map[string]any{
						"success":        false,
						"error":          "internal server error",
						"error_code":     "INTERNAL_SERVER_ERROR",
						"correlation_id": correlationID,
					})
				}
			}()

			next.ServeHTTP(w, r)
		})
	}
}

type HTTPMetrics struct {
	RequestCount *prometheus.CounterVec
	Latency      *prometheus.HistogramVec
}

func NewHTTPMetrics(reg prometheus.Registerer) *HTTPMetrics {
	metrics := &HTTPMetrics{
		RequestCount: prometheus.NewCounterVec(
			prometheus.CounterOpts{
				Namespace: "verified_dating",
				Subsystem: "http",
				Name:      "requests_total",
				Help:      "Total HTTP requests.",
			},
			[]string{"method", "route", "status"},
		),
		Latency: prometheus.NewHistogramVec(
			prometheus.HistogramOpts{
				Namespace: "verified_dating",
				Subsystem: "http",
				Name:      "request_duration_seconds",
				Help:      "HTTP request latency.",
				Buckets:   prometheus.DefBuckets,
			},
			[]string{"method", "route"},
		),
	}

	reg.MustRegister(metrics.RequestCount, metrics.Latency)
	return metrics
}

func RequestLoggingMiddleware(log *zap.Logger, metrics *HTTPMetrics, routeName string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			wrapped := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
			next.ServeHTTP(wrapped, r)

			statusCode := strconv.Itoa(wrapped.status)
			duration := time.Since(start).Seconds()

			metrics.RequestCount.WithLabelValues(r.Method, routeName, statusCode).Inc()
			metrics.Latency.WithLabelValues(r.Method, routeName).Observe(duration)

			correlationID := CorrelationIDFromContext(r.Context())

			log.Info("http_request",
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
				zap.String("route", routeName),
				zap.Int("status", wrapped.status),
				zap.Float64("duration_seconds", duration),
				zap.String("correlation_id", correlationID),
			)
		})
	}
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *statusRecorder) WriteHeader(statusCode int) {
	s.status = statusCode
	s.ResponseWriter.WriteHeader(statusCode)
}
