"""Live console updates: what the ``/ws/live/`` socket pushes.

Every topic is read from the Go BFF with the connected operator's own
session, so Go's role checks apply exactly as they do to a page load; a topic
the operator's role cannot read is simply left out. ``consumers.py`` runs these
builders on asyncio and pushes a topic only when its payload changed.

Topics:
  ``nav``        open-item counts for the sidebar's queue links, the BFF
                 health badge, and the open SOS ids (for the new-SOS alert).
                 Every console page subscribes to it.
  ``dashboard``  the command center's live region, rendered from the same
                 snapshot the page itself renders.
"""
from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from datetime import timedelta
from typing import Any, Callable

from django.template.loader import render_to_string

from .operator_access import nav_visibility
from .services.go_client import GoBFFClient
from .views import _queue_status, dashboard_snapshot

TOPICS = frozenset({"nav", "dashboard"})

# How often each topic is re-read while a page is open and visible.
INTERVAL_SECONDS = {"nav": 15, "dashboard": 15}


@dataclass(frozen=True)
class Queue:
    key: str
    url_name: str  # the sidebar link (and nav_visibility key) it belongs to
    fetch: Callable[[GoBFFClient], Any]
    items_key: str
    open_statuses: frozenset[str]
    target: timedelta
    created_field: str = "created_at"
    deadline_field: str = ""


QUEUES = (
    Queue("sos", "safety_sos", lambda c: c.list_sos_alerts(), "alerts",
          frozenset({"active", "open", "acknowledged"}), timedelta(minutes=5), "triggered_at"),
    Queue("reports", "moderation_reports", lambda c: c.list_reports(limit=100), "reports",
          frozenset({"pending", "under_review", "open"}), timedelta(hours=24)),
    Queue("appeals", "appeal_queue", lambda c: c.list_appeals(limit=100), "appeals",
          frozenset({"submitted", "under_review"}), timedelta(hours=48), deadline_field="sla_deadline_at"),
    Queue("verifications", "verification_queue", lambda c: c.list_verifications(status="pending", limit=100),
          "verifications", frozenset({"pending"}), timedelta(hours=24), "submitted_at"),
    Queue("media", "media_moderation_queue", lambda c: c.list_media_moderation(status="review_required", limit=100),
          "items", frozenset({"review_required", "pending"}), timedelta(hours=24), "uploaded_at"),
    Queue("recovery", "account_recovery_queue", lambda c: c.list_account_recovery(status="open"), "requests",
          frozenset({"open"}), timedelta(hours=24)),
)


def _int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def nav_snapshot(client: GoBFFClient, roles: list[str] | None) -> dict:
    """Open counts for every queue link the operator's sidebar shows."""
    visible = nav_visibility(roles)
    health = client.health()
    queues: dict[str, dict] = {}
    sos_open_ids: list[str] = []
    for queue in QUEUES:
        if not visible.get(queue.url_name, True):
            continue
        result = queue.fetch(client)
        if not result.ok or not isinstance(result.data, dict):
            continue  # 403 for this role, or unavailable: no badge
        items = [i for i in result.data.get(queue.items_key) or [] if isinstance(i, dict)]
        status = _queue_status(
            label=queue.key, items=items, url_name=queue.url_name, open_statuses=set(queue.open_statuses),
            target=queue.target, created_field=queue.created_field, deadline_field=queue.deadline_field,
        )
        queues[queue.url_name] = {"count": status["count"], "overdue": status["overdue"], "capped": len(items) >= 100}
        if queue.key == "sos":
            sos_open_ids = sorted(
                str(i.get("id") or i.get("alert_id") or "") for i in items
                if str(i.get("status") or "").lower() in queue.open_statuses
            )
    if visible.get("support_queue", True):
        support = client.support_dashboard(days=30)
        data = support.data if support.ok and isinstance(support.data, dict) else None
        if data is not None:
            by_status = data.get("open_by_status") if isinstance(data.get("open_by_status"), dict) else {}
            breaches = data.get("breaches") if isinstance(data.get("breaches"), dict) else {}
            queues["support_queue"] = {
                "count": _int(by_status.get("new")) + _int(by_status.get("open")),
                "overdue": _int(breaches.get("first_response")) + _int(breaches.get("resolution")),
                "capped": False,
            }
    return {
        "bff_ok": bool(health.ok and isinstance(health.data, dict) and health.data.get("status") == "ok"),
        "queues": queues,
        "sos_open_ids": [i for i in sos_open_ids if i],
    }


def dashboard_region(client: GoBFFClient) -> dict:
    snapshot = dashboard_snapshot(client)
    html = render_to_string("control_panel/dashboard/_live.html", snapshot)
    return {"html": html, "stamp": f"Snapshot {snapshot['snapshot_at']:%b %d, %H:%M:%S} UTC."}


def build(topic: str, client: GoBFFClient, roles: list[str] | None) -> dict:
    if topic == "nav":
        return nav_snapshot(client, roles)
    if topic == "dashboard":
        return dashboard_region(client)
    raise ValueError(f"unknown live topic {topic!r}")


def fingerprint(topic: str, payload: dict) -> str:
    """What decides whether a payload is worth pushing. The dashboard's
    snapshot stamp changes every read, so it is left out."""
    body = dict(payload)
    body.pop("stamp", None)
    return hashlib.sha256(json.dumps(body, sort_keys=True, default=str).encode()).hexdigest()
