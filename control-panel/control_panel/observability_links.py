"""Deep links from the operator console into the logs/metrics backend.

LOGS_BACKEND selects where "View logs" points:
  * "loki"   - Grafana Explore on the Loki datasource (production VPS,
               documents/MONITORING_AND_OBSERVABILITY_2026-10-01.md)
  * "kibana" - Kibana Discover (the local ELK stack in backend/observability/elk)
"""

from __future__ import annotations

import json
import re
from urllib.parse import quote, quote_plus

from django.conf import settings

# Member ids are UUIDs; anything else is not interpolated into a query.
_SAFE_ID = re.compile(r"^[A-Za-z0-9_-]{1,64}$")

LOKI_DATASOURCE_UID = "verified-dating-loki"
API_DASHBOARD_UID = "connect-api-overview"


def _grafana_explore_url(base: str, focus_user_id: str) -> str:
    expr = '{unit=~"connect.*"} | json'
    if focus_user_id and _SAFE_ID.match(focus_user_id):
        expr += f' |= "{focus_user_id}"'
    panes = {
        "a": {
            "datasource": LOKI_DATASOURCE_UID,
            "queries": [
                {"refId": "A", "expr": expr, "datasource": {"type": "loki", "uid": LOKI_DATASOURCE_UID}}
            ],
            "range": {"from": "now-24h", "to": "now"},
        }
    }
    return f"{base}/explore?schemaVersion=1&orgId=1&panes={quote(json.dumps(panes, separators=(',', ':')))}"


def observability_links(focus_user_id: str) -> dict:
    backend = (getattr(settings, "LOGS_BACKEND", "kibana") or "kibana").strip().lower()
    focus_user_id = (focus_user_id or "").strip()
    grafana = (getattr(settings, "GRAFANA_BASE_URL", "") or "").rstrip("/")

    if backend == "loki" and grafana:
        return {
            "logs_backend": "loki",
            "logs_label": "Logs (Grafana / Loki)",
            "logs_url": _grafana_explore_url(grafana, focus_user_id),
            "dashboards_label": "Grafana dashboards",
            "dashboards_url": f"{grafana}/d/{API_DASHBOARD_UID}",
            "logs_query": "",
        }

    kql = "*"
    if focus_user_id and _SAFE_ID.match(focus_user_id):
        kql = f'user_id : "{focus_user_id}" or userId : "{focus_user_id}"'
    base = settings.KIBANA_BASE_URL
    return {
        "logs_backend": "kibana",
        "logs_label": "Kibana Discover",
        "logs_url": (
            f"{base}/app/discover#/?_g=(time:(from:now-24h,to:now))"
            f"&_a=(query:(language:kuery,query:'{quote_plus(kql)}'))"
        ),
        "dashboards_label": "Dashboards",
        "dashboards_url": (
            f"{base}{settings.KIBANA_DASHBOARD_PATH}"
            f"?_g=(time:(from:now-24h,to:now))&user_id={quote_plus(focus_user_id)}"
        ),
        "logs_query": kql,
    }
