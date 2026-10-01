# Monitoring runbooks — 2026-10-01

One section per Prometheus alert. Every alert's `runbook_url` annotation points
at the `###` heading with its name (the Go test
`backend/internal/platform/observability/monitoring_assets_test.go` fails if an
alert has no section here, or a section has no alert).

Architecture, install and SLO definitions: `documents/MONITORING_AND_OBSERVABILITY_2026-10-01.md`.

## How to use these runbooks

**Severity.** `page` = wakes the on-call (acknowledge within 5 minutes, work it
now). `ticket` = Slack/email, handle within one business day. `none` = the
watchdog heartbeat, never shown to a human.

**Owners** (the `owner` label routes and names who is accountable):

| owner | covers | escalate to |
|---|---|---|
| `backend-oncall` | API, BFF, workers, realtime, push | backend lead |
| `platform-oncall` | VPS, PostgreSQL, disks, TLS, monitoring stack | platform lead / hosting provider |
| `trust-safety-oncall` | SOS delivery, erasure, fraud queues | trust & safety lead (and legal for erasure) |
| `progression-oncall` | Level/XP projection | backend lead |

**Shell conventions** (on the VPS, as an operator with sudo):

```bash
PSQL='sudo -u postgres psql -d dating_app -X -v ON_ERROR_STOP=1'   # adjust the DB name if different
PROM='http://127.0.0.1:9090'                                      # Prometheus (loopback)
q() { curl -fsS --get "$PROM/api/v1/query" --data-urlencode "query=$1" | jq -r '.data.result[] | "\(.metric) \(.value[1])"'; }
logs() { sudo journalctl -u "$1" -S "${2:--30min}" -o cat; }          # zap JSON lines; pipe to jq
```

From a laptop: `ssh -L 9090:127.0.0.1:9090 -L 9193:127.0.0.1:9193 -L 3000:127.0.0.1:3000 <vps>`
then open `http://localhost:9090/alerts`, `http://localhost:9193` (Alertmanager)
and Grafana (or `https://<domain>/grafana/` when published).

**Always start with** (30 seconds):

```bash
systemctl --no-pager status connect.target connect-monitoring.target | head -40
systemctl list-units --failed
q 'up{job=~"connect-.*"} == 0'
q 'changes(process_start_time_seconds{job=~"connect-.*"}[30m]) > 0'
q 'verified_dating_build_info'          # which version is running where
```

Every request log carries `correlation_id` (also returned to clients in the
`X-Correlation-ID` header) and `route` (the chi template). In Grafana Explore
(Loki): `{unit="connect-mobile-bff.service"} | json | level="error"`.

**Silencing.** During planned maintenance create a silence in Alertmanager
(`amtool --alertmanager.url=http://127.0.0.1:9193 silence add alertname=~".+" -d 30m -c "deploy <version>"`)
rather than stopping Prometheus.

---

## API and SLOs

SLOs: 99.5% of non-infrastructure requests per route without 5xx over 30 days;
99% of non-upload BFF requests faster than 1 s. Burn-rate alerts are defined in
`backend/observability/prometheus/rules/api-slo.yml`.

### VerifiedDatingRouteErrorBudgetFastBurn

**Means:** one BFF route returns 5xx often enough to spend 2% of its monthly
error budget per hour (or 5% in six hours). The `route` and `method` labels name it.

**First checks**
1. Grafana → *Connect · API overview* → filter `route`; look at *Top 10 erroring routes* and *Responses 429/5xx by code*.
2. Errors for that route in logs:
   `logs connect-mobile-bff.service 30min | jq -c 'select(.route=="<route>" and .status>=500)' | tail -20`
3. Pick a `correlation_id` from a failing line and search all units for it to see the underlying error (`http_unhandled_exception`, repository error, upstream timeout).
4. Did it start with a deploy? `q 'verified_dating_build_info'` and the *Restarts* annotation on the dashboard.
5. Is the database healthy? (*Connect · PostgreSQL*; `VerifiedDatingPostgres*` alerts.)

**Mitigation:** roll back a bad deploy (reinstall the previous binary in
`/opt/connect/bin` and `sudo systemctl restart connect-mobile-bff`); if a
feature flag gates the route, switch it off; if a dependency (payments, moderation,
push) is failing, follow its section below.

**Escalation:** backend lead after 30 minutes without a cause; incident channel if more than one route burns.

### VerifiedDatingRouteErrorBudgetSlowBurn

**Means:** a route's 5xx ratio over a day is 3× the sustainable rate — a
persistent low-grade failure (one bad input path, a flaky provider).

**First checks:** same queries as the fast burn but over 24 h:
`q 'topk(5, verified_dating:http_error_ratio:rate1d{service="mobile_bff"})'`; group
error log lines by `msg` to find the dominant failure:
`logs connect-mobile-bff.service 24h | jq -r 'select(.route=="<route>" and .status>=500) | .msg' | sort | uniq -c | sort -rn | head`

**Mitigation:** file a bug with sample correlation ids; fix forward.
**Escalation:** none unless it turns into a fast burn.

