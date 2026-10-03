package observability

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math"
	"net/http"
	"runtime"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

// Durable server activity (migration 133). The HTTP middleware and the worker
// heartbeat aggregate in memory here; the mobile BFF flushes the aggregates
// to Postgres once a minute (internal/bff/mobile/server_activity.go). Nothing
// in this file touches a database, so a slow or failing database can never
// block a request or a worker.

// ── Request rollups ─────────────────────────────────────────────────────────

// RequestRollupBucketsSeconds are the latency bucket upper bounds of
// platform.request_rollups_hourly: the Prometheus DefBuckets, so percentiles
// derived from the table match histogram_quantile over
// verified_dating_http_request_duration_seconds. A last +Inf bucket follows.
var RequestRollupBucketsSeconds = append([]float64(nil), prometheus.DefBuckets...)

// RequestRollupBucketCount is len(RequestRollupBucketsSeconds) + 1 (+Inf).
var RequestRollupBucketCount = len(RequestRollupBucketsSeconds) + 1

// maxRequestRollupKeys bounds one flush interval's distinct keys. Route labels
// are already bounded by the route labeler; this is a second fuse.
const maxRequestRollupKeys = 20000

// RequestRollupKey is one row key of platform.request_rollups_hourly.
type RequestRollupKey struct {
	Hour        time.Time
	Service     string
	Method      string
	Route       string
	StatusClass string
	// StatusCode is exact for 401/403/404/409/429 and every 5xx, else 0.
	StatusCode int
}

// RequestRollupRow is the additive value accumulated for one key.
type RequestRollupRow struct {
	RequestRollupKey
	Requests      int64
	TimedRequests int64
	SumDurationMS float64
	MaxDurationMS float64
	Buckets       []int64 // len RequestRollupBucketCount, non-cumulative
}

// RollupStatusCode keeps the exact status only where it is diagnostic.
func RollupStatusCode(status int) int {
	switch status {
	case http.StatusUnauthorized, http.StatusForbidden, http.StatusNotFound, http.StatusConflict, http.StatusTooManyRequests:
		return status
	}
	if status >= 500 && status < 600 {
		return status
	}
	return 0
}

// RequestRollups aggregates requests per hour in memory. Safe for concurrent use.
type RequestRollups struct {
	mu      sync.Mutex
	rows    map[RequestRollupKey]*RequestRollupRow
	dropped atomic.Int64
	now     func() time.Time
}

func NewRequestRollups() *RequestRollups {
	return &RequestRollups{rows: map[RequestRollupKey]*RequestRollupRow{}, now: time.Now}
}

// Observe folds one finished request. timed is false for upgraded
// (WebSocket) connections, whose duration is a connection lifetime.
func (a *RequestRollups) Observe(service, method, route string, status int, duration time.Duration, timed bool) {
	if a == nil {
		return
	}
	key := RequestRollupKey{
		Hour:        a.now().UTC().Truncate(time.Hour),
		Service:     service,
		Method:      normalizeMethod(method),
		Route:       route,
		StatusClass: StatusClass(status),
		StatusCode:  RollupStatusCode(status),
	}
	if key.Route == "" {
		key.Route = RouteUnmatched
	}
	ms := float64(duration) / float64(time.Millisecond)
	a.mu.Lock()
	defer a.mu.Unlock()
	row := a.rows[key]
	if row == nil {
		if len(a.rows) >= maxRequestRollupKeys {
			key.Route = RouteOverflow
			if row = a.rows[key]; row == nil && len(a.rows) >= maxRequestRollupKeys+100 {
				a.dropped.Add(1)
				return
			}
		}
		if row == nil {
			row = &RequestRollupRow{RequestRollupKey: key, Buckets: make([]int64, RequestRollupBucketCount)}
			a.rows[key] = row
		}
	}
	row.Requests++
	if !timed {
		return
	}
	row.TimedRequests++
	row.SumDurationMS += ms
	if ms > row.MaxDurationMS {
		row.MaxDurationMS = ms
	}
	row.Buckets[requestRollupBucket(duration.Seconds())]++
}

