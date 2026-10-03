package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"runtime"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// Durable server activity (migration 133).
//
// serverActivityRecorder owns the in-memory aggregates the request
// middleware and the worker heartbeat fill (observability.RequestRollups,
// observability.ServerEvents, the job rollups below) and writes them to
// Postgres from one background goroutine:
//
//	platform.job_runs                  worker runs, sent through a bounded queue
//	platform.job_run_rollups_hourly    every run, additive upsert each minute
//	platform.request_rollups_hourly    every request, additive upsert each minute
//	platform.server_events             aggregated events, additive upsert each minute
//
// Nothing here blocks a request or a worker: the sink folds a run under a
// short mutex and hands the row to a buffered channel, dropping (and
// counting) it when the queue is full. A failed flush puts the aggregates
// back for the next one. Close flushes once more on shutdown.

const (
	serverActivityFlushInterval = time.Minute
	serverActivityRunQueue      = 2048
	serverActivityRunBatch      = 200
	serverActivityWriteTimeout  = 10 * time.Second
	serverActivityCloseTimeout  = 15 * time.Second
	jobRunErrorLimit            = 500
	serverEventDetailsLimit     = 16384
	// workerStaleFloor keeps a sub-second poll loop from being called stale
	// because one batch took a few seconds.
	workerStaleFloor = 2 * time.Minute
	// workerStaleFactor × the expected interval without a successful run
	// makes a worker stale (the Prometheus staleness alert uses the same).
	workerStaleFactor = 3
)

// highFrequencyWorkers poll continuously; only their failed runs and runs
// that handled items are stored in platform.job_runs. Every other worker
// stores every run. All runs reach the hourly rollups.
var highFrequencyWorkers = map[string]bool{
	workerLevelProjection:      true,
	workerNotificationDelivery: true,
	workerSOSDelivery:          true,
	workerSOSGaugeRefresh:      true,
	workerXPAwardSpoolReplay:   true,
}

// retentionSummaryWorkers report what they purged as a retention_summary event.
var retentionSummaryWorkers = map[string]bool{
	workerTrustRetention:       true,
	workerIdempotencyRetention: true,
}

// jobDurationBucketsMS are the upper bounds (ms) of
// platform.job_run_rollups_hourly.duration_buckets; a last +Inf bucket follows.
var jobDurationBucketsMS = []float64{5, 25, 100, 500, 1000, 5000, 15000, 60000, 300000, 900000}

func jobDurationBucket(ms int64) int {
	for i, bound := range jobDurationBucketsMS {
		if float64(ms) <= bound {
			return i
		}
	}
	return len(jobDurationBucketsMS)
}

type jobRollupKey struct {
	worker string
	hour   time.Time
}

type jobRollup struct {
	runs, failures, items, itemsFailed int64
	sumMS, maxMS                       int64
	buckets                            []int64
	lastRun, lastSuccess               time.Time
}

type jobRunRow struct {
	worker, status, errText string
	started, finished       time.Time
	durationMS              int64
	processed, failed       int64
	backlog                 *int64
	details                 map[string]any
}

type serverActivityRecorder struct {
	db       *sql.DB
	log      *zap.Logger
	service  string
	instance string
	version  string
	commit   string

	requests *observability.RequestRollups
	events   *observability.ServerEvents
	runs     chan jobRunRow
	now      func() time.Time

	mu          sync.Mutex
	jobRollups  map[jobRollupKey]*jobRollup
	lastSuccess map[string]time.Time
	staleAt     map[string]time.Time
	startedAt   time.Time

	droppedRuns atomic.Int64
	failures    atomic.Int64
	lastWarn    atomic.Int64

	cancel   context.CancelFunc
	done     chan struct{}
	stopOnce sync.Once
}

func serverInstanceName() string {
	host, err := os.Hostname()
	if err != nil || strings.TrimSpace(host) == "" {
		host = "unknown"
	}
	return fmt.Sprintf("%s:%d", host, os.Getpid())
}

func newServerActivityRecorder(db *sql.DB, log *zap.Logger, service string) *serverActivityRecorder {
	if log == nil {
		log = zap.NewNop()
	}
	version, commit := observability.BuildVersion()
	return &serverActivityRecorder{
		db: db, log: log, service: service, instance: serverInstanceName(),
		version: version, commit: commit,
		requests:    observability.NewRequestRollups(),
		events:      observability.NewServerEvents(),
		runs:        make(chan jobRunRow, serverActivityRunQueue),
		now:         time.Now,
		jobRollups:  map[jobRollupKey]*jobRollup{},
		lastSuccess: map[string]time.Time{},
		staleAt:     map[string]time.Time{},
		done:        make(chan struct{}),
	}
}