### VerifiedDatingRouteLatencyBudgetFastBurn

**Means:** more than 14.4% (1 h) / 6% (6 h) of requests to a route take longer
than 1 s — members feel the app hang.

**First checks**
1. *API overview* → *Top 10 slowest routes (p95)*; *Saturation* row (DB pool utilisation, in-flight, CPU).
2. Slow queries right now:
   `$PSQL -c "SELECT pid, now()-query_start AS age, state, left(query,120) FROM pg_stat_activity WHERE datname=current_database() AND state<>'idle' ORDER BY age DESC LIMIT 10;"`
3. Lock waits: `$PSQL -c "SELECT pid, wait_event_type, wait_event, left(query,80) FROM pg_stat_activity WHERE wait_event_type='Lock';"`
4. Host: `uptime; free -m; iostat -x 5 2` (sysstat).

**Mitigation:** cancel a runaway query (`SELECT pg_cancel_backend(<pid>);`), roll
back a deploy that introduced a slow path, temporarily raise
`POSTGRES_POOL_MAX_CONNS` only if PostgreSQL has headroom.
**Escalation:** platform-oncall if the database or host is saturated.

### VerifiedDatingRouteLatencyBudgetSlowBurn

**Means:** a route is steadily slower than its SLO over a day.
**First checks:** `q 'topk(5, verified_dating:http_latency_slow_ratio:rate1d{service="mobile_bff"})'`;
`EXPLAIN (ANALYZE, BUFFERS)` the route's main query on a replica or off-peak; check table bloat
(`$PSQL -c "SELECT relname, n_dead_tup, last_autovacuum FROM pg_stat_user_tables ORDER BY n_dead_tup DESC LIMIT 10;"`).
**Mitigation:** add the missing index / pagination limit in a migration; ticket to the route owner.
**Escalation:** none.

### VerifiedDatingEdgeAvailabilityBurn

**Means:** across all routes, the API gateway (what the apps actually talk to)
returns 5xx fast enough to burn the budget. Includes 502s when the BFF is down,
so this fires even when the BFF is not scraped.

**First checks:** `systemctl status connect-mobile-bff connect-backend@api-gateway`;
`curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8081/readyz`;
`q 'sum by (code) (rate(verified_dating_http_responses_by_code_total{service="api_gateway"}[5m]))'`;
gateway logs `logs connect-backend@api-gateway.service 15min | jq -c 'select(.status>=500)' | tail`.

**Mitigation:** restart a hung BFF (`sudo systemctl restart connect-mobile-bff`), then
find out why (OOM? `journalctl -k | grep -i oom`). Roll back if a deploy caused it.
**Escalation:** incident channel immediately — this is a user-visible outage.

### VerifiedDatingUploadLatencyHigh

**Means:** photo/cover/evidence/voice/export routes (excluded from the 1 s SLO) have p95 above 10 s.
**First checks:** media disk (`df -h /var/lib/connect/media`), S3 latency if
`FILE_STORAGE_BACKEND=aws_s3` (look for `s3` errors in BFF logs), the moderation
provider (Rekognition) latency in logs, nginx `client_body_timeout` errors in `/var/log/nginx/error.log`.
**Mitigation:** fix the storage/moderation provider; temporarily raise nothing — uploads already stream.
**Escalation:** platform-oncall for disk/S3.

## Reliability guardrails

### VerifiedDatingHTTPP99LatencyHigh

**Means:** the BFF's overall p99 exceeds 2 s for 10 minutes.
**First checks:** as for *RouteLatencyBudgetFastBurn*; also `q 'sum(verified_dating_http_in_flight_requests)'`
and goroutines `q 'go_goroutines{job="connect-mobile-bff"}'` (a leak shows as a steady climb).
**Mitigation:** cancel runaway queries; restart the BFF only if goroutines/memory are runaway (capture `curl -s http://127.0.0.1:8081/debug/pprof/goroutine?debug=1 > /tmp/goroutines.txt` first).
**Escalation:** backend lead.

### VerifiedDatingHTTPErrorBudgetBurn

**Means:** more than 2% of all BFF requests are 5xx over 5 minutes.
**First checks:** the per-route burn alerts name the route; otherwise
`q 'topk(10, sum by (route) (rate(verified_dating_http_requests_total{service="mobile_bff",status_class="5xx"}[5m])))'`.
Then follow *VerifiedDatingRouteErrorBudgetFastBurn*.
**Mitigation / escalation:** as above.

### VerifiedDatingGatewayUpstreamUnavailable

**Means:** more than 5% of gateway responses are 502/503/504 — the gateway cannot reach the BFF on `MOBILE_BFF_UPSTREAM_URL` (127.0.0.1:8081).
**First checks:** `systemctl status connect-mobile-bff`; `ss -ltnp | grep 8081`;
`journalctl -u connect-mobile-bff -n 100 --no-pager` (startup failures: storage layout, database URL, migrations).
**Mitigation:** fix the start failure and `sudo systemctl restart connect-mobile-bff`; if it crash-loops after a deploy, roll back.
**Escalation:** incident channel.