func requestRollupBucket(seconds float64) int {
	for i, bound := range RequestRollupBucketsSeconds {
		if seconds <= bound {
			return i
		}
	}
	return len(RequestRollupBucketsSeconds)
}

// Drain returns and clears everything aggregated so far.
func (a *RequestRollups) Drain() []RequestRollupRow {
	if a == nil {
		return nil
	}
	a.mu.Lock()
	rows := a.rows
	a.rows = map[RequestRollupKey]*RequestRollupRow{}
	a.mu.Unlock()
	out := make([]RequestRollupRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, *row)
	}
	return out
}

// Restore merges rows back after a failed flush so they go out with the
// next one. Rows beyond the key bound are dropped (and counted).
func (a *RequestRollups) Restore(rows []RequestRollupRow) {
	if a == nil {
		return
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	for _, in := range rows {
		row := a.rows[in.RequestRollupKey]
		if row == nil {
			if len(a.rows) >= maxRequestRollupKeys {
				a.dropped.Add(in.Requests)
				continue
			}
			copied := in
			copied.Buckets = append([]int64(nil), in.Buckets...)
			a.rows[in.RequestRollupKey] = &copied
			continue
		}
		row.Requests += in.Requests
		row.TimedRequests += in.TimedRequests
		row.SumDurationMS += in.SumDurationMS
		row.MaxDurationMS = math.Max(row.MaxDurationMS, in.MaxDurationMS)
		for i := range row.Buckets {
			if i < len(in.Buckets) {
				row.Buckets[i] += in.Buckets[i]
			}
		}
	}
}

// Dropped is the number of requests that could not be aggregated.
func (a *RequestRollups) Dropped() int64 {
	if a == nil {
		return 0
	}
	return a.dropped.Load()
}

// HistogramQuantile estimates quantile q (0..1) from non-cumulative bucket
// counts with upper bounds bounds (counts has one extra +Inf bucket), the way
// Prometheus histogram_quantile does: linear interpolation inside the bucket
// holding the rank, the highest finite bound for the +Inf bucket, 0 without
// observations. The result is in the unit of bounds.
func HistogramQuantile(q float64, bounds []float64, counts []int64) float64 {
	var total int64
	for _, c := range counts {
		total += c
	}
	if total == 0 || len(bounds) == 0 {
		return 0
	}
	q = math.Max(0, math.Min(1, q))
	rank := q * float64(total)
	var cumulative int64
	for i, c := range counts {
		previous := cumulative
		cumulative += c
		if float64(cumulative) < rank || c == 0 {
			continue
		}
		if i >= len(bounds) {
			return bounds[len(bounds)-1]
		}
		lower := 0.0
		if i > 0 {
			lower = bounds[i-1]
		}
		upper := bounds[i]
		return lower + (upper-lower)*(rank-float64(previous))/float64(c)
	}
	return bounds[len(bounds)-1]
}

// ── Server events ───────────────────────────────────────────────────────────

// Server event kinds (platform.server_events.kind).
const (
	EventProcessStart     = "process_start"
	EventProcessStop      = "process_stop"
	EventPanic            = "panic"
	EventServerError      = "server_error"
	EventRefused          = "refused"
	EventWorkerFailed     = "worker_failed"
	EventWorkerStale      = "worker_stale"
	EventRetentionSummary = "retention_summary"
	EventMigrationApplied = "migration_applied"
)

// Severities (platform.server_events.severity).
const (
	SeverityInfo     = "info"
	SeverityWarning  = "warning"
	SeverityError    = "error"
	SeverityCritical = "critical"
)

// Refusal reasons noted by the middleware chain (RequestNoteRefusal).
const (
	RefusalUnauthenticated   = "unauthenticated"
	RefusalForbiddenRole     = "forbidden_role"
	RefusalForbiddenResource = "forbidden_resource"
	RefusalAccountState      = "account_state"
	RefusalShedInflight      = "shed_inflight"
	RefusalShedBulkhead      = "shed_bulkhead"
	RefusalRateLimited       = "rate_limited"
	RefusalTimeout           = "timeout"
)

// maxServerEventKeys bounds the distinct aggregates held between flushes.
const maxServerEventKeys = 5000

// ServerEvent is one occurrence. Events with the same Kind, DedupeKey and
// bucket (At truncated to Window, a minute by default) become one row whose
// count, first_at and last_at cover every occurrence; the first occurrence's
// message, route, correlation id and details are kept as the sample.
type ServerEvent struct {
	At            time.Time
	Kind          string
	Severity      string
	Message       string
	Route         string
	CorrelationID string
	DedupeKey     string
	Window        time.Duration
	Details       map[string]any
}

// ServerEventRow is an aggregated event ready to be stored.
type ServerEventRow struct {
	ServerEvent
	Count    int64
	FirstAt  time.Time
	LastAt   time.Time
	BucketAt time.Time
}

type serverEventKey struct {
	kind, dedupe string
	bucket       time.Time
}

// ServerEvents aggregates events in memory. Safe for concurrent use.
type ServerEvents struct {
	mu      sync.Mutex
	rows    map[serverEventKey]*ServerEventRow
	dropped atomic.Int64
	now     func() time.Time
}

func NewServerEvents() *ServerEvents {
	return &ServerEvents{rows: map[serverEventKey]*ServerEventRow{}, now: time.Now}
}

// Record adds one occurrence.
func (e *ServerEvents) Record(event ServerEvent) {
	if e == nil || event.Kind == "" {
		return
	}
	if event.At.IsZero() {
		event.At = e.now()
	}
	event.At = event.At.UTC()
	if event.Window <= 0 {
		event.Window = time.Minute
	}
	if event.Severity == "" {
		event.Severity = SeverityInfo
	}
	if event.DedupeKey == "" {
		event.DedupeKey = event.Route
	}
	event.Message = truncateRunes(event.Message, 500)
	event.DedupeKey = truncateRunes(event.DedupeKey, 400)
	event.Route = truncateRunes(event.Route, 300)
	event.CorrelationID = truncateRunes(event.CorrelationID, 128)
	key := serverEventKey{kind: event.Kind, dedupe: event.DedupeKey, bucket: event.At.Truncate(event.Window)}
	e.mu.Lock()
	defer e.mu.Unlock()
	row := e.rows[key]
	if row == nil {
		if len(e.rows) >= maxServerEventKeys {
			e.dropped.Add(1)
			return
		}
		e.rows[key] = &ServerEventRow{ServerEvent: event, Count: 1, FirstAt: event.At, LastAt: event.At, BucketAt: key.bucket}
		return
	}
	row.Count++
	if event.At.Before(row.FirstAt) {
		row.FirstAt = event.At
	}
	if event.At.After(row.LastAt) {
		row.LastAt = event.At
	}
	if row.CorrelationID == "" {
		row.CorrelationID = event.CorrelationID
	}
}

// Drain returns and clears the aggregates, oldest first.
func (e *ServerEvents) Drain() []ServerEventRow {
	if e == nil {
		return nil
	}
	e.mu.Lock()
	rows := e.rows
	e.rows = map[serverEventKey]*ServerEventRow{}
	e.mu.Unlock()
	out := make([]ServerEventRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, *row)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].FirstAt.Before(out[j].FirstAt) })
	return out
}

