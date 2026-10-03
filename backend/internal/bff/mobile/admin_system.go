package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"regexp"
	"slices"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// Server activity for the command center (migration 133).
//
//	GET /admin/system/events       platform.server_events, paged
//	GET /admin/system/jobs         one row per heartbeat worker
//	GET /admin/system/job-runs     platform.job_runs, paged
//	GET /admin/system/requests     platform.request_rollups_hourly by hour or day
//	GET /admin/system/capacity     platform.capacity_snapshots: latest, tables, series
//	GET /admin/system/third-party  platform.third_party_usage_daily rows and totals
//
// admin and ops_admin read every endpoint; analysts read requests, capacity
// and third-party (principalCanAccessAdminRoute).

const (
	systemListCountCap       = 10000
	systemRequestsWindow     = 24 * time.Hour
	systemCapacityWindow     = 30 * 24 * time.Hour
	systemThirdPartyWindow   = 30 * 24 * time.Hour
	systemCapacitySeriesMax  = 2000
	systemRequestsDefaultMax = 500
)

var systemEventsSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts:       map[string]string{"at": "at"},
	DefaultSort: "at", TieBreak: "id {dir}",
}

var systemJobRunsSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts:       map[string]string{"started_at": "started_at"},
	DefaultSort: "started_at", TieBreak: "id {dir}",
}

var (
	systemEventKinds = []string{
		observability.EventProcessStart, observability.EventProcessStop, observability.EventPanic,
		observability.EventServerError, observability.EventRefused, observability.EventWorkerFailed,
		observability.EventWorkerStale, observability.EventRetentionSummary, observability.EventMigrationApplied,
	}
	systemSeverities    = []string{observability.SeverityInfo, observability.SeverityWarning, observability.SeverityError, observability.SeverityCritical}
	systemRunStatuses   = []string{observability.WorkerRunSucceeded, observability.WorkerRunFailed, observability.WorkerRunSkipped, observability.WorkerRunBusy}
	systemStatusClasses = []string{"1xx", "2xx", "3xx", "4xx", "5xx", "unknown"}
	systemMethods       = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "OTHER"}
	systemWorkerPattern = regexp.MustCompile(`^[a-z0-9_]{1,64}$`)
)

func (s *Server) systemDB(w http.ResponseWriter, r *http.Request) (*sql.DB, bool) {
	if _, err := authenticatedOperatorID(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return nil, false
	}
	db := s.adminListDB()
	if db == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("server activity store unavailable"))
		return nil, false
	}
	return db, true
}

// oneOf validates an optional enumerated filter.
func oneOf(r *http.Request, key string, allowed []string, normalize func(string) string) (string, error) {
	value := strings.TrimSpace(r.URL.Query().Get(key))
	if normalize != nil {
		value = normalize(value)
	}
	if value == "" || slices.Contains(allowed, value) {
		return value, nil
	}
	return "", fmt.Errorf("%s must be one of: %s", key, strings.Join(allowed, ", "))
}

// parseSystemWindow reads the shared list contract (limit, from/to dates)
// and additionally accepts RFC 3339 timestamps for from/to. Without from the
// window starts def before to (or now).
func parseSystemWindow(r *http.Request, spec adminListSpec, def time.Duration, now time.Time) (adminListParams, time.Time, time.Time, error) {
	clone := r.Clone(r.Context())
	query := clone.URL.Query()
	var from, to time.Time
	for _, key := range []string{"from", "to"} {
		raw := strings.TrimSpace(query.Get(key))
		if !strings.Contains(raw, "T") {
			continue
		}
		parsed, err := time.Parse(time.RFC3339, raw)
		if err != nil {
			return adminListParams{}, from, to, errors.New("from and to must be YYYY-MM-DD dates or RFC 3339 timestamps")
		}
		if key == "from" {
			from = parsed.UTC()
		} else {
			to = parsed.UTC()
		}
		query.Del(key)
	}
	clone.URL.RawQuery = query.Encode()
	p, err := parseAdminListParams(clone, spec)
	if err != nil {
		return p, from, to, err
	}
	if from.IsZero() {
		from = p.From
	}
	if to.IsZero() {
		to = p.To
	}
	if from.IsZero() {
		end := now
		if !to.IsZero() {
			end = to
		}
		from = end.Add(-def)
	}
	if !to.IsZero() && !from.Before(to) {
		return p, from, to, errors.New("from must be before to")
	}
	return p, from, to, nil
}