### VerifiedDatingRequestTimeoutRateHigh

**Means:** over 1% of BFF requests hit their timeout tier.
**First checks:** `q 'topk(5, sum by (tier, domain) (rate(verified_dating_reliability_request_timeouts_total[5m])))'`;
database slow queries (see latency runbook); external providers in logs (`grep -E 'timeout|deadline'`).
**Mitigation:** cancel blocking queries; disable the slow provider's feature flag; never raise timeouts as a first response.
**Escalation:** platform-oncall if PostgreSQL is the cause.

### VerifiedDatingBulkheadShedding

**Means:** a domain bulkhead (matching, profile, chat …) is rejecting requests with 429 because its concurrency limit is full.
**First checks:** *API overview → Bulkhead shedding by domain*; which routes in that domain are slow (they hold the slots).
**Mitigation:** fix the slow dependency; raise the bulkhead limit (`BFF_BULKHEAD_*` in `/etc/connect/connect.env`) only with database headroom.
**Escalation:** backend lead if it lasts more than an hour.

### VerifiedDatingNotificationQueueLagHigh

**Means:** the oldest pending notification has waited more than 30 s; in-app and push notifications are late.
**First checks**
1. Worker alive? *Workers & queues* → `notification_delivery` heartbeat; `q 'verified_dating:worker_heartbeat_age_seconds{worker="notification_delivery"}'`.
2. Queue state: `$PSQL -c "SELECT status, count(*), min(created_at) FROM matching.notification_outbox GROUP BY status;"`
3. Errors: `logs connect-mobile-bff.service 30min | jq -c 'select(.msg|test("notification"))' | tail -20`.
**Mitigation:** restart the BFF if the worker is stuck (stale leases are recovered on start); if the push provider is failing see *PushSuccessSLOBreach*.
**Escalation:** backend lead after 30 minutes.

### VerifiedDatingNotificationQueueDepthHigh

**Means:** more than 1000 notification jobs pending or retrying.
**First checks:** same as queue lag; check for a fan-out storm (one event creating many jobs):
`$PSQL -c "SELECT event_type, count(*) FROM matching.notification_outbox WHERE status IN ('pending','retry') GROUP BY 1 ORDER BY 2 DESC LIMIT 10;"`
**Mitigation:** let it drain if lag is fine; raise `NOTIFICATION_WORKER_COUNT` for sustained load.
**Escalation:** none unless lag alerts fire.

### VerifiedDatingNotificationDeadLetters

**Means:** notification jobs exhausted their retries.
**First checks:** `$PSQL -c "SELECT event_type, left(last_error,120), count(*) FROM matching.notification_outbox WHERE status='dead_letter' GROUP BY 1,2 ORDER BY 3 DESC LIMIT 20;"`;
the operator console's notification queue page (`/admin/notifications/queue/metrics`).
**Mitigation:** fix the cause (invalid token handling, provider credentials), then requeue from the console or
`UPDATE matching.notification_outbox SET status='retry', available_at=NOW(), attempt_count=0 WHERE status='dead_letter' AND <filter>;`
**Escalation:** none.

### VerifiedDatingPushSuccessSLOBreach

**Means:** fewer than 99% of push attempts in 15 minutes reached the provider (with at least 20 attempts).
**First checks:** BFF logs for the push sender (`jq 'select(.msg|test("push"))'`); FCM/APNs status pages; whether credentials or the APNs certificate expired.
**Mitigation:** rotate expired credentials in `/etc/connect/connect.env` and restart the BFF; failed jobs retry automatically.
**Escalation:** backend lead; vendor support if the provider is degraded.

### VerifiedDatingPushP95LatencyHigh

**Means:** outbox-to-provider p95 above 10 s.
**First checks:** notification queue depth and worker heartbeat; provider latency in logs; host network.
**Mitigation:** raise `NOTIFICATION_WORKER_COUNT` if the queue, not the provider, is slow.
**Escalation:** none.

### VerifiedDatingPostgresDeadlocks

**Means:** PostgreSQL aborted a transaction to break a deadlock; a member saw an error.
**First checks:** `sudo journalctl -u postgresql@*-main -S -15min | grep -A5 -i deadlock` (the log names both statements); match them to code paths.
**Mitigation:** none immediately (the client retries); ticket to fix lock ordering. Page again only if it repeats.
**Escalation:** backend lead if more than a few per hour.

### VerifiedDatingIdempotencyExpiredLeases

**Means:** idempotent commands started but never completed or released their lease (crash mid-request). Retries of those requests get "outcome uncertain".
**First checks:** `$PSQL -c "SELECT * FROM platform.idempotency_health;"`;
`$PSQL -c "SELECT left(cache_key,16), actor_id, lease_expires_at FROM platform.idempotency_records WHERE state='processing' AND lease_expires_at<NOW() LIMIT 20;"`; BFF restarts around the lease time.
**Mitigation:** the retention worker (`idempotency_retention`) clears them once their replay window passes; verify its heartbeat. For a stuck payment-type command check the aggregate manually before telling the member to retry.
**Escalation:** backend lead.