// Restore merges rows back after a failed flush.
func (e *ServerEvents) Restore(rows []ServerEventRow) {
	if e == nil {
		return
	}
	e.mu.Lock()
	defer e.mu.Unlock()
	for _, in := range rows {
		key := serverEventKey{kind: in.Kind, dedupe: in.DedupeKey, bucket: in.BucketAt}
		row := e.rows[key]
		if row == nil {
			if len(e.rows) >= maxServerEventKeys {
				e.dropped.Add(in.Count)
				continue
			}
			copied := in
			e.rows[key] = &copied
			continue
		}
		row.Count += in.Count
		if in.FirstAt.Before(row.FirstAt) {
			row.FirstAt = in.FirstAt
		}
		if in.LastAt.After(row.LastAt) {
			row.LastAt = in.LastAt
		}
	}
}

// Dropped counts occurrences lost to the key bound.
func (e *ServerEvents) Dropped() int64 {
	if e == nil {
		return 0
	}
	return e.dropped.Load()
}

func truncateRunes(value string, limit int) string {
	if limit <= 0 || len(value) <= limit {
		return value
	}
	runes := []rune(value)
	if len(runes) <= limit {
		return value
	}
	return string(runes[:limit])
}

// ── Request notes ───────────────────────────────────────────────────────────

