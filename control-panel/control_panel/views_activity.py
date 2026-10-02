"""Member activity: every member action, in detail, with a live tail.

Go records each action once (backend M/admin_member_activity.go): the
request itself (who, what, when, from which device and IP, on which entity,
with what outcome), the named events and security events it caused, and the
domain events of the rows it changed. This page lists them with server-side
search, filters and paging, exports them to Excel, and streams new ones over
the console's live socket (topic ``activity``).
"""
from __future__ import annotations

from django.http import HttpRequest, HttpResponse
from django.views.decorators.http import require_GET

from . import listing
from .services.go_client import GoBFFClient
from .views import _base_context

CATEGORIES = ("Auth", "Profile", "Discovery", "Matches & chat", "Dates", "Social", "Safety",
              "Billing & coins", "Engagement", "Support", "Settings", "Other")
# Without a choice the log shows what members did (requests, named events,
# security events); the database's row-change events are one choice away.
ACTION_SOURCES = "request,event,security"
SOURCES = (("actions", "Member actions"), ("request", "Member requests"), ("event", "Named events"), ("security", "Security events"),
           ("domain", "Data changes"), ("all", "Everything, incl. data changes"))
OUTCOMES = (("success", "Succeeded"), ("client_error", "Refused (4xx)"), ("server_error", "Failed (5xx)"))
METHODS = tuple((m, m) for m in ("POST", "PUT", "PATCH", "DELETE", "GET"))

C = listing.Column


def _details(row: dict) -> str:
    details = row.get("details")
    if not isinstance(details, dict):
        return ""
    return ", ".join(f"{k}: {v}" for k, v in sorted(details.items()) if v not in (None, "", [], {}))


ACTIVITY_LIST = listing.ListSpec(
    name="member-activity", search_label="Search action or route", default_page_size=50,
    filters=(
        listing.Filter("member", "Member ID", kind="text", max_length=36),
        listing.Filter("category", "Area", tuple((c, c) for c in CATEGORIES)),
        listing.Filter("action", "Action key", kind="text", max_length=80),
        listing.Filter("outcome", "Outcome", OUTCOMES),
        listing.Filter("source", "Source", SOURCES, allow_all=False),
        listing.Filter("method", "Method", METHODS),
        listing.Filter("include_reads", "Include reads", (("true", "Yes"),)),
        listing.Filter("from", "From (UTC)", kind="date"),
        listing.Filter("to", "To (UTC)", kind="date"),
    ),
    columns=(
        C("at", "Time (UTC)", width=24), C("member_id", "Member ID", width=38), C("actor_id", "Actor ID", width=38),
        C("actor_role", "Actor role"), C("category", "Area", width=16), C("action_label", "Action", width=34),
        C("action_key", "Action key", width=26), C("source", "Source", width=10), C("method", "Method", width=8),
        C("route", "Route", width=36), C("status_code", "Status", width=8), C("outcome", "Outcome", width=12),
        C("duration_ms", "Duration (ms)", width=10), C("entity_type", "Entity", width=16), C("entity_id", "Entity ID", width=38),
        C("ip", "IP address", width=16), C("device_id", "Device ID", width=38), C("platform", "Platform", width=10),
        C("app_version", "App version", width=10), C("user_agent", "User agent", width=40),
        C("session_id", "Session ID", width=38), C("request_id", "Request ID", width=38),
        C("correlation_id", "Correlation ID", width=38), C("details", "Details", _details, width=60),
    ),
)


@require_GET
def member_activity(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()

    def go(query: listing.ListQuery) -> dict:
        params = query.go_params()
        if params.get("source") in (None, "", "actions"):
            params["source"] = ACTION_SOURCES
        return params

    def extra(page: listing.Page, data: dict) -> dict:
        f = page.query.filters
        return {
            "total_capped": bool(data.get("total_capped")),
            "live_filters": {k: f.get(k, "") for k in ("member", "category")} | {
                "source": f.get("source") or ACTION_SOURCES, "include_reads": f.get("include_reads") == "true"},
            "member_filter": f.get("member", ""),
        }

    return listing.simple_view(request, ACTIVITY_LIST, client.list_member_actions, items_key="actions",
                               template="control_panel/member_activity.html", title="Member activity",
                               base_context=_base_context, context_name="actions", map_filters=go, extra=extra)


def member_timeline_context(client: GoBFFClient, user_id: str) -> dict:
    """The Activity section of a member's page: summary plus the newest
    actions (first page), linking to the full explorer for this member."""
    result = client.member_activity(user_id, limit=25)
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    return {
        "activity_actions": [a for a in data.get("actions") or [] if isinstance(a, dict)],
        "activity_total": data.get("total"),
        "activity_total_capped": bool(data.get("total_capped")),
        "activity_summary": data.get("summary") if isinstance(data.get("summary"), dict) else {},
        "activity_error": "" if result.ok else (result.error or "Activity is unavailable."),
        "activity_denied": result.status_code == 403,
    }
