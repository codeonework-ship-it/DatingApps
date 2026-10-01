package mobile

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

type fakeChatRealtimeStore struct {
	mu             sync.Mutex
	events         []chatRealtimeEvent
	requestedAfter []int64
	delivered      []int64
}

type revokingRealtimeAuthorizer struct {
	mu    sync.Mutex
	calls int
}

func (a *revokingRealtimeAuthorizer) authorizeRealtimeSession(_ context.Context, _ securityPrincipal) error {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.calls++
	if a.calls > 1 {
		return errors.New("revoked")
	}
	return nil
}

func (f *fakeChatRealtimeStore) listEvents(_ context.Context, _ string, after int64, _ int) ([]chatRealtimeEvent, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.requestedAfter = append(f.requestedAfter, after)
	out := make([]chatRealtimeEvent, 0)
	for _, event := range f.events {
		if event.Sequence > after {
			out = append(out, event)
		}
	}
	return out, nil
}

func (f *fakeChatRealtimeStore) markDelivered(_ context.Context, _ string, sequence int64) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.delivered = append(f.delivered, sequence)
	return nil
}

func TestChatRealtimeWebSocketReplaysAfterCursor(t *testing.T) {
	store := &fakeChatRealtimeStore{events: []chatRealtimeEvent{{
		Sequence:   42,
		EventID:    "event-42",
		Type:       "message.created",
		MatchID:    "match-1",
		Payload:    map[string]any{"message_id": "message-1", "match_id": "match-1"},
		OccurredAt: time.Now().UTC().Format(time.RFC3339Nano),
	}}}
	server := &Server{realtime: store, log: zap.NewNop()}
	metrics := observability.NewHTTPMetrics(prometheus.NewRegistry())
	handler := observability.RequestLoggingMiddleware(zap.NewNop(), metrics, "test")(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			recorder := &responseStatusRecorder{ResponseWriter: w, status: http.StatusOK}
			principal := securityPrincipal{UserID: "user-1", Roles: map[string]bool{"user": true}}
			ctx := context.WithValue(r.Context(), securityPrincipalContextKey{}, principal)
			server.streamChatEvents(recorder, r.WithContext(ctx))
		}),
	)
	httpServer := httptest.NewServer(handler)
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/v1/realtime/chat?after=41"
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	_ = conn.SetReadDeadline(time.Now().Add(2 * time.Second))

	var connected map[string]any
	if err := conn.ReadJSON(&connected); err != nil {
		t.Fatal(err)
	}
	if connected["type"] != "stream.connected" || int64(connected["sequence"].(float64)) != 41 {
		t.Fatalf("unexpected connected envelope: %#v", connected)
	}
	var event chatRealtimeEvent
	if err := conn.ReadJSON(&event); err != nil {
		t.Fatal(err)
	}
	if event.Sequence != 42 || event.Type != "message.created" {
		t.Fatalf("unexpected event: %#v", event)
	}

	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		store.mu.Lock()
		delivered := append([]int64(nil), store.delivered...)
		store.mu.Unlock()
		if len(delivered) == 1 && delivered[0] == 42 {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("event delivery was not checkpointed")
}

func TestChatRealtimeRequiresPrincipal(t *testing.T) {
	server := &Server{realtime: &fakeChatRealtimeStore{}, log: zap.NewNop()}
	recorder := httptest.NewRecorder()
	server.streamChatEvents(recorder, httptest.NewRequest(http.MethodGet, "/v1/realtime/chat", nil))
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
}

func TestChatRealtimeClosesAnAlreadyConnectedRevokedSession(t *testing.T) {
	authorizer := &revokingRealtimeAuthorizer{}
	server := &Server{realtime: &fakeChatRealtimeStore{}, realtimeAuthorizer: authorizer, log: zap.NewNop()}
	httpServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		principal := securityPrincipal{SessionID: "session-1", UserID: "user-1", Roles: map[string]bool{"user": true}}
		ctx := context.WithValue(r.Context(), securityPrincipalContextKey{}, principal)
		server.streamChatEvents(w, r.WithContext(ctx))
	}))
	defer httpServer.Close()

	wsURL := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/v1/realtime/chat"
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	_ = conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	var connected map[string]any
	if err := conn.ReadJSON(&connected); err != nil {
		t.Fatal(err)
	}
	_, _, err = conn.ReadMessage()
	if closeErr, ok := err.(*websocket.CloseError); !ok || closeErr.Code != websocket.ClosePolicyViolation {
		t.Fatalf("expected policy close after revocation, got %v", err)
	}
}
