package mobile

import (
	"errors"
	"net/http/httptest"
	"testing"

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// A generic 503 from member handlers must leave the cause in the logs.
func TestWriteActivityErrorLogsUnexpectedCause(t *testing.T) {
	core, logs := observer.New(zap.ErrorLevel)
	previous := unexpectedErrorLog.Load()
	setUnexpectedErrorLogger(zap.New(core))
	t.Cleanup(func() { unexpectedErrorLog.Store(previous) })

	rec := httptest.NewRecorder()
	rec.Header().Set(observability.CorrelationIDHeader, "corr-123")
	writeActivityError(rec, errors.New("deadlock detected"), "Try again later.")
	if rec.Code != 503 {
		t.Fatalf("status %d", rec.Code)
	}
	entries := logs.FilterMessage("unexpected_handler_error").All()
	if len(entries) != 1 {
		t.Fatalf("want one log entry, got %d", len(entries))
	}
	fields := entries[0].ContextMap()
	if fields["error"] != "deadlock detected" || fields["correlation_id"] != "corr-123" {
		t.Fatalf("fields %v", fields)
	}

	// Expected outcomes (not found, forbidden) are not logged as errors.
	writeActivityError(httptest.NewRecorder(), errDatePlanNotFound, "x")
	if n := logs.FilterMessage("unexpected_handler_error").Len(); n != 1 {
		t.Fatalf("not-found was logged: %d", n)
	}
}