// requestNote travels in the request context from RequestLoggingMiddleware
// to the inner layers, which note why they refused a request or that the
// handler panicked. The logging middleware turns the note into events.
type requestNote struct {
	mu      sync.Mutex
	refusal string
	panic   *PanicInfo
}

type requestNoteKey struct{}

func withRequestNote(ctx context.Context) (context.Context, *requestNote) {
	note := &requestNote{}
	return context.WithValue(ctx, requestNoteKey{}, note), note
}

func requestNoteFrom(ctx context.Context) *requestNote {
	if ctx == nil {
		return nil
	}
	note, _ := ctx.Value(requestNoteKey{}).(*requestNote)
	return note
}

// NoteRefusal records why a layer refused the request (Refusal* reasons).
// The first reason wins; timeout overrides since it is noted after the
// handler returned. It is a no-op outside RequestLoggingMiddleware.
func NoteRefusal(ctx context.Context, reason string) {
	note := requestNoteFrom(ctx)
	if note == nil || reason == "" {
		return
	}
	note.mu.Lock()
	if note.refusal == "" || reason == RefusalTimeout {
		note.refusal = reason
	}
	note.mu.Unlock()
}

func (n *requestNote) snapshot() (string, *PanicInfo) {
	if n == nil {
		return "", nil
	}
	n.mu.Lock()
	defer n.mu.Unlock()
	return n.refusal, n.panic
}

// PanicInfo is what a recovered panic leaves for the event log: no request
// data, only the panic's type, a redacted and truncated value, the code
// frames (function and file:line) and a hash of the function names.
type PanicInfo struct {
	Type      string
	Value     string
	Frames    []string
	StackHash string
}

// capturePanic must run inside the deferred recover.
func capturePanic(recovered any) *PanicInfo {
	info := &PanicInfo{Type: fmt.Sprintf("%T", recovered)}
	info.Value = truncateRunes(RedactText(fmt.Sprint(recovered)), 200)
	pcs := make([]uintptr, 48)
	n := runtime.Callers(3, pcs)
	frames := runtime.CallersFrames(pcs[:n])
	afterPanic := false
	var names []string
	for {
		frame, more := frames.Next()
		if frame.Function == "runtime.gopanic" {
			afterPanic = true
		} else if afterPanic && !strings.HasPrefix(frame.Function, "runtime.") {
			file := frame.File
			if idx := strings.LastIndex(file, "/backend/"); idx >= 0 {
				file = file[idx+len("/backend/"):]
			} else if idx := strings.LastIndex(file, "/"); idx >= 0 {
				file = file[idx+1:]
			}
			info.Frames = append(info.Frames, fmt.Sprintf("%s (%s:%d)", frame.Function, file, frame.Line))
			names = append(names, frame.Function)
			if len(info.Frames) >= 8 {
				break
			}
		}
		if !more {
			break
		}
	}
	sum := sha256.Sum256([]byte(info.Type + "|" + strings.Join(names, "|")))
	info.StackHash = hex.EncodeToString(sum[:6])
	return info
}

