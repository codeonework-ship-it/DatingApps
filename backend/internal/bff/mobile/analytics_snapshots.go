package mobile

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/verified-dating/backend/internal/platform/observability"
	"go.uber.org/zap"
)

// analyticsSnapshotWorker keeps the durable product analytics snapshots of
// migration 123 current:
//
//   - every completed UTC day is built once after midnight and rebuilt once
//     more after the following midnight (late rows), after which it is final;
//   - missing days in the trailing analyticsSnapshotWindowDays are built, which
//     is also the initial backfill from durable timestamps;
//   - operators can rebuild a range on demand (POST
//     /v1/admin/analytics/snapshots/rebuild).
//
// Every run holds a session advisory lock, so several BFF instances never
// build concurrently, and every build replaces whole days, so a repeated or
// interrupted run is harmless. The heavy lifting is SQL (analytics.rebuild_day).
const (
	analyticsSnapshotLockKey      int64 = 0x616e616c79746963 // "analytic"
	analyticsSnapshotWindowDays         = 35
	analyticsSnapshotInterval           = 30 * time.Minute
	analyticsRebuildMaxDays             = 400
	analyticsActiveWindowLookback       = 29
)

// workerAnalyticsSnapshot is the heartbeat label (observability.NewHeartbeat).
const workerAnalyticsSnapshot = "analytics_snapshot"

var errAnalyticsSnapshotBusy = errors.New("an analytics snapshot run is already in progress")

type analyticsSnapshotWorker struct {
	db       *sql.DB
	log      *zap.Logger
	interval time.Duration
	now      func() time.Time
	cancel   context.CancelFunc
	done     sync.WaitGroup
}

type analyticsSnapshotRun struct {
	ID        string
	Kind      string
	From, To  time.Time
	DaysBuilt int
}

func newAnalyticsSnapshotWorker(db *sql.DB, log *zap.Logger, interval time.Duration) *analyticsSnapshotWorker {
	if db == nil {
		return nil
	}
	if log == nil {
		log = zap.NewNop()
	}
	if interval <= 0 {
		interval = analyticsSnapshotInterval
	}
	return &analyticsSnapshotWorker{db: db, log: log, interval: interval, now: time.Now}
}

func (w *analyticsSnapshotWorker) Start(parent context.Context) {
	if w == nil || w.cancel != nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	w.cancel = cancel
	w.done.Add(1)
	go func() {
		defer w.done.Done()
		ticker := time.NewTicker(w.interval)
		defer ticker.Stop()
		w.cycle(ctx)
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				w.cycle(ctx)
			}
		}
	}()
}

func (w *analyticsSnapshotWorker) Stop() {
	if w == nil || w.cancel == nil {
		return
	}
	w.cancel()
	w.done.Wait()
}

func (w *analyticsSnapshotWorker) cycle(ctx context.Context) {
	started := time.Now()
	beat := observability.NewHeartbeat(workerAnalyticsSnapshot, w.interval).Begin()
	run, err := w.RunScheduled(ctx)
	beat.Items("days_built", run.DaysBuilt)
	beat.Detail("days_built", run.DaysBuilt)
	if run.ID != "" {
		beat.Detail("run_id", run.ID)
	}
	if !run.From.IsZero() {
		beat.Detail("from", run.From.Format(time.DateOnly))
		beat.Detail("to", run.To.Format(time.DateOnly))
	}
	if errors.Is(err, errAnalyticsSnapshotBusy) {
		beat.MarkBusy()
		beat.End(nil) // another instance holds the lock and is building
	} else {
		beat.End(err)
	}
	switch {
	case errors.Is(err, errAnalyticsSnapshotBusy):
		w.log.Debug("analytics_snapshot_cycle_skipped", zap.String("reason", "another run holds the lock"))
	case err != nil && !errors.Is(err, context.Canceled):
		w.log.Error("analytics_snapshot_cycle_failed", zap.Error(err))
	case run.DaysBuilt > 0:
		w.log.Info("analytics_snapshot_cycle",
			zap.String("run_id", run.ID), zap.Int("days_built", run.DaysBuilt),
			zap.String("from", run.From.Format(time.DateOnly)), zap.String("to", run.To.Format(time.DateOnly)),
			zap.Duration("duration", time.Since(started)))
	default:
		// Heartbeat: the worker is alive and every day in the window is final.
		w.log.Debug("analytics_snapshot_cycle_idle", zap.Duration("duration", time.Since(started)))
	}
}

func utcDay(t time.Time) time.Time {
	t = t.UTC()
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}

// dayIsFinal reports whether a day's sources are settled enough that a build
// now is the last one: a full day has passed since the day ended.
func dayIsFinal(day, now time.Time) bool {
	return !now.Before(day.AddDate(0, 0, 2))
}

