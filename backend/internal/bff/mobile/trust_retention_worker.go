package mobile

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"sync"
	"time"

	"github.com/verified-dating/backend/internal/platform/observability"
	"go.uber.org/zap"
)

// trustRetentionWorker runs the retention classes of
// documents/contracts/trust_operations.v1.json that need a job:
//
//   - platform.run_trust_retention (migration 081): revoked sessions, disabled
//     push tokens, SOS delivery snapshots and 24-month audit history, all in
//     SQL and all skipping members on legal hold where the policy says so.
//   - identity evidence 30 days after a final verification decision: the
//     private objects are deleted here, then the database reference is cleared.
//
// It also publishes the SOS delivery gauges on every cycle. That is on purpose
// independent of the SOS delivery engine: when no provider is configured the
// engine never starts, and undelivered emergency alerts must still be visible.
const sosGaugeRefreshInterval = 30 * time.Second

type trustRetentionWorker struct {
	db          *sql.DB
	log         *zap.Logger
	metrics     *observability.HTTPMetrics
	deleteMedia func(string) error
	interval    time.Duration
	batch       int
	cancel      context.CancelFunc
	done        sync.WaitGroup
}

type trustRetentionResult struct {
	RevokedSessions      int
	DisabledPushTokens   int
	SOSDeliverySnapshots int
	SecurityEvents       int
	RowChanges           int
	ActivityEvents       int
	IdentityEvidence     int
	// Migration 122: 90-day request telemetry and client crash reports.
	APIRequestEvents       int
	ClientErrorOccurrences int
	ClientErrorIssues      int
	// Migration 132: 400-day member action history.
	MemberActionEvents int
	// Migration 133: server activity classes by policy name.
	ServerActivity map[string]int
}

func newTrustRetentionWorker(
	db *sql.DB,
	log *zap.Logger,
	metrics *observability.HTTPMetrics,
	deleteMedia func(string) error,
	interval time.Duration,
) *trustRetentionWorker {
	if db == nil {
		return nil
	}
	if log == nil {
		log = zap.NewNop()
	}
	if interval <= 0 {
		interval = time.Hour
	}
	return &trustRetentionWorker{
		db: db, log: log, metrics: metrics, deleteMedia: deleteMedia,
		interval: interval, batch: 1000,
	}
}

func (w *trustRetentionWorker) Start(parent context.Context) {
	if w == nil || w.cancel != nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	w.cancel = cancel
	w.done.Add(1)
	go func() {
		defer w.done.Done()
		retention := time.NewTicker(w.interval)
		defer retention.Stop()
		// Emergency delivery health cannot wait for the hourly retention pass;
		// the SOS gauges refresh on their own short cadence.
		gauges := time.NewTicker(sosGaugeRefreshInterval)
		defer gauges.Stop()
		sosGauges := observability.NewHeartbeat(workerSOSGaugeRefresh, sosGaugeRefreshInterval)
		if _, err := w.RunOnce(ctx); err != nil && !errors.Is(err, context.Canceled) {
			w.log.Error("trust_retention_cycle_failed", zap.Error(err))
		}
		for {
			select {
			case <-ctx.Done():
				return
			case <-retention.C:
				if _, err := w.RunOnce(ctx); err != nil && !errors.Is(err, context.Canceled) {
					w.log.Error("trust_retention_cycle_failed", zap.Error(err))
				}
			case <-gauges.C:
				run := sosGauges.Begin()
				err := w.refreshSOSGauges(ctx)
				run.End(err)
				if err != nil && !errors.Is(err, context.Canceled) {
					w.log.Warn("sos_gauge_refresh_failed", zap.Error(err))
				}
			}
		}
	}()
}

func (w *trustRetentionWorker) Stop() {
	if w == nil || w.cancel == nil {
		return
	}
	w.cancel()
	w.done.Wait()
}