// ── Worker run sink ─────────────────────────────────────────────────────────

// RecordWorkerRun implements observability.WorkerRunSink.
func (a *serverActivityRecorder) RecordWorkerRun(rec observability.WorkerRunRecord) {
	if a == nil || rec.Worker == "" {
		return
	}
	failed := rec.Status == observability.WorkerRunFailed
	durationMS := rec.Duration().Milliseconds()
	finished := rec.FinishedAt.UTC()

	a.mu.Lock()
	key := jobRollupKey{worker: rec.Worker, hour: finished.Truncate(time.Hour)}
	roll := a.jobRollups[key]
	if roll == nil {
		roll = &jobRollup{buckets: make([]int64, len(jobDurationBucketsMS)+1)}
		a.jobRollups[key] = roll
	}
	roll.runs++
	roll.items += rec.ItemsProcessed
	roll.itemsFailed += rec.ItemsFailed
	roll.sumMS += durationMS
	roll.maxMS = max(roll.maxMS, durationMS)
	roll.buckets[jobDurationBucket(durationMS)]++
	if finished.After(roll.lastRun) {
		roll.lastRun = finished
	}
	if failed {
		roll.failures++
	} else {
		if finished.After(roll.lastSuccess) {
			roll.lastSuccess = finished
		}
		a.lastSuccess[rec.Worker] = finished
		delete(a.staleAt, rec.Worker)
	}
	a.mu.Unlock()

	errText := ""
	if rec.Err != nil {
		errText = scrubJobError(rec.Err.Error())
	}
	details := map[string]any{}
	for k, v := range rec.Details {
		details[k] = v
	}
	if len(rec.Items) > 0 {
		details["items"] = rec.Items
	}

	if failed {
		a.events.Record(observability.ServerEvent{
			At: finished, Kind: observability.EventWorkerFailed, Severity: observability.SeverityError,
			Message:   "Worker " + rec.Worker + " run failed",
			DedupeKey: rec.Worker,
			Details:   map[string]any{"worker": rec.Worker, "error": errText, "duration_ms": durationMS},
		})
	}
	if retentionSummaryWorkers[rec.Worker] && !failed {
		if purged, total := retentionPurged(rec.Details); total > 0 {
			a.events.Record(observability.ServerEvent{
				At: finished, Kind: observability.EventRetentionSummary, Severity: observability.SeverityInfo,
				Message:   fmt.Sprintf("Retention (%s) removed %d rows", rec.Worker, total),
				DedupeKey: rec.Worker,
				Details:   map[string]any{"worker": rec.Worker, "purged": purged, "total": total},
			})
		}
	}

	if highFrequencyWorkers[rec.Worker] && !failed && rec.ItemsProcessed+rec.ItemsFailed == 0 {
		return
	}
	row := jobRunRow{
		worker: rec.Worker, status: rec.Status, errText: errText,
		started: rec.StartedAt.UTC(), finished: finished, durationMS: durationMS,
		processed: rec.ItemsProcessed, failed: rec.ItemsFailed, details: details,
	}
	if rec.Backlog != nil {
		backlog := int64(*rec.Backlog)
		row.backlog = &backlog
	}
	select {
	case a.runs <- row:
	default:
		a.droppedRuns.Add(1)
	}
}

// retentionPurged reads the "purged" detail ({class: rows}) of a retention run.
func retentionPurged(details map[string]any) (map[string]int64, int64) {
	purged := map[string]int64{}
	var total int64
	raw, ok := details["purged"]
	if !ok {
		return purged, 0
	}
	switch typed := raw.(type) {
	case map[string]int:
		for k, v := range typed {
			if v > 0 {
				purged[k] = int64(v)
				total += int64(v)
			}
		}
	case map[string]int64:
		for k, v := range typed {
			if v > 0 {
				purged[k] = v
				total += v
			}
		}
	}
	return purged, total
}