// ── Events ──────────────────────────────────────────────────────────────────

// adminSystemEvents serves GET /admin/system/events.
func (s *Server) adminSystemEvents(w http.ResponseWriter, r *http.Request) {
	db, ok := s.systemDB(w, r)
	if !ok {
		return
	}
	params, err := parseAdminListParams(r, systemEventsSpec)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	kind, err := oneOf(r, "kind", systemEventKinds, strings.ToLower)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	severity, err := oneOf(r, "severity", systemSeverities, strings.ToLower)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	filter := newSQLFilter().
		Eq("kind", kind).
		Eq("severity", severity).
		Eq("service", truncateRunes(r.URL.Query().Get("service"), 64)).
		Search(params.Q, "message", "route").
		TimeRange("at", params)
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	items, total, capped, err := queryAdminMapPageCapped(ctx, db,
		`id, at, kind, severity, service, instance, message, route, correlation_id, count, first_at, last_at, details`,
		` FROM platform.server_events`, filter, params, systemListCountCap)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, params.Page(map[string]any{"events": items, "total_capped": capped}, total))
}

// ── Job runs ────────────────────────────────────────────────────────────────

// adminSystemJobRuns serves GET /admin/system/job-runs.
func (s *Server) adminSystemJobRuns(w http.ResponseWriter, r *http.Request) {
	db, ok := s.systemDB(w, r)
	if !ok {
		return
	}
	params, err := parseAdminListParams(r, systemJobRunsSpec)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	status, err := oneOf(r, "status", systemRunStatuses, strings.ToLower)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	worker := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("worker")))
	if worker != "" && !systemWorkerPattern.MatchString(worker) {
		writeAdminListParamError(w, errors.New("worker must be a worker name"))
		return
	}
	filter := newSQLFilter().
		Eq("worker", worker).
		Eq("status", status).
		Search(params.Q, "worker", "error").
		TimeRange("started_at", params)
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	items, total, capped, err := queryAdminMapPageCapped(ctx, db,
		`id, worker, instance, build_commit, started_at, finished_at, duration_ms, status, items_processed, items_failed,
		 backlog_after, error, details`,
		` FROM platform.job_runs`, filter, params, systemListCountCap)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, params.Page(map[string]any{"runs": items, "total_capped": capped}, total))
}

// ── Jobs ────────────────────────────────────────────────────────────────────

// systemWorkerCatalog is every heartbeat worker with its expected interval:
// the configured defaults, overridden by what this process's heartbeats
// actually published (observability.WorkerRegistry).
func (s *Server) systemWorkerCatalog() map[string]time.Duration {
	pollInterval := func(ms int) time.Duration {
		poll := time.Duration(ms) * time.Millisecond
		if poll < 100*time.Millisecond || poll > time.Minute {
			poll = 500 * time.Millisecond
		}
		return poll
	}
	billingSweep := time.Duration(s.cfg.BillingRenewalSweepSeconds) * time.Second
	if billingSweep <= 0 {
		billingSweep = 5 * time.Minute
	}
	catalog := map[string]time.Duration{
		workerAccountErasure:       time.Hour,
		workerMediaCleanup:         mediaCleanupInterval,
		workerBillingRenewalSweep:  billingSweep,
		workerDatePlanSweep:        datePlanSweepInterval,
		workerXPAwardSpoolReplay:   30 * time.Second,
		workerNotificationDelivery: pollInterval(s.cfg.NotificationPollIntervalMS),
		workerLevelProjection:      200 * time.Millisecond,
		workerTrustRetention:       time.Hour,
		workerSOSGaugeRefresh:      sosGaugeRefreshInterval,
		workerSOSDelivery:          pollInterval(s.cfg.SOSDeliveryPollIntervalMS),
		workerIdempotencyRetention: idempotencyRetentionInterval,
		workerAnalyticsSnapshot:    analyticsSnapshotInterval,
		workerSupportSLA:           supportSLAWorkerInterval,
		workerCapacitySnapshot:     capacitySnapshotInterval,
	}
	for _, info := range observability.WorkerRegistry() {
		if info.Interval > 0 {
			catalog[info.Worker] = info.Interval
		} else if _, ok := catalog[info.Worker]; !ok {
			catalog[info.Worker] = 0
		}
	}
	return catalog
}

