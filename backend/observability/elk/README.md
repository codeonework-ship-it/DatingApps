# Local ELK for Dating App

This stack ingests backend logs from `backend/.run/logs/*.log` into Elasticsearch and exposes Kibana.

## Services

- Elasticsearch: `http://localhost:9200`
- Logstash (Beats input): `localhost:5044`
- Kibana: `http://localhost:5601`

## Start / Stop (No Docker)

From `backend/`:

```bash
make elk-up-local
make elk-status-local
make elk-down-local
```

This uses local binaries from your machine (`elasticsearch`, `logstash`, `kibana`, `filebeat`).

### Prerequisites (macOS)

Install local binaries (example via Homebrew):

```bash
brew tap elastic/tap
brew install elastic/tap/elasticsearch-full elastic/tap/logstash-full elastic/tap/kibana-full elastic/tap/filebeat-full
```

Verify they are available on `PATH`:

```bash
for bin in elasticsearch logstash kibana filebeat; do command -v "$bin"; done
```

If binaries are not on `PATH`, set explicit paths:

```bash
export ELASTICSEARCH_BIN=/absolute/path/to/elasticsearch
export LOGSTASH_BIN=/absolute/path/to/logstash
export KIBANA_BIN=/absolute/path/to/kibana
export FILEBEAT_BIN=/absolute/path/to/filebeat
make elk-up-local
```

Logs and runtime data are written under `backend/.run/elk/`.

## Start / Stop (Docker, optional)

From `backend/`:

```bash
make elk-up
make elk-logs
make elk-down
```

Or directly:

```bash
docker compose -f observability/elk/docker-compose.yml up -d
```

## Index pattern

Logs are indexed as:

- `dating-app-logs-YYYY.MM.DD`

In Kibana Discover, use data view pattern:

- `dating-app-logs-*`

## Personalized dashboard from control panel

Set in `control-panel/.env`:

- `KIBANA_BASE_URL=http://localhost:5601`
- `KIBANA_DISCOVER_INDEX=dating-app-logs-*`
- `KIBANA_DASHBOARD_PATH=/app/dashboards`

Then open Control Panel dashboard and pass `?user_id=<uuid>` to prefilter Discover KQL.
