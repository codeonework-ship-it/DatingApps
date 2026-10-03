package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"
	"syscall"
	"time"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

// Capacity snapshots and third-party usage (migration 133).
//
// capacitySnapshotWorker runs once at startup and then hourly. Each run:
//
//  1. writes platform.capacity_snapshots: database size, connections, the 30
//     largest relations, row estimates of the growth tables, stored media
//     bytes per kind and local disk (media directory and, when readable, the
//     database data directory). A snapshot newer than half the interval
//     (another instance, a quick restart) makes the snapshot step a skip.
//  2. upserts today's and yesterday's platform.third_party_usage_daily rows,
//     aggregated from the tables the integrations already write.
//
// It uses the shared heartbeat, so its runs land in platform.job_runs too.

const (
	workerCapacitySnapshot   = "capacity_snapshot"
	capacitySnapshotInterval = time.Hour
	capacityTopRelations     = 30
	capacityStatementTimeout = 30 * time.Second
)

type capacitySnapshotWorker struct {
	db       *sql.DB
	log      *zap.Logger
	interval time.Duration
	mediaDir string
	instance string
	now      func() time.Time

	cancel context.CancelFunc
	done   sync.WaitGroup
}

func newCapacitySnapshotWorker(db *sql.DB, log *zap.Logger, cfg config.Config, interval time.Duration) *capacitySnapshotWorker {
	if log == nil {
		log = zap.NewNop()
	}
	if interval <= 0 {
		interval = capacitySnapshotInterval
	}
	return &capacitySnapshotWorker{
		db: db, log: log, interval: interval, mediaDir: localMediaDir(cfg),
		instance: serverInstanceName(), now: time.Now,
	}
}

// localMediaDir is the local filesystem root of stored media ("" for S3).
func localMediaDir(cfg config.Config) string {
	storage := mediaStorageConfigFor(cfg)
	if storage.Backend == config.StorageBackendAWSS3 {
		return ""
	}
	if dir := strings.TrimSpace(storage.Local.Root); dir != "" {
		return dir
	}
	return strings.TrimSpace(storage.Local.LegacyUploadsDir)
}