// adminSystemJobs serves GET /admin/system/jobs.
func (s *Server) adminSystemJobs(w http.ResponseWriter, r *http.Request) {
	db, ok := s.systemDB(w, r)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	workers, err := systemJobsOverview(ctx, db, s.systemWorkerCatalog(), time.Now().UTC())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"workers": workers})
}

func systemJobsOverview(ctx context.Context, db *sql.DB, catalog map[string]time.Duration, now time.Time) ([]map[string]any, error) {
	names := make([]string, 0, len(catalog))
	for name := range catalog {
		names = append(names, name)
	}
	sort.Strings(names)
	rows, err := db.QueryContext(ctx, `SELECT w.worker,
		       lr.finished_at, lr.status, lr.duration_ms, lr.error,
		       ls.finished_at,
		       COALESCE(r24.runs, 0), COALESCE(r24.failures, 0), COALESCE(r24.items, 0),
		       ra.last_run_at, ra.last_success_at
		FROM unnest($1::text[]) AS w(worker)
		LEFT JOIN LATERAL (SELECT j.finished_at, j.status, j.duration_ms, j.error FROM platform.job_runs j
		                   WHERE j.worker = w.worker ORDER BY j.started_at DESC LIMIT 1) lr ON TRUE
		LEFT JOIN LATERAL (SELECT j.finished_at FROM platform.job_runs j
		                   WHERE j.worker = w.worker AND j.status <> 'failed' ORDER BY j.started_at DESC LIMIT 1) ls ON TRUE
		LEFT JOIN LATERAL (SELECT SUM(h.runs) AS runs, SUM(h.failures) AS failures, SUM(h.items) AS items
		                   FROM platform.job_run_rollups_hourly h
		                   WHERE h.worker = w.worker AND h.hour > $2::timestamptz - INTERVAL '24 hours') r24 ON TRUE
		LEFT JOIN LATERAL (SELECT MAX(h.last_run_at) AS last_run_at, MAX(h.last_success_at) AS last_success_at
		                   FROM platform.job_run_rollups_hourly h WHERE h.worker = w.worker) ra ON TRUE
		ORDER BY w.worker`, names, now)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]map[string]any, 0, len(names))
	for rows.Next() {
		var worker string
		var runFinished, runSuccess, rollRun, rollSuccess sql.NullTime
		var runStatus, runError sql.NullString
		var runDuration sql.NullInt64
		var runs24, failures24, items24 int64
		if err := rows.Scan(&worker, &runFinished, &runStatus, &runDuration, &runError, &runSuccess,
			&runs24, &failures24, &items24, &rollRun, &rollSuccess); err != nil {
			return nil, err
		}
		interval := catalog[worker]
		lastRun := latestTime(runFinished, rollRun)
		lastSuccess := latestTime(runSuccess, rollSuccess)
		item := map[string]any{
			"worker":                    worker,
			"expected_interval_seconds": interval.Seconds(),
			"last_run_at":               systemTime(lastRun),
			"last_success_at":           systemTime(lastSuccess),
			"last_status":               nil,
			"last_duration_ms":          nil,
			"last_error":                nil,
			"runs_24h":                  runs24,
			"failures_24h":              failures24,
			"items_24h":                 items24,
			"stale":                     nil,
		}
		switch {
		case runFinished.Valid && (!rollRun.Valid || !runFinished.Time.Before(rollRun.Time)):
			// The stored run is the latest one.
			item["last_status"] = runStatus.String
			item["last_duration_ms"] = runDuration.Int64
			if runError.Valid {
				item["last_error"] = runError.String
			}
		case rollRun.Valid:
			// A high-frequency worker's latest run had nothing to store; the
			// hourly rollup knows whether it succeeded.
			if rollSuccess.Valid && !rollSuccess.Time.Before(rollRun.Time) {
				item["last_status"] = observability.WorkerRunSucceeded
			} else {
				item["last_status"] = observability.WorkerRunFailed
			}
		}
		if interval > 0 && !lastRun.IsZero() {
			reference := lastSuccess
			if reference.IsZero() {
				reference = lastRun // runs exist but none succeeded
				item["stale"] = true
			} else {
				item["stale"] = now.Sub(reference) > workerStaleThreshold(interval)
			}
		}
		out = append(out, item)
	}
	return out, rows.Err()
}

