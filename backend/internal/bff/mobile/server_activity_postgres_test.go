package mobile

import (
	"context"
	"database/sql"
	"net/http"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

// Postgres-backed checks for durable server activity (migration 133): the
// recorder's additive flushes, the capacity snapshot SQL and every
// /admin/system endpoint's filters. They skip without
// PROFILE_TEST_DATABASE_URL, e.g.
//
//	PROFILE_TEST_DATABASE_URL='postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable' \
//	  go test ./internal/bff/mobile/ -run ServerActivityPostgres -count=1

func serverActivityDB(t *testing.T) *sql.DB {
	t.Helper()
	db := trustOpsDB(t)
	var ready bool
	if err := db.QueryRow(`SELECT to_regclass('platform.server_events') IS NOT NULL
		AND to_regprocedure('platform.sum_bigint_arrays(bigint[])') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 133 is not applied")
	}
	return db
}

// testMarker is unique per test and valid as a worker name.
func testMarker(prefix string) string {
	return prefix + "_" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
}

func TestServerActivityPostgresFlushIsAdditive(t *testing.T) {
	db := serverActivityDB(t)
	worker := testMarker("zz_test_worker")
	service := testMarker("zz_test_service")
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM platform.job_runs WHERE worker=$1`, worker)
		_, _ = db.Exec(`DELETE FROM platform.job_run_rollups_hourly WHERE worker=$1`, worker)
		_, _ = db.Exec(`DELETE FROM platform.request_rollups_hourly WHERE service=$1`, service)
		_, _ = db.Exec(`DELETE FROM platform.server_events WHERE service=$1`, service)
	})
	a := newServerActivityRecorder(db, zap.NewNop(), service)

	for round := 0; round < 2; round++ {
		a.RecordWorkerRun(runRecord(worker, observability.WorkerRunSucceeded, 2, 0, map[string]any{"round": round}))
		a.RecordWorkerRun(runRecord(worker, observability.WorkerRunFailed, 0, 1, nil))
		a.requests.Observe(service, "GET", "/v1/profile/{userID}", 200, 20*time.Millisecond, true)
		a.requests.Observe(service, "GET", "/v1/profile/{userID}", 200, 2*time.Second, true)
		a.requests.Observe(service, "POST", "/v1/swipe", 503, 5*time.Millisecond, true)
		if rest := a.writeJobRuns(drainRuns(a)); len(rest) != 0 {
			t.Fatalf("job runs not written: %d", len(rest))
		}
		a.flush()
	}

	var runs, failures, items, itemsFailed, buckets int64
	var lastSuccess sql.NullTime
	if err := db.QueryRow(`SELECT SUM(runs), SUM(failures), SUM(items), SUM(items_failed),
		       SUM((SELECT SUM(b) FROM unnest(duration_buckets) b)), MAX(last_success_at)
		FROM platform.job_run_rollups_hourly WHERE worker=$1`, worker).
		Scan(&runs, &failures, &items, &itemsFailed, &buckets, &lastSuccess); err != nil {
		t.Fatal(err)
	}
	if runs != 4 || failures != 2 || items != 4 || itemsFailed != 2 || buckets != 4 || !lastSuccess.Valid {
		t.Fatalf("job rollup = runs %d failures %d items %d/%d buckets %d success %v", runs, failures, items, itemsFailed, buckets, lastSuccess)
	}
	var stored, storedFailed int
	var errText sql.NullString
	if err := db.QueryRow(`SELECT COUNT(*), COUNT(*) FILTER (WHERE status='failed'), MAX(error)
		FROM platform.job_runs WHERE worker=$1`, worker).Scan(&stored, &storedFailed, &errText); err != nil {
		t.Fatal(err)
	}
	if stored != 4 || storedFailed != 2 || strings.Contains(errText.String, "alice@example.com") {
		t.Fatalf("job runs = %d (%d failed), error %q", stored, storedFailed, errText.String)
	}

	var requests, timed int64
	var p95Buckets string
	if err := db.QueryRow(`SELECT requests, timed_requests, array_to_string(duration_buckets, ',')
		FROM platform.request_rollups_hourly WHERE service=$1 AND route='/v1/profile/{userID}'`, service).
		Scan(&requests, &timed, &p95Buckets); err != nil {
		t.Fatal(err)
	}
	if requests != 4 || timed != 4 || p95Buckets != "0,0,2,0,0,0,0,0,2,0,0,0" {
		t.Fatalf("request rollup additive: %d %d %s", requests, timed, p95Buckets)
	}
	var code int
	if err := db.QueryRow(`SELECT status_code FROM platform.request_rollups_hourly WHERE service=$1 AND route='/v1/swipe'`, service).Scan(&code); err != nil || code != 503 {
		t.Fatalf("503 keeps its code: %d %v", code, err)
	}

	// Both rounds' worker_failed occurrences fall in one minute row (or two
	// when the test crosses a minute boundary); the count adds up either way.
	var failedEvents int64
	if err := db.QueryRow(`SELECT COALESCE(SUM(count), 0) FROM platform.server_events WHERE service=$1 AND kind='worker_failed' AND dedupe_key=$2`,
		service, worker).Scan(&failedEvents); err != nil || failedEvents != 2 {
		t.Fatalf("worker_failed count = %d %v", failedEvents, err)
	}
	var startRows int
	a.startedAt = time.Now().UTC()
	a.events.Record(observability.ServerEvent{Kind: observability.EventProcessStart, DedupeKey: a.processKey(), Message: "start"})
	a.flush()
	a.events.Record(observability.ServerEvent{Kind: observability.EventProcessStart, DedupeKey: a.processKey(), Message: "start"})
	a.flush()
	if err := db.QueryRow(`SELECT COUNT(*) FROM platform.server_events WHERE service=$1 AND kind='process_start'`, service).Scan(&startRows); err != nil || startRows != 1 {
		t.Fatalf("same key and minute upserts one row: %d %v", startRows, err)
	}
}