func (w *capacitySnapshotWorker) Start(parent context.Context) {
	if w == nil || w.db == nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	w.cancel = cancel
	w.done.Add(1)
	go func() {
		defer w.done.Done()
		w.cycle(ctx)
		ticker := time.NewTicker(w.interval)
		defer ticker.Stop()
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

func (w *capacitySnapshotWorker) Stop() {
	if w == nil || w.cancel == nil {
		return
	}
	w.cancel()
	w.done.Wait()
}

func (w *capacitySnapshotWorker) cycle(ctx context.Context) {
	if _, err := w.RunOnce(ctx); err != nil && !errors.Is(err, context.Canceled) {
		w.log.Warn("capacity_snapshot_failed", zap.Error(err))
	}
}

// capacityTable is one entry of capacity_snapshots.tables.
type capacityTable struct {
	Table          string  `json:"table"`
	TotalBytes     int64   `json:"total_bytes"`
	TableBytes     int64   `json:"table_bytes"`
	IndexBytes     int64   `json:"index_bytes"`
	LiveRows       *int64  `json:"live_rows"`
	DeadRows       *int64  `json:"dead_rows"`
	LastAutovacuum *string `json:"last_autovacuum"`
	SeqScan        *int64  `json:"seq_scan"`
	IdxScan        *int64  `json:"idx_scan"`
}

type capacitySnapshot struct {
	At                time.Time
	DBSizeBytes       int64
	Connections       int
	MaxConnections    int
	OutboxRows        *int64
	ActivityRows      *int64
	SecurityEventRows *int64
	MediaBytes        map[string]int64
	MediaBytesTotal   int64
	Disk              map[string]any
	Tables            []capacityTable
	Skipped           bool
	ThirdPartyRows    int
}

// RunOnce takes one snapshot and refreshes third-party usage.
func (w *capacitySnapshotWorker) RunOnce(ctx context.Context) (capacitySnapshot, error) {
	run := observability.NewHeartbeat(workerCapacitySnapshot, w.interval).Begin()
	var runErr error
	var snap capacitySnapshot
	defer func() { run.End(runErr) }()
	ctx, cancel := context.WithTimeout(ctx, 2*capacityStatementTimeout)
	defer cancel()
	started := w.now()

	var recent bool
	if err := w.db.QueryRowContext(ctx, `SELECT EXISTS (SELECT 1 FROM platform.capacity_snapshots WHERE at > NOW() - $1::interval)`,
		fmt.Sprintf("%d seconds", int(w.interval.Seconds()/2))).Scan(&recent); err != nil {
		runErr = err
		return snap, err
	}
	if recent {
		snap.Skipped = true
	} else {
		var err error
		snap, err = collectCapacitySnapshot(ctx, w.db, w.mediaDir)
		if err != nil {
			runErr = err
			return snap, err
		}
		if err := w.insertSnapshot(ctx, snap, time.Since(started)); err != nil {
			runErr = err
			return snap, err
		}
		run.Items("processed", 1)
		run.Detail("db_size_bytes", snap.DBSizeBytes)
		run.Detail("media_bytes_total", snap.MediaBytesTotal)
		run.Detail("connections", snap.Connections)
	}

	usageRows, err := refreshThirdPartyUsage(ctx, w.db, w.now().UTC())
	snap.ThirdPartyRows = usageRows
	run.Detail("third_party_rows", usageRows)
	if err != nil {
		runErr = err
		return snap, err
	}
	if snap.Skipped {
		run.Detail("snapshot", "recent snapshot exists")
		run.MarkSkipped()
	}
	return snap, nil
}

func (w *capacitySnapshotWorker) insertSnapshot(ctx context.Context, snap capacitySnapshot, took time.Duration) error {
	media, _ := json.Marshal(snap.MediaBytes)
	disk, _ := json.Marshal(snap.Disk)
	tables, _ := json.Marshal(snap.Tables)
	_, err := w.db.ExecContext(ctx, `INSERT INTO platform.capacity_snapshots
		(instance, db_size_bytes, connections, max_connections, outbox_rows, activity_rows, security_event_rows,
		 media_bytes, media_bytes_total, disk, tables, duration_ms)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb,$9,$10::jsonb,$11::jsonb,$12)`,
		w.instance, snap.DBSizeBytes, snap.Connections, snap.MaxConnections,
		snap.OutboxRows, snap.ActivityRows, snap.SecurityEventRows,
		string(media), snap.MediaBytesTotal, string(disk), string(tables), took.Milliseconds())
	return err
}

// capacityMediaSources lists where each kind of stored media records its size
// (migrations 056, 073, 105, 107, 121, 126).
var capacityMediaSources = []struct{ kind, table, column string }{
	{"profile_photos", "user_management.photos", "size_bytes"},
	{"voice_icebreakers", "matching.voice_icebreakers", "audio_size_bytes"},
	{"blog_photos", "matching.blog_photos", "size_bytes"},
	{"theme_photos", "matching.photo_theme_entries", "size_bytes"},
	{"group_covers", "matching.community_group_covers", "size_bytes"},
	{"support_attachments", "support.ticket_attachments", "size_bytes"},
}

// capacityRowEstimates are the growth tables whose row count is estimated
// from the planner statistics (reltuples), never counted.
var capacityRowEstimates = []string{"platform.domain_event_outbox", "matching.activity_events", "audit.security_events"}

func collectCapacitySnapshot(ctx context.Context, db *sql.DB, mediaDir string) (capacitySnapshot, error) {
	snap := capacitySnapshot{At: time.Now().UTC(), MediaBytes: map[string]int64{}, Disk: map[string]any{}, Tables: []capacityTable{}}
	if err := db.QueryRowContext(ctx, `SELECT pg_database_size(current_database()),
		       COALESCE((SELECT SUM(numbackends) FROM pg_stat_database WHERE datname = current_database()), 0)::int,
		       current_setting('max_connections')::int`).
		Scan(&snap.DBSizeBytes, &snap.Connections, &snap.MaxConnections); err != nil {
		return snap, fmt.Errorf("database size: %w", err)
	}

	rows, err := db.QueryContext(ctx, `SELECT n.nspname || '.' || c.relname,
		       pg_total_relation_size(c.oid), pg_table_size(c.oid), pg_indexes_size(c.oid),
		       s.n_live_tup, s.n_dead_tup, s.last_autovacuum, s.seq_scan, s.idx_scan
		FROM pg_class c
		JOIN pg_namespace n ON n.oid = c.relnamespace
		LEFT JOIN pg_stat_all_tables s ON s.relid = c.oid
		WHERE c.relkind IN ('r', 'm', 'p')
		  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
		  AND n.nspname NOT LIKE 'pg_toast%' AND n.nspname NOT LIKE 'pg_temp%'
		ORDER BY pg_total_relation_size(c.oid) DESC
		LIMIT $1`, capacityTopRelations)
	if err != nil {
		return snap, fmt.Errorf("relation sizes: %w", err)
	}
	for rows.Next() {
		var t capacityTable
		var live, dead, seq, idx sql.NullInt64
		var vacuum sql.NullTime
		if err := rows.Scan(&t.Table, &t.TotalBytes, &t.TableBytes, &t.IndexBytes, &live, &dead, &vacuum, &seq, &idx); err != nil {
			rows.Close()
			return snap, err
		}
		t.LiveRows, t.DeadRows, t.SeqScan, t.IdxScan = nullInt64Ptr(live), nullInt64Ptr(dead), nullInt64Ptr(seq), nullInt64Ptr(idx)
		if vacuum.Valid {
			formatted := vacuum.Time.UTC().Format(time.RFC3339)
			t.LastAutovacuum = &formatted
		}
		snap.Tables = append(snap.Tables, t)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return snap, err
	}

	estimates := make([]*int64, len(capacityRowEstimates))
	for i, relation := range capacityRowEstimates {
		var estimate sql.NullInt64
		if err := db.QueryRowContext(ctx, `SELECT CASE WHEN c.reltuples < 0 THEN NULL ELSE c.reltuples::bigint END
			FROM pg_class c WHERE c.oid = to_regclass($1)`, relation).Scan(&estimate); err != nil && !errors.Is(err, sql.ErrNoRows) {
			return snap, fmt.Errorf("row estimate %s: %w", relation, err)
		}
		estimates[i] = nullInt64Ptr(estimate)
	}
	snap.OutboxRows, snap.ActivityRows, snap.SecurityEventRows = estimates[0], estimates[1], estimates[2]

	for _, source := range capacityMediaSources {
		var exists bool
		if err := db.QueryRowContext(ctx, `SELECT EXISTS (SELECT 1 FROM information_schema.columns
			WHERE table_schema = split_part($1, '.', 1) AND table_name = split_part($1, '.', 2) AND column_name = $2)`,
			source.table, source.column).Scan(&exists); err != nil {
			return snap, err
		}
		if !exists {
			continue
		}
		var bytes int64
		// Identifiers come from the fixed list above, never from a request.
		if err := db.QueryRowContext(ctx, `SELECT COALESCE(SUM(`+source.column+`), 0)::bigint FROM `+source.table).Scan(&bytes); err != nil {
			return snap, fmt.Errorf("media bytes %s: %w", source.kind, err)
		}
		snap.MediaBytes[source.kind] = bytes
		snap.MediaBytesTotal += bytes
	}

	if mediaDir != "" {
		if usage, ok := diskUsage(mediaDir); ok {
			snap.Disk["media"] = usage
		}
	}
	var dataDir string
	if err := db.QueryRowContext(ctx, `SELECT current_setting('data_directory', true)`).Scan(&dataDir); err == nil && dataDir != "" {
		if usage, ok := diskUsage(dataDir); ok {
			snap.Disk["database"] = usage
		}
	}
	return snap, nil
}

func nullInt64Ptr(value sql.NullInt64) *int64 {
	if !value.Valid {
		return nil
	}
	v := value.Int64
	return &v
}

// diskUsage reports free and total bytes of the filesystem holding path; it
// is false when the path cannot be read (a remote database, a missing dir).
// The path itself is not stored.
func diskUsage(path string) (map[string]any, bool) {
	var stat syscall.Statfs_t
	if err := syscall.Statfs(path, &stat); err != nil {
		return nil, false
	}
	total := int64(stat.Blocks) * int64(stat.Bsize)
	free := int64(stat.Bavail) * int64(stat.Bsize)
	if total <= 0 {
		return nil, false
	}
	return map[string]any{
		"free_bytes": free, "total_bytes": total,
		"used_percent": float64(int64((1-float64(free)/float64(total))*10000)) / 100,
	}, true
}

// ── Third-party usage ───────────────────────────────────────────────────────

// thirdPartyUsageSources aggregate existing tables per UTC day into
// (provider, operation, calls, failures, units, unit_label). $1 is the first
// instant of the window. Each needs its table to exist.
var thirdPartyUsageSources = []struct{ table, sql string }{
	// Push and in-app notification deliveries (057): calls are provider attempts.
	{"matching.notification_deliveries", `SELECT (created_at AT TIME ZONE 'UTC')::date, channel, 'deliver',
		SUM(GREATEST(attempt_count, 1)), COUNT(*) FILTER (WHERE status IN ('failed', 'dead_letter')),
		COUNT(*) FILTER (WHERE status = 'delivered'), 'deliveries'
		FROM matching.notification_deliveries WHERE created_at >= $1 GROUP BY 1, 2`},
	// Image moderation (Rekognition and local validation; operator decisions excluded).
	{"user_management.media_moderation_events", `SELECT (created_at AT TIME ZONE 'UTC')::date, provider, 'image_moderation',
		COUNT(*), COUNT(*) FILTER (WHERE decision ILIKE ANY (ARRAY['%error%', '%fail%', '%unavailable%'])),
		COALESCE(SUM(duration_ms), 0), 'ms'
		FROM user_management.media_moderation_events
		WHERE created_at >= $1 AND provider <> 'operator_review' GROUP BY 1, 2`},
	// Voice moderation (077).
	{"matching.voice_moderation_events", `SELECT (created_at AT TIME ZONE 'UTC')::date, provider, 'voice_moderation',
		COUNT(*), 0, COUNT(*), 'clips'
		FROM matching.voice_moderation_events WHERE created_at >= $1 GROUP BY 1, 2`},
	// Conversation copilot drafts (Claude or the template fallback).
	{"matching.copilot_drafts", `SELECT (created_at AT TIME ZONE 'UTC')::date, COALESCE(NULLIF(provider, ''), 'unknown'), 'draft',
		COUNT(*), 0, COUNT(*), 'drafts'
		FROM matching.copilot_drafts WHERE created_at >= $1 GROUP BY 1, 2`},
	// SOS contact webhook deliveries (076): calls are attempts.
	{"matching.sos_delivery_outbox", `SELECT (created_at AT TIME ZONE 'UTC')::date, 'sos_webhook', 'deliver',
		COALESCE(SUM(attempt_count), 0), COUNT(*) FILTER (WHERE status = 'dead_letter'),
		COUNT(*) FILTER (WHERE status = 'delivered'), 'delivered'
		FROM matching.sos_delivery_outbox WHERE created_at >= $1 GROUP BY 1`},
	// Payment provider webhooks received (070).
	{"matching.billing_webhook_events", `SELECT (received_at AT TIME ZONE 'UTC')::date, provider, 'webhook',
		COUNT(*), COUNT(*) FILTER (WHERE status = 'failed'), COUNT(*), 'events'
		FROM matching.billing_webhook_events WHERE received_at >= $1 GROUP BY 1, 2`},
	// Payments created with the provider; units are captured minor units.
	{"matching.billing_payments_runtime", `SELECT (created_at AT TIME ZONE 'UTC')::date, COALESCE(NULLIF(provider, ''), 'unknown'), 'payment',
		COUNT(*), COUNT(*) FILTER (WHERE status = 'failed'),
		COALESCE(SUM(amount_paise) FILTER (WHERE paid_at IS NOT NULL), 0), 'minor_units'
		FROM matching.billing_payments_runtime WHERE created_at >= $1 GROUP BY 1, 2`},
	// Video calls; units are connected minutes.
	{"matching.video_call_sessions", `SELECT (started_at AT TIME ZONE 'UTC')::date, 'video_calls', 'session',
		COUNT(*), COUNT(*) FILTER (WHERE status = 'failed'),
		COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM (ended_at - started_at))) FILTER (WHERE ended_at IS NOT NULL) / 60.0, 2), 0), 'minutes'
		FROM matching.video_call_sessions WHERE started_at >= $1 GROUP BY 1`},
}

// refreshThirdPartyUsage recomputes yesterday's and today's rows (UTC) and
// returns how many rows it upserted.
func refreshThirdPartyUsage(ctx context.Context, db *sql.DB, now time.Time) (int, error) {
	since := now.UTC().Truncate(24*time.Hour).AddDate(0, 0, -1)
	parts := []string{}
	for _, source := range thirdPartyUsageSources {
		var exists bool
		if err := db.QueryRowContext(ctx, `SELECT to_regclass($1) IS NOT NULL`, source.table).Scan(&exists); err != nil {
			return 0, err
		}
		if exists {
			parts = append(parts, "("+source.sql+")")
		}
	}
	if len(parts) == 0 {
		return 0, nil
	}
	var upserted int
	err := db.QueryRowContext(ctx, `WITH usage(day, provider, operation, calls, failures, units, unit_label) AS (
		`+strings.Join(parts, "\nUNION ALL\n")+`
	), upserted AS (
		INSERT INTO platform.third_party_usage_daily AS t (day, provider, operation, calls, failures, units, unit_label, updated_at)
		SELECT day, left(COALESCE(provider, 'unknown'), 64), operation, calls, failures, units, unit_label, NOW() FROM usage
		ON CONFLICT (day, provider, operation) DO UPDATE SET
		  calls = EXCLUDED.calls, failures = EXCLUDED.failures, units = EXCLUDED.units,
		  unit_label = EXCLUDED.unit_label, updated_at = NOW()
		RETURNING 1
	) SELECT COUNT(*) FROM upserted`, since).Scan(&upserted)
	return upserted, err
}
