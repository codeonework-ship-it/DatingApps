# Jira Import-Ready Backlog - 10M Concurrency (Remaining Scope)

Date: 2 Mar 2026
Source: `documents/06_10M_CONCURRENT_REQUESTS_BLUEPRINT.md`
Exclusions requested: circuit breaker, DB sharding, jitter
Already completed: async fanout (non-critical writes), read-replica routing support, master-data TTL cache refresh, precomputed aggregate pipeline (baseline), queue lag metrics baseline, SLO/playbook docs baseline.

## Suggested CSV Columns (for Jira import)
- Issue Type
- Epic Name
- Summary
- Description
- Acceptance Criteria
- Labels
- Components
- Priority
- Story Points
- Depends On

---

## Epic 10M-1: Stateless Scale + Domain Isolation

### Story 10M-1.1
- Issue Type: Story
- Summary: Split BFF domain workloads into isolated worker pools
- Description: Move heavy in-process background tasks into dedicated pools for `auth`, `profile`, `matching`, `engagement`, `messaging` with bounded queues and per-domain saturation limits.
- Acceptance Criteria:
  1) Each domain has independent worker pool and queue limits.
  2) One saturated domain does not increase p95 latency of unrelated domains by >10% in load test.
  3) Pool utilization and queue depth are observable in metrics/logs.
- Labels: 10m-concurrency, bulkhead, worker-pool
- Components: backend/mobile-bff
- Priority: High
- Story Points: 8
- Depends On: None

### Story 10M-1.2
- Summary: Add async notification/feed fanout channels
- Description: Extend current non-critical fanout beyond activity logging to notifications and feed fanout channels with bounded backpressure.
- Acceptance Criteria:
  1) Notification and feed fanout run asynchronously with bounded queues.
  2) Drop/defer strategy is explicitly defined for overload.
  3) Queue lag and drop rates appear in admin metrics.
- Labels: 10m-concurrency, fanout
- Components: backend/mobile-bff
- Priority: High
- Story Points: 8
- Depends On: Story 10M-1.1

---

## Epic 10M-2: Timeout Tiering + Reliability Controls

### Story 10M-2.1
- Summary: Implement timeout tiers per endpoint class
- Description: Introduce explicit timeout classes (`fast_read`, `normal_read`, `write`) and bind routes to class-level defaults.
- Acceptance Criteria:
  1) Route groups are mapped to timeout tiers.
  2) Tier values configurable by env and documented.
  3) Timeout-rate is measurable per tier.
- Labels: 10m-concurrency, timeout-policy
- Components: backend/api-gateway, backend/mobile-bff
- Priority: High
- Story Points: 5
- Depends On: None

### Story 10M-2.2
- Summary: Add idempotency coverage to all critical write APIs
- Description: Extend idempotency enforcement to remaining write endpoints not yet covered (admin/safety/calls/subscriptions and future XP writes).
- Acceptance Criteria:
  1) Full write API inventory marks idempotent/non-idempotent behavior.
  2) Duplicate delivery/retry test proves no duplicate side effects.
  3) Replay hit metrics are emitted.
- Labels: 10m-concurrency, idempotency
- Components: backend/mobile-bff
- Priority: High
- Story Points: 8
- Depends On: Story 10M-2.1

---

## Epic 10M-3: Transaction Safety and DB Concurrency

### Story 10M-3.1
- Summary: Enforce DB lock timeout and statement timeout defaults
- Description: Set server/session-safe defaults to avoid lock storms and long-running query pileups.
- Acceptance Criteria:
  1) Lock timeout and statement timeout applied by default in DB/session config.
  2) Timeouts are observable with structured error tags.
  3) Playbook includes tuning and rollback values.
- Labels: 10m-concurrency, db-safety
- Components: backend/database
- Priority: High
- Story Points: 5
- Depends On: None

### Story 10M-3.2
- Summary: Define deterministic transaction ordering for shared tables
- Description: Publish and enforce transaction lock/order rules on high-contention tables (matches, messages, unlock workflows, xp ledger).
- Acceptance Criteria:
  1) Transaction order matrix documented.
  2) Hot write paths comply with deterministic ordering.
  3) Deadlock frequency reduces under stress tests.
- Labels: 10m-concurrency, deadlock-prevention
- Components: backend/database, backend/services
- Priority: High
- Story Points: 8
- Depends On: Story 10M-3.1

### Story 10M-3.3
- Summary: Add optimistic concurrency controls to mutable aggregates
- Description: Add version/timestamp checks for user level state, unlock workflow state, and comparable mutable records.
- Acceptance Criteria:
  1) Conflicting writes fail with domain-safe conflict response.
  2) Retries on conflict are deterministic and bounded.
  3) Conflict-rate metrics are emitted.
- Labels: 10m-concurrency, optimistic-locking
- Components: backend/services, backend/database
- Priority: Medium
- Story Points: 8
- Depends On: Story 10M-3.2

---

## Epic 10M-4: Data Access Performance (Non-sharding)

### Story 10M-4.1
- Summary: Add covering indexes for discovery, timeline, and moderation queries
- Description: Create index plan for top read queries and verify via query plans.
- Acceptance Criteria:
  1) Top 10 heavy queries have explicit index coverage.
  2) p95 query latency reduction is measured before/after.
  3) Index migration scripts are reversible.
- Labels: 10m-concurrency, indexing
- Components: backend/database
- Priority: High
- Story Points: 8
- Depends On: None

