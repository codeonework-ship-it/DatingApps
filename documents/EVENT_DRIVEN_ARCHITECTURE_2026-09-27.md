# Event-driven architecture baseline

**Date:** 2026-09-27  
**Status:** implemented and locally accepted  
**Scope:** mobile and web commands, Go services, PostgreSQL state, asynchronous workers, Django operations, and provider boundary events. Billing provider behavior remains separately owned; its persisted changes and webhook ledger participate in the common event envelope without changing provider logic.

## Decision

The product uses an event-driven architecture with PostgreSQL as the local durable event backbone. Commands remain synchronous where a caller needs an immediate acceptance or validation result. Every committed product-table change creates an event in the same database transaction. Asynchronous consumers use an at-least-once claim, acknowledge, retry, and dead-letter contract. Existing specialized outboxes remain the delivery projections for chat, notifications, progression, and provider webhooks.

This is not full event sourcing. Aggregate tables remain the authoritative current state. The canonical event log records facts and drives asynchronous projections, recovery, integration, monitoring, and audit correlation.

## Canonical event contract

Migration [`075_domain_event_backbone.sql`](../backend/scripts/075_domain_event_backbone.sql) introduces:

- `platform.domain_event_outbox`: append-only, globally ordered event envelopes.
- `platform.publish_domain_event(...)`: explicit semantic publication with event version, aggregate, actor, subject, correlation, causation, idempotency, payload, metadata, and occurrence time.
- `platform.event_source_registry`: coverage inventory for mutable product tables.
- `platform.capture_row_change()`: transactional safety-net capture for registered tables.
- `platform.event_subscriptions` and `platform.event_deliveries`: consumer patterns and idempotent inbox state.
- `platform.claim_domain_events(...)`: bounded `FOR UPDATE SKIP LOCKED` leasing with stale-lease recovery.
- `platform.ack_domain_event(...)` and `platform.nack_domain_event(...)`: acknowledgement, exponential retry, and dead-letter transitions.
- `platform.domain_event_pipeline_metrics`: source, traffic, backlog, lag, and failure monitoring.

Low-latency PostgreSQL `NOTIFY` messages are hints. Consumers always recover by durable sequence after reconnecting.

## Coverage and privacy

All 115 mutable tables currently present in `user_management`, `matching`, `progression`, and `audit` are registered event sources. This includes identity, profile, discovery, matches, messages, calls, voice, safety, moderation, notification, progression, engagement, administrative, and persisted billing state.

Generic capture stores the operation and changed field names only. It does not copy passwords, recovery codes, session tokens, member profile fields, messages, media evidence, voice content, identity documents, payment details, or webhook bodies into the common event log. A feature may publish a richer semantic payload only after the owning team classifies and minimizes that payload.

## Existing delivery projections

| Domain | Event source | Delivery or projection |
|---|---|---|
| Matching and chat | Match/message state plus `matching.realtime_outbox` | Resumable bearer WebSocket and read cursors |
| Notifications | Likes, matches, messages, nudges, calls, and safety state | `matching.notification_outbox`, in-app inbox, push workers, retries and dead letters |
| Progression | Immutable `progression.xp_ledger` | `progression.projection_outbox`, level state and transitions |
| Safety and operators | Moderation/SOS state and immutable audit events | Command center queues and operator audit |
| Billing boundary | Signed provider webhook ledger and subscription/payment state | Existing deduplication and reconciliation owned by billing |
| All product aggregates | Registered transactional change capture | Canonical domain stream and future named consumers |

## Rules for new features

1. Model a user/API request as a command and validate ownership, authorization, invariants, and idempotency before state mutation.
2. Commit aggregate state and its event in one transaction. Register every new mutable product table with `platform.register_event_source` in the migration that creates it.
3. Use past-tense event names: `<domain>.<aggregate>.<fact>`. Never use an event as an instruction to bypass aggregate ownership.
4. Add `event_version` when a contract changes. Consumers must ignore fields they do not understand and tolerate additive fields.
5. Use event IDs or the domain command identity as the consumer idempotency key. Delivery is at least once; exactly-once claims are prohibited.
6. Acknowledge only after the consumer side effect commits. Retry transient failures and dead-letter exhausted or non-retryable failures.
7. Carry correlation and causation IDs through explicit semantic events. Do not put secrets or unrestricted row snapshots in payloads.
8. UIs read projections and respond to streams or refreshed queries. Flutter and Django do not write database tables or publish trusted events directly.
9. Provider callbacks enter through authenticated adapters, are deduplicated, and publish internal facts only after verification.
10. A feature is incomplete until its event contract, replay/idempotency behavior, source coverage, monitoring, and failure recovery pass the event architecture gate.

## Operational visibility

Authenticated operators can read:

- `GET /v1/admin/events` for filtered, sequence-ordered event envelopes.
- `GET /v1/admin/events/metrics` for source coverage, throughput, pending deliveries, lag, and dead letters.
- `/events/` in the Django command center for the same evidence.

Analyst and operational roles have read access. Event facts cannot be edited through the API.

## Acceptance evidence

Run:

```bash
qa/event_architecture/run_event_architecture_gate.sh
```

The gate proves complete source registration, transaction rollback coupling, privacy-safe generic payloads, idempotent publication, consumer claiming, acknowledgement, retry exhaustion, dead-letter transition, RBAC, SQL parameter binding, and OpenAPI coverage. The command-center screen gate separately verifies the browser surface.

## Deployment gates

- Select and operate a production broker or retained PostgreSQL polling topology based on measured traffic. The database contract allows a later Kafka, NATS, or managed-bus relay without changing aggregate transactions.
- Assign owners and alerts for consumer lag and dead letters.
- Exercise multi-instance consumer crash, lease takeover, replay, and poison-event recovery in staging.
- Define retention/archive durations by event classification and prove restore/replay from production backups.
- Register future tables in the same migration and keep `unregistered_sources` at zero.