func TestServerActivityPostgresCapacitySnapshot(t *testing.T) {
	db := serverActivityDB(t)
	ctx := context.Background()
	snap, err := collectCapacitySnapshot(ctx, db, t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	if snap.DBSizeBytes <= 0 || snap.Connections <= 0 || snap.MaxConnections <= 0 {
		t.Fatalf("database summary: %+v", snap)
	}
	if len(snap.Tables) == 0 || len(snap.Tables) > capacityTopRelations {
		t.Fatalf("tables = %d", len(snap.Tables))
	}
	for i := 1; i < len(snap.Tables); i++ {
		if snap.Tables[i].TotalBytes > snap.Tables[i-1].TotalBytes {
			t.Fatalf("tables not ordered by size: %+v", snap.Tables[:i+1])
		}
	}
	if _, ok := snap.MediaBytes["profile_photos"]; !ok {
		t.Fatalf("media bytes: %+v", snap.MediaBytes)
	}
	if snap.OutboxRows == nil || snap.ActivityRows == nil {
		t.Fatalf("row estimates: outbox %v activity %v", snap.OutboxRows, snap.ActivityRows)
	}
	if _, ok := snap.Disk["media"]; !ok {
		t.Fatalf("disk usage of the media dir: %+v", snap.Disk)
	}

	if _, err := refreshThirdPartyUsage(ctx, db, time.Now().UTC()); err != nil {
		t.Fatalf("third-party usage SQL: %v", err)
	}

	cfg := config.Config{MediaUploadsDir: t.TempDir()}
	worker := newCapacitySnapshotWorker(db, zap.NewNop(), cfg, 2*time.Second)
	worker.instance = testMarker("zz_capacity_test")
	t.Cleanup(func() { _, _ = db.Exec(`DELETE FROM platform.capacity_snapshots WHERE instance=$1`, worker.instance) })
	var recent bool
	_ = db.QueryRow(`SELECT EXISTS (SELECT 1 FROM platform.capacity_snapshots WHERE at > NOW() - INTERVAL '1 second')`).Scan(&recent)
	if recent {
		time.Sleep(1100 * time.Millisecond)
	}
	first, err := worker.RunOnce(ctx)
	if err != nil || first.Skipped {
		t.Fatalf("first run: skipped=%v err=%v", first.Skipped, err)
	}
	second, err := worker.RunOnce(ctx)
	if err != nil || !second.Skipped {
		t.Fatalf("a run within half the interval skips the snapshot: skipped=%v err=%v", second.Skipped, err)
	}
	var tables int
	var mediaKinds int
	if err := db.QueryRow(`SELECT jsonb_array_length(tables), (SELECT COUNT(*) FROM jsonb_object_keys(media_bytes))
		FROM platform.capacity_snapshots WHERE instance=$1`, worker.instance).Scan(&tables, &mediaKinds); err != nil {
		t.Fatal(err)
	}
	if tables == 0 || mediaKinds == 0 {
		t.Fatalf("stored snapshot: tables %d media kinds %d", tables, mediaKinds)
	}
}

func TestServerActivityPostgresAdminEndpoints(t *testing.T) {
	db := serverActivityDB(t)
	s := adminPagingServer(t, db)
	service := testMarker("zz_svc")
	worker := testMarker("zz_job")
	provider := testMarker("zz_provider")
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM platform.server_events WHERE service=$1`, service)
		_, _ = db.Exec(`DELETE FROM platform.job_runs WHERE worker=$1`, worker)
		_, _ = db.Exec(`DELETE FROM platform.job_run_rollups_hourly WHERE worker=$1`, worker)
		_, _ = db.Exec(`DELETE FROM platform.request_rollups_hourly WHERE service=$1`, service)
		_, _ = db.Exec(`DELETE FROM platform.third_party_usage_daily WHERE provider=$1`, provider)
	})
	now := time.Now().UTC()
	hour := now.Truncate(time.Hour)
	mustExec := func(query string, args ...any) {
		t.Helper()
		if _, err := db.Exec(query, args...); err != nil {
			t.Fatalf("%s: %v", query, err)
		}
	}
	for i, kind := range []string{"refused", "refused", "server_error", "panic"} {
		severity := map[string]string{"refused": "warning", "server_error": "error", "panic": "critical"}[kind]
		mustExec(`INSERT INTO platform.server_events (at, kind, severity, service, instance, message, route, count, first_at, last_at, details, dedupe_key, bucket_at)
			VALUES ($1,$2,$3,$4,'test','Refused on GET /v1/thing/'||$5,'/v1/thing/{id}',2,$1,$1,'{}',$5,$1)`,
			now.Add(-time.Duration(i)*time.Minute).Truncate(time.Minute), kind, severity, service, uuid.NewString())
	}
	_, events := callSystem(t, s.adminSystemEvents, "/v1/admin/system/events?service="+service)
	if events["total"] != float64(4) || len(events["events"].([]any)) != 4 {
		t.Fatalf("events by service: %v", events)
	}
	first := events["events"].([]any)[0].(map[string]any)
	for _, key := range []string{"id", "at", "kind", "severity", "service", "instance", "message", "route", "correlation_id", "count", "first_at", "last_at", "details"} {
		if _, ok := first[key]; !ok {
			t.Fatalf("event key %s missing: %v", key, first)
		}
	}
	_, refused := callSystem(t, s.adminSystemEvents, "/v1/admin/system/events?service="+service+"&kind=refused&limit=1&offset=1&order=asc")
	if refused["total"] != float64(2) || len(refused["events"].([]any)) != 1 || refused["offset"] != float64(1) {
		t.Fatalf("kind filter and paging: %v", refused)
	}
	_, critical := callSystem(t, s.adminSystemEvents, "/v1/admin/system/events?service="+service+"&severity=critical&q=thing")
	if critical["total"] != float64(1) {
		t.Fatalf("severity + q: %v", critical)
	}
	if code, _ := callSystem(t, s.adminSystemEvents, "/v1/admin/system/events?kind=boom"); code != http.StatusBadRequest {
		t.Fatalf("bad kind = %d", code)
	}

	for i, status := range []string{"succeeded", "failed", "busy"} {
		mustExec(`INSERT INTO platform.job_runs (worker, instance, started_at, finished_at, duration_ms, status, items_processed, error, details)
			VALUES ($1,'test',$2,$2,12,$3,$4,CASE WHEN $3='failed' THEN 'timeout talking to db' END,'{"k":1}')`,
			worker, now.Add(-time.Duration(3-i)*time.Hour), status, i)
	}
	_, runs := callSystem(t, s.adminSystemJobRuns, "/v1/admin/system/job-runs?worker="+worker)
	if runs["total"] != float64(3) {
		t.Fatalf("runs by worker: %v", runs)
	}
	latest := runs["runs"].([]any)[0].(map[string]any)
	if latest["status"] != "busy" || latest["details"].(map[string]any)["k"] != float64(1) {
		t.Fatalf("newest first with details: %v", latest)
	}
	_, failedRuns := callSystem(t, s.adminSystemJobRuns, "/v1/admin/system/job-runs?worker="+worker+"&status=failed&q=timeout")
	if failedRuns["total"] != float64(1) {
		t.Fatalf("status + q: %v", failedRuns)
	}
	if code, _ := callSystem(t, s.adminSystemJobRuns, "/v1/admin/system/job-runs?status=done"); code != http.StatusBadRequest {
		t.Fatalf("bad status = %d", code)
	}

	// Jobs: the stored runs say the last success was 1h ago (busy counts as
	// alive); with a 1 minute interval the worker is stale. A worker without
	// rows is listed with nulls.
	never := testMarker("zz_never")
	mustExec(`INSERT INTO platform.job_run_rollups_hourly (worker, hour, runs, failures, items, duration_buckets, last_run_at, last_success_at)
		VALUES ($1,$2,10,1,5,'{10,0,0,0,0,0,0,0,0,0,0}',$3,$3)`, worker, hour, now.Add(-time.Hour))
	overview, err := systemJobsOverview(context.Background(), db, map[string]time.Duration{worker: time.Minute, never: time.Minute}, now)
	if err != nil {
		t.Fatal(err)
	}
	byWorker := map[string]map[string]any{}
	for _, row := range overview {
		byWorker[row["worker"].(string)] = row
	}
	job := byWorker[worker]
	if job["last_status"] != "busy" || job["stale"] != true || job["runs_24h"] != int64(10) || job["failures_24h"] != int64(1) || job["items_24h"] != int64(5) {
		t.Fatalf("job overview: %v", job)
	}
	if row := byWorker[never]; row["last_run_at"] != nil || row["stale"] != nil || row["runs_24h"] != int64(0) {
		t.Fatalf("worker without rows: %v", row)
	}
	_, jobs := callSystem(t, s.adminSystemJobs, "/v1/admin/system/jobs")
	listed := map[string]bool{}
	for _, raw := range jobs["workers"].([]any) {
		listed[raw.(map[string]any)["worker"].(string)] = true
	}
	for name := range s.systemWorkerCatalog() {
		if !listed[name] {
			t.Fatalf("worker %s missing from /jobs: %v", name, listed)
		}
	}
	if !listed[workerCapacitySnapshot] || !listed[workerTrustRetention] {
		t.Fatalf("catalog workers: %v", listed)
	}

	// Requests: 3 fast 200s and one slow 503 on one route, one 401 on another.
	mustExec(`INSERT INTO platform.request_rollups_hourly (hour, service, method, route, status_class, status_code, requests, timed_requests, sum_duration_ms, max_duration_ms, duration_buckets) VALUES
		($1,$2,'GET','/v1/a','2xx',0,3,3,30,12,'{0,3,0,0,0,0,0,0,0,0,0,0}'),
		($1,$2,'GET','/v1/a','5xx',503,1,1,3000,3000,'{0,0,0,0,0,0,0,0,0,1,0,0}'),
		($1,$2,'POST','/v1/b','4xx',401,2,2,2,1,'{2,0,0,0,0,0,0,0,0,0,0,0}'),
		($3,$2,'GET','/v1/a','2xx',0,5,5,50,10,'{0,5,0,0,0,0,0,0,0,0,0,0}')`, hour, service, hour.Add(-48*time.Hour))
	_, byRoute := callSystem(t, s.adminSystemRequests, "/v1/admin/system/requests?group_by=route&service="+service)
	rows := byRoute["rows"].([]any)
	if len(rows) != 2 {
		t.Fatalf("last 24h by route (the 48h-old row is outside): %v", byRoute)
	}
	routeA := rows[0].(map[string]any)
	if routeA["route"] != "/v1/a" || routeA["requests"] != float64(4) || routeA["server_errors"] != float64(1) || routeA["method"] != nil {
		t.Fatalf("route row: %v", routeA)
	}
	if p95 := routeA["p95_ms"].(float64); p95 < 2500 || p95 > 5000 {
		t.Fatalf("p95 from buckets = %v (rank 3.8 of 4 is in the 2.5-5s bucket)", p95)
	}
	if p50 := routeA["p50_ms"].(float64); p50 < 5 || p50 > 10 {
		t.Fatalf("p50 from buckets = %v", p50)
	}
	if avg := routeA["avg_ms"].(float64); avg != 757.5 {
		t.Fatalf("avg = %v", avg)
	}
	totals := byRoute["totals"].(map[string]any)
	if totals["requests"] != float64(6) || totals["refused"] != float64(2) || totals["server_errors"] != float64(1) {
		t.Fatalf("totals: %v", totals)
	}
	from := url.QueryEscape(hour.Add(-72 * time.Hour).Format(time.RFC3339))
	_, daily := callSystem(t, s.adminSystemRequests, "/v1/admin/system/requests?grain=day&status_class=2xx&method=get&service="+service+"&from="+from)
	if dailyRows := daily["rows"].([]any); len(dailyRows) != 2 || daily["totals"].(map[string]any)["requests"] != float64(8) {
		t.Fatalf("daily 2xx rows over 72h: %v", daily)
	}
	if code, _ := callSystem(t, s.adminSystemRequests, "/v1/admin/system/requests?grain=week"); code != http.StatusBadRequest {
		t.Fatalf("bad grain = %d", code)
	}
	if code, _ := callSystem(t, s.adminSystemRequests, "/v1/admin/system/requests?group_by=user"); code != http.StatusBadRequest {
		t.Fatalf("bad group_by = %d", code)
	}
	if code, _ := callSystem(t, s.adminSystemRequests, "/v1/admin/system/requests?service="+service, "analyst"); code != http.StatusOK {
		t.Fatalf("analyst reads requests = %d", code)
	}

	// Third-party usage.
	today := now.Format("2006-01-02")
	mustExec(`INSERT INTO platform.third_party_usage_daily (day, provider, operation, calls, failures, units, unit_label) VALUES
		($1::date,$2,'deliver',10,1,9,'deliveries'), ($1::date - 1,$2,'deliver',4,0,4,'deliveries'),
		($1::date - 40,$2,'deliver',99,0,99,'deliveries')`, today, provider)
	_, usage := callSystem(t, s.adminSystemThirdParty, "/v1/admin/system/third-party?provider="+provider)
	if len(usage["rows"].([]any)) != 2 {
		t.Fatalf("30-day window: %v", usage)
	}
	total := usage["totals"].([]any)[0].(map[string]any)
	if total["calls"] != float64(14) || total["failures"] != float64(1) || total["units"] != float64(13) {
		t.Fatalf("totals: %v", total)
	}
	_, oneDay := callSystem(t, s.adminSystemThirdParty, "/v1/admin/system/third-party?provider="+provider+"&from="+today+"&to="+today)
	if len(oneDay["rows"].([]any)) != 1 {
		t.Fatalf("one day: %v", oneDay)
	}

	// Capacity: at least one snapshot exists after a worker run.
	worker2 := newCapacitySnapshotWorker(db, zap.NewNop(), config.Config{MediaUploadsDir: t.TempDir()}, 2*time.Second)
	worker2.instance = testMarker("zz_capacity_api")
	t.Cleanup(func() { _, _ = db.Exec(`DELETE FROM platform.capacity_snapshots WHERE instance=$1`, worker2.instance) })
	time.Sleep(1100 * time.Millisecond)
	if _, err := worker2.RunOnce(context.Background()); err != nil {
		t.Fatal(err)
	}
	_, capacity := callSystem(t, s.adminSystemCapacity, "/v1/admin/system/capacity", "analyst")
	latestSnap, ok := capacity["latest"].(map[string]any)
	if !ok || latestSnap["db_size_bytes"].(float64) <= 0 || latestSnap["media_bytes"] == nil {
		t.Fatalf("capacity latest: %v", capacity["latest"])
	}
	table := capacity["tables"].([]any)[0].(map[string]any)
	for _, key := range []string{"table", "total_bytes", "table_bytes", "index_bytes", "live_rows", "dead_rows", "last_autovacuum", "seq_scan", "idx_scan"} {
		if _, ok := table[key]; !ok {
			t.Fatalf("table key %s missing: %v", key, table)
		}
	}
	if len(capacity["series"].([]any)) == 0 {
		t.Fatalf("series: %v", capacity)
	}
}