func notePanic(ctx context.Context, info *PanicInfo) {
	note := requestNoteFrom(ctx)
	if note == nil || info == nil {
		return
	}
	note.mu.Lock()
	note.panic = info
	note.mu.Unlock()
}

// ── 5xx error excerpts ──────────────────────────────────────────────────────

// Handlers answer errors through helpers that see only the ResponseWriter;
// the correlation id header is the join key between such a helper and the
// request's logging middleware. Bounded: entries are removed when the
// request finishes, and the map is reset if it ever exceeds its bound
// (writers used outside the middleware, e.g. in tests).
var (
	serverErrorNotesMu sync.Mutex
	serverErrorNotes   = map[string]string{}
)

const maxServerErrorNotes = 2000

// NoteServerError keeps a redacted excerpt of the error behind a 5xx answer
// so the server_error event can show it. correlationID is the response's
// X-Correlation-ID; nothing is kept without one.
func NoteServerError(correlationID, message string) {
	correlationID = strings.TrimSpace(correlationID)
	if correlationID == "" || message == "" {
		return
	}
	excerpt := truncateRunes(RedactText(message), 300)
	serverErrorNotesMu.Lock()
	if len(serverErrorNotes) >= maxServerErrorNotes {
		serverErrorNotes = map[string]string{}
	}
	if _, exists := serverErrorNotes[correlationID]; !exists {
		serverErrorNotes[correlationID] = excerpt
	}
	serverErrorNotesMu.Unlock()
}

func takeServerErrorNote(correlationID string) string {
	if correlationID == "" {
		return ""
	}
	serverErrorNotesMu.Lock()
	defer serverErrorNotesMu.Unlock()
	excerpt, ok := serverErrorNotes[correlationID]
	if ok {
		delete(serverErrorNotes, correlationID)
	}
	return excerpt
}

// recordRequestEvents turns a finished request into server events.
func recordRequestEvents(events *ServerEvents, note *requestNote, method, route string, status int, correlationID string, at time.Time) {
	refusal, panicInfo := note.snapshot()
	excerpt := takeServerErrorNote(correlationID)
	if events == nil {
		return
	}
	method = normalizeMethod(method)
	endpoint := method + " " + route
	if panicInfo != nil {
		events.Record(ServerEvent{
			At: at, Kind: EventPanic, Severity: SeverityCritical,
			Message:       "Handler panic (" + panicInfo.Type + ") on " + endpoint,
			Route:         route,
			CorrelationID: correlationID,
			DedupeKey:     endpoint + "|" + panicInfo.StackHash,
			Details: map[string]any{
				"method": method, "stack_hash": panicInfo.StackHash, "panic_type": panicInfo.Type,
				"panic_value": panicInfo.Value, "stack": panicInfo.Frames,
			},
		})
	}
	if status >= 500 && status < 600 {
		details := map[string]any{"method": method, "status": status}
		if excerpt != "" {
			details["error_excerpt"] = excerpt
		}
		events.Record(ServerEvent{
			At: at, Kind: EventServerError, Severity: SeverityError,
			Message:       fmt.Sprintf("%d responses on %s", status, endpoint),
			Route:         route,
			CorrelationID: correlationID,
			DedupeKey:     fmt.Sprintf("%s|%d", endpoint, status),
			Details:       details,
		})
	}
	if refusal == "" {
		switch status {
		case http.StatusUnauthorized:
			refusal = RefusalUnauthenticated
		case http.StatusTooManyRequests:
			refusal = RefusalRateLimited
		}
	}
	if refusal != "" {
		severity := SeverityWarning
		if refusal == RefusalTimeout {
			severity = SeverityError
		}
		events.Record(ServerEvent{
			At: at, Kind: EventRefused, Severity: severity,
			Message:       fmt.Sprintf("Refused (%s) on %s", refusal, endpoint),
			Route:         route,
			CorrelationID: correlationID,
			DedupeKey:     refusal + "|" + endpoint,
			Details:       map[string]any{"reason": refusal, "method": method, "status": status},
		})
	}
}
