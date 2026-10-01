# Reliability and Scale Guardrails — Native Local PostgreSQL

Date: 2026-08-09  
Authority: current native-PostgreSQL runtime and release gate

## Outcome

The local runtime now has enforceable request timeout tiers, PostgreSQL session
limits on every pgx and `database/sql` pool, bounded connection pools, covering
indexes for the hottest journeys, Prometheus reliability/notification metrics,
committed Grafana/Prometheus/Alertmanager provisioning, shared PostgreSQL
idempotency, partitioned retention, production-cardinality plan checks, and
repeatable duplicate/reconnect/burst gates.

This is local hardening evidence. It is **not** a ten-million-concurrent-user
capacity claim. A production-shaped distributed burst, 24-hour soak, duplicate
storm, and fault-injection campaign remain mandatory before any scale claim.

## Runtime guardrails

| Boundary | Default | Configuration |
|---|---:|---|
| Fast reads: health, readiness, master data, unread count | 750 ms | `BFF_FAST_READ_TIMEOUT_MS` |
| Normal reads | 3 s | `BFF_NORMAL_READ_TIMEOUT_MS` |
| Writes | 8 s | `BFF_WRITE_TIMEOUT_MS` |
| PostgreSQL statement | 5 s | `POSTGRES_STATEMENT_TIMEOUT_MS` |
| PostgreSQL lock wait | 1 s | `POSTGRES_LOCK_TIMEOUT_MS` |
| PostgreSQL idle transaction | 15 s | `POSTGRES_IDLE_TRANSACTION_TIMEOUT_MS` |
| Native pgx pool | 16 max / 2 min | `POSTGRES_POOL_MAX_CONNS`, `POSTGRES_POOL_MIN_CONNS` |
| Idempotency replay window | 10 min | `IDEMPOTENCY_TTL_SECONDS` |
| Idempotency processing lease | 15 s | `IDEMPOTENCY_LEASE_SECONDS` |
| Idempotency claim poll | 25 ms | `IDEMPOTENCY_POLL_MS` |
| Maximum replay response | 1 MiB | `IDEMPOTENCY_MAX_RESPONSE_BYTES` |

Every non-WebSocket BFF response identifies its tier in `X-Timeout-Tier`.
Timeout, idempotent-replay, and bulkhead-shed counts are emitted with bounded
`tier`/`domain` labels. Notification queue depth, processing count, oldest age,
dead letters, and worker failures come from the durable outbox state.

PostgreSQL error classification distinguishes statement timeout (`57014`),
lock timeout (`55P03`), and deadlock (`40P01`) without discarding the original
driver error.

## Transaction lock order

New multi-row workflows must acquire locks in this order:

1. `user_management.users` account row, ordered by UUID when more than one user
   is involved.
2. Credential/session or primary domain aggregate (`auth_credentials`, match,
   report, appeal, SOS, verification state), ordered by UUID.
3. Child rows such as photos, messages, notification deliveries, or cursors.
4. Outbox rows.
5. Append-only audit/security events.

Current explicit locks follow a single-aggregate form: profile/media locks the
user first; account enforcement locks the user before revoking sessions;
moderation and verification lock the selected aggregate; notification workers
claim ordered outbox rows with `FOR UPDATE SKIP LOCKED`. Match lifecycle retains
its `lock_version` for compare-and-swap evolution.

Never hold a transaction open during HTTP/provider calls. A lock timeout is a
retryable concurrency failure only when the command has an idempotency key.

## Migration 058

`058_reliability_scale_guardrails.sql` adds additive, rollback-documented
covering indexes for:

- active match lists from either participant side;
- chat timeline reconnect/resume;
- active discovery cards;
- operator moderation queues;
- priority/availability/expiry notification claims.

The migration is applied and recorded in the local `dating_app` database. The
indexes are deliberately not declared `CONCURRENTLY` because local rebuilds run
inside a transaction. Production rollout must use the documented individual
`CREATE INDEX CONCURRENTLY`/rollback procedure and monitor index-build I/O.

