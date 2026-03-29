# Blueprint: 10M Concurrent Requests

Date: 2026-03-01

## Target
Build for extreme concurrency with graceful degradation and strong correctness.

## 1) Architecture Shape
- API Gateway + Mobile BFF remain stateless and horizontally scalable.
- Split heavy domains into isolated worker pools (`auth`, `profile`, `matching`, `engagement`, `messaging`).
- Add queue-based async fanout for non-critical writes (notifications, analytics, feed fanout).
- Use read replicas for read-heavy paths and keep writes on primary.

## 2) Reliability Patterns
- Global timeout policy per endpoint tier (fast read, normal read, write).
- Circuit breakers on downstream DB/service calls.
- Retry with exponential backoff + jitter only for idempotent operations.
- Request shedding with `429` and `Retry-After` under overload.
- Bulkheads to prevent one domain from saturating shared resources.

## 3) Concurrency Safety
- Idempotency keys on write APIs (`swipe`, `match actions`, `agreement updates`, `message send`).
- Strict transaction ordering across shared tables.
- Keep transactions short and lock scope minimal.
- Add DB lock timeout + statement timeout defaults.
- Prefer optimistic concurrency (version/timestamp checks) over coarse locking.

## 4) Data & Indexing
- Partition high-volume append tables by time shard.
- Add covering indexes for top filter and timeline queries.
- Cache hot immutable datasets (master data) with short TTL.
- Precompute popular aggregates asynchronously.

## 5) Observability & Operations
- SLO dashboards: p50/p95/p99, saturation, error-rate, timeout-rate.
- Correlation IDs end-to-end (gateway -> BFF -> internal services -> DB).
- Alerts: error-budget burn, deadlock count, queue lag, p99 spike.
- Incident playbooks: lock storm, replica lag, dependency outage, queue saturation.

## 6) Rollout Plan
- Phase 1: Timeouts, circuit breakers, rate limits, request shedding.
- Phase 2: Idempotency middleware + queue fanout + bulkheads.
- Phase 3: Partitioning + read replica routing + chaos testing.
- Phase 4: Regional failover and disaster recovery rehearsals.

## 7) Validation Gates
- Burst test: 5x traffic spike with stable p99.
- Soak test: 24h mixed traffic with no memory growth trend.
- Chaos test: dependency latency/failures with controlled degradation.
- Correctness test: no duplicate writes under retries/idempotency flow.

## 8) Implementation Status (2 Mar 2026)

Completed in code (excluding circuit breaker, DB sharding, jitter):
- Queue-based async fanout for non-critical writes (activity stream offloaded to async worker queue).
- Precomputed aggregate pipeline (interaction counters updated asynchronously by fanout workers).
- Queue lag and saturation metrics (depth/capacity/enqueued/processed/dropped/max queue lag) surfaced via admin analytics response.
- Read-replica routing support for read-heavy paths (`SelectRead`) with optional `SUPABASE_READ_REPLICA_URL`.
- Master-data hot cache with TTL + async background refresh.

Operational coverage:
- SLO and alert dashboard definitions and incident playbooks documented in:
	- `documents/06_10M_SLO_DASHBOARDS_AND_PLAYBOOKS.md`
- Remaining scope Jira backlog documented in:
	- `documents/codex/JIRA_IMPORT_READY_10M_CONCURRENCY_BACKLOG.md`

---

## Level Events and XP Ledger Throughput Notes

Reference: `08_LEVEL_SYSTEM_ENGAGEMENT_BRAINSTORM.md`

### High-Volume Event Paths
- XP event ingestion (`level_xp_earned`) is expected to be one of the highest-frequency write paths.
- Level transition events (`level_up`, `level_reward_claimed`) require strict correctness and idempotency.
- Acceleration usage events (`acceleration_used`) require anti-fraud checks in near-real-time.

### Data and Write Strategy
- Maintain append-only `xp_ledger` entries for auditability.
- Derive current level state via materialized projection (`user_level_state`) updated asynchronously.
- Use idempotency key pattern on XP and reward-claim writes.
- Partition ledger tables by time shard and optionally by user hash for hot-spot control.

### Concurrency and Deadlock Avoidance
- Keep XP write transactions short: insert ledger row -> enqueue projection update.
- Avoid wide multi-table locks inside request path.
- Use optimistic concurrency for level state updates (version check).
- Enforce deterministic lock order for reward claim flows.

### Degradation and Backpressure
- Under overload, prioritize correctness over freshness:
	- Accept XP ledger writes.
	- Delay non-critical projections and cosmetic updates.
- Apply queue backpressure and request shedding for non-critical progression endpoints.
- Expose stale-read indicators if level projection lag exceeds threshold.

### Throughput SLO Additions
- XP ingest success rate and p99 write latency.
- Projection lag (event-time to visible level-time).
- Idempotency conflict rate.
- Fraud-check service latency and timeout rate.

### Validation Additions
- Ledger replay test: reconstructed level state matches projected state.
- Duplicate-event storm test: no double reward claims.
- Queue saturation test: graceful degradation without data loss.

