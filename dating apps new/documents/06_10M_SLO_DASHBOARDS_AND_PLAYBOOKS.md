# 10M Concurrency - SLO Dashboards, Alerts, and Incident Playbooks

Date: 2026-03-02

## Scope
This document defines SLO views, alert thresholds, and incident runbooks for the 10M concurrency hardening tracks implemented in backend runtime:
- Async fanout queue for non-critical writes
- Queue lag metrics exposure
- Precomputed aggregate pipeline
- Read-replica routing on read-heavy paths
- Master-data TTL hot cache refresh behavior

## Dashboard Panels (Primary)

### 1) API Availability and Latency
Use `verified_dating_http_requests_total` and `verified_dating_http_request_duration_seconds`.

Panels:
- Request rate by route (`api_gateway`, `mobile_bff`)
- Error rate (`status >= 500`) by route
- p50/p95/p99 latency by route
- Saturation proxy: 429 share over total requests

### 2) Overload and Shedding
Panels:
- 429 volume over time (`REQUEST_SHEDDED` pattern in logs)
- Retry-After response rate
- Correlation ID sampled traces for shed requests

### 3) Queue Health (Admin Analytics Source)
Source: `GET /v1/admin/analytics/overview` -> `metrics.queue_metrics`

Fields:
- `queue_depth`
- `queue_capacity`
- `enqueued_total`
- `processed_total`
- `dropped_total`
- `max_observed_queue_lag_ms`

Derived panels:
- Queue utilization = `queue_depth / queue_capacity`
- Drop ratio = `dropped_total / max(enqueued_total,1)`
- Processing throughput = delta(`processed_total`)

### 4) Product Throughput Aggregates
Source: `GET /v1/admin/analytics/overview` -> `metrics.precomputed_aggregates`

Fields:
- `total_interactions`
- `swipe_events`
- `message_events`
- `report_events`
- `server_error_events`
- `client_error_events`

### 5) Read Replica Effectiveness
Panels:
- Primary vs replica request distribution (from app logs with endpoint tags)
- Replica error count and fallback count
- Read endpoint p95 before/after replica enablement

### 6) Master Data Cache Health
Panels:
- Master data cache hit ratio (inferred by DB read drop for master data tables)
- Master data fetch latency (refresh path)
- Cache refresh failures (error logs)

---

## Alerts (Starting Thresholds)

### Critical
- API 5xx rate > 2% for 5 min
- p99 latency > 2.5s for 5 min on `mobile_bff`
- Queue drop ratio > 1% for 3 min
- Queue lag (`max_observed_queue_lag_ms`) > 10000 ms for 3 min

### Warning
- 429 shed ratio > 5% for 10 min
- Queue utilization > 80% for 10 min
- Read-replica failures > 1% for 10 min
- Cache refresh failures >= 3 consecutive attempts

---

## Incident Playbooks

## Playbook A: Queue Saturation / Fanout Drops
Symptoms:
- Rising `dropped_total`
- Queue utilization pinned > 90%
- API still serving but analytics lagging

Actions:
1. Confirm current values from `/v1/admin/analytics/overview` queue metrics.
2. Increase `FANOUT_WORKER_COUNT` and `FANOUT_QUEUE_SIZE` conservatively.
3. Reduce non-critical event volume sources if possible.
4. Validate `processed_total` slope recovers.
5. Post-incident: tune thresholds and worker/queue defaults.

## Playbook B: Shedding Spike (429)
Symptoms:
- 429 surge with `REQUEST_SHEDDED`
- Elevated p99

Actions:
1. Identify scope: gateway-level vs domain bulkhead via logs.
2. Increase specific bulkhead limits first (targeted), not global max-inflight blindly.
3. Keep `Retry-After` at short interval unless sustained outage.
4. Validate 5xx remains controlled while 429 normalizes.

## Playbook C: Read Replica Degradation
Symptoms:
- Read path failures or latency regression after replica enablement.

Actions:
1. Set `SUPABASE_READ_REPLICA_URL` empty to force primary reads.
2. Restart affected service(s).
3. Validate error-rate/latency recovery.
4. Re-enable replica after provider-side stability confirmation.

## Playbook D: Master Data Cache Staleness
Symptoms:
- Old master-data values visible beyond acceptable TTL.

Actions:
1. Check cache TTL config (`MASTER_DATA_CACHE_TTL_SECONDS`).
2. Trigger traffic to endpoint to force refresh path.
3. Validate refresh succeeds (no Supabase read errors).
4. If DB unavailable, keep stale serving and raise warning only.

---

## Rollback Controls
- Disable read replica routing: clear `SUPABASE_READ_REPLICA_URL`.
- Reduce fanout pressure: temporarily lower event-producing non-critical paths.
- If severe, disable fanout workers by setting `FANOUT_WORKER_COUNT=0` (falls back to sync activity writes).

---

## Evidence in Code
- Async fanout and precomputed pipeline:
  - `backend/internal/bff/mobile/server_fanout.go`
- Queue metrics surfaced in admin analytics response:
  - `backend/internal/bff/mobile/server.go` (`adminAnalyticsOverview`)
- Read-replica select routing support:
  - `backend/internal/platform/supabase/rest_client.go`
- Read-heavy repositories using read-replica path:
  - `backend/internal/bff/mobile/master_data_repository.go`
  - `backend/internal/bff/mobile/terms_repository.go`
  - `backend/internal/bff/mobile/quest_repository.go`
- Master-data TTL cache + async refresh:
  - `backend/internal/bff/mobile/master_data_repository.go`
