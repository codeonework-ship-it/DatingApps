# Progression production rollout — 27 September 2026

## Decision

The Level/XP production-rollout implementation is complete locally and governed
by `documents/contracts/progression_production_rollout.v1.json`. Production
remains `NO_GO`: repository evidence cannot substitute for real exposed
cohorts, target-environment capacity, deployed paging, or an exercised safety
stop.

## Enforced rollout

| Stage | Exposure | Minimum cohort | Observation | Promotion rule |
|---|---:|---:|---:|---|
| Dogfood | 1% | 25 members | 7 days | Promote only from draft with reviewed evidence. |
| Limited | 5% | 250 members | 7 days | Dogfood gate must pass. |
| Expanded | 25% | 1,000 members | 14 days | Five-percent gate must pass. |
| General availability | 100% | 5,000 members | 14 days | Twenty-five-percent gate must pass. |

The database accepts only 0%, 1%, 5%, 25%, and 100%, rejects skipped forward
stages, rejects a backwards active rollout, and permits emergency pause at the
current stage. A pause immediately removes the experiment from runtime
multiplier selection while retaining assignments for analysis. Every change
records the prior stage/status, evidence URI, decision, owner, operator, and
time in an append-only stage-history row.

Every promotion requires a nonempty exposed cohort and named metric contracts:
moderation-report rate, day-7 retention, resolved-case false-positive rate, XP
inflation, projection completion p95, oldest queued age, and dead letters.
Empty or unavailable data does not pass.

## Fraud tuning

`repeated_source_cap` is now a bounded database policy instead of a hard-coded
threshold. Operators can tune rejected-attempt threshold 2–20, window 60–86,400
seconds, severity, enablement, review SLA, and rationale. The only permitted
automated response is `review_only`; account freezing or risk reduction remains
an attributed operator action. The control-panel form exposes the same bounds.

The isolated database gate changed the threshold to two, accepted one valid
award, rejected two cap attempts, and verified a high-severity review case with
the configured threshold/window evidence. Cross-account and device-graph fraud
remain deferred and are not implied by this deterministic rule.

## Projection load evidence

`qa/load/run_progression_projection_load_gate.sh` creates an ephemeral local
database, copies only schema and required progression catalogs, and refuses any
non-loopback database host. It drives the real projector with four concurrent
workers, verifies every user projection against the ledger, writes a JSON
report, and drops the database.

Current local result:

| Measure | Result | Local gate |
|---|---:|---:|
| Ledger/outbox events | 2,000 | — |
| Workers | 4 | — |
| Throughput | 4,542.1 events/second | ≥100 |
| Completion p95 | 0.530 seconds | ≤5 seconds |
| Dead letters | 0 | 0 |
| Projection mismatches | 0 | 0 |

This proves the harness and local implementation. The production gate still
requires a target-shaped workload using expected cohort volume, instance count,
database tier, connection pool, and contention profile.

## Production monitoring

The BFF exports these Prometheus gauges and refreshes them from the durable
projection/fraud state every five seconds:

- projection queue depth, processing leases, oldest pending age, completion p95
  over 15 minutes, and dead letters;
- open/reviewing fraud cases; and
- cap/cooldown denials over 15 minutes.

The committed Grafana dashboard presents all seven signals. Prometheus alerts
route runtime ownership to `progression-oncall` and fraud/safety ownership to
`trust-safety-oncall`. Alert assets are locally validated; paging is not
accepted until Alertmanager delivers an induced alert to the named humans.

## Safety-stop ownership

| Responsibility | Owner | Deadline |
|---|---|---:|
| Projection health and pause execution | `progression-oncall` | Acknowledge within 5 minutes; pause within 15 minutes |
| Member-safety/fraud decision | `trust-safety-oncall` | Acknowledge within 5 minutes; pause within 15 minutes |
| Promotion/resume approval | `product-progression-owner` | Before any stage change |

Resume requires fresh evidence for the current stage and another immutable
decision record. A previous pass cannot authorize a later cohort.

## Projection lag or backlog

1. Page `progression-oncall` and freeze stage promotion.
2. If oldest pending age exceeds 30 seconds for five minutes, set the active
   experiment to `paused` within 15 minutes.
3. Inspect PostgreSQL pool saturation, worker leases, lock waits, retry count,
   and per-user hot keys. Scale workers only while database saturation remains
   below its guardrail.
4. Drain the queue, confirm p95 at or below two seconds and zero dead letters,
   then repeat the current-stage review before resuming.

## Projection dead letter

1. Pause the experiment and retain assignments.
2. Capture the outbox ID, ledger sequence, error, attempt count, and correlated
   logs without copying private member content.
3. Repair the cause and replay through the existing idempotent projection path.
4. Verify the projection against the immutable ledger before resolving the
   incident. Do not edit the XP ledger.

## Fraud queue or cap-denial spike

1. Page `trust-safety-oncall`; pause promotion and pause the experiment if the
   configured safety threshold or staffed queue capacity is breached.
2. Segment by source, cohort, variant, account state, and rule version. Preserve
   numerator, denominator, scope, source, and window.
3. Sample resolved cases before tuning. Record false positives and the operator
   rationale; do not introduce an automatic ban or freeze.
4. After a policy change, restart the observation window and require fresh
   stage evidence.

## Remaining production evidence

The eight production rows remain pending: dogfood, 5%, 25%, GA, real-traffic
fraud calibration, target load, paging drill, and safety-stop drill. The launch
validator fails closed until each row contains passed evidence and the decision
is explicitly changed to `GO`.