## Shared idempotency

Migration `063_shared_idempotency_and_retention.sql` creates
`platform.idempotency_records`. Every BFF instance claims the same
method/path/verified-actor/key namespace in PostgreSQL, stores a SHA-256 request
fingerprint, and replays the completed status/content type/body. Reusing a key
for another body or query is rejected with HTTP 409 and
`IDEMPOTENCY_KEY_CONFLICT`. A crashed owner can be replaced only after the
lease expires, using a conditional update.

All authenticated `POST`/`PUT`/`PATCH`/`DELETE` commands are covered by default.
The explicit exclusions are login/signup/refresh/recovery (never cache live
credential issuance) and multipart profile-photo upload (content-digest and
repository uniqueness apply there). The OpenAPI semantic test fails whenever a
covered command does not document `Idempotency-Key`.

The Flutter API client attaches a generated key to those authenticated commands
unless a feature supplies a stable domain key itself. The key remains on the
same `RequestOptions` during an authorization retry; explicit billing/gift keys
are never overwritten.

The response store is a retry-safety boundary, not a universal exactly-once
claim. If an owner executes longer than the lease, its domain mutation must
also retain a unique command/dedupe constraint; provider calls must use their
own idempotency key. Server errors and oversized responses are not cached.

## Retention and partitioning

Active idempotency records remain unpartitioned so PostgreSQL can enforce one
global primary key. Expired completed rows move in bounded `SKIP LOCKED`
batches to monthly range partitions of `platform.idempotency_archive`.
`platform.retention_policies` records the approved idempotency, notification,
and realtime retention windows. `platform.run_runtime_retention` deletes only
terminal notification rows and expired realtime rows in bounded `SKIP LOCKED`
batches (dependent notification rows cascade from the outbox). Dropping old
archive partitions must follow the production retention approval process. The
BFF creates current/next archive partitions and runs bounded retention batches
every five minutes.

Do not partition the hot message/outbox tables merely because a calendar date
changed. Capture growth, vacuum, index, and query evidence first; perform any
online repartition as a separate backfill/dual-write/cutover migration.

## Monitoring assets

- Grafana dashboard: `backend/observability/grafana/dashboards/reliability-10m.json`
- Grafana provisioning: `backend/observability/grafana/provisioning/dashboards/reliability-10m.yml`
- Prometheus datasource provisioning: `backend/observability/grafana/provisioning/datasources/prometheus.yml`
- Prometheus alerts: `backend/observability/prometheus/rules/reliability-10m.yml`
- Alertmanager paging template: `backend/observability/alertmanager/alertmanager.yml.tmpl`

The Go test `TestReliabilityDashboardAndAlertsAreProvisionable` validates the
dashboard JSON, core metric queries, stable UID, provisioning path, required
alerts, and runbook linkage. Deployment still must mount these assets and run a
PostgreSQL exporter for the deadlock rule. Paging configuration is rendered
only when both secret webhook environment variables are present; committing a
webhook or paging credential is forbidden.

## Local reliability gate

Run:

```bash
./qa/reliability/run_local_reliability_gate.sh
```

The gate rejects non-loopback PostgreSQL/API URLs and Supabase URLs, runs the
race-enabled timeout/bulkhead/idempotency tests, validates monitoring assets,
migrations 058/063, and 250k-row query-plan fixtures, then executes an
authenticated read mix against the native
PostgreSQL gateway.

It also runs `qa/reliability/scale_gate_integrity_test.py`, which asserts that
`distributed_scale_gate.py` still refuses a shortened `production-soak`, still
refuses loopback targets on distributed profiles, and still emits
`capacity_claim` only for a non-loopback multi-target soak. Those guards are the
only barrier between a laptop run and a signed production capacity claim, and
deleting any one of them would leave a harness that still runs, still writes a
report, and still prints "passed". The check needs no services and no load.

