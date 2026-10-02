package mobile

import (
	"context"
	"database/sql"
	"errors"
	"sync"
	"sync/atomic"
	"time"

	"go.uber.org/zap"
)

// realtimeWakeHub replaces per-socket database polling with one shared
// change detector per BFF instance and stream.
//
// Before, every connected socket ran its own 400ms ticker with two queries per
// tick (session check + outbox read), so database load grew with the number
// of open sockets even when nobody was talking: ~5 queries/s per socket, or
// ~300k queries/s for 60k concurrent members. Now one goroutine reads the new
// outbox rows of the last few seconds every tick, grouped by recipient, and
// wakes only the sockets of members who actually have something new. Each
// woken socket still re-checks its session and reads its own events through
// the authoritative per-user query, so visibility rules are unchanged.
//
// The hub is a hint, never the source of truth: sequence ids are allocated
// before commit, so a slow transaction can commit a lower sequence after the
// hub has moved past it. The rescan window (realtimeWakeLookbackRows and
// realtimeWakeLookbackAge) covers ordinary commit skew, and every socket
// still polls on its own every realtimeFallbackPollInterval, so a missed wake
// costs latency (at most that interval), never an event.
type realtimeWakeHub struct {
	name    string
	scan    realtimeWakeScanner
	every   time.Duration
	log     *zap.Logger
	mu      sync.Mutex
	subs    map[string]map[*realtimeWakeSub]struct{}
	high    int64
	primed  bool
	started sync.Once
	cancel  context.CancelFunc
	done    chan struct{}
}

// realtimeWakeScanner returns, per recipient, the highest sequence above
// `after` written recently, plus the highest sequence seen overall. With
// prime=true it only reports the current high-water mark.
type realtimeWakeScanner func(ctx context.Context, after int64, prime bool) (map[string]int64, int64, error)

type realtimeWakeSub struct {
	seq atomic.Int64
	ch  chan struct{}
}

const (
	// realtimeFallbackPollInterval bounds delivery latency when a wake is
	// missed (late commit, hub query failure).
	realtimeFallbackPollInterval = 5 * time.Second
	realtimeWakeLookbackRows     = 2048
	realtimeWakeLookbackAge      = 10 * time.Second
)

func newRealtimeWakeHub(name string, every time.Duration, log *zap.Logger, scan realtimeWakeScanner) *realtimeWakeHub {
	if scan == nil {
		return nil
	}
	if every <= 0 {
		every = chatRealtimePollInterval
	}
	if log == nil {
		log = zap.NewNop()
	}
	return &realtimeWakeHub{name: name, scan: scan, every: every, log: log, subs: map[string]map[*realtimeWakeSub]struct{}{}}
}

// subscribe registers a socket for wakes. The returned channel fires when the
// member may have new events; Seq reports the highest sequence signalled.
func (h *realtimeWakeHub) subscribe(userID string) (*realtimeWakeSub, func()) {
	sub := &realtimeWakeSub{ch: make(chan struct{}, 1)}
	if h == nil {
		return sub, func() {}
	}
	h.started.Do(h.start)
	h.mu.Lock()
	set := h.subs[userID]
	if set == nil {
		set = map[*realtimeWakeSub]struct{}{}
		h.subs[userID] = set
	}
	set[sub] = struct{}{}
	h.mu.Unlock()
	return sub, func() {
		h.mu.Lock()
		defer h.mu.Unlock()
		if set := h.subs[userID]; set != nil {
			delete(set, sub)
			if len(set) == 0 {
				delete(h.subs, userID)
			}
		}
	}
}

func (h *realtimeWakeHub) start() {
	ctx, cancel := context.WithCancel(context.Background())
	h.cancel = cancel
	h.done = make(chan struct{})
	go h.run(ctx)
}