// lockedConn returns a dedicated session holding the snapshot advisory lock.
func (w *analyticsSnapshotWorker) lockedConn(ctx context.Context) (*sql.Conn, error) {
	conn, err := w.db.Conn(ctx)
	if err != nil {
		return nil, err
	}
	var locked bool
	if err := conn.QueryRowContext(ctx, `SELECT pg_try_advisory_lock($1)`, analyticsSnapshotLockKey).Scan(&locked); err != nil {
		_ = conn.Close()
		return nil, err
	}
	if !locked {
		_ = conn.Close()
		return nil, errAnalyticsSnapshotBusy
	}
	return conn, nil
}

func releaseAnalyticsLock(conn *sql.Conn) {
	// A fresh context: the run's own context may already be cancelled, and a
	// session lock left behind would block every later run on this connection.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, _ = conn.ExecContext(ctx, `SELECT pg_advisory_unlock($1)`, analyticsSnapshotLockKey)
	_ = conn.Close()
}

// RunScheduled builds whatever the trailing window still needs.
func (w *analyticsSnapshotWorker) RunScheduled(ctx context.Context) (analyticsSnapshotRun, error) {
	// A database without migration 123 has nothing to build; stay quiet.
	var present bool
	if err := w.db.QueryRowContext(ctx, `SELECT to_regclass('analytics.snapshot_days') IS NOT NULL`).Scan(&present); err != nil {
		return analyticsSnapshotRun{}, err
	}
	if !present {
		return analyticsSnapshotRun{}, nil
	}
	conn, err := w.lockedConn(ctx)
	if err != nil {
		return analyticsSnapshotRun{}, err
	}
	defer releaseAnalyticsLock(conn)

	now := w.now().UTC()
	yesterday := utcDay(now).AddDate(0, 0, -1)
	windowStart := yesterday.AddDate(0, 0, -(analyticsSnapshotWindowDays - 1))
	earliest, err := earliestAnalyticsDay(ctx, conn)
	if err != nil {
		return analyticsSnapshotRun{}, err
	}
	if earliest.IsZero() || earliest.After(yesterday) {
		return analyticsSnapshotRun{}, nil
	}
	if windowStart.Before(earliest) {
		windowStart = earliest
	}
	state := map[time.Time]bool{} // day -> final
	rows, err := conn.QueryContext(ctx, `SELECT day, final FROM analytics.snapshot_days
		WHERE built_at IS NOT NULL AND day BETWEEN $1 AND $2`, windowStart, yesterday)
	if err != nil {
		return analyticsSnapshotRun{}, err
	}
	for rows.Next() {
		var day time.Time
		var final bool
		if err := rows.Scan(&day, &final); err != nil {
			rows.Close()
			return analyticsSnapshotRun{}, err
		}
		state[utcDay(day)] = final
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return analyticsSnapshotRun{}, err
	}
	var days []time.Time
	for d := windowStart; !d.After(yesterday); d = d.AddDate(0, 0, 1) {
		final, built := state[d]
		if !built || (!final && dayIsFinal(d, now)) {
			days = append(days, d)
		}
	}
	if len(days) == 0 {
		return analyticsSnapshotRun{}, nil
	}
	return w.build(ctx, conn, "scheduled", "scheduler", days, now)
}

// Rebuild replaces every day in [from, to] synchronously. The caller must not
// hold the lock.
func (w *analyticsSnapshotWorker) Rebuild(ctx context.Context, from, to time.Time, requestedBy string) (analyticsSnapshotRun, error) {
	conn, days, err := w.prepareRebuild(ctx, from, to)
	if err != nil {
		return analyticsSnapshotRun{}, err
	}
	defer releaseAnalyticsLock(conn)
	return w.build(ctx, conn, "rebuild", requestedBy, days, w.now().UTC())
}

// StartRebuild takes the lock and records the run before returning, so the
// caller learns synchronously whether another run is in progress, then builds
// in the background.
func (w *analyticsSnapshotWorker) StartRebuild(from, to time.Time, requestedBy string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Hour)
	conn, days, err := w.prepareRebuild(ctx, from, to)
	if err != nil {
		cancel()
		return "", err
	}
	runID, err := w.startRun(ctx, conn, "rebuild", requestedBy, days)
	if err != nil {
		releaseAnalyticsLock(conn)
		cancel()
		return "", err
	}
	go func() {
		defer cancel()
		defer releaseAnalyticsLock(conn)
		if _, err := w.buildRecorded(ctx, conn, runID, days, w.now().UTC()); err != nil {
			w.log.Error("analytics_snapshot_rebuild_failed", zap.String("run_id", runID), zap.Error(err))
			return
		}
		w.log.Info("analytics_snapshot_rebuild", zap.String("run_id", runID), zap.Int("days_built", len(days)),
			zap.String("requested_by", requestedBy))
	}()
	return runID, nil
}