### VerifiedDatingIdempotencyRetentionBacklog

**Means:** more than 10 000 expired idempotency records wait for archival.
**First checks:** `idempotency_retention` heartbeat and error ratio on *Workers & queues*; `logs connect-mobile-bff.service 1h | grep -i 'idempotency retention'`.
**Mitigation:** fix the failing archival (usually a lock timeout) — the worker processes 1000 rows per 5 minutes.
**Escalation:** none.

### VerifiedDatingPostgresPoolSaturation

**Means:** an application pool (`pool` label, e.g. `mobile/profile_repository`, `dataaccess/runtime_store`) has over 90% of its connections checked out for 10 minutes; callers queue and time out.
**First checks:** *Connect · PostgreSQL → Application pools*; long transactions (`VerifiedDatingPostgresLongTransaction`); `q 'rate(verified_dating_db_pool_wait_seconds_total[5m])'`.
**Mitigation:** kill leaked idle-in-transaction sessions
(`$PSQL -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state='idle in transaction' AND now()-state_change > interval '5 minutes';"`);
raise `POSTGRES_POOL_MAX_CONNS` only when `max_connections` has headroom.
**Escalation:** platform-oncall.

## Workers and queues

Worker names: `account_erasure`, `media_cleanup`, `billing_renewal_sweep`,
`date_plan_sweep`, `xp_award_spool_replay`, `notification_delivery`,
`level_projection`, `trust_retention`, `sos_gauge_refresh`, `sos_delivery`,
`idempotency_retention` (all in the mobile BFF; heartbeat code in
`backend/internal/bff/mobile/observability_wiring.go`).

### VerifiedDatingCriticalWorkerStale

**Means:** `sos_delivery`, `sos_gauge_refresh`, `notification_delivery` or `level_projection` has not completed a successful run within max(3× its interval, 5 min). Emergency alerts, notifications or XP are not moving.
**First checks**
1. `q 'verified_dating:worker_heartbeat_age_seconds'` and `q 'sum by (worker,result) (rate(verified_dating_worker_runs_total[15m]))'` — is it failing (errors) or not running at all (no runs)?
2. Errors: `logs connect-mobile-bff.service 30min | jq -c 'select(.level!="info") | select(.msg|test("sos|notification|progression"))' | tail -20`.
3. Database reachable? (`VerifiedDatingPostgresDown`).
**Mitigation:** failing → fix the error (DB, provider credentials). Not running → capture goroutines (`curl -s http://127.0.0.1:8081/debug/pprof/goroutine?debug=2 > /tmp/g.txt`) then `sudo systemctl restart connect-mobile-bff`.
For SOS, trust & safety must manually check `matching.sos_delivery_outbox` for undelivered alerts while the worker is down.
**Escalation:** trust-safety-oncall immediately for SOS workers; backend lead otherwise.

### VerifiedDatingWorkerStale

**Means:** a non-critical worker (erasure, media cleanup, billing expiry, date-plan sweep, XP spool replay, trust retention, idempotency retention) has not succeeded within 3× its interval.
**First checks:** same as above; `systemctl status connect-mobile-bff` (workers run inside the BFF; a BFF restart resets heartbeats).
**Mitigation:** fix the error; the next run catches up (all sweeps are idempotent).
`billing_renewal_sweep` stale means lapsed subscriptions stay active — check
`$PSQL -c "SELECT count(*) FROM matching.billing_subscriptions_runtime WHERE status='past_due' AND current_period_end < NOW() - interval '7 days';"`.
**Escalation:** owner of the affected domain (billing, trust & safety for erasure/retention).

### VerifiedDatingWorkerErrorRateHigh

**Means:** more than half of a worker's runs failed over 15 minutes, although it may still be "fresh".
**First checks:** `logs connect-mobile-bff.service 30min | jq -c 'select(.level=="warn" or .level=="error")' | grep <worker keyword> | tail`.
**Mitigation:** fix the dependency named in the error.
**Escalation:** none unless the worker goes stale.

### VerifiedDatingAccountErasureFailures

**Means:** scheduled account erasures failed. Deletion is a legal commitment (GDPR art. 17); a failing member is retried hourly but must not be forgotten.
**First checks:** `logs connect-mobile-bff.service 6h | jq -c 'select(.msg=="account_erasure_failed")'` (contains `user_id` and the error);
overdue erasures: `$PSQL -c "SELECT id, deletion_effective_at FROM user_management.users WHERE deletion_effective_at <= NOW() AND erased_at IS NULL ORDER BY 2 LIMIT 20;"`; legal hold status.
**Mitigation:** fix the blocking row (FK, storage delete failure) and let the next run erase; never delete rows by hand outside `eraseAccount`.
**Escalation:** trust-safety-oncall; legal/DPO if any erasure is more than 30 days past due.