func latestTime(values ...sql.NullTime) time.Time {
	var latest time.Time
	for _, value := range values {
		if value.Valid && value.Time.After(latest) {
			latest = value.Time
		}
	}
	return latest
}

func systemTime(t time.Time) any {
	if t.IsZero() {
		return nil
	}
	return t.UTC().Format(time.RFC3339Nano)
}

// ── Requests ────────────────────────────────────────────────────────────────

// systemRequestGroups maps group_by to its column.
var systemRequestGroups = map[string]string{
	"none": "", "route": "route", "status_class": "status_class", "service": "service", "method": "method",
}

// requestRollupAggregate is one aggregated request row.
type requestRollupAggregate struct {
	requests, serverErrors, refused, timed int64
	sumMS                                  float64
	buckets                                []int64
}

func (a requestRollupAggregate) avgMS() any {
	if a.timed == 0 {
		return nil
	}
	return roundMS(a.sumMS / float64(a.timed))
}

func (a requestRollupAggregate) percentileMS(q float64) any {
	if a.timed == 0 {
		return nil
	}
	return roundMS(observability.HistogramQuantile(q, observability.RequestRollupBucketsSeconds, a.buckets) * 1000)
}

func roundMS(value float64) float64 {
	return math.Round(value*100) / 100
}

func parseBigintArray(raw string) []int64 {
	out := make([]int64, observability.RequestRollupBucketCount)
	for i, part := range strings.Split(strings.Trim(raw, "{}"), ",") {
		if i >= len(out) {
			break
		}
		if value, err := strconv.ParseInt(strings.TrimSpace(part), 10, 64); err == nil {
			out[i] = value
		}
	}
	return out
}

// requestRollupSelect aggregates request rollups; refused counts 401, 403 and 429.
const requestRollupSelect = `COALESCE(SUM(requests), 0)::bigint,
	COALESCE(SUM(requests) FILTER (WHERE status_class = '5xx'), 0)::bigint,
	COALESCE(SUM(requests) FILTER (WHERE status_code IN (401, 403, 429)), 0)::bigint,
	COALESCE(SUM(timed_requests), 0)::bigint,
	COALESCE(SUM(sum_duration_ms), 0)::double precision,
	COALESCE(array_to_string(platform.sum_bigint_arrays(duration_buckets), ','), '')`