func (w *analyticsSnapshotWorker) prepareRebuild(ctx context.Context, from, to time.Time) (*sql.Conn, []time.Time, error) {
	from, to = utcDay(from), utcDay(to)
	yesterday := utcDay(w.now()).AddDate(0, 0, -1)
	if to.After(yesterday) {
		return nil, nil, fmt.Errorf("only completed UTC days can be rebuilt (latest is %s)", yesterday.Format(time.DateOnly))
	}
	if to.Before(from) {
		return nil, nil, errors.New("to must not be before from")
	}
	if int(to.Sub(from).Hours()/24)+1 > analyticsRebuildMaxDays {
		return nil, nil, fmt.Errorf("rebuild at most %d days at a time", analyticsRebuildMaxDays)
	}
	conn, err := w.lockedConn(ctx)
	if err != nil {
		return nil, nil, err
	}
	earliest, err := earliestAnalyticsDay(ctx, conn)
	if err != nil {
		releaseAnalyticsLock(conn)
		return nil, nil, err
	}
	if !earliest.IsZero() && from.Before(earliest) {
		from = earliest
	}
	var days []time.Time
	for d := from; !d.After(to); d = d.AddDate(0, 0, 1) {
		days = append(days, d)
	}
	if len(days) == 0 {
		releaseAnalyticsLock(conn)
		return nil, nil, errors.New("no member activity exists in that range")
	}
	return conn, days, nil
}

func earliestAnalyticsDay(ctx context.Context, conn *sql.Conn) (time.Time, error) {
	var earliest sql.NullTime
	if err := conn.QueryRowContext(ctx, `SELECT MIN((created_at AT TIME ZONE 'UTC')::date) FROM user_management.users`).Scan(&earliest); err != nil {
		return time.Time{}, err
	}
	if !earliest.Valid {
		return time.Time{}, nil
	}
	return utcDay(earliest.Time), nil
}

func (w *analyticsSnapshotWorker) startRun(ctx context.Context, conn *sql.Conn, kind, requestedBy string, days []time.Time) (string, error) {
	var runID string
	err := conn.QueryRowContext(ctx, `INSERT INTO analytics.snapshot_runs(kind, from_day, to_day, requested_by)
		VALUES ($1, $2, $3, $4) RETURNING id::text`, kind, days[0], days[len(days)-1], requestedBy).Scan(&runID)
	return runID, err
}

func (w *analyticsSnapshotWorker) build(ctx context.Context, conn *sql.Conn, kind, requestedBy string, days []time.Time, now time.Time) (analyticsSnapshotRun, error) {
	runID, err := w.startRun(ctx, conn, kind, requestedBy, days)
	if err != nil {
		return analyticsSnapshotRun{}, err
	}
	run, err := w.buildRecorded(ctx, conn, runID, days, now)
	run.Kind = kind
	return run, err
}

// buildRecorded derives the activity the rolling windows need, rebuilds each
// day in order, refreshes the activation milestones and closes the run row.
func (w *analyticsSnapshotWorker) buildRecorded(ctx context.Context, conn *sql.Conn, runID string, days []time.Time, now time.Time) (analyticsSnapshotRun, error) {
	run := analyticsSnapshotRun{ID: runID, From: days[0], To: days[len(days)-1]}
	finish := func(buildErr error) error {
		status, message := "succeeded", sql.NullString{}
		if buildErr != nil {
			status, message = "failed", sql.NullString{String: buildErr.Error(), Valid: true}
		}
		closeCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, err := conn.ExecContext(closeCtx, `UPDATE analytics.snapshot_runs
			SET status = $2, error = $3, days_built = $4, finished_at = NOW() WHERE id = $1`,
			runID, status, message, run.DaysBuilt)
		if buildErr != nil {
			return buildErr
		}
		return err
	}
	// WAU/MAU of the first day read the 29 days before it; derive any of those
	// that have never been derived (cheap, insert-only).
	if _, err := conn.ExecContext(ctx, `
		SELECT analytics.derive_active_days(d::date)
		  FROM generate_series($1::date - $2::int, $1::date - 1, INTERVAL '1 day') d
		 WHERE d::date >= (SELECT MIN((created_at AT TIME ZONE 'UTC')::date) FROM user_management.users)
		   AND NOT EXISTS (SELECT 1 FROM analytics.snapshot_days s WHERE s.day = d::date AND s.derived_at IS NOT NULL)`,
		days[0], analyticsActiveWindowLookback); err != nil {
		return run, finish(fmt.Errorf("derive lookback activity: %w", err))
	}
	// Days are rebuilt oldest first and each rebuild derives its own activity,
	// so a later day's rolling windows see the earlier days of the range.
	for _, day := range days {
		if err := ctx.Err(); err != nil {
			return run, finish(err)
		}
		var metricRows, active, surfaces int
		if err := conn.QueryRowContext(ctx, `SELECT metric_rows, active_members, surface_rows FROM analytics.rebuild_day($1::date, $2)`,
			day, dayIsFinal(day, now)).Scan(&metricRows, &active, &surfaces); err != nil {
			return run, finish(fmt.Errorf("rebuild %s: %w", day.Format(time.DateOnly), err))
		}
		run.DaysBuilt++
	}
	if _, err := conn.ExecContext(ctx, `SELECT analytics.refresh_member_milestones()`); err != nil {
		return run, finish(fmt.Errorf("refresh milestones: %w", err))
	}
	return run, finish(nil)
}
