package observability

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
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
				zap.String("path", RedactedRequestPath(r)),
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
						zap.String("path", RedactedRequestPath(r)),
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
