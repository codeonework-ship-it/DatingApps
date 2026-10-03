package observability

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"go.uber.org/zap"
)

func InflightSheddingMiddleware(log *zap.Logger, scope string, maxInFlight int, retryAfterSec int) func(http.Handler) http.Handler {
	return InflightSheddingMiddlewareWithMetrics(log, nil, scope, maxInFlight, retryAfterSec)
}

// InflightSheddingMiddlewareWithMetrics is InflightSheddingMiddleware that also
// counts each shed request on requests_shed_total{domain="inflight"} (when the
// metrics carry ShedCount) and notes the refusal for the server event log.
func InflightSheddingMiddlewareWithMetrics(log *zap.Logger, metrics *HTTPMetrics, scope string, maxInFlight int, retryAfterSec int) func(http.Handler) http.Handler {
	if log == nil {
		log = zap.NewNop()
	}
	if maxInFlight <= 0 {
		return func(next http.Handler) http.Handler { return next }
	}
	if retryAfterSec <= 0 {
		retryAfterSec = 1
	}

	limiter := make(chan struct{}, maxInFlight)
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if strings.EqualFold(strings.TrimSpace(r.Header.Get("Upgrade")), "websocket") {
				next.ServeHTTP(w, r)
				return
			}
			select {
			case limiter <- struct{}{}:
				defer func() { <-limiter }()
				next.ServeHTTP(w, r)
				return
			default:
				NoteRefusal(r.Context(), RefusalShedInflight)
				if metrics != nil && metrics.ShedCount != nil {
					metrics.ShedCount.WithLabelValues(ShedDomainInflight).Inc()
				}
				correlationID := CorrelationIDFromContext(r.Context())
				w.Header().Set("Content-Type", "application/json")
				w.Header().Set("Retry-After", strconv.Itoa(retryAfterSec))
				if correlationID != "" {
					w.Header().Set(CorrelationIDHeader, correlationID)
				}
				w.WriteHeader(http.StatusTooManyRequests)
				_ = json.NewEncoder(w).Encode(map[string]any{
					"success":         false,
					"error":           "service overloaded, retry later",
					"error_code":      "REQUEST_SHEDDED",
					"retry_after_sec": retryAfterSec,
					"correlation_id":  correlationID,
				})
				log.Warn(
					"request_shedded",
					zap.String("scope", scope),
					zap.String("method", r.Method),
					zap.String("path", RedactedRequestPath(r)),
					zap.Int("max_in_flight", maxInFlight),
					zap.String("correlation_id", correlationID),
				)
			}
		})
	}
}