// scrubJobError redacts personal data and secrets and keeps 500 characters.
func scrubJobError(message string) string {
	message = strings.TrimSpace(observability.RedactText(message))
	if runes := []rune(message); len(runes) > jobRunErrorLimit {
		message = string(runes[:jobRunErrorLimit])
	}
	return message
}

// ── Lifecycle ───────────────────────────────────────────────────────────────

// start records process_start, surfaces applied migrations and runs the
// flush loop until Close.
func (a *serverActivityRecorder) start() {
	if a == nil {
		return
	}
	a.startedAt = a.now().UTC()
	ctx, cancel := context.WithCancel(context.Background())
	a.cancel = cancel
	a.events.Record(observability.ServerEvent{
		At: a.startedAt, Kind: observability.EventProcessStart, Severity: observability.SeverityInfo,
		Message:   fmt.Sprintf("%s started (version %s, commit %s)", a.service, a.version, a.commit),
		DedupeKey: a.processKey(),
		Details: map[string]any{
			"version": a.version, "commit": a.commit, "go_version": runtime.Version(),
			"instance": a.instance,
		},
	})
	go a.loop(ctx)
}

func (a *serverActivityRecorder) processKey() string {
	return a.instance + "|" + a.startedAt.Format(time.RFC3339Nano)
}

func (a *serverActivityRecorder) loop(ctx context.Context) {
	defer close(a.done)
	a.recordMigrations()
	a.flush()
	ticker := time.NewTicker(serverActivityFlushInterval)
	defer ticker.Stop()
	pending := make([]jobRunRow, 0, 64)
	for {
		select {
		case row := <-a.runs:
			pending = append(pending, row)
			if len(pending) >= serverActivityRunBatch {
				pending = a.writeJobRuns(pending)
			}
		case <-ticker.C:
			pending = a.writeJobRuns(pending)
			a.checkStale(a.now().UTC())
			a.flush()
		case <-ctx.Done():
			for drained := false; !drained; {
				select {
				case row := <-a.runs:
					pending = append(pending, row)
				default:
					drained = true
				}
			}
			a.writeJobRuns(pending)
			a.flush()
			return
		}
	}
}

// Close records process_stop and flushes everything once more.
func (a *serverActivityRecorder) Close() {
	if a == nil || a.cancel == nil {
		return
	}
	a.stopOnce.Do(func() {
		if observability.CurrentWorkerRunSink() == observability.WorkerRunSink(a) {
			observability.SetWorkerRunSink(nil)
		}
		now := a.now().UTC()
		a.events.Record(observability.ServerEvent{
			At: now, Kind: observability.EventProcessStop, Severity: observability.SeverityInfo,
			Message:   fmt.Sprintf("%s stopping after %s", a.service, now.Sub(a.startedAt).Round(time.Second)),
			DedupeKey: a.processKey(),
			Details: map[string]any{
				"version": a.version, "commit": a.commit, "go_version": runtime.Version(),
				"instance": a.instance, "uptime_seconds": int64(now.Sub(a.startedAt).Seconds()),
				"dropped_job_runs": a.droppedRuns.Load(), "dropped_requests": a.requests.Dropped(),
				"dropped_events": a.events.Dropped(),
			},
		})
		a.cancel()
		select {
		case <-a.done:
		case <-time.After(serverActivityCloseTimeout):
			a.log.Warn("server_activity_close_timeout")
		}
	})
}

// checkStale records worker_stale, at most once an hour per worker, for a
// worker whose last success (or first run in this process) is older than
// workerStaleFactor × its interval (at least workerStaleFloor).
func (a *serverActivityRecorder) checkStale(now time.Time) {
	for _, info := range observability.WorkerRegistry() {
		if info.Interval <= 0 {
			continue
		}
		threshold := workerStaleThreshold(info.Interval)
		a.mu.Lock()
		last := a.lastSuccess[info.Worker]
		if last.IsZero() {
			last = info.FirstSeen
		}
		emitted, already := a.staleAt[info.Worker]
		stale := now.Sub(last) > threshold && (!already || now.Sub(emitted) >= time.Hour)
		if stale {
			a.staleAt[info.Worker] = now
		}
		a.mu.Unlock()
		if !stale {
			continue
		}
		a.events.Record(observability.ServerEvent{
			At: now, Kind: observability.EventWorkerStale, Severity: observability.SeverityWarning,
			Message:   fmt.Sprintf("Worker %s has not succeeded for %s", info.Worker, now.Sub(last).Round(time.Second)),
			DedupeKey: info.Worker, Window: time.Hour,
			Details: map[string]any{
				"worker": info.Worker, "expected_interval_seconds": info.Interval.Seconds(),
				"threshold_seconds": threshold.Seconds(), "last_success_at": last.UTC().Format(time.RFC3339),
			},
		})
	}
}

