# Monitoring and observability — 2026-10-01

How Connect is monitored in production on a single Ubuntu VPS: what the
services expose, how metrics, logs and alerts are collected, what each
dashboard shows, the SLOs, and the on-call checklist. Per-alert procedures are
in `documents/MONITORING_RUNBOOKS_2026-10-01.md`.

## 1. Architecture

```
                      Internet
                         │ 443 (nginx: /metrics denied, /readyz loopback only,
                         │      optional /grafana/ behind allowlist + basic auth)
   ┌─────────────────────┼────────────────────────────── Ubuntu VPS ───────────────┐
   │  nginx ──► api-gateway :8080 ──► mobile-bff :8081 ──► gRPC svcs :9091-9094      │
   │              │ /metrics            │ /metrics, /debug     │ admin :10091-10094   │
   │              ▼                     ▼                      ▼  (/metrics,/healthz) │
   │        ┌──────────── Prometheus 127.0.0.1:9090 (30d / 20GB) ────────────┐      │
   │        │ scrapes: app, node_exporter :9100, postgres_exporter :9187,     │      │
   │        │ blackbox :9115 (public https, TLS expiry, WebSocket, readiness) │      │
   │        └──────┬───────────────────────────────┬──────────────────────────┘      │
   │               │ alerts                        │ queries                         │
   │        Alertmanager 127.0.0.1:9193      Grafana 127.0.0.1:3000 ◄── Loki :3100   │
   │          │ page / ticket / watchdog                                 ▲            │
   │          ▼                                                Alloy (journald, nginx │
   │  PagerDuty-compatible webhook, Slack, email,               error log)            │
   │  dead man's switch (all outbound HTTPS/SMTP)                                     │
   └──────────────────────────────────────────────────────────────────────────────────┘
```

Design choices:

* **Everything listens on loopback.** Operators reach Prometheus/Alertmanager
  through an SSH tunnel; only Grafana may be published, behind an IP allowlist,
  nginx basic auth and Grafana's own login.
* **Upstream Prometheus binaries with our own hardened units** (`deploy/monitoring/systemd`),
  pinned in `deploy/monitoring/versions.env` and verified against each
  release's `sha256sums.txt`. Grafana, Loki and Alloy come from the signed
  Grafana APT repository with drop-ins.
* **Port clash avoided:** Alertmanager's defaults (9093/9094) are taken by the
  matching/chat gRPC servers, so Alertmanager runs on **9193** with clustering
  disabled.
* **Logs: Loki + Grafana Alloy** (chosen over the ELK stack for a single VPS:
  ~300 MB RAM instead of several GB for Elasticsearch, same Grafana UI,
  journald-native). Retention 14 days because logs carry member ids. The
  ELK compose stack in `backend/observability/elk` stays for local development
  only; the operator console's log link is configurable (§7).
  (Promtail is end-of-life; Alloy is its replacement.)

## 2. What the services expose

All application metrics use the `verified_dating_` prefix and are registered
per process — each binary registers only the collectors it updates, so no
process exports a misleading zero gauge (the gateway used to export
notification/SOS/progression gauges stuck at 0, which kept the push-SLO alert
firing and stopped the SOS `absent()` alert from ever working).

| Process | Endpoint | Collectors |
|---|---|---|
| api-gateway | `127.0.0.1:8080/metrics` | HTTP RED (`service="api_gateway"`), realtime connections, build info |
| mobile-bff | `127.0.0.1:8081/metrics` | HTTP RED (`service="mobile_bff"`), realtime, reliability, notification, progression, SOS, queues, workers, DB pools, build info |
| auth/profile/matching/chat | `127.0.0.1:1009{1..4}/metrics` | gRPC requests/latency, DB pools, build info |

### Metric catalogue (new on 2026-10-01 unless noted)

**HTTP RED** — labels `service`, `method` (known verbs or `OTHER`), `route`
(the chi route template, e.g. `/v1/profile/{userID}`; `unmatched` when no route
resolved — scanners never create series; `other` after 1000 distinct templates),
`status_class` (`1xx`..`5xx`):

* `verified_dating_http_requests_total{service,method,route,status_class}`
* `verified_dating_http_request_duration_seconds{service,method,route}` (WebSocket lifetimes excluded)
* `verified_dating_http_responses_by_code_total{service,code}` (exact codes, no route)
* `verified_dating_http_in_flight_requests{service}`