Profiles are `smoke`, `burst`, and `soak`; duration, concurrency, target RPS,
p99, and error thresholds are configurable. HTTP 429 is an error in this gate,
so overload cannot be hidden as a successful response.

The cross-instance gate starts a second BFF connected to the same PostgreSQL
database, sends a duplicate storm across both processes, verifies byte-identical
replays and payload-conflict rejection, then runs notification-WebSocket
reconnects and a bounded read burst:

```bash
./qa/reliability/run_cross_instance_idempotency_gate.sh
```

`run_query_plan_gate.sh` uses isolated temporary tables and will fail any chat,
notification-claim, or idempotency lookup/retention query that regresses to a
sequential scan. `SCALE_PLAN_ROWS` can be increased to the target production
cardinality without polluting application tables.

The unified release regression runs the smoke profile by default. Set
`QA_SKIP_RELIABILITY_BURST=true` only for a documented diagnostic rerun.

## Incident runbooks

### HTTP latency or timeout

1. Break down `request_timeouts_total` by tier/domain and compare p95/p99.
2. Inspect PostgreSQL statement/lock timeout logs using the correlation ID.
3. Identify query/lock cause before increasing a tier; never raise every tier
   together.
4. Confirm recovery with the smoke gate and a five-minute metric window.

### HTTP errors

1. Split 5xx by route and correlate with database SQLSTATE classification.
2. Check dependency readiness and notification worker batch failures.
3. Roll back the smallest affected deployment or feature flag.
4. Verify the error ratio returns below one percent.

### Bulkhead shedding

1. Identify the shedding domain; preserve isolation for healthy domains.
2. Check database saturation and p99 before changing concurrency.
3. Tune only the affected bulkhead and keep `Retry-After` enabled.
4. Revert if 5xx, lock waits, or pool saturation increase.

### Notification backlog

1. Compare queue depth, processing jobs, and oldest-pending age.
2. Verify provider health and worker batch failures.
3. Increase workers conservatively within the database pool budget.
4. Confirm oldest age and depth decrease continuously.

### Notification dead letters

1. Inspect `matching.notification_dead_letters` without replaying blindly.
2. Classify permanent tokens versus transient provider failures.
3. Correct the cause, then replay with the original dedupe identity.
4. Verify one inbox/provider delivery per outbox/channel/device.

### PostgreSQL locks and timeouts

1. Inspect `pg_stat_activity` and `pg_locks`; capture blockers and query age.
2. Cancel the narrow blocking statement before terminating a session.
3. Validate the transaction follows the lock order above.
4. Add a regression test reproducing the contention before changing limits.

### Shared idempotency

1. Check expired leases, retention backlog, conflicts, and PostgreSQL pool use.
2. Correlate the namespace hash with method/path/actor; never log the request body.
3. Confirm the domain table also has a unique command/dedupe constraint before
   taking over or replaying an external side effect.
4. Run the cross-instance duplicate storm after remediation.

### Retention and partitioning

1. Confirm the current and next monthly archive partitions exist.
2. Inspect blockers before increasing the bounded archive batch.
3. Drop an old partition only after legal/product retention approval and backup
   verification.
4. Track archive row count/storage and retention backlog after the change.

## Remaining scale gate

- deployed Prometheus/Grafana/PostgreSQL exporter and paging integration;
- distributed production burst and non-shortenable 24-hour soak across at least
  two load-balanced targets;
- production reconnect/duplicate storms and documented retry convergence;
- database failover, network impairment, provider failure, and recovery drills;
- production-cardinality query plans using captured statistics and data skew;
- measured growth proof before repartitioning any hot domain table;
- capacity model and signed SLO evidence before a 10M claim.

The production harness refuses a shortened `production-soak`; the chaos wrapper
requires non-loopback targets, explicit `SCALE_ALLOW_CHAOS=true`, and two
operator-provided executable hooks. These guardrails prevent local evidence from
being misreported as production scale proof.