// adminSystemRequests serves GET /admin/system/requests.
func (s *Server) adminSystemRequests(w http.ResponseWriter, r *http.Request) {
	db, ok := s.systemDB(w, r)
	if !ok {
		return
	}
	params, from, to, err := parseSystemWindow(r, adminListSpec{DefaultLimit: systemRequestsDefaultMax, MaxLimit: 5000}, systemRequestsWindow, time.Now().UTC())
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	values := r.URL.Query()
	grain := strings.ToLower(strings.TrimSpace(values.Get("grain")))
	if grain == "" {
		grain = "hour"
	}
	if grain != "hour" && grain != "day" {
		writeAdminListParamError(w, errors.New("grain must be hour or day"))
		return
	}
	groupBy := strings.ToLower(strings.TrimSpace(values.Get("group_by")))
	if groupBy == "" {
		groupBy = "none"
	}
	groupColumn, valid := systemRequestGroups[groupBy]
	if !valid {
		writeAdminListParamError(w, errors.New("group_by must be none, route, status_class, service or method"))
		return
	}
	method, err := oneOf(r, "method", systemMethods, strings.ToUpper)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	statusClass, err := oneOf(r, "status_class", systemStatusClasses, strings.ToLower)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	filter := newSQLFilter()
	filter.Where("hour >= " + filter.Arg(from.Truncate(time.Hour)))
	if !to.IsZero() {
		filter.Where("hour < " + filter.Arg(to))
	}
	filter.Eq("route", truncateRunes(values.Get("route"), 300)).
		Eq("method", method).
		Eq("status_class", statusClass).
		Eq("service", truncateRunes(values.Get("service"), 64))

	bucket := "hour"
	if grain == "day" {
		bucket = "(date_trunc('day', hour AT TIME ZONE 'UTC') AT TIME ZONE 'UTC')"
	}
	group := "NULL::text"
	if groupColumn != "" {
		group = groupColumn
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	rows, err := db.QueryContext(ctx, `SELECT `+bucket+` AS bucket, `+group+` AS grp, `+requestRollupSelect+`
		FROM platform.request_rollups_hourly`+filter.SQL()+`
		GROUP BY 1, 2 ORDER BY 1 DESC, 3 DESC, 2 LIMIT `+strconv.Itoa(params.Limit), filter.Args()...)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer rows.Close()
	out := make([]map[string]any, 0)
	for rows.Next() {
		var at time.Time
		var grp sql.NullString
		var agg requestRollupAggregate
		var buckets string
		if err := rows.Scan(&at, &grp, &agg.requests, &agg.serverErrors, &agg.refused, &agg.timed, &agg.sumMS, &buckets); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		agg.buckets = parseBigintArray(buckets)
		row := map[string]any{
			"bucket": at.UTC().Format(time.RFC3339), "service": nil, "method": nil, "route": nil, "status_class": nil,
			"requests": agg.requests, "server_errors": agg.serverErrors, "refused": agg.refused,
			"avg_ms": agg.avgMS(), "p50_ms": agg.percentileMS(0.5), "p95_ms": agg.percentileMS(0.95), "p99_ms": agg.percentileMS(0.99),
		}
		if groupColumn != "" && grp.Valid {
			row[groupColumn] = grp.String
		}
		out = append(out, row)
	}
	if err := rows.Err(); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	var totals requestRollupAggregate
	var buckets string
	if err := db.QueryRowContext(ctx, `SELECT `+requestRollupSelect+` FROM platform.request_rollups_hourly`+filter.SQL(), filter.Args()...).
		Scan(&totals.requests, &totals.serverErrors, &totals.refused, &totals.timed, &totals.sumMS, &buckets); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	totals.buckets = parseBigintArray(buckets)
	writeJSON(w, http.StatusOK, map[string]any{
		"rows": out,
		"totals": map[string]any{
			"requests": totals.requests, "server_errors": totals.serverErrors, "refused": totals.refused,
			"avg_ms": totals.avgMS(), "p95_ms": totals.percentileMS(0.95),
		},
		"from": from.UTC().Format(time.RFC3339), "to": systemTime(to),
		"grain": grain, "group_by": groupBy, "limit": params.Limit,
	})
}

// ── Capacity ────────────────────────────────────────────────────────────────

// adminSystemCapacity serves GET /admin/system/capacity.
func (s *Server) adminSystemCapacity(w http.ResponseWriter, r *http.Request) {
	db, ok := s.systemDB(w, r)
	if !ok {
		return
	}
	_, from, to, err := parseSystemWindow(r, adminListSpec{DefaultLimit: systemCapacitySeriesMax, MaxLimit: systemCapacitySeriesMax}, systemCapacityWindow, time.Now().UTC())
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	resp := map[string]any{"latest": nil, "tables": []any{}, "series": []any{}}

	var at time.Time
	var dbSize, mediaTotal int64
	var connections, maxConnections int
	var outbox, activity, security sql.NullInt64
	var media, disk, tables []byte
	err = db.QueryRowContext(ctx, `SELECT at, db_size_bytes, connections, max_connections, outbox_rows, activity_rows,
		       security_event_rows, media_bytes, media_bytes_total, disk, tables
		FROM platform.capacity_snapshots ORDER BY at DESC LIMIT 1`).
		Scan(&at, &dbSize, &connections, &maxConnections, &outbox, &activity, &security, &media, &mediaTotal, &disk, &tables)
	switch {
	case errors.Is(err, sql.ErrNoRows):
	case err != nil:
		writeError(w, http.StatusBadGateway, err)
		return
	default:
		resp["latest"] = map[string]any{
			"at": at.UTC().Format(time.RFC3339), "db_size_bytes": dbSize,
			"connections": connections, "max_connections": maxConnections,
			"outbox_rows": nullableInt64(outbox), "activity_rows": nullableInt64(activity),
			"security_event_rows": nullableInt64(security),
			"media_bytes":         decodeJSONValue(media, map[string]any{}), "media_bytes_total": mediaTotal,
			"disk": decodeJSONValue(disk, map[string]any{}),
		}
		resp["tables"] = decodeJSONValue(tables, []any{})
	}

	filter := newSQLFilter()
	filter.Where("at >= " + filter.Arg(from))
	if !to.IsZero() {
		filter.Where("at < " + filter.Arg(to))
	}
	rows, err := db.QueryContext(ctx, `SELECT at, db_size_bytes, outbox_rows, activity_rows, media_bytes_total FROM (
		SELECT at, db_size_bytes, outbox_rows, activity_rows, media_bytes_total
		FROM platform.capacity_snapshots`+filter.SQL()+` ORDER BY at DESC LIMIT `+strconv.Itoa(systemCapacitySeriesMax)+`) s
		ORDER BY at`, filter.Args()...)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer rows.Close()
	series := make([]map[string]any, 0)
	for rows.Next() {
		var pointAt time.Time
		var size, total int64
		var pointOutbox, pointActivity sql.NullInt64
		if err := rows.Scan(&pointAt, &size, &pointOutbox, &pointActivity, &total); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		series = append(series, map[string]any{
			"at": pointAt.UTC().Format(time.RFC3339), "db_size_bytes": size,
			"outbox_rows": nullableInt64(pointOutbox), "activity_rows": nullableInt64(pointActivity),
			"media_bytes_total": total,
		})
	}
	if err := rows.Err(); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp["series"] = series
	writeJSON(w, http.StatusOK, resp)
}

func nullableInt64(value sql.NullInt64) any {
	if !value.Valid {
		return nil
	}
	return value.Int64
}

func decodeJSONValue(raw []byte, fallback any) any {
	if len(raw) == 0 {
		return fallback
	}
	var decoded any
	if err := json.Unmarshal(raw, &decoded); err != nil || decoded == nil {
		return fallback
	}
	return decoded
}

// ── Third-party usage ───────────────────────────────────────────────────────

// adminSystemThirdParty serves GET /admin/system/third-party.
func (s *Server) adminSystemThirdParty(w http.ResponseWriter, r *http.Request) {
	db, ok := s.systemDB(w, r)
	if !ok {
		return
	}
	params, from, to, err := parseSystemWindow(r, adminListSpec{DefaultLimit: 1000, MaxLimit: 5000}, systemThirdPartyWindow, time.Now().UTC())
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	filter := newSQLFilter()
	filter.Where("day >= " + filter.Arg(from.UTC().Format(adminListDateLayout)) + "::date")
	if !to.IsZero() {
		// to is exclusive; a timestamp inside a day keeps that day.
		end := to.UTC()
		if !end.Equal(end.Truncate(24 * time.Hour)) {
			end = end.Truncate(24 * time.Hour).Add(24 * time.Hour)
		}
		filter.Where("day < " + filter.Arg(end.Format(adminListDateLayout)) + "::date")
	}
	values := r.URL.Query()
	filter.Eq("provider", truncateRunes(values.Get("provider"), 64)).Eq("operation", truncateRunes(values.Get("operation"), 64))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	rows, err := db.QueryContext(ctx, `SELECT day::text, provider, operation, calls, failures, units, unit_label
		FROM platform.third_party_usage_daily`+filter.SQL()+`
		ORDER BY day DESC, provider, operation LIMIT `+strconv.Itoa(params.Limit), filter.Args()...)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	out := make([]map[string]any, 0)
	for rows.Next() {
		var day, provider, operation, label string
		var calls, failures int64
		var units float64
		if err := rows.Scan(&day, &provider, &operation, &calls, &failures, &units, &label); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		out = append(out, map[string]any{
			"day": day, "provider": provider, "operation": operation,
			"calls": calls, "failures": failures, "units": units, "unit_label": label,
		})
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}

	totalRows, err := db.QueryContext(ctx, `SELECT provider, operation, SUM(calls)::bigint, SUM(failures)::bigint,
		       SUM(units)::double precision, MIN(unit_label)
		FROM platform.third_party_usage_daily`+filter.SQL()+`
		GROUP BY provider, operation ORDER BY provider, operation`, filter.Args()...)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer totalRows.Close()
	totals := make([]map[string]any, 0)
	for totalRows.Next() {
		var provider, operation, label string
		var calls, failures int64
		var units float64
		if err := totalRows.Scan(&provider, &operation, &calls, &failures, &units, &label); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		totals = append(totals, map[string]any{
			"provider": provider, "operation": operation, "calls": calls, "failures": failures,
			"units": units, "unit_label": label,
		})
	}
	if err := totalRows.Err(); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"rows": out, "totals": totals,
		"from": from.UTC().Format(adminListDateLayout), "to": systemTime(to), "limit": params.Limit,
	})
}