func workerStaleThreshold(interval time.Duration) time.Duration {
	return max(workerStaleFactor*interval, workerStaleFloor)
}

// ── Writes ──────────────────────────────────────────────────────────────────

func (a *serverActivityRecorder) writeCtx() (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), serverActivityWriteTimeout)
}

func (a *serverActivityRecorder) warn(msg string, err error) {
	a.failures.Add(1)
	now := time.Now().Unix()
	if last := a.lastWarn.Load(); now-last < 60 || !a.lastWarn.CompareAndSwap(last, now) {
		return
	}
	a.log.Warn(msg, zap.Error(err))
}

// flush writes the hourly job and request rollups and the event aggregates.
func (a *serverActivityRecorder) flush() {
	if a == nil || a.db == nil {
		return
	}
	a.mu.Lock()
	jobs := a.jobRollups
	a.jobRollups = map[jobRollupKey]*jobRollup{}
	a.mu.Unlock()
	if err := a.writeJobRollups(jobs); err != nil {
		a.restoreJobRollups(jobs)
		a.warn("server_activity_job_rollups_flush_failed", err)
	}
	if unwritten, err := a.writeRequestRollups(a.requests.Drain()); err != nil {
		a.requests.Restore(unwritten)
		a.warn("server_activity_request_rollups_flush_failed", err)
	}
	if unwritten, err := a.writeEvents(a.events.Drain()); err != nil {
		a.events.Restore(unwritten)
		a.warn("server_activity_events_flush_failed", err)
	}
}

func (a *serverActivityRecorder) restoreJobRollups(rows map[jobRollupKey]*jobRollup) {
	a.mu.Lock()
	defer a.mu.Unlock()
	for key, in := range rows {
		roll := a.jobRollups[key]
		if roll == nil {
			a.jobRollups[key] = in
			continue
		}
		roll.runs += in.runs
		roll.failures += in.failures
		roll.items += in.items
		roll.itemsFailed += in.itemsFailed
		roll.sumMS += in.sumMS
		roll.maxMS = max(roll.maxMS, in.maxMS)
		for i := range roll.buckets {
			roll.buckets[i] += in.buckets[i]
		}
		if in.lastRun.After(roll.lastRun) {
			roll.lastRun = in.lastRun
		}
		if in.lastSuccess.After(roll.lastSuccess) {
			roll.lastSuccess = in.lastSuccess
		}
	}
}

func activityNullTime(t time.Time) any {
	if t.IsZero() {
		return nil
	}
	return t
}

func activityNullString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	return value
}

// boundedJSON encodes an object for a jsonb column with a size check; an
// object that does not fit is replaced by a marker.
func boundedJSON(value map[string]any) string {
	if len(value) == 0 {
		return "{}"
	}
	raw, err := json.Marshal(value)
	if err != nil {
		return `{"encode_error":true}`
	}
	if len(raw) > serverEventDetailsLimit {
		return `{"truncated":true}`
	}
	return string(raw)
}

// valuesRows renders "(…),(…)" placeholders for n rows of width columns,
// with casts per column ("" for none).
func valuesRows(n int, casts []string) string {
	var b strings.Builder
	param := 1
	for row := 0; row < n; row++ {
		if row > 0 {
			b.WriteString(",")
		}
		b.WriteString("(")
		for col, cast := range casts {
			if col > 0 {
				b.WriteString(",")
			}
			fmt.Fprintf(&b, "$%d%s", param, cast)
			param++
		}
		b.WriteString(")")
	}
	return b.String()
}

