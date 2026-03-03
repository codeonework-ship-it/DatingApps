package mobile

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestIdempotencyMiddleware_ReplaysCachedResponse(t *testing.T) {
	s := &Server{
		cfg:         config.Config{APIPrefix: "/v1"},
		idempotency: newIdempotencyStore(time.Minute),
	}

	calls := 0
	handler := s.idempotencyMiddleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		calls++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(fmt.Sprintf(`{"value":%d}`, calls)))
	}))

	req1 := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	req1.Header.Set("Idempotency-Key", "key-1")
	rec1 := httptest.NewRecorder()
	handler.ServeHTTP(rec1, req1)

	if rec1.Code != http.StatusOK {
		t.Fatalf("expected first status 200, got %d", rec1.Code)
	}
	if got := rec1.Body.String(); got != `{"value":1}` {
		t.Fatalf("unexpected first body: %s", got)
	}

	req2 := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	req2.Header.Set("Idempotency-Key", "key-1")
	rec2 := httptest.NewRecorder()
	handler.ServeHTTP(rec2, req2)

	if rec2.Code != http.StatusOK {
		t.Fatalf("expected replay status 200, got %d", rec2.Code)
	}
	if got := rec2.Body.String(); got != `{"value":1}` {
		t.Fatalf("unexpected replay body: %s", got)
	}
	if rec2.Header().Get("X-Idempotent-Replay") != "true" {
		t.Fatalf("expected replay header true")
	}
	if calls != 1 {
		t.Fatalf("expected single handler invocation, got %d", calls)
	}
}

func TestIdempotencyMiddleware_DoesNotCacheServerErrors(t *testing.T) {
	s := &Server{
		cfg:         config.Config{APIPrefix: "/v1"},
		idempotency: newIdempotencyStore(time.Minute),
	}

	calls := 0
	handler := s.idempotencyMiddleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		calls++
		if calls == 1 {
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte(`{"error":"boom"}`))
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"ok":true}`))
	}))

	req1 := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	req1.Header.Set("Idempotency-Key", "key-2")
	rec1 := httptest.NewRecorder()
	handler.ServeHTTP(rec1, req1)

	req2 := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	req2.Header.Set("Idempotency-Key", "key-2")
	rec2 := httptest.NewRecorder()
	handler.ServeHTTP(rec2, req2)

	if rec1.Code != http.StatusInternalServerError {
		t.Fatalf("expected first status 500, got %d", rec1.Code)
	}
	if rec2.Code != http.StatusOK {
		t.Fatalf("expected second status 200, got %d", rec2.Code)
	}
	if calls != 2 {
		t.Fatalf("expected two handler invocations, got %d", calls)
	}
}