### VerifiedDatingFanoutDroppingEvents

**Means:** the in-process activity fan-out queue was full and dropped events; activity history and admin aggregates are incomplete (requests themselves succeeded).
**First checks:** *Workers & queues → In-process queues*; `logs connect-mobile-bff.service 30min | grep fanout_queue_full_drop | head`; database write latency (the fan-out workers write activity rows).
**Mitigation:** raise `FANOUT_QUEUE_SIZE` / `FANOUT_WORKER_COUNT` in `/etc/connect/connect.env` and restart the BFF; fix slow activity inserts.
**Escalation:** none.

### VerifiedDatingFanoutQueueSaturated

**Means:** the fan-out queue is over 80% full for 5 minutes — drops are imminent.
**First checks / mitigation:** as for *FanoutDroppingEvents*.
**Escalation:** none.

## Realtime and chat

### VerifiedDatingRealtimeConnectionsDropped

**Means:** open WebSockets fell by more than half versus the last 15 minutes (with at least 20 before) and stayed down for 5 minutes. A deploy drops all sockets but clients reconnect within seconds, so a lasting drop means clients cannot reconnect.
**First checks:** *Realtime & chat* dashboard; `VerifiedDatingRealtimeEndpointDown`; nginx errors
(`sudo tail -50 /var/log/nginx/error.log | grep realtime`); BFF logs for `chat_realtime_upgrade_failed`; session/auth errors (revoked sessions close sockets with policy violation).
**Mitigation:** restore nginx config (`sudo nginx -t`); restart the BFF if upgrades fail; roll back a client-auth change.
**Escalation:** backend lead.

### VerifiedDatingRealtimeShortLivedConnections

**Means:** most sockets close within 10 s — clients are reconnect-looping (load and battery drain).
**First checks:** BFF logs for `chat_realtime_delivery_failed` / `session revoked`; nginx `proxy_read_timeout` on `/v1/realtime/` (must stay 3600 s); client version distribution.
**Mitigation:** fix the server error or proxy timeout; coordinate a client fix for client-side loops.
**Escalation:** none.

### VerifiedDatingRealtimeDeliveryLagHigh

**Means:** live chat events reach connected sockets more than 5 s (p95) after being written. Polling runs every 400 ms, so the database query or socket writes are slow.
**First checks:** `matching.realtime_outbox` query latency
(`$PSQL -c "EXPLAIN ANALYZE SELECT sequence_id FROM matching.realtime_outbox WHERE recipient_user_id='<uuid>' AND sequence_id>0 AND expires_at>NOW() ORDER BY sequence_id LIMIT 100;"`); table size and vacuum; DB saturation.
**Mitigation:** vacuum/prune the outbox, fix missing index, reduce load.
**Escalation:** platform-oncall if PostgreSQL-bound.

## Safety and trust

### VerifiedDatingSOSDeliveryOverdue

**Means:** an SOS contact delivery is past its response deadline and not delivered. A member may be in danger and their emergency contact has not been told.
**First checks:** `$PSQL -c "SELECT id, status, attempt_count, left(last_error,120), response_deadline_at FROM matching.sos_delivery_outbox WHERE status<>'delivered' ORDER BY created_at LIMIT 20;"`;
`sos_delivery` worker heartbeat; SOS provider (`SOS_DELIVERY_WEBHOOK_URL`) reachability: `curl -sS -o /dev/null -w '%{http_code}\n' -X POST <url>` from the VPS.
**Mitigation:** fix the provider/credentials (restart BFF after editing `/etc/connect/connect.env`). Trust & safety follows the manual SOS outreach procedure in parallel — do not wait for the fix.
**Escalation:** trust-safety-oncall immediately (page), trust & safety lead.

### VerifiedDatingSOSDeliveryDeadLetters

**Means:** an SOS delivery exhausted its attempts and will not retry.
**First checks:** query above with `status='dead_letter'`; the `last_error`.
**Mitigation:** manual outreach now; after fixing the provider, requeue
(`UPDATE matching.sos_delivery_outbox SET status='retry', available_at=NOW() WHERE id='<id>';`) if still within the response window.
**Escalation:** trust-safety-oncall (page).

### VerifiedDatingSOSDeliveryStalled

**Means:** the oldest undelivered SOS delivery is over two minutes old.
**First checks / mitigation / escalation:** as *SOSDeliveryOverdue*; also check `VerifiedDatingCriticalWorkerStale{worker="sos_delivery"}`. If no SOS provider is configured (`SOS_DELIVERY_PROVIDER` empty) the engine never runs — configuring it is a launch blocker.

### VerifiedDatingSOSGaugesMissing

**Means:** no BFF has exported the SOS gauges for 10 minutes — usually the BFF is not being scraped, so the SOS alerts above are blind.
**First checks:** `q 'up{job="connect-mobile-bff"}'`; Prometheus targets page; `systemctl status connect-mobile-bff`.
**Mitigation:** restore the BFF or the scrape. (A dead trust retention worker with a live BFF shows as `VerifiedDatingCriticalWorkerStale{worker="sos_gauge_refresh"}` instead.)
**Escalation:** platform-oncall.