// writeJobRuns inserts pending runs; on failure the newest 1000 are kept.
func (a *serverActivityRecorder) writeJobRuns(rows []jobRunRow) []jobRunRow {
	if len(rows) == 0 || a.db == nil {
		return rows[:0]
	}
	casts := []string{"", "", "", "::timestamptz", "::timestamptz", "::bigint", "", "::bigint", "::bigint", "::bigint", "", "::jsonb"}
	for start := 0; start < len(rows); start += serverActivityRunBatch {
		end := min(start+serverActivityRunBatch, len(rows))
		chunk := rows[start:end]
		args := make([]any, 0, len(chunk)*len(casts))
		for _, row := range chunk {
			var backlog any
			if row.backlog != nil {
				backlog = *row.backlog
			}
			args = append(args, row.worker, a.instance, activityNullString(a.commit), row.started, row.finished,
				row.durationMS, row.status, row.processed, row.failed, backlog, activityNullString(row.errText), boundedJSON(row.details))
		}
		ctx, cancel := a.writeCtx()
		_, err := a.db.ExecContext(ctx, `INSERT INTO platform.job_runs
			(worker, instance, build_commit, started_at, finished_at, duration_ms, status,
			 items_processed, items_failed, backlog_after, error, details)
			VALUES `+valuesRows(len(chunk), casts), args...)
		cancel()
		if err != nil {
			a.warn("server_activity_job_runs_write_failed", err)
			remaining := rows[start:]
			if len(remaining) > 1000 {
				remaining = remaining[len(remaining)-1000:]
			}
			return append([]jobRunRow(nil), remaining...)
		}
	}
	return rows[:0]
}

func (a *serverActivityRecorder) writeJobRollups(rows map[jobRollupKey]*jobRollup) error {
	if len(rows) == 0 {
		return nil
	}
	keys := make([]jobRollupKey, 0, len(rows))
	for key := range rows {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(i, j int) bool {
		if keys[i].worker != keys[j].worker {
			return keys[i].worker < keys[j].worker
		}
		return keys[i].hour.Before(keys[j].hour)
	})
	casts := []string{"", "::timestamptz", "::bigint", "::bigint", "::bigint", "::bigint", "::bigint", "::bigint", "::bigint[]", "::timestamptz", "::timestamptz"}
	args := make([]any, 0, len(keys)*len(casts))
	for _, key := range keys {
		roll := rows[key]
		args = append(args, key.worker, key.hour, roll.runs, roll.failures, roll.items, roll.itemsFailed,
			roll.sumMS, roll.maxMS, roll.buckets, activityNullTime(roll.lastRun), activityNullTime(roll.lastSuccess))
	}
	ctx, cancel := a.writeCtx()
	defer cancel()
	_, err := a.db.ExecContext(ctx, `INSERT INTO platform.job_run_rollups_hourly AS t
		(worker, hour, runs, failures, items, items_failed, sum_duration_ms, max_duration_ms,
		 duration_buckets, last_run_at, last_success_at)
		VALUES `+valuesRows(len(keys), casts)+`
		ON CONFLICT (worker, hour) DO UPDATE SET
		  runs = t.runs + EXCLUDED.runs,
		  failures = t.failures + EXCLUDED.failures,
		  items = t.items + EXCLUDED.items,
		  items_failed = t.items_failed + EXCLUDED.items_failed,
		  sum_duration_ms = t.sum_duration_ms + EXCLUDED.sum_duration_ms,
		  max_duration_ms = GREATEST(t.max_duration_ms, EXCLUDED.max_duration_ms),
		  duration_buckets = platform.add_bigint_arrays(t.duration_buckets, EXCLUDED.duration_buckets),
		  last_run_at = GREATEST(t.last_run_at, EXCLUDED.last_run_at),
		  last_success_at = GREATEST(t.last_success_at, EXCLUDED.last_success_at),
		  updated_at = NOW()`, args...)
	return err
}