func (h *realtimeWakeHub) run(ctx context.Context) {
	defer close(h.done)
	ticker := time.NewTicker(h.every)
	defer ticker.Stop()
	for {
		h.tick(ctx)
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

// tick runs one scan; exported to tests through the package.
func (h *realtimeWakeHub) tick(ctx context.Context) {
	h.mu.Lock()
	idle := len(h.subs) == 0
	primed, high := h.primed, h.high
	h.mu.Unlock()
	if idle && primed {
		return
	}
	scanCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	if !primed {
		// Start from the current high-water mark: the hub only reports what
		// happens after it starts; sockets read their own backlog directly.
		_, top, err := h.scan(scanCtx, 0, true)
		if err != nil {
			h.logScanError(err)
			return
		}
		h.mu.Lock()
		h.high, h.primed = top, true
		h.mu.Unlock()
		return
	}
	after := high - realtimeWakeLookbackRows
	if after < 0 {
		after = 0
	}
	latest, top, err := h.scan(scanCtx, after, false)
	if err != nil {
		h.logScanError(err)
		return
	}
	h.mu.Lock()
	if top > h.high {
		h.high = top
	}
	for userID, seq := range latest {
		for sub := range h.subs[userID] {
			sub.signal(seq)
		}
	}
	h.mu.Unlock()
}

func (h *realtimeWakeHub) logScanError(err error) {
	if errors.Is(err, context.Canceled) {
		return
	}
	h.log.Warn("realtime_wake_scan_failed", zap.String("stream", h.name), zap.Error(err))
}

func (h *realtimeWakeHub) Close() {
	if h == nil || h.cancel == nil {
		return
	}
	h.cancel()
	<-h.done
}

func (s *realtimeWakeSub) signal(seq int64) {
	for {
		current := s.seq.Load()
		if seq <= current {
			return
		}
		if s.seq.CompareAndSwap(current, seq) {
			break
		}
	}
	select {
	case s.ch <- struct{}{}:
	default:
	}
}

// Seq is the highest sequence the hub has signalled for this socket.
func (s *realtimeWakeSub) Seq() int64 { return s.seq.Load() }

// C fires when new events may be waiting.
func (s *realtimeWakeSub) C() <-chan struct{} { return s.ch }

// realtimeWakePollDue reports whether a socket woken by the hub needs to read
// its events: only when the hub saw something beyond what it already read.
func realtimeWakePollDue(sub *realtimeWakeSub, after, polledThrough int64) bool {
	seq := sub.Seq()
	return seq > after && seq > polledThrough
}

// postgresRealtimeWakeScanner builds the shared scan for an outbox-style
// table keyed by a global sequence. table/timeColumn are compile-time
// constants from this file, never caller input.
func postgresRealtimeWakeScanner(db *sql.DB, table, timeColumn string) realtimeWakeScanner {
	if db == nil {
		return nil
	}
	recentSQL := `SELECT recipient_user_id::text, MAX(sequence_id) FROM ` + table + `
		WHERE sequence_id > $1 AND ` + timeColumn + ` > NOW() - make_interval(secs => $2)
		GROUP BY recipient_user_id`
	topSQL := `SELECT COALESCE(MAX(sequence_id), 0) FROM ` + table
	return func(ctx context.Context, after int64, prime bool) (map[string]int64, int64, error) {
		if prime {
			var top int64
			err := db.QueryRowContext(ctx, topSQL).Scan(&top)
			return nil, top, err
		}
		rows, err := db.QueryContext(ctx, recentSQL, after, realtimeWakeLookbackAge.Seconds())
		if err != nil {
			return nil, 0, err
		}
		defer rows.Close()
		latest := map[string]int64{}
		var top int64
		for rows.Next() {
			var userID string
			var seq int64
			if err := rows.Scan(&userID, &seq); err != nil {
				return nil, 0, err
			}
			latest[userID] = seq
			if seq > top {
				top = seq
			}
		}
		return latest, top, rows.Err()
	}
}

func newChatRealtimeWakeHub(db *sql.DB, log *zap.Logger) *realtimeWakeHub {
	return newRealtimeWakeHub("chat", chatRealtimePollInterval, log,
		postgresRealtimeWakeScanner(db, "matching.realtime_outbox", "occurred_at"))
}

func newNotificationRealtimeWakeHub(db *sql.DB, log *zap.Logger) *realtimeWakeHub {
	return newRealtimeWakeHub("notifications", chatRealtimePollInterval, log,
		postgresRealtimeWakeScanner(db, "matching.user_notifications", "created_at"))
}