## Level / XP progression

Rollout context: `documents/PROGRESSION_PRODUCTION_ROLLOUT_2026-09-27.md`.

### VerifiedDatingProgressionProjectionLagHigh

**Means:** the oldest pending XP projection job is older than 30 s; members see stale level/XP.
**First checks:** `level_projection` heartbeat; `$PSQL -c "SELECT status, count(*), min(available_at) FROM progression.projection_outbox GROUP BY 1;"`; BFF logs for `progression_`.
**Mitigation:** restart the BFF if the worker is stuck (leases older than 5 minutes are recovered automatically); fix DB errors.
**Escalation:** progression-oncall → backend lead.

### VerifiedDatingProgressionQueueDepthHigh

**Means:** more than 500 projection jobs waiting.
**First checks / mitigation:** as above; look for a bulk award (campaign) that enqueued many users at once and let it drain if lag is acceptable.
**Escalation:** none.

### VerifiedDatingProgressionCompletionP95High

**Means:** queue-to-completion p95 above 2 s over 15 minutes.
**First checks:** projection query latency, DB saturation, worker batch duration (`q 'histogram_quantile(0.95, sum by (le) (rate(verified_dating_worker_run_duration_seconds_bucket{worker="level_projection"}[15m])))'`).
**Mitigation:** fix the slow query; reduce concurrent load.
**Escalation:** none.

### VerifiedDatingProgressionDeadLetters

**Means:** a projection failed 8 times and stopped retrying; that member's level will not update.
**First checks:** `$PSQL -c "SELECT id, user_id, left(last_error,160) FROM progression.projection_outbox WHERE status='dead_letter' ORDER BY id DESC LIMIT 20;"`.
**Mitigation:** fix the data/code bug, then `UPDATE progression.projection_outbox SET status='retry', attempt_count=0, available_at=NOW() WHERE id IN (...);`.
**Escalation:** progression-oncall (page).

### VerifiedDatingProgressionCriticalFraudQueue

**Means:** more than 100 open XP fraud cases — more than the review team can handle.
**First checks:** operator console fraud queue; recent cap-denial spike; a single actor/ring behind many cases.
**Mitigation:** add reviewers; tighten caps via runtime config; bulk-action a confirmed ring.
**Escalation:** trust & safety lead.

### VerifiedDatingProgressionCapDenialSpike

**Means:** more than 1000 XP cap/cooldown denials in 15 minutes — farming or a client retry loop.
**First checks:** BFF logs grouped by actor/route for cap denials; client version of the top actors.
**Mitigation:** throttle/ban abusive accounts; ship a client fix for loops.
**Escalation:** trust-safety-oncall.

## Platform: processes, database, host

### VerifiedDatingTargetDown

**Means:** Prometheus cannot scrape a Connect process (`job`, `component` labels) — it is down, hung, or bound to another address.
**First checks:** `systemctl status <unit>`; `ss -ltnp | grep <port>` (8080 gateway, 8081 BFF, 10091-10094 gRPC admin, 9100/9187/9115 exporters);
`journalctl -u <unit> -n 100 --no-pager`. For gRPC services make sure `*_ADMIN_ADDR=127.0.0.1:1009x` is set in `/etc/connect/connect.env`.
**Mitigation:** `sudo systemctl restart <unit>`; fix configuration errors shown at startup.
**Escalation:** backend lead for app units, platform for exporters.

### VerifiedDatingProcessRestarting

**Means:** a Connect process restarted more than three times in 30 minutes (crash loop or OOM kill).
**First checks:** `journalctl -u <unit> -S -1h --no-pager | grep -E 'panic|fatal|Main process exited'`; `journalctl -k -S -1h | grep -i 'out of memory'`.
**Mitigation:** roll back the last deploy; if OOM, see *HostMemoryLow*.
**Escalation:** backend lead.

### VerifiedDatingSystemdUnitFailed

**Means:** systemd gave up restarting a unit (start limit hit). Nothing brings it back automatically.
**First checks:** `systemctl status <unit>`; `journalctl -u <unit> -n 200 --no-pager`.
**Mitigation:** fix the cause, then `sudo systemctl reset-failed <unit> && sudo systemctl start <unit>`.
**Escalation:** owner of the unit.

### VerifiedDatingPostgresDown

**Means:** postgres_exporter cannot connect to PostgreSQL (or postgres_exporter itself is not scraped). Every write and most reads fail.
**First checks:** `systemctl status postgresql@*-main`; `sudo -u postgres pg_isready`; `df -h /var/lib/postgresql` (a full disk stops PostgreSQL);
`sudo journalctl -u postgresql@*-main -n 100 --no-pager`; if only the exporter is broken: `systemctl status connect-postgres-exporter` and its DSN in `/etc/connect-monitoring/postgres_exporter.env`.
**Mitigation:** free disk space, then `sudo systemctl start postgresql`; never delete WAL files by hand. Restore from backup only with the platform lead.
**Escalation:** incident channel + platform lead immediately.