// writeRequestRollups upserts the rows in chunks and returns the rows that
// were not written when a chunk fails.
func (a *serverActivityRecorder) writeRequestRollups(rows []observability.RequestRollupRow) ([]observability.RequestRollupRow, error) {
	if len(rows) == 0 {
		return nil, nil
	}
	casts := []string{"::timestamptz", "", "", "", "", "::smallint", "::bigint", "::bigint", "::double precision", "::double precision", "::bigint[]"}
	const chunkSize = 500
	for start := 0; start < len(rows); start += chunkSize {
		chunk := rows[start:min(start+chunkSize, len(rows))]
		args := make([]any, 0, len(chunk)*len(casts))
		for _, row := range chunk {
			args = append(args, row.Hour, row.Service, row.Method, row.Route, row.StatusClass, row.StatusCode,
				row.Requests, row.TimedRequests, row.SumDurationMS, row.MaxDurationMS, row.Buckets)
		}
		ctx, cancel := a.writeCtx()
		_, err := a.db.ExecContext(ctx, `INSERT INTO platform.request_rollups_hourly AS t
			(hour, service, method, route, status_class, status_code, requests, timed_requests,
			 sum_duration_ms, max_duration_ms, duration_buckets)
			VALUES `+valuesRows(len(chunk), casts)+`
			ON CONFLICT (hour, service, method, route, status_class, status_code) DO UPDATE SET
			  requests = t.requests + EXCLUDED.requests,
			  timed_requests = t.timed_requests + EXCLUDED.timed_requests,
			  sum_duration_ms = t.sum_duration_ms + EXCLUDED.sum_duration_ms,
			  max_duration_ms = GREATEST(t.max_duration_ms, EXCLUDED.max_duration_ms),
			  duration_buckets = platform.add_bigint_arrays(t.duration_buckets, EXCLUDED.duration_buckets),
			  updated_at = NOW()`, args...)
		cancel()
		if err != nil {
			return rows[start:], err
		}
	}
	return nil, nil
}

// writeEvents upserts the aggregates in chunks and returns the rows that were
// not written when a chunk fails.
func (a *serverActivityRecorder) writeEvents(rows []observability.ServerEventRow) ([]observability.ServerEventRow, error) {
	if len(rows) == 0 {
		return nil, nil
	}
	casts := []string{"::timestamptz", "", "", "", "", "", "", "", "::bigint", "::timestamptz", "::timestamptz", "::jsonb", "", "::timestamptz"}
	const chunkSize = 300
	for start := 0; start < len(rows); start += chunkSize {
		chunk := rows[start:min(start+chunkSize, len(rows))]
		args := make([]any, 0, len(chunk)*len(casts))
		for _, row := range chunk {
			args = append(args, row.FirstAt, row.Kind, row.Severity, a.service, a.instance, row.Message,
				activityNullString(row.Route), activityNullString(row.CorrelationID), row.Count, row.FirstAt, row.LastAt,
				boundedJSON(row.Details), row.DedupeKey, row.BucketAt)
		}
		ctx, cancel := a.writeCtx()
		_, err := a.db.ExecContext(ctx, `INSERT INTO platform.server_events AS t
			(at, kind, severity, service, instance, message, route, correlation_id, count,
			 first_at, last_at, details, dedupe_key, bucket_at)
			VALUES `+valuesRows(len(chunk), casts)+`
			ON CONFLICT (kind, dedupe_key, bucket_at) DO UPDATE SET
			  count = t.count + EXCLUDED.count,
			  first_at = LEAST(t.first_at, EXCLUDED.first_at),
			  last_at = GREATEST(t.last_at, EXCLUDED.last_at),
			  correlation_id = COALESCE(t.correlation_id, EXCLUDED.correlation_id)`, args...)
		cancel()
		if err != nil {
			return rows[start:], err
		}
	}
	return nil, nil
}

// recordMigrations surfaces public.schema_migrations as migration_applied
// events: one per (version, applied_at), so re-applying a migration shows
// again and a restart adds nothing. One cheap statement; skipped quietly
// when the table does not exist.
func (a *serverActivityRecorder) recordMigrations() {
	if a.db == nil {
		return
	}
	ctx, cancel := a.writeCtx()
	defer cancel()
	var exists bool
	if err := a.db.QueryRowContext(ctx, `SELECT to_regclass('public.schema_migrations') IS NOT NULL`).Scan(&exists); err != nil || !exists {
		return
	}
	_, err := a.db.ExecContext(ctx, `INSERT INTO platform.server_events
		(at, kind, severity, service, instance, message, route, correlation_id, count,
		 first_at, last_at, details, dedupe_key, bucket_at)
		SELECT m.applied_at, 'migration_applied', 'info', $1, $2, 'Migration ' || left(m.version, 200) || ' applied',
		       NULL, NULL, 1, m.applied_at, m.applied_at, jsonb_build_object('version', left(m.version, 200)),
		       left(m.version, 400), m.applied_at
		FROM public.schema_migrations m
		WHERE m.applied_at > NOW() - INTERVAL '180 days'
		ON CONFLICT (kind, dedupe_key, bucket_at) DO NOTHING`, a.service, a.instance)
	if err != nil {
		a.warn("server_activity_migrations_failed", err)
	}
}