// RunOnce performs one retention pass and refreshes the SOS gauges. Each class
// runs even if an earlier one failed; the first error is returned.
func (w *trustRetentionWorker) RunOnce(ctx context.Context) (trustRetentionResult, error) {
	var result trustRetentionResult
	var firstErr error
	run := observability.NewHeartbeat(workerTrustRetention, w.interval).Begin()
	defer func() { run.End(firstErr) }()
	keep := func(err error) {
		if err != nil && firstErr == nil {
			firstErr = err
		}
	}

	if err := w.db.QueryRowContext(ctx, `SELECT * FROM platform.run_trust_retention($1)`, w.batch).Scan(
		&result.RevokedSessions, &result.DisabledPushTokens, &result.SOSDeliverySnapshots,
		&result.SecurityEvents, &result.RowChanges, &result.ActivityEvents); err != nil {
		keep(err)
	}
	purged, err := w.purgeIdentityEvidence(ctx)
	result.IdentityEvidence = purged
	keep(err)
	apiRequests, occurrences, issues, memberActions, err := runActivityTelemetryRetention(ctx, w.db, w.batch)
	if err != nil && strings.Contains(err.Error(), "run_client_telemetry_retention") && strings.Contains(err.Error(), "does not exist") {
		err = nil // migration 122 not applied yet
	}
	result.APIRequestEvents, result.ClientErrorOccurrences, result.ClientErrorIssues = apiRequests, occurrences, issues
	result.MemberActionEvents = memberActions
	keep(err)
	serverActivity, err := runServerActivityRetention(ctx, w.db, w.batch)
	result.ServerActivity = serverActivity
	keep(err)
	keep(w.refreshSOSGauges(ctx))

	w.record(result)
	classes := result.classCounts()
	removed := 0
	for _, n := range classes {
		removed += n
	}
	run.Items("processed", removed)
	run.Detail("purged", classes)
	return result, firstErr
}

// classCounts is the rows each retention class removed in one pass.
func (r trustRetentionResult) classCounts() map[string]int {
	counts := map[string]int{
		"revoked_sessions":       r.RevokedSessions,
		"disabled_push_tokens":   r.DisabledPushTokens,
		"sos_delivery_snapshots": r.SOSDeliverySnapshots,
		"security_audit_history": r.SecurityEvents,
		"row_change_history":     r.RowChanges,
		"activity_history":       r.ActivityEvents,
		"identity_evidence":      r.IdentityEvidence,
		"api_request_telemetry":  r.APIRequestEvents,
		"client_error_reports":   r.ClientErrorOccurrences,
		"client_error_issues":    r.ClientErrorIssues,
		"member_action_history":  r.MemberActionEvents,
	}
	for class, n := range r.ServerActivity {
		counts[class] = n
	}
	return counts
}

// runServerActivityRetention applies the migration 133 classes (job runs,
// rollups, server events, capacity snapshots, third-party usage). Before the
// migration is applied it does nothing.
func runServerActivityRetention(ctx context.Context, db *sql.DB, batch int) (map[string]int, error) {
	var jobRuns, jobRollups, requestRollups, events, snapshots, usage int
	err := db.QueryRowContext(ctx, `SELECT job_runs, job_rollups, request_rollups, server_events, capacity_snapshots, third_party_usage
		FROM platform.run_server_activity_retention($1)`, batch).
		Scan(&jobRuns, &jobRollups, &requestRollups, &events, &snapshots, &usage)
	if err != nil {
		if strings.Contains(err.Error(), "run_server_activity_retention") && strings.Contains(err.Error(), "does not exist") {
			return nil, nil
		}
		return nil, err
	}
	return map[string]int{
		"server_job_runs": jobRuns, "server_job_rollups": jobRollups, "server_request_rollups": requestRollups,
		"server_events": events, "server_capacity_snapshots": snapshots, "server_third_party_usage": usage,
	}, nil
}

type identityEvidenceRow struct {
	id    string
	paths []string
}