### VerifiedDatingPostgresConnectionsNearLimit

**Means:** over 80% of `max_connections` in use. New pools, migrations and the operator console fail at 100%.
**First checks:** `$PSQL -c "SELECT usename, application_name, state, count(*) FROM pg_stat_activity GROUP BY 1,2,3 ORDER BY 4 DESC;"`.
**Mitigation:** terminate idle-in-transaction leaks; lower pool sizes of non-critical services; raising `max_connections` needs a restart and RAM.
**Escalation:** platform-oncall.

### VerifiedDatingPostgresPoolWaiting

**Means:** callers spend more than 0.5 s per second waiting for a free connection in a pool.
**First checks / mitigation:** as *PostgresPoolSaturation*.
**Escalation:** none unless latency SLO alerts fire.

### VerifiedDatingPostgresLongTransaction

**Means:** a transaction has been active or idle-in-transaction for over 5 minutes; it holds locks and blocks vacuum.
**First checks:** `$PSQL -c "SELECT pid, usename, application_name, state, now()-xact_start AS age, left(query,120) FROM pg_stat_activity WHERE xact_start IS NOT NULL ORDER BY age DESC LIMIT 5;"`.
**Mitigation:** `SELECT pg_terminate_backend(<pid>);` for leaked app sessions; let a known maintenance job (backup, migration) finish.
**Escalation:** none.

### VerifiedDatingMediaDiskLow

**Means:** the filesystem holding `/var/lib/connect/media` has less than 15% free. Uploads fail when it fills.
**First checks:** `df -h /var/lib/connect/media`; `q 'verified_dating_media_bytes'` (which area grows); `sudo du -sh /var/lib/connect/media/*`; orphaned temp files in `tmp/`.
**Mitigation:** make sure `media_cleanup` runs (heartbeat); grow the volume; move media to S3 with `mediactl` (`documents/MEDIA_STORAGE_VPS_AND_S3_2026-10-01.md` §6).
**Escalation:** platform-oncall.

### VerifiedDatingDatabaseDiskLow

**Means:** the filesystem holding `/var/lib/postgresql` has less than 15% free. PostgreSQL stops (and may need recovery) at 0%.
**First checks:** `df -h /var/lib/postgresql`; biggest relations: `$PSQL -c "SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) FROM pg_class ORDER BY pg_total_relation_size(oid) DESC LIMIT 10;"`; WAL size `sudo du -sh /var/lib/postgresql/*/main/pg_wal`; stale replication slots.
**Mitigation:** run retention workers (trust/idempotency retention heartbeats), `VACUUM` bloated tables, drop stale replication slots, grow the disk.
**Escalation:** platform lead (page).

### VerifiedDatingFilesystemAlmostFull

**Means:** any real filesystem has less than 5% free.
**First checks:** `df -h`; `sudo du -xh --max-depth=2 <mountpoint> | sort -h | tail`; journald size (`journalctl --disk-usage`); Prometheus/Loki data (`du -sh /var/lib/connect-monitoring/prometheus /var/lib/loki`).
**Mitigation:** `sudo journalctl --vacuum-size=1G`; lower Prometheus `PROMETHEUS_RETENTION_SIZE` in `/etc/connect-monitoring/prometheus.env`; remove old release tarballs in `/var/cache/connect-monitoring`.
**Escalation:** platform-oncall.

### VerifiedDatingFilesystemFillingUp

**Means:** at the six-hour trend a filesystem will be full within 24 hours.
**First checks / mitigation:** as *FilesystemAlmostFull*, before it becomes urgent.
**Escalation:** none.

### VerifiedDatingDiskUsageReportStale

**Means:** `connect-disk-usage.timer` has not refreshed the media/database disk report for 3 hours; the media and database disk alerts are blind.
**First checks:** `systemctl status connect-disk-usage.timer connect-disk-usage.service`; `journalctl -u connect-disk-usage -n 50`; `ls -l /var/lib/node_exporter/textfile/`.
**Mitigation:** fix and `sudo systemctl start connect-disk-usage.service`.
**Escalation:** none.

### VerifiedDatingHostMemoryLow

**Means:** less than 10% RAM available for 10 minutes.
**First checks:** `ps aux --sort=-rss | head`; `q 'process_resident_memory_bytes{job=~"connect-.*"}'`; PostgreSQL `shared_buffers`/`work_mem` vs RAM.
**Mitigation:** restart a leaking process (after a heap profile: `curl -s http://127.0.0.1:8081/debug/pprof/heap > /tmp/heap.pb.gz`); add swap or RAM.
**Escalation:** platform-oncall.

### VerifiedDatingHostOOMKill

**Means:** the kernel killed a process for memory.
**First checks:** `journalctl -k -S -1h | grep -iA5 'killed process'`.
**Mitigation:** as *HostMemoryLow*; verify the killed service restarted.
**Escalation:** platform-oncall.

### VerifiedDatingHostCPUSaturated

