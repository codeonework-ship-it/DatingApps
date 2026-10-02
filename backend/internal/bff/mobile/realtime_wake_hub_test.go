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
	"go.uber.org/zap"
)

type fakeWakeScanner struct {
	mu     sync.Mutex
	top    int64
	latest map[string]int64
	afters []int64
	err    error
}

func (f *fakeWakeScanner) scan(_ context.Context, after int64, prime bool) (map[string]int64, int64, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.err != nil {
		return nil, 0, f.err
	}
	if prime {
		return nil, f.top, nil
	}
	f.afters = append(f.afters, after)
	out := map[string]int64{}
	top := int64(0)
	for user, seq := range f.latest {
		if seq > after {
			out[user] = seq
			if seq > top {
				top = seq
			}
		}
	}
	return out, top, nil
}

func (f *fakeWakeScanner) publish(user string, seq int64) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.latest == nil {
		f.latest = map[string]int64{}
	}
	f.latest[user] = seq
}

func TestRealtimeWakeHubWakesOnlyMembersWithNewEvents(t *testing.T) {
	scanner := &fakeWakeScanner{top: 5000}
	hub := newRealtimeWakeHub("test", time.Hour, zap.NewNop(), scanner.scan)
	alice, unsubscribeAlice := hub.subscribe("alice")
	defer unsubscribeAlice()
	bob, unsubscribeBob := hub.subscribe("bob")
	defer hub.Close()
	ctx := context.Background()

	hub.tick(ctx) // the background run may already have primed; ticks are idempotent
	hub.tick(ctx)
	scanner.publish("alice", 5003)
	hub.tick(ctx)

	select {
	case <-alice.C():
	case <-time.After(time.Second):
		t.Fatal("alice was not woken for her new event")
	}
	if alice.Seq() != 5003 {
		t.Fatalf("alice wake sequence = %d, want 5003", alice.Seq())
	}
	select {
	case <-bob.C():
		t.Fatal("bob was woken without an event")
	default:
	}
	scanner.mu.Lock()
	lastAfter := scanner.afters[len(scanner.afters)-1]
	scanner.mu.Unlock()
	// The scan re-reads a window below the high-water mark so late commits of
	// lower sequences still wake their recipients.
	if want := int64(5003 - realtimeWakeLookbackRows); lastAfter != want && lastAfter != 5000-realtimeWakeLookbackRows {
		t.Fatalf("scan lower bound = %d, want the lookback window below the high-water mark", lastAfter)
	}

	// Unsubscribed sockets are never signalled again.
	unsubscribeBob()
	scanner.publish("bob", 5010)
	hub.tick(ctx)
	select {
	case <-bob.C():
		t.Fatal("unsubscribed socket was woken")
	default:
	}
}

func TestRealtimeWakePollDueIgnoresAlreadyReadSequences(t *testing.T) {
	sub := &realtimeWakeSub{ch: make(chan struct{}, 1)}
	sub.signal(40)
	if realtimeWakePollDue(sub, 40, 0) {
		t.Fatal("a wake at or below the socket cursor must not trigger a read")
	}
	if realtimeWakePollDue(sub, 10, 40) {
		t.Fatal("a wake already covered by the last read must not trigger another read")
	}
	sub.signal(41)
	if !realtimeWakePollDue(sub, 40, 40) {
		t.Fatal("a newer sequence must trigger a read")
	}
	sub.signal(30) // never moves backwards
	if sub.Seq() != 41 {
		t.Fatalf("wake sequence went backwards: %d", sub.Seq())
	}
}

func TestRealtimeWakeHubScanFailureFallsBackQuietly(t *testing.T) {
	scanner := &fakeWakeScanner{err: errors.New("database unavailable")}
	hub := newRealtimeWakeHub("test", time.Hour, zap.NewNop(), scanner.scan)
	sub, unsubscribe := hub.subscribe("alice")
	defer unsubscribe()
	defer hub.Close()
	hub.tick(context.Background())
	select {
	case <-sub.C():
		t.Fatal("a failed scan must not wake sockets; their fallback poll covers it")
	default:
	}
}

// The socket no longer reads the database every 400ms while idle: it reads on
// connect, when the hub reports a new event for the member, and on the slow
// fallback poll.
func TestChatRealtimeSocketReadsOnlyWhenWoken(t *testing.T) {
	store := &fakeChatRealtimeStore{}
	scanner := &fakeWakeScanner{top: 1}
	hub := newRealtimeWakeHub("chat", 20*time.Millisecond, zap.NewNop(), scanner.scan)
	server := &Server{realtime: store, chatWake: hub, log: zap.NewNop()}
	defer hub.Close()
	httpServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		principal := securityPrincipal{SessionID: "session-1", UserID: "user-1", Roles: map[string]bool{"user": true}}
		ctx := context.WithValue(r.Context(), securityPrincipalContextKey{}, principal)
		server.streamChatEvents(w, r.WithContext(ctx))
	}))
	defer httpServer.Close()

	conn, _, err := websocket.DefaultDialer.Dial("ws"+strings.TrimPrefix(httpServer.URL, "http")+"/v1/realtime/chat", nil)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	_ = conn.SetReadDeadline(time.Now().Add(3 * time.Second))
	var connected map[string]any
	if err := conn.ReadJSON(&connected); err != nil {
		t.Fatal(err)
	}

	time.Sleep(1200 * time.Millisecond) // three old-style poll intervals, idle
	store.mu.Lock()
	idleReads := len(store.requestedAfter)
	store.mu.Unlock()
	if idleReads != 1 {
		t.Fatalf("idle socket read the outbox %d times in 1.2s, want only the initial read", idleReads)
	}

	store.mu.Lock()
	store.events = append(store.events, chatRealtimeEvent{
		Sequence: 7, EventID: "event-7", Type: "message.created", MatchID: "match-1",
		Payload: map[string]any{"message_id": "m-7"}, OccurredAt: time.Now().UTC().Format(time.RFC3339Nano),
	})
	store.mu.Unlock()
	scanner.publish("user-1", 7)

	var event chatRealtimeEvent
	if err := conn.ReadJSON(&event); err != nil {
		t.Fatalf("woken socket did not deliver the new event: %v", err)
	}
	if event.Sequence != 7 {
		t.Fatalf("unexpected event %#v", event)
	}
}