**Realtime**: `verified_dating_realtime_connections{service,route}`,
`verified_dating_realtime_connections_opened_total`,
`verified_dating_realtime_connection_duration_seconds` (tracked automatically
when a handler hijacks the connection), `verified_dating_realtime_delivery_lag_seconds{stream="chat"}`
(written → pushed to a connected socket, live events only). Chat send rate is a
recording rule over the RED metrics: `verified_dating:chat_sends:rate5m`.

**Workers** (helper `observability.NewHeartbeat(name, interval)`; every BFF background loop is instrumented):
`verified_dating_worker_last_success_timestamp_seconds{worker}`,
`_last_run_timestamp_seconds`, `_expected_interval_seconds`,
`_runs_total{worker,result}`, `_run_duration_seconds`, `_items_total{worker,outcome}`,
`_backlog{worker}`.

| worker | interval | what it does | backlog |
|---|---|---|---|
| `account_erasure` | `ACCOUNT_ERASURE_*` poll (1h default) | completes scheduled deletions, prunes exports | – |
| `media_cleanup` | 1h | deletes expired/orphaned media | – |
| `billing_renewal_sweep` | `BILLING_RENEWAL_SWEEP_SECONDS` (5m) | expires lapsed subscriptions/checkouts | – |
| `date_plan_sweep` | 5m | date-plan expiry/reminders, friend intros | – |
| `xp_award_spool_replay` | 30s | replays spooled XP awards | – |
| `notification_delivery` | `NOTIFICATION_*` poll | push/in-app outbox | queue depth |
| `level_projection` | 200ms | XP projection outbox | queue depth |
| `trust_retention` | 1h | trust retention + identity evidence purge | – |
| `sos_gauge_refresh` | 30s | SOS delivery gauges | – |
| `sos_delivery` | `SOS_DELIVERY_POLL_INTERVAL_MS` | SOS contact delivery | queue depth |
| `idempotency_retention` | 5m | archives expired idempotency records | retention backlog |

The analytics snapshot worker being added in parallel should call
`observability.NewHeartbeat("analytics_snapshot", interval)` the same way; the
generic staleness alerts then cover it with no rule change.

**Queues**: `verified_dating_queue_{depth,capacity,enqueued_total,processed_total,dropped_total,max_lag_seconds}{queue="activity_fanout"}`
(previously only in the admin JSON).

**DB pools** (every pgx and database/sql pool, named by the opening package/file
or `Options.PoolName`): `verified_dating_db_pool_{max,open,in_use,idle}_connections{pool}`,
`_wait_total`, `_wait_seconds_total`, `_instances`. Pools: `dataaccess/runtime_store`,
`mobile/profile_repository`, `mobile/terms_repository`, `auth/postgres_repository`.

**Build**: `verified_dating_build_info{service,version,commit,go_version} 1`.
Stamp versions at build time:

```bash
V=$(git describe --tags --always) C=$(git rev-parse --short=12 HEAD)
go build -trimpath -ldflags "-X github.com/verified-dating/backend/internal/platform/observability.Version=$V \
  -X github.com/verified-dating/backend/internal/platform/observability.Commit=$C" -o /tmp/connect-$s ./cmd/$s
```
(Without ldflags the Go toolchain's embedded VCS revision is used.)

**Existing (kept)**: reliability (`timeouts`, `idempotency_*`, `requests_shed_total`,
`postgres_*_connections`), notification (now plus `push_attempts_15m`),
progression, SOS, trust retention, gRPC.

**Exporters**: node_exporter (host, filesystems, systemd unit states, textfile),
postgres_exporter (as the `connect_monitor` role with `pg_monitor`), blackbox
(probes), and the `connect-disk-usage.timer` textfile:
`verified_dating_disk_{avail,size}_bytes{path_role="media|postgres"}`,
`verified_dating_media_bytes{area}`, `verified_dating_disk_usage_report_timestamp_seconds`.

**Logs**: zap JSON on stdout → journald → Alloy → Loki. Every request line has
`service`, `method`, `path` (redacted by the logging work), `route`, `status`,
`duration_seconds` and `correlation_id` (also returned in `X-Correlation-ID`).

## 3. SLOs

| SLO | Target | Measured on | Alerting |
|---|---|---|---|
| API availability per route | 99.5% non-5xx / 30 days | `mobile_bff` routes, excluding `/metrics`, `/healthz`, `/readyz`, `/debug`, docs, `unmatched`, upgrades | multi-window burn: page 14.4× (1h & 5m) and 6× (6h & 30m), ticket 3× (1d & 2h); min. 0.01 req/s |
| Edge availability | 99.5% | gateway, all routes | same burn rates (`VerifiedDatingEdgeAvailabilityBurn`) |
| API latency per route | 99% < 1 s / 30 days | `mobile_bff`, excluding upload/media/verification/export routes | same burn rates |
| Upload latency | p95 < 10 s | photo/cover/evidence/voice/export routes | ticket |
| Push delivery | ≥ 99% success / 15 min | ≥ 20 attempts | page |
| Notification freshness | oldest pending < 30 s | outbox | page |
| SOS delivery | nothing overdue, nothing dead-lettered, oldest < 2 min | SOS outbox | page |
| Realtime delivery | p95 < 5 s | live chat events | ticket |
| Workers | last success < max(3× interval, 5 min) | heartbeats | page (SOS/notification/XP) or ticket |
| Uptime | public `/healthz`, `/`, WebSocket route | blackbox every 15 s | page after 2–5 min |

Recording rules (`verified_dating:http_*:rate{5m,30m,1h,6h,2h,1d}`) live in
`backend/observability/prometheus/rules/api-slo.yml`.

## 4. Alerts

62 alerts in `backend/observability/prometheus/rules/`:
`api-slo.yml` (per-route burn rates), `reliability-10m.yml` (fixed for the split
metrics; push SLO now requires volume; pool saturation covers every pool),
`workers-queues.yml` (staleness, errors, erasure failures, fan-out drops,
realtime drops/short-lived sockets/delivery lag), `safety-trust.yml` (SOS),
`progression-production.yml`, `platform.yml` (targets, restarts, systemd,
PostgreSQL, disks, memory/CPU/OOM, uptime, TLS, readiness, watchdog, monitoring
self-health). Every alert has `severity` (page/ticket/none), `owner`, `summary`,
`description` and `runbook_url` → `documents/MONITORING_RUNBOOKS_2026-10-01.md#<alertname lowercased>`.

Alertmanager (`backend/observability/alertmanager/`): `severity=page` →
`oncall-page` (PagerDuty Events v2 and/or any webhook pager + Slack),
`severity=ticket` → `engineering-ticket` (webhook + Slack + email),
`VerifiedDatingWatchdog` → `deadmans-switch`. Inhibitions: pages suppress
matching tickets; `PostgresDown` suppresses pool/worker/route symptoms; a BFF
`TargetDown` suppresses its stale-gauge alerts. Unset channels are left out of
the rendered config, so you can start with webhooks only.

## 5. Dashboards (Grafana, one folder each)

| Folder / dashboard | uid | Shows |
|---|---|---|
| Connect · API / *API overview (RED per route)* | `connect-api-overview` | rps, 5xx ratio, p95, in-flight, 30-day error budget left, unmatched traffic; status classes; latency percentiles; top 10 routes by traffic / p95 / 5xx / 4xx; 1h route table; burn rates; bulkheads, timeouts, 429/5xx codes, pool utilisation, goroutines, memory, CPU; running builds; Loki error log. Variables: service, route |
| Connect · API / *Reliability guardrails* (existing, fixed) | `verified-dating-reliability` | timeouts, shedding, idempotency, notification queue, push SLO, pools |
| Connect · Workers & queues | `connect-workers-queues` | heartbeat age vs threshold, runs by result, duration p95, items, backlogs; notification outbox/push; SOS; XP projection; trust retention; idempotency; erasure items; fan-out queue fill/drops/lag; worker warnings from Loki |
| Connect · Realtime & chat | `connect-realtime-chat` | open sockets by stream, opens/s, lifetime p50/p95, short-lived ratio, live delivery lag, chat sends/s, chat send status and p95, fan-out |
| Connect · Database | `connect-database` | up, connections vs max, DB size, cache hit, deadlocks, data-disk free; TPS, connections by state, longest transaction, row throughput, locks, temp bytes; application pool in-use/max and wait |
| Connect · Host & uptime | `connect-host` | probe status/duration, TLS days left, failed units, media bytes; media/postgres filesystem free; per-mount free; disk busy; CPU, load, memory/swap, network, OOM kills |
| Connect · Product health / *Progression production* (existing) | `verified-dating-progression` | XP projection queue, lag, p95, dead letters, fraud cases, cap denials |

Provisioning (`backend/observability/grafana/provisioning/`) creates one
provider per directory under `${GRAFANA_DASHBOARDS_DIR}` (default
`/var/lib/grafana/dashboards/connect/<dir>`); the installer copies only the
committed JSON there (the old provider pointed at a relative path in the
checkout and would have loaded anything in it). UI edits are not saved
(`allowUiUpdates: false`): export JSON and commit.

## 6. Installing on Ubuntu (22.04 / 24.04)

Prerequisites: the app is installed per `documents/MEDIA_STORAGE_VPS_AND_S3_2026-10-01.md`
§5, the checkout is at `/opt/connect/src`, and `/etc/connect/connect.env` binds
every listener to loopback:

```
API_GATEWAY_ADDR=127.0.0.1:8080
MOBILE_BFF_ADDR=127.0.0.1:8081
AUTH_SVC_GRPC_ADDR=127.0.0.1:9091      AUTH_SVC_ADMIN_ADDR=127.0.0.1:10091
PROFILE_SVC_GRPC_ADDR=127.0.0.1:9092   PROFILE_SVC_ADMIN_ADDR=127.0.0.1:10092
MATCHING_SVC_GRPC_ADDR=127.0.0.1:9093  MATCHING_SVC_ADMIN_ADDR=127.0.0.1:10093
CHAT_SVC_GRPC_ADDR=127.0.0.1:9094      CHAT_SVC_ADMIN_ADDR=127.0.0.1:10094
```
(the defaults `:909x`/`:1009x` listen on all interfaces; the BFF also serves
`/debug/pprof` on its port, so it must stay on loopback). Keep a host firewall:
`sudo ufw default deny incoming && sudo ufw allow OpenSSH && sudo ufw allow 'Nginx Full' && sudo ufw enable`.

```bash
cd /opt/connect/src
# 1) PostgreSQL monitoring role (pg_monitor, read-only, 3 connections)
PW=$(openssl rand -base64 30)
sudo -u postgres psql -v ON_ERROR_STOP=1 -v monitor_password="$PW" -v app_db=dating_app \
     -f deploy/monitoring/postgres/create_monitoring_role.sql

# 2) preview, then install Prometheus, Alertmanager, exporters (+ Grafana, Loki/Alloy)
sudo deploy/monitoring/install_monitoring.sh --domain connect.example.com --with-grafana --with-loki --dry-run
sudo deploy/monitoring/install_monitoring.sh --domain connect.example.com --with-grafana --with-loki
#    first run stops after creating /etc/connect-monitoring/alertmanager.env from the example:
sudo editor /etc/connect-monitoring/alertmanager.env          # receivers, dead man's switch, RUNBOOK_BASE_URL
sudo editor /etc/connect-monitoring/postgres_exporter.env     # DATA_SOURCE_NAME with $PW
sudo deploy/monitoring/install_monitoring.sh --domain connect.example.com --with-grafana --with-loki

# 3) optional: Grafana at https://connect.example.com/grafana/
sudo apt-get install -y apache2-utils
sudo htpasswd -B -c /etc/nginx/connect-grafana.htpasswd <operator>
sudo install -m 0644 deploy/nginx/snippets/connect-grafana.conf /etc/nginx/snippets/connect-grafana.conf
sudo editor /etc/nginx/snippets/connect-grafana.conf           # allow <office/VPN IPs>
sudo editor /etc/nginx/sites-available/connect.conf            # uncomment the include line
sudo nginx -t && sudo systemctl reload nginx
sudo cat /etc/connect-monitoring/grafana_admin_password        # first Grafana login, then create named users

# 4) verify
ssh -L 9090:127.0.0.1:9090 <vps>   # http://localhost:9090/targets: all UP; /alerts: only Watchdog firing
```

Re-apply one part after a change: `--only rules` (after editing rules),
`--only dashboards`, `--only alertmanager` (after editing receivers),
`--only exporters`, `--only prometheus`, `--only grafana`, `--only loki`.
Upgrades: bump `deploy/monitoring/versions.env` and re-run.

Retention and sizing (defaults): Prometheus 30 days capped at 20 GB
(`/etc/connect-monitoring/prometheus.env`); Alertmanager 120 h of silences/
notification log; Loki 14 days (`deploy/monitoring/loki/loki.yml`). Expect
~1–2 GB/month of Prometheus data at current cardinality and ~0.5 GB RAM for the
whole stack without Loki, ~1 GB with it.

## 7. Operator console log link

`control-panel` builds its "Observability workspace" links from
`control_panel/observability_links.py`:

* `LOGS_BACKEND=kibana` (default, local ELK) — uses `KIBANA_BASE_URL`.
* `LOGS_BACKEND=loki` + `GRAFANA_BASE_URL=https://<domain>/grafana` — opens
  Grafana Explore on Loki (`{unit=~"connect.*"} | json`, with a line filter for
  the focused member id when one is given) and the API overview dashboard.

Member ids are only interpolated when they look like ids, so the focus field
cannot inject KQL/LogQL.

## 8. On-call setup checklist

- [ ] Paging receiver created (PagerDuty service with Events v2 key, or another pager's Alertmanager webhook) and set in `alertmanager.env`.
- [ ] Ticket destination (Slack channel webhook and/or email via an SMTP relay with TLS) set.
- [ ] Dead man's switch (healthchecks.io or similar, 1-minute period, 5-minute grace) receiving `VerifiedDatingWatchdog`, alerting a different channel than Alertmanager.
- [ ] `RUNBOOK_BASE_URL` points at the repository so runbook links work from a phone.
- [ ] Primary and secondary on-call named for each owner (`backend-oncall`, `platform-oncall`, `trust-safety-oncall`, `progression-oncall`), rotation scheduled, escalation contacts written into the pager.
- [ ] Trust & safety has a manual SOS outreach procedure and is paged by SOS alerts directly.
- [ ] Test the path end to end: `amtool --alertmanager.url=http://127.0.0.1:9193 alert add TestPage severity=page owner=platform-oncall --annotation=summary="test page"` → the pager rings; resolve it.
- [ ] Stop `connect-postgres-exporter` for 2 minutes in a quiet window → `VerifiedDatingPostgresDown` pages; start it again.
- [ ] Grafana admin password rotated, named accounts created, `/grafana/` allowlist limited to office/VPN.
- [ ] Backups of `/var/lib/connect-monitoring/prometheus` are **not** required (metrics are disposable); the rules, dashboards and configs live in git.
- [ ] Review alert noise weekly for the first month; tune thresholds in git, never with permanent silences.

## 9. Testing and validation

* `go test ./internal/platform/observability/` covers route-template labelling
  (bounded cardinality, `unmatched`, overflow), the gateway/BFF registry split,
  WebSocket accounting, worker heartbeats, pool and queue collectors, and
  validates every rule file (YAML, severity/owner/summary/description/runbook,
  every referenced metric exists in code, a recording rule or the textfile
  script, every selected job is scraped), the Prometheus config (loopback
  targets) and every dashboard (valid JSON, unique uids, provisioned folder,
  known datasources and metrics).
* With promtool available: `promtool check rules backend/observability/prometheus/rules/*.yml`
  and `promtool check config` (the installer runs the latter, and the
  Prometheus/Alertmanager units refuse to start on an invalid config).

## 10. Owner actions still required

1. **Alert receivers**: pager (PagerDuty routing key or webhook URL), Slack
   webhook/channels, SMTP relay + address, dead man's switch URL.
2. **Domain** for blackbox probes (and optionally a `monitoring.` host name
   with its certificate), plus office/VPN IPs for the Grafana allowlist.
3. **Credentials**: the `connect_monitor` PostgreSQL password, Grafana admin
   (generated) and basic-auth users.
4. **On-call people** for the four owner groups and the escalation chain.
5. Optional: confirm the database name (`dating_app`) and PostgreSQL data path
   (`/var/lib/postgresql`) match the server; adjust
   `deploy/monitoring/systemd/connect-disk-usage.service` if not.
6. Database backups are not covered by these alerts yet: add a freshness
   metric (e.g. the backup job writing a textfile timestamp) once the backup
   job is defined.