### Story 10M-4.2
- Summary: Partition append-only high-volume tables by time
- Description: Partition non-sharded append tables (events/ledger) by time windows for maintenance and query efficiency.
- Acceptance Criteria:
  1) Partition strategy documented and implemented for target tables.
  2) Writes and reads remain backward compatible.
  3) Retention and vacuum strategy per partition documented.
- Labels: 10m-concurrency, partitioning
- Components: backend/database
- Priority: Medium
- Story Points: 13
- Depends On: Story 10M-4.1

---

## Epic 10M-5: Observability and Alerting Automation

### Story 10M-5.1
- Summary: Convert SLO dashboard spec into provisioned dashboards
- Description: Materialize docs into deployable Grafana/Prometheus dashboard assets and queries.
- Acceptance Criteria:
  1) Dashboard JSON/provisioning assets exist in repo.
  2) Panels for p50/p95/p99, saturation, queue lag, error-rate, timeout-rate are present.
  3) Dashboards can be bootstrapped in non-prod with one runbook.
- Labels: 10m-concurrency, observability
- Components: backend/ops
- Priority: Medium
- Story Points: 5
- Depends On: None

### Story 10M-5.2
- Summary: Implement alert rules for queue lag, p99 spike, deadlock, error budget burn
- Description: Add alert policy definitions and escalation metadata.
- Acceptance Criteria:
  1) Critical and warning alerts encoded as rule files.
  2) Alert annotations include runbook links.
  3) Synthetic trigger test validates alert routing.
- Labels: 10m-concurrency, alerting
- Components: backend/ops
- Priority: High
- Story Points: 8
- Depends On: Story 10M-5.1

---

## Epic 10M-6: Validation and Resilience Test Gates

### Story 10M-6.1
- Summary: Build burst and soak load test suites
- Description: Add repeatable k6/Gatling scenarios for burst (5x) and soak (24h) traffic profiles.
- Acceptance Criteria:
  1) Burst profile produces stable p99 under target threshold.
  2) 24h soak shows no memory growth trend.
  3) Test artifacts are archived with run metadata.
- Labels: 10m-concurrency, load-test
- Components: backend/testing
- Priority: High
- Story Points: 8
- Depends On: Epics 10M-1 to 10M-5

### Story 10M-6.2
- Summary: Chaos test dependency latency/failure with controlled degradation
- Description: Inject DB/network/dependency faults and validate graceful degradation behavior.
- Acceptance Criteria:
  1) Failure modes execute via scripted experiments.
  2) Service degrades with bounded 429/timeout behavior, not cascading failure.
  3) Recovery time and error budget impact captured.
- Labels: 10m-concurrency, chaos-engineering
- Components: backend/testing
- Priority: Medium
- Story Points: 8
- Depends On: Story 10M-6.1

### Story 10M-6.3
- Summary: Correctness gate for duplicate-event storms
- Description: Validate idempotency and optimistic concurrency under repeated/reordered delivery.
- Acceptance Criteria:
  1) No duplicate side effects for covered write paths.
  2) Conflict and replay metrics are recorded.
  3) Gate integrated into release checklist.
- Labels: 10m-concurrency, correctness
- Components: backend/testing
- Priority: High
- Story Points: 8
- Depends On: Story 10M-2.2, Story 10M-3.3

---

## Epic 10M-7: XP Ledger and Level Projection Throughput

### Story 10M-7.1
- Summary: Implement append-only XP ledger with idempotent ingest
- Description: Build `xp_ledger` ingest path with idempotency keys and audit-safe writes.
- Acceptance Criteria:
  1) Duplicate ingest requests do not create duplicate ledger entries.
  2) Ingest p99 and success rates are measurable.
  3) Ledger schema/migration and retention policy documented.
- Labels: 10m-concurrency, xp-ledger
- Components: backend/engagement, backend/database
- Priority: High
- Story Points: 13
- Depends On: Story 10M-3.1

### Story 10M-7.2
- Summary: Build async level-state projection with lag telemetry
- Description: Consume ledger events and project `user_level_state` asynchronously with lag tracking.
- Acceptance Criteria:
  1) Projection is eventually consistent and idempotent.
  2) Projection lag metric is exposed.
  3) Replay test reconstructs matching state.
- Labels: 10m-concurrency, projection
- Components: backend/engagement
- Priority: High
- Story Points: 13
- Depends On: Story 10M-7.1

### Story 10M-7.3
- Summary: Protect reward-claim flows with deterministic concurrency controls
- Description: Add strict lock order/optimistic checks on reward claim path.
- Acceptance Criteria:
  1) Duplicate-event storm does not double-claim rewards.
  2) Conflict handling returns deterministic user-visible outcome.
  3) Reward claim conflict-rate is tracked.
- Labels: 10m-concurrency, anti-duplication
- Components: backend/engagement
- Priority: High
- Story Points: 8
- Depends On: Story 10M-7.2

---

## Definition of Ready (DoR)
A story is ready when:
1) Load profile and expected traffic envelope are specified.
2) Failure behavior and user-facing degradation are defined.
3) Metrics + alert fields are identified.
4) Rollback/toggle path is specified.

## Definition of Done (DoD)
A story is done when:
1) Code/config/migrations are merged.
2) Acceptance criteria pass in automated tests or scripted validation.
3) Observability (metrics/logs/alerts) is present.
4) Runbook and rollback procedure are updated.