// purgeIdentityEvidence deletes ID-document and selfie objects once a final
// decision (verified, rejected or expired) is older than the policy window,
// then clears the database reference. A row whose objects could not all be
// deleted keeps its reference so the next cycle retries.
func (w *trustRetentionWorker) purgeIdentityEvidence(ctx context.Context) (int, error) {
	rows, err := w.db.QueryContext(ctx, `
		SELECT v.id::text,
		       COALESCE(v.details->'id_document'->>'storage_path',''),
		       COALESCE(v.details->'selfie'->>'storage_path','')
		FROM matching.verification_states v
		JOIN platform.retention_policies p
		  ON p.policy_name='identity_evidence' AND p.enabled
		WHERE v.status IN ('verified','rejected','expired')
		  AND v.reviewed_at IS NOT NULL
		  AND v.reviewed_at < NOW() - p.retention_interval
		  AND (v.details ? 'id_document' OR v.details ? 'selfie')
		  AND NOT platform.member_on_legal_hold(v.user_id)
		ORDER BY v.reviewed_at
		LIMIT 100`)
	if err != nil {
		return 0, err
	}
	var due []identityEvidenceRow
	for rows.Next() {
		var id, document, selfie string
		if err := rows.Scan(&id, &document, &selfie); err != nil {
			rows.Close()
			return 0, err
		}
		row := identityEvidenceRow{id: id}
		for _, path := range []string{document, selfie} {
			if strings.TrimSpace(path) != "" {
				row.paths = append(row.paths, path)
			}
		}
		due = append(due, row)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return 0, err
	}

	purged := 0
	var firstErr error
	for _, row := range due {
		if !w.deleteObjects(row) {
			continue
		}
		if _, err := w.db.ExecContext(ctx, `
			UPDATE matching.verification_states
			SET details = (details - 'id_document' - 'selfie')
			              || jsonb_build_object('evidence_purged_at', NOW()),
			    updated_at = NOW()
			WHERE id = $1::uuid`, row.id); err != nil {
			if firstErr == nil {
				firstErr = err
			}
			continue
		}
		purged++
	}
	return purged, firstErr
}

func (w *trustRetentionWorker) deleteObjects(row identityEvidenceRow) bool {
	if w.deleteMedia == nil {
		return len(row.paths) == 0
	}
	for _, path := range row.paths {
		if err := w.deleteMedia(path); err != nil {
			w.log.Warn("identity_evidence_delete_failed",
				zap.String("verification_id", row.id), zap.Error(err))
			return false
		}
	}
	return true
}

func (w *trustRetentionWorker) refreshSOSGauges(ctx context.Context) error {
	if w.metrics == nil {
		return nil
	}
	var queueDepth, overdue, deadLetters, oldest int64
	if err := w.db.QueryRowContext(ctx, `
		SELECT queue_depth + processing, overdue, dead_letters, oldest_pending_age_seconds
		FROM matching.sos_delivery_metrics`).Scan(&queueDepth, &overdue, &deadLetters, &oldest); err != nil {
		return err
	}
	w.metrics.SOSDeliveryQueueDepth.Set(float64(queueDepth))
	observability.NewHeartbeat(workerSOSDelivery, 0).SetBacklog(float64(queueDepth))
	w.metrics.SOSDeliveryOverdue.Set(float64(overdue))
	w.metrics.SOSDeliveryDeadLetters.Set(float64(deadLetters))
	w.metrics.SOSDeliveryOldestPendingAge.Set(float64(oldest))
	return nil
}

func (w *trustRetentionWorker) record(result trustRetentionResult) {
	if w.metrics != nil && w.metrics.TrustRetentionRuns != nil {
		for class, count := range result.classCounts() {
			if count > 0 {
				w.metrics.TrustRetentionRuns.WithLabelValues(class).Add(float64(count))
			}
		}
	}
	total := result.RevokedSessions + result.DisabledPushTokens + result.SOSDeliverySnapshots +
		result.SecurityEvents + result.RowChanges + result.ActivityEvents + result.IdentityEvidence +
		result.APIRequestEvents + result.ClientErrorOccurrences + result.ClientErrorIssues + result.MemberActionEvents
	if total > 0 {
		w.log.Info("trust_retention_cycle",
			zap.Int("revoked_sessions", result.RevokedSessions),
			zap.Int("disabled_push_tokens", result.DisabledPushTokens),
			zap.Int("sos_delivery_snapshots", result.SOSDeliverySnapshots),
			zap.Int("security_events", result.SecurityEvents),
			zap.Int("row_changes", result.RowChanges),
			zap.Int("activity_events", result.ActivityEvents),
			zap.Int("identity_evidence", result.IdentityEvidence),
			zap.Int("api_request_telemetry", result.APIRequestEvents),
			zap.Int("client_error_reports", result.ClientErrorOccurrences),
			zap.Int("client_error_issues", result.ClientErrorIssues),
			zap.Int("member_action_history", result.MemberActionEvents))
	}
}