**Means:** CPU above 90% for 15 minutes.
**First checks:** `top -o %CPU`; `q 'rate(process_cpu_seconds_total{job=~"connect-.*"}[5m])'`; a CPU profile: `curl -s 'http://127.0.0.1:8081/debug/pprof/profile?seconds=30' > /tmp/cpu.pb.gz`.
**Mitigation:** stop runaway jobs; scale the VPS.
**Escalation:** platform-oncall.

## Uptime and TLS

### VerifiedDatingPublicEndpointDown

**Means:** the blackbox probe of `https://<domain>/healthz` or `https://<domain>/` fails (DNS, TLS, nginx, gateway or website).
**First checks:** `curl -sv https://<domain>/healthz` from outside and from the VPS; `systemctl status nginx connect-website connect-backend@api-gateway`; `sudo nginx -t`;
`probe_*` details: `curl -s 'http://127.0.0.1:9115/probe?module=https_2xx&target=https://<domain>/healthz&debug=true'`.
**Mitigation:** restart the failing unit; restore the nginx config; check DNS records and the provider's status page.
**Escalation:** incident channel — the product is unreachable.

### VerifiedDatingServiceNotReady

**Means:** `/readyz` of the BFF (127.0.0.1:8081) or gateway (127.0.0.1:8080) answers non-200: a gRPC dependency (auth/profile/matching/chat) or PostgreSQL is unavailable to it.
**First checks:** `curl -s http://127.0.0.1:8081/readyz | jq` (names the failing dependency); `systemctl status 'connect-backend@*'`.
**Mitigation:** restart the failing dependency; see *PostgresDown* for the database.
**Escalation:** backend lead.

### VerifiedDatingRealtimeEndpointDown

**Means:** an unauthenticated WebSocket upgrade to `https://<domain>/v1/realtime/chat` did not get the expected 401/403 — the realtime route is broken at nginx (`location ^~ /v1/realtime/`), the gateway or the BFF.
**First checks:** `curl -si -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: Y29ubmVjdC1wcm9iZS1rZXk=' https://<domain>/v1/realtime/chat | head -1`;
nginx config for the upgrade map; BFF status.
**Mitigation:** restore nginx config / restart the BFF.
**Escalation:** backend lead.

### VerifiedDatingTLSCertificateExpiringSoon

**Means:** the public certificate expires in under 14 days — certbot renewal is failing.
**First checks:** `sudo certbot certificates`; `systemctl list-timers | grep certbot`; `sudo certbot renew --dry-run`; port 80 reachability for the ACME challenge (`location ^~ /.well-known/acme-challenge/`).
**Mitigation:** fix the challenge path / DNS and run `sudo certbot renew && sudo systemctl reload nginx`.
**Escalation:** platform-oncall.

### VerifiedDatingTLSCertificateExpiryImminent

**Means:** under 3 days left. Apps refuse to connect once it lapses.
**First checks / mitigation:** as above, now. If ACME cannot work in time, issue with DNS-01 (`certbot certonly --manual --preferred-challenges dns`).
**Escalation:** platform lead (page).

## Monitoring stack

### VerifiedDatingWatchdog

**Means:** always firing by design; Alertmanager sends it every minute to the dead man's switch (`DEADMANS_SWITCH_URL`). You only hear about it from the external service when it **stops** — then Prometheus, Alertmanager, the network or the whole VPS is down.
**First checks (when the dead man's switch alerts):** can you SSH to the VPS? `systemctl status connect-prometheus connect-alertmanager`; `curl -s http://127.0.0.1:9090/-/ready`; `curl -s http://127.0.0.1:9193/-/ready`; outbound HTTPS from the VPS.
**Mitigation:** restart the monitoring units; contact the hosting provider if the VPS is unreachable.
**Escalation:** platform lead.

### VerifiedDatingPrometheusRuleFailures

**Means:** some rule evaluations fail, so some alerts cannot fire.
**First checks:** `http://localhost:9090/rules` (via tunnel) shows the error; `sudo /opt/connect-monitoring/prometheus/promtool check rules /etc/connect-monitoring/prometheus/rules/*.yml`.
**Mitigation:** fix the rule in `backend/observability/prometheus/rules`, run the Go asset test, redeploy with `install_monitoring.sh --only rules`.
**Escalation:** none.

### VerifiedDatingAlertmanagerNotificationsFailing

**Means:** Alertmanager cannot deliver to a receiver (`integration` label: webhook, slack, pagerduty, email). Pages may be lost.
**First checks:** `journalctl -u connect-alertmanager -S -1h | grep -i 'notify'`; receiver credentials in `/etc/connect-monitoring/alertmanager.env`; outbound HTTPS/SMTP from the VPS.
**Mitigation:** fix credentials and re-render: `sudo deploy/monitoring/install_monitoring.sh --domain <domain> --only alertmanager`. Watch the Alertmanager UI for firing pages meanwhile.
**Escalation:** platform-oncall (this alert itself may be routed to the broken receiver — the dead man's switch and Slack are the backups).
