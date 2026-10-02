from __future__ import annotations

from datetime import datetime, timedelta, timezone
from urllib.parse import quote_plus

from django.conf import settings
from django.contrib import messages
from django.http import Http404, HttpRequest, HttpResponse
from django.shortcuts import redirect, render
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_GET, require_POST
from django.views.decorators.http import require_http_methods

from . import listing
from .live_sessions import end_session_sockets
from .observability_links import observability_links
from .operator_access import ROLES_SESSION_KEY, resolve_operator_roles
from .services.go_client import GoBFFClient, bff_failure_status
from .views_analytics import durable_dashboard_kpis
from .views_support import dashboard_safety_card


def _base_context(*, include_health: bool = True) -> dict:
    context = {"project_name": settings.PROJECT_DISPLAY_NAME}
    if include_health:
        health = GoBFFClient().health()
        context["health"] = (
            health.data
            if health.ok and isinstance(health.data, dict)
            else {"status": "unreachable"}
        )
    return context


def _bounded_int(value: str, default: int, *, minimum: int = 1, maximum: int = 500) -> int:
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return default
    return min(max(parsed, minimum), maximum)


def _parse_timestamp(value: object) -> datetime | None:
    raw = str(value or "").strip()
    if not raw:
        return None
    try:
        parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _queue_status(
    *,
    label: str,
    items: list[dict],
    url_name: str,
    open_statuses: set[str],
    target: timedelta,
    deadline_field: str = "",
    created_field: str = "created_at",
) -> dict:
    now = datetime.now(timezone.utc)
    open_items = []
    overdue = 0
    oldest_minutes = 0
    for item in items:
        status = str(item.get("status") or "").strip().lower()
        if status not in open_statuses:
            continue
        open_items.append(item)
        created = _parse_timestamp(item.get(created_field) or item.get("submitted_at") or item.get("triggered_at"))
        deadline = _parse_timestamp(item.get(deadline_field)) if deadline_field else None
        if deadline is None and created is not None:
            deadline = created + target
        if deadline is not None and deadline < now:
            overdue += 1
        if created is not None:
            oldest_minutes = max(oldest_minutes, max(0, int((now - created).total_seconds() // 60)))
    return {
        "label": label,
        "count": len(open_items),
        "overdue": overdue,
        "oldest_minutes": oldest_minutes,
        "target": f"{int(target.total_seconds() // 3600)}h" if target >= timedelta(hours=1) else f"{int(target.total_seconds() // 60)}m",
        "url_name": url_name,
        "tone": "danger" if overdue else ("warning" if open_items else "green"),
    }


@require_http_methods(["GET", "POST"])
def operator_login(request: HttpRequest) -> HttpResponse:
    next_path = (request.POST.get("next") or request.GET.get("next") or "/").strip()
    if not next_path.startswith("/") or next_path.startswith("//"):
        next_path = "/"
    error = ""
    if request.method == "POST":
        username = (request.POST.get("username") or "").strip().lower()
        password = request.POST.get("password") or ""
        result = GoBFFClient(use_operator_context=False).login(username, password)
        access_token = str(result.data.get("access_token") or "").strip()
        refresh_token = str(result.data.get("refresh_token") or "").strip()
        user_id = str(result.data.get("user_id") or "").strip()
        if result.ok and access_token and refresh_token and user_id:
            operator_client = GoBFFClient(
                access_token=access_token,
                refresh_token=refresh_token,
                use_operator_context=False,
            )
            probe = operator_client.analytics_overview()
            if probe.ok:
                # Sidebar filtering (CON-05); None means unknown, show every link.
                roles = resolve_operator_roles(operator_client, user_id)
                request.session.cycle_key()
                request.session["operator_access_token"] = access_token
                request.session["operator_refresh_token"] = refresh_token
                request.session["operator_username"] = username
                request.session["operator_user_id"] = user_id
                if roles is None:
                    request.session.pop(ROLES_SESSION_KEY, None)
                else:
                    request.session[ROLES_SESSION_KEY] = roles
                request.session.set_expiry(settings.SESSION_COOKIE_AGE)
                return redirect(next_path)
            error = "This account does not have permission to use the operator console."
        else:
            error = result.error or "Invalid username or password."
    context = _base_context(include_health=False)
    context.update({"error": error, "next": next_path, "login_page": True})
    return render(request, "control_panel/login.html", context)


@require_POST
def operator_logout(request: HttpRequest) -> HttpResponse:
    # POST only (the sidebar submits a CSRF-protected form): a GET logout let
    # any page that links or redirects to /logout/ sign an operator out.
    access_token = str(request.session.get("operator_access_token") or "").strip()
    if access_token:
        GoBFFClient(
            access_token=access_token,
            refresh_token=str(request.session.get("operator_refresh_token") or ""),
            use_operator_context=False,
        ).logout()
    session_key = request.session.session_key
    request.session.flush()
    # Close this session's live sockets in every open tab.
    end_session_sockets(session_key)
    return redirect("operator_login")


# ── Dashboard ─────────────────────────────────────────────────────────────────

def dashboard_snapshot(client: GoBFFClient) -> dict:
    """Everything the dashboard's live region shows, read with the current
    operator's session. The page and the live socket (``live.py``) both
    render from this, so a pushed update is exactly what a reload shows."""
    health = client.health()
    readiness = client.readiness()
    verifications = client.list_verifications(limit=25, status="pending")
    activities = client.list_activities(limit=25)
    analytics = client.analytics_overview()
    users = client.list_users(limit=1)
    reports = client.list_reports(limit=100)
    appeals = client.list_appeals(limit=100)
    media = client.list_media_moderation(status="review_required", limit=100)
    sos = client.list_sos_alerts()
    audits = client.list_audit_events(limit=12)
    domain_events = client.list_domain_events(limit=8)
    event_metrics = client.domain_event_metrics()

    metrics = analytics.data.get("metrics", {}) if analytics.ok else {}
    user_kpis = users.data.get("kpis", {}) if users.ok else {}
    verification_items = verifications.data.get("verifications", []) if verifications.ok else []
    report_items = reports.data.get("reports", []) if reports.ok else []
    appeal_items = appeals.data.get("appeals", []) if appeals.ok else []
    media_items = media.data.get("items", []) if media.ok else []
    sos_items = sos.data.get("alerts", []) if sos.ok else []
    activity_items = activities.data.get("activities", []) if activities.ok else []
    audit_items = audits.data.get("events", []) if audits.ok else []
    domain_event_items = domain_events.data.get("events", []) if domain_events.ok else []
    event_pipeline = event_metrics.data if event_metrics.ok else {}

    queue_cards = [
        _queue_status(label="SOS", items=sos_items, url_name="safety_sos", open_statuses={"active", "open", "acknowledged"}, target=timedelta(minutes=5), created_field="triggered_at"),
        _queue_status(label="Reports", items=report_items, url_name="moderation_reports", open_statuses={"pending", "under_review", "open"}, target=timedelta(hours=24)),
        _queue_status(label="Appeals", items=appeal_items, url_name="appeal_queue", open_statuses={"submitted", "under_review"}, target=timedelta(hours=48), deadline_field="sla_deadline_at"),
        _queue_status(label="Verifications", items=verification_items, url_name="verification_queue", open_statuses={"pending"}, target=timedelta(hours=24), created_field="submitted_at"),
        _queue_status(label="Media review", items=media_items, url_name="media_moderation_queue", open_statuses={"review_required", "pending"}, target=timedelta(hours=24), created_field="uploaded_at"),
    ]
    safety_tickets = dashboard_safety_card(client)
    if safety_tickets:
        queue_cards.append(safety_tickets)

    # Unavailable, never zero, when the durable source cannot answer (KPI contract).
    member_activity = metrics.get("member_activity") or {}
    headline_metrics = [
        {"label": "Total users", "value": user_kpis.get("total"), "unit": "accounts", "window": "Current snapshot", "source": "user_management.users", "available": users.ok},
        {"label": "Active users", "value": user_kpis.get("active"), "unit": "accounts", "window": "Current enforcement state", "source": "user_management.users", "available": users.ok},
        {"label": "Pending reports", "value": metrics.get("pending_reports", len(report_items)), "unit": "cases", "window": "Current queue", "source": "moderation reports", "available": reports.ok or analytics.ok},
        {"label": "Active SOS", "value": metrics.get("active_sos_alerts", len(sos_items)), "unit": "alerts", "window": "Current queue", "source": "safety alerts", "available": sos.ok or analytics.ok},
    ]
    # DAU/MAU come from the durable analytics snapshots (latest completed UTC
    # day) and fall back to the live trailing windows of member_last_activity.
    durable = durable_dashboard_kpis(client)
    durable_tiles = durable["tiles"]
    for key, label, live_window in (("dau", "DAU", "Trailing 24 hours"), ("mau", "MAU", "Trailing 30 days")):
        if key in durable_tiles:
            headline_metrics.append({"label": label, "value": durable_tiles[key]["value"], "unit": "members",
                                     "window": f"UTC day {durable['as_of']}", "source": "analytics snapshots (operators and test accounts excluded)", "available": True})
        else:
            headline_metrics.append({"label": label, "value": member_activity.get(key), "unit": "members", "window": live_window,
                                     "source": "platform.member_last_activity (operators excluded)", "available": bool(member_activity.get("available"))})

    # The runtime funnel counters of /admin/analytics/overview are per BFF
    # instance and reset on restart; the dashboard shows durable KPIs instead.
    product_metrics = [
        {"label": durable_tiles.get(key, {}).get("label") or label, "value": durable_tiles.get(key, {}).get("value"), "unit": "",
         "definition": (durable_tiles.get(key, {}).get("definition") or "") + (f" Week before: {durable_tiles[key]['previous']}." if key in durable_tiles else f" Unavailable: {durable['error']}")}
        for key, label in (
            ("plans_kept_per_active_member", "Weekly plans kept per active member"),
            ("womens_good_day_rate", "Women's weekly good-day rate"),
            ("stickiness", "Stickiness (DAU/MAU)"),
            ("new_members", "New members (7 days)"),
        )
    ]

    return {
        "health": health.data if health.ok else {"status": "unreachable"},
        "health_error": health.error,
        "readiness": readiness.data if readiness.ok else {"status": "unreachable"},
        "readiness_error": readiness.error,
        "pending_verifications": verification_items,
        "verification_error": verifications.error,
        "activities": activity_items,
        "activity_error": activities.error,
        "dashboard_panels": metrics.get("dashboard_panels", []),
        "event_taxonomy": metrics.get("event_taxonomy", {}),
        "data_quality_checks": metrics.get("data_quality_checks", {}),
        "spotlight_metrics": metrics.get("spotlight_metrics", {}),
        "headline_metrics": headline_metrics,
        "product_metrics": product_metrics,
        "queue_cards": queue_cards,
        "audit_events": audit_items,
        "audit_error": audits.error,
        "domain_events": domain_event_items,
        "event_pipeline": event_pipeline,
        "event_error": domain_events.error or event_metrics.error,
        "snapshot_at": datetime.now(timezone.utc),
        "readiness_controls": [
            {"label": "Bearer operator sessions", "status": "implemented", "detail": "Server-side refresh and revocation"},
            {"label": "Role-scoped access", "status": "implemented", "detail": "Admin, ops, trust, moderator, support, analyst, finance"},
            {"label": "Immutable operator audit", "status": "implemented" if audits.ok else "unavailable", "detail": audits.error or "Append-only database evidence"},
            {"label": "Domain-event source coverage", "status": "implemented" if event_pipeline.get("coverage_complete") else "unavailable", "detail": event_metrics.error or f"{event_pipeline.get('registered_sources', 0)} sources · {event_pipeline.get('unregistered_sources', 0)} unregistered"},
            {"label": "SSO / MFA", "status": "deployment_gate", "detail": "Required before deployed operator access"},
            {"label": "Managed production secrets", "status": "deployment_gate", "detail": "Required before deployment"},
            {"label": "Staffed queue escalation", "status": "deployment_gate", "detail": "Primary, backup and paging ownership required"},
        ],
        "analytics_error": analytics.error,
    }


@require_GET
def dashboard(request: HttpRequest) -> HttpResponse:
    # "0" turns live updates off; any other value keeps them on (older links
    # carried a reload interval in seconds).
    live_updates = (request.GET.get("refresh") or "").strip() != "0"
    focus_user_id = (request.GET.get("user_id") or "").strip()
    links = observability_links(focus_user_id)

    context = _base_context(include_health=False)
    context.update(dashboard_snapshot(GoBFFClient()))
    context.update(
        {
            "live_updates": live_updates,
            "focus_user_id": focus_user_id,
            "kibana_discover_index": settings.KIBANA_DISCOVER_INDEX,
            "kibana_kql": links["logs_query"],
            "kibana_discover_url": links["logs_url"],
            "kibana_dashboard_url": links["dashboards_url"],
            "observability_links": links,
        }
    )
    return render(request, "control_panel/dashboard.html", context)


# ── Verifications ─────────────────────────────────────────────────────────────

@require_GET
def verification_queue(request: HttpRequest) -> HttpResponse:
    status = request.GET.get("status", "").strip()
    try:
        limit = int(request.GET.get("limit", "100"))
    except ValueError:
        limit = 100

    client = GoBFFClient()
    result = client.list_verifications(status=status, limit=limit)

    context = _base_context()
    context.update(
        {
            "status_filter": status,
            "limit": limit,
            "verifications": result.data.get("verifications", []) if result.ok else [],
            "error": result.error,
        }
    )
    return render(request, "control_panel/verifications.html", context)


@require_POST
def approve_verification(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.approve_verification(user_id)
    if result.ok:
        messages.success(request, f"Verification approved for {user_id}.")
    else:
        messages.error(request, f"Failed to approve {user_id}: {result.error}")
    return redirect("verification_queue")


@require_POST
def reject_verification(request: HttpRequest, user_id: str) -> HttpResponse:
    reason = (request.POST.get("rejection_reason") or "").strip()
    if not reason:
        messages.error(request, "Rejection reason is required.")
        return redirect("verification_queue")

    client = GoBFFClient()
    result = client.reject_verification(user_id, reason)
    if result.ok:
        messages.success(request, f"Verification rejected for {user_id}.")
    else:
        messages.error(request, f"Failed to reject {user_id}: {result.error}")
    return redirect("verification_queue")


# ── Activity Feed ─────────────────────────────────────────────────────────────

@require_GET
def activity_feed(request: HttpRequest) -> HttpResponse:
    limit = _bounded_int(request.GET.get("limit", "200"), 200, maximum=1000)
    status = (request.GET.get("status") or "").strip().lower()
    action = (request.GET.get("action") or "").strip().lower()
    user_id = (request.GET.get("user_id") or "").strip().lower()

    client = GoBFFClient()
    result = client.list_activities(limit=limit)
    activities = result.data.get("activities", []) if result.ok else []
    if status:
        activities = [item for item in activities if str(item.get("status") or "").lower() == status]
    if action:
        activities = [item for item in activities if action in str(item.get("action") or item.get("event_type") or "").lower()]
    if user_id:
        activities = [item for item in activities if user_id in str(item.get("user_id") or "").lower()]

    context = _base_context()
    context.update(
        {
            "limit": limit,
            "activities": activities,
            "error": result.error,
            "status_filter": status,
            "action_filter": action,
            "user_filter": user_id,
            "snapshot_at": datetime.now(timezone.utc),
        }
    )
    return render(request, "control_panel/activities.html", context)


@require_GET
def audit_log(request: HttpRequest) -> HttpResponse:
    limit = _bounded_int(request.GET.get("limit", "100"), 100)
    filters = {
        "event_type": (request.GET.get("event_type") or "").strip(),
        "actor_user_id": (request.GET.get("actor_user_id") or "").strip(),
        "subject_user_id": (request.GET.get("subject_user_id") or "").strip(),
        "resource_type": (request.GET.get("resource_type") or "").strip(),
    }
    result = GoBFFClient().list_audit_events(limit=limit, **filters)
    context = _base_context()
    context.update(
        {
            "events": result.data.get("events", []) if result.ok else [],
            "source": result.data.get("source", "audit.operator_action_log") if result.ok else "audit.operator_action_log",
            "append_only": result.data.get("append_only", True) if result.ok else True,
            "limit": limit,
            "filters": filters,
            "error": result.error,
            "snapshot_at": datetime.now(timezone.utc),
        }
    )
    return render(request, "control_panel/audit_log.html", context)


@require_GET
def domain_events(request: HttpRequest) -> HttpResponse:
    limit = _bounded_int(request.GET.get("limit", "100"), 100, maximum=500)
    filters = {
        "event_name": (request.GET.get("event_name") or "").strip(),
        "aggregate_type": (request.GET.get("aggregate_type") or "").strip(),
        "aggregate_id": (request.GET.get("aggregate_id") or "").strip(),
        "producer": (request.GET.get("producer") or "").strip(),
        "correlation_id": (request.GET.get("correlation_id") or "").strip(),
        "subject_user_id": (request.GET.get("subject_user_id") or "").strip(),
        "after_sequence": (request.GET.get("after_sequence") or "").strip(),
    }
    client = GoBFFClient()
    result = client.list_domain_events(limit=limit, **filters)
    metrics = client.domain_event_metrics()
    context = _base_context()
    context.update(
        {
            "events": result.data.get("events", []) if result.ok else [],
            "metrics": metrics.data if metrics.ok else {},
            "source": result.data.get("source", "platform.domain_event_outbox") if result.ok else "platform.domain_event_outbox",
            "limit": limit,
            "filters": filters,
            "error": result.error or metrics.error,
            "snapshot_at": datetime.now(timezone.utc),
        }
    )
    return render(request, "control_panel/domain_events.html", context)


# ── Appeals ───────────────────────────────────────────────────────────────────

@require_GET
def appeal_queue(request: HttpRequest) -> HttpResponse:
    status = request.GET.get("status", "").strip()
    try:
        limit = int(request.GET.get("limit", "100"))
    except ValueError:
        limit = 100

    client = GoBFFClient()
    result = client.list_appeals(status=status, limit=limit)

    context = _base_context()
    context.update(
        {
            "status_filter": status,
            "limit": limit,
            "appeals": result.data.get("appeals", []) if result.ok else [],
            "error": result.error,
        }
    )
    return render(request, "control_panel/appeals.html", context)


@require_POST
def action_appeal(request: HttpRequest, appeal_id: str) -> HttpResponse:
    status = (request.POST.get("status") or "").strip()
    resolution_reason = (request.POST.get("resolution_reason") or "").strip()

    if not status:
        messages.error(request, "Appeal status is required.")
        return redirect("appeal_queue")

    client = GoBFFClient()
    result = client.action_appeal(appeal_id, status, resolution_reason, reviewed_by=_operator_reviewer(request))
    if result.ok:
        messages.success(request, f"Appeal {appeal_id} updated to {status}.")
    else:
        messages.error(request, f"Failed to update appeal {appeal_id}: {result.error}")
    return redirect("appeal_queue")


# ── Deferred growth governance (P2 launch register) ─────────────────────────
# Support tickets moved to views_support.py (the /support/ section).

@require_GET
def growth_governance(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    portfolio_result = client.growth_portfolio()
    fraud_result = client.list_growth_fraud_graph(status="open", limit=100)
    context = _base_context()
    context.update(
        {
            "modules": portfolio_result.data.get("modules", []) if portfolio_result.ok else [],
            "fraud_edges": fraud_result.data.get("edges", []) if fraud_result.ok else [],
            "error": portfolio_result.error or fraud_result.error,
        }
    )
    return render(request, "control_panel/growth_governance.html", context)


# ── Moderation Reports ────────────────────────────────────────────────────────

@require_GET
def moderation_reports(request: HttpRequest) -> HttpResponse:
    status = request.GET.get("status", "").strip()
    try:
        limit = int(request.GET.get("limit", "100"))
    except ValueError:
        limit = 100

    client = GoBFFClient()
    result = client.list_reports(status=status, limit=limit)

    context = _base_context()
    context.update(
        {
            "status_filter": status,
            "reports": result.data.get("reports", []) if result.ok else [],
            "error": result.error,
        }
    )
    return render(request, "control_panel/moderation_reports.html", context)


# Console report actions -> the report status Go records (under_review,
# resolved or rejected) and what the operator is told. Go requires a status;
# the console used to send only the action, so every report action failed
# with "status is required".
REPORT_ACTIONS = {
    "under_review": ("under_review", "moved to under review"),
    "warn": ("resolved", "resolved with a warning to the reported member"),
    "suspend_reported": ("resolved", "resolved as needing a suspension"),
    "ban_reported": ("resolved", "resolved as needing a ban"),
    "dismiss": ("rejected", "dismissed"),
}


def _operator_reviewer(request: HttpRequest) -> str:
    """The signed-in operator's id. Go only fills the reviewer from the
    session for the admin role and otherwise falls back to a label that its
    UUID column rejects, so moderators' decisions failed without it."""
    return str(request.session.get("operator_user_id") or "").strip()


@require_POST
def action_report(request: HttpRequest, report_id: str) -> HttpResponse:
    action = (request.POST.get("action") or "").strip()
    reason = (request.POST.get("reason") or "").strip()

    if action not in REPORT_ACTIONS:
        messages.error(request, "Choose a report action.")
        return redirect("moderation_reports")
    status, done = REPORT_ACTIONS[action]

    client = GoBFFClient()
    result = client.action_report(report_id, action, reason, status=status, reviewed_by=_operator_reviewer(request))
    if result.ok:
        note = ""
        if action in {"suspend_reported", "ban_reported"}:
            # Go records the decision only; the account change is a separate action.
            note = " The account is not changed by this: suspend or ban the member from their user page."
        messages.success(request, f"Report {report_id} {done}.{note}")
    else:
        messages.error(request, f"Failed to action report {report_id}: {result.error}")
    return redirect("moderation_reports")


@require_GET
def media_moderation_queue(request: HttpRequest) -> HttpResponse:
    status = (request.GET.get("status") or "review_required").strip()
    try:
        limit = min(max(int(request.GET.get("limit", "50")), 1), 200)
    except ValueError:
        limit = 50
    result = GoBFFClient().list_media_moderation(status=status, limit=limit)
    context = _base_context()
    context.update(
        {
            "status_filter": status,
            "limit": limit,
            "items": result.data.get("items", []) if result.ok else [],
            "error": result.error,
        }
    )
    return render(request, "control_panel/media_moderation.html", context)


@require_GET
def media_moderation_content(request: HttpRequest, photo_id: str) -> HttpResponse:
    result = GoBFFClient().get_media_moderation_content(photo_id)
    if not result.ok:
        return HttpResponse(result.error or "Media not found", status=bff_failure_status(result.status_code), content_type="text/plain")
    response = HttpResponse(result.content, content_type=result.content_type)
    response["Cache-Control"] = "private, no-store"
    response["X-Content-Type-Options"] = "nosniff"
    return response


@require_POST
def media_moderation_decision(request: HttpRequest, photo_id: str) -> HttpResponse:
    decision = (request.POST.get("decision") or "").strip().lower()
    reason = (request.POST.get("reason") or "").strip()
    if decision not in {"approved", "rejected"}:
        messages.error(request, "Choose approve or reject.")
        return redirect("media_moderation_queue")
    if decision == "rejected" and not reason:
        messages.error(request, "A rejection reason is required.")
        return redirect("media_moderation_queue")
    result = GoBFFClient().decide_media_moderation(photo_id, decision, reason)
    if result.ok:
        messages.success(request, f"Media {photo_id} marked {decision}.")
    else:
        messages.error(request, f"Media decision failed: {result.error}")
    return redirect("media_moderation_queue")


# ── Gift Catalog ──────────────────────────────────────────────────────────────

@require_GET
def catalog_list(request: HttpRequest) -> HttpResponse:
    category = request.GET.get("category", "").strip()
    tier = request.GET.get("tier", "").strip()
    active = request.GET.get("active", "").strip()
    q = request.GET.get("q", "").strip()
    try:
        offset = int(request.GET.get("offset", "0"))
    except ValueError:
        offset = 0
    limit = 50

    client = GoBFFClient()
    result = client.list_catalog_gifts(category=category, tier=tier, active=active, q=q, limit=limit, offset=offset)

    gifts = result.data.get("gifts", []) if result.ok else []
    total = result.data.get("count", len(gifts)) if result.ok else 0
    active_count = sum(1 for g in gifts if g.get("is_active"))

    context = _base_context()
    context.update(
        {
            "q": q,
            "category_filter": category,
            "tier_filter": tier,
            "active_filter": active,
            "offset": offset,
            "limit": limit,
            "gifts": gifts,
            "total": total,
            "active_count": active_count,
            "error": result.error,
            "categories": GIFT_CATEGORIES,
            "rarity_tiers": GIFT_TIERS,
            "prev_offset": max(0, offset - limit),
            "next_offset": offset + limit,
        }
    )
    return render(request, "control_panel/catalog.html", context)


# The same lists the catalog page filters by. The form used to offer only the
# first five categories, so editing a "themed_pack" (etc.) gift lost its category.
GIFT_CATEGORIES = ["roses", "sparkle", "playful", "luxury", "seasonal", "themed_pack", "reaction", "experience", "exclusive"]
GIFT_TIERS = ["free", "common", "uncommon", "rare", "epic", "legendary"]


def _gift_form_context(gift: dict | None = None) -> dict:
    """Choices for catalog_edit.html. The template reads ``rarity_tiers``;
    the views used to pass ``tiers``, which left the required tier select
    empty, so the browser refused to submit the gift form at all."""
    categories = list(GIFT_CATEGORIES)
    current = str((gift or {}).get("category") or "")
    if current and current not in categories:
        categories.append(current)
    return {"categories": categories, "rarity_tiers": GIFT_TIERS}


# Gift artwork the console accepts. Anything else (HTML, SVG with script, an
# executable) would be served from the console's own origin under /static/.
GIFT_IMAGE_TYPES = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".gif": "image/gif", ".webp": "image/webp"}
GIFT_IMAGE_MAX_BYTES = 5 * 1024 * 1024


class GiftImageError(ValueError):
    pass


def _store_gift_image(uploaded) -> str:
    """Save an uploaded gift image under static/uploads/gifts and return its URL."""
    import os
    import uuid

    ext = os.path.splitext(uploaded.name or "")[1].lower()
    content_type = (getattr(uploaded, "content_type", "") or "").split(";")[0].strip().lower()
    if ext not in GIFT_IMAGE_TYPES or content_type not in set(GIFT_IMAGE_TYPES.values()):
        raise GiftImageError("Upload a PNG, JPEG, GIF or WebP image.")
    if uploaded.size > GIFT_IMAGE_MAX_BYTES:
        raise GiftImageError("Gift images must be 5 MB or smaller.")
    fname = f"gifts/{uuid.uuid4().hex}{ext}"
    # Anchored to the project (STATICFILES_DIRS), not the process's working directory.
    dest = os.path.join(settings.BASE_DIR, "static", "uploads", fname)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "wb") as f:
        for chunk in uploaded.chunks():
            f.write(chunk)
    return f"/static/uploads/{fname}"


def _find_gift(client, gift_id: str):
    """(gift or None, result) for one catalog gift. Go has no single-gift read
    and lists at most 500 per page, so page through instead of only looking
    at the first 50 (gifts past the first page could not be edited)."""
    result = None
    for page in range(20):
        result = client.list_catalog_gifts(limit=500, offset=page * 500)
        data = result.data if result.ok and isinstance(result.data, dict) else {}
        gifts = [g for g in data.get("gifts") or [] if isinstance(g, dict)]
        gift = next((g for g in gifts if str(g.get("id")) == gift_id), None)
        if gift is not None or not result.ok or len(gifts) < 500:
            return gift, result
    return None, result


@require_http_methods(["GET", "POST"])
def catalog_new(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        try:
            price_coins = int(request.POST.get("price_coins") or 0)
        except ValueError:
            price_coins = 0
        try:
            sort_order = int(request.POST.get("sort_order") or 100)
        except ValueError:
            sort_order = 100

        # Resolve image: uploaded file takes precedence over pasted URL
        gif_url = request.POST.get("gif_url", "").strip()
        uploaded = request.FILES.get("image_file")
        if uploaded:
            try:
                gif_url = _store_gift_image(uploaded)
            except GiftImageError as exc:
                messages.error(request, str(exc))
                context = _base_context()
                context.update(_gift_form_context())
                return render(request, "control_panel/catalog_edit.html", context)

        payload = {
            "gift_id": request.POST.get("gift_id", "").strip(),
            "name": request.POST.get("name", "").strip(),
            "category": request.POST.get("category", "").strip(),
            "tier": request.POST.get("tier", "free").strip(),
            "description": request.POST.get("description", "").strip(),
            "price_coins": price_coins,
            "icon_emoji": request.POST.get("icon_emoji", "🎁").strip(),
            "gif_url": gif_url,
            "sort_order": sort_order,
            "is_active": True,
        }
        client = GoBFFClient()
        result = client.create_catalog_gift(payload)
        if result.ok:
            messages.success(request, f"Gift '{payload['name']}' created successfully.")
            return redirect("catalog_list")
        messages.error(request, f"Failed to create gift: {result.error}")

    context = _base_context()
    context.update(_gift_form_context())
    return render(request, "control_panel/catalog_edit.html", context)


@require_http_methods(["GET", "POST"])
def catalog_edit(request: HttpRequest, gift_id: str) -> HttpResponse:
    client = GoBFFClient()

    if request.method == "POST":
        try:
            price_coins = int(request.POST.get("price_coins") or 0)
        except ValueError:
            price_coins = 0
        try:
            sort_order = int(request.POST.get("sort_order") or 100)
        except ValueError:
            sort_order = 100

        # Resolve image: uploaded file takes precedence over pasted URL
        gif_url = request.POST.get("gif_url", "").strip()
        uploaded = request.FILES.get("image_file")
        image_error = ""
        if uploaded:
            try:
                gif_url = _store_gift_image(uploaded)
            except GiftImageError as exc:
                image_error = str(exc)

        payload = {
            "name": request.POST.get("name", "").strip(),
            "category": request.POST.get("category", "").strip(),
            "tier": request.POST.get("tier", "free").strip(),
            "description": request.POST.get("description", "").strip(),
            "price_coins": price_coins,
            "icon_emoji": request.POST.get("icon_emoji", "🎁").strip(),
            "gif_url": gif_url,
            "sort_order": sort_order,
        }
        if image_error:
            messages.error(request, image_error)
        else:
            result = client.update_catalog_gift(gift_id, payload)
            if result.ok:
                messages.success(request, "Gift updated successfully.")
                return redirect("catalog_list")
            messages.error(request, f"Failed to update gift: {result.error}")

    gift, lookup = _find_gift(client, gift_id)
    if lookup is not None and lookup.ok and gift is None:
        # An unknown id is a 404, not the "Add New Gift" form posting to it.
        raise Http404("Gift not found")
    if lookup is not None and not lookup.ok:
        messages.error(request, f"Could not load this gift: {lookup.error}")
    context = _base_context()
    context.update(
        {
            "gift": gift,
            "gift_id": gift_id,
            **_gift_form_context(gift),
        }
    )
    return render(request, "control_panel/catalog_edit.html", context)


@require_POST
def catalog_toggle(request: HttpRequest, gift_id: str) -> HttpResponse:
    is_active = request.POST.get("is_active") == "1"
    client = GoBFFClient()
    result = client.toggle_catalog_gift(gift_id, is_active=is_active)
    if result.ok:
        state = "activated" if is_active else "deactivated"
        messages.success(request, f"Gift {gift_id} {state}.")
    else:
        messages.error(request, f"Failed to toggle gift: {result.error}")
    return redirect("catalog_list")


@require_POST
def catalog_delete(request: HttpRequest, gift_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.delete_catalog_gift(gift_id)
    if result.ok:
        messages.success(request, f"Gift {gift_id} deleted.")
    else:
        messages.error(request, f"Failed to delete gift: {result.error}")
    return redirect("catalog_list")


# ── User Management ───────────────────────────────────────────────────────────

USER_LIST = listing.ListSpec(
    name="users",
    search_label="Search name, phone or ID",
    filters=(
        listing.Filter("status", "Status", (("active", "Active"), ("suspended", "Suspended"), ("banned", "Banned"))),
        listing.Filter("gender", "Gender", (("male", "Male"), ("female", "Female"), ("other", "Other"))),
        listing.Filter("verified", "Verified", (("yes", "Yes"), ("no", "No"))),
    ),
    columns=(
        listing.Column("id", "User ID", width=38),
        listing.Column("name", "Name", width=24),
        listing.Column("username", "Username", width=20),
        listing.Column("phone_number", "Phone", width=18),
        listing.Column("gender", "Gender", width=10),
        listing.Column("created_at", "Joined (UTC)", width=22),
        listing.Column("status", "Status", lambda u: "Banned" if u.get("is_banned") else ("Suspended" if u.get("suspended_at") else "Active"), width=12),
        listing.Column("is_verified", "Verified", width=10),
    ),
)


@require_GET
def user_list(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    kpis: dict = {}

    def fetch(query: listing.ListQuery, limit: int, offset: int):
        f = query.filters
        result = client.list_users(limit=limit, offset=offset, q=query.q, status=f.get("status", ""),
                                   gender=f.get("gender", ""), verified=f.get("verified", ""))
        if not result.ok:
            return [], None, result.error
        kpis.update(result.data.get("kpis") or {})
        return result.data.get("users") or [], result.data.get("total"), ""

    def render_page(page: listing.Page) -> HttpResponse:
        users = page.rows
        verified_count = sum(1 for u in users if u.get("is_verified"))
        context = _base_context()
        context.update(listing.context(page))
        context.update(
            {
                "users": users,
                "total": page.total or 0,
                "active_count": kpis.get("active", sum(1 for u in users if not u.get("suspended_at") and not u.get("is_banned"))),
                "suspended_count": kpis.get("suspended", sum(1 for u in users if u.get("suspended_at"))),
                "banned_count": kpis.get("banned", sum(1 for u in users if u.get("is_banned"))),
                "verified_pct": round(float(kpis.get("verified_pct", verified_count / len(users) * 100 if users else 0))),
                "kpi_scope": kpis.get("scope", "returned_page"),
                "error": page.error,
            }
        )
        return render(request, "control_panel/users.html", context)

    return listing.respond(request, USER_LIST, fetch, title="Users", render_page=render_page)


@require_http_methods(["GET", "POST"])
def user_create(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        payload = {
            "username": request.POST.get("username", "").strip().lower(),
            "password": request.POST.get("password", ""),
            "name": request.POST.get("name", "").strip(),
            "phone_number": request.POST.get("phone_number", "").strip(),
            "gender": request.POST.get("gender", "").strip(),
            "bio": request.POST.get("bio", "").strip(),
            "education": request.POST.get("education", "").strip(),
            "profession": request.POST.get("profession", "").strip(),
            "city": request.POST.get("city", "").strip(),
            "state": request.POST.get("state", "").strip(),
        }
        height = request.POST.get("height_cm", "").strip()
        if height:
            try:
                payload["height_cm"] = int(height)
            except ValueError:
                pass

        if not payload["name"] or not payload["username"] or not payload["password"]:
            messages.error(request, "Name, username, and password are required.")
            ctx = _base_context()
            ctx["form_data"] = payload
            return render(request, "control_panel/user_form.html", ctx)

        client = GoBFFClient()
        result = client.create_user(payload)
        if result.ok:
            messages.success(request, f"User '@{payload['username']}' created successfully.")
            return redirect("user_list")
        messages.error(request, f"Failed to create user: {result.error}")
        ctx = _base_context()
        ctx["form_data"] = payload
        return render(request, "control_panel/user_form.html", ctx)

    context = _base_context()
    context["form_data"] = {}
    return render(request, "control_panel/user_form.html", context)


@require_http_methods(["GET", "POST"])
def user_edit(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()

    if request.method == "POST" and not (request.POST.get("name") or "").strip():
        messages.error(request, "Name is required.")
    elif request.method == "POST":
        payload = {
            "name": request.POST.get("name", "").strip(),
            "phone_number": request.POST.get("phone_number", "").strip(),
            "gender": request.POST.get("gender", "").strip(),
            "bio": request.POST.get("bio", "").strip(),
            "education": request.POST.get("education", "").strip(),
            "profession": request.POST.get("profession", "").strip(),
            "income_range": request.POST.get("income_range", "").strip(),
            "city": request.POST.get("city", "").strip(),
            "state": request.POST.get("state", "").strip(),
            "country": request.POST.get("country", "").strip(),
            "drinking": request.POST.get("drinking", "").strip(),
            "smoking": request.POST.get("smoking", "").strip(),
            "religion": request.POST.get("religion", "").strip(),
            "mother_tongue": request.POST.get("mother_tongue", "").strip(),
            "personality_type": request.POST.get("personality_type", "").strip(),
        }
        height = request.POST.get("height_cm", "").strip()
        if height:
            try:
                payload["height_cm"] = int(height)
            except ValueError:
                pass

        result = client.update_user(user_id, payload)
        if result.ok:
            messages.success(request, "User updated successfully.")
            return redirect("user_detail", user_id=user_id)
        messages.error(request, f"Failed to update user: {result.error}")

    result = client.get_user(user_id)
    if not result.ok and result.status_code == 404:
        raise Http404("User not found")
    user = result.data.get("user", {}) if result.ok and isinstance(result.data, dict) else {}

    context = _base_context()
    # Without the member's current values the form would post blanks over
    # every profile field, so it is not shown when the read fails.
    context.update({"form_data": user, "user_id": user_id, "editing": True,
                    "load_error": "" if result.ok else (result.error or "the member could not be read")})
    return render(request, "control_panel/user_form.html", context)


@require_POST
def user_delete(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.delete_user(user_id)
    if result.ok:
        # The BFF schedules the standard erasure (deactivated and signed out
        # now, erased after the grace window) instead of dropping the row.
        messages.success(
            request,
            f"User {user_id} deactivated and signed out; erasure is scheduled after the grace period.",
        )
    else:
        messages.error(request, f"Failed to delete user: {result.error}")
    return redirect("user_list")


@require_GET
def user_detail(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.get_user(user_id)

    user = result.data.get("user", {}) if result.ok else {}

    # Fetch wallet balance from dedicated endpoint
    wallet_balance = 0
    wallet_result = client.get_wallet_balance(user_id)
    if wallet_result.ok:
        wallet_obj = wallet_result.data.get("wallet", {})
        wallet_balance = wallet_obj.get("coin_balance", 0)

    # Ask Go for this member's own rows (CON-04). Rows for anyone else are
    # dropped so a BFF that ignores user_id can never show another member's
    # purchases; the page then says the list may be incomplete.
    wallet_transactions = []
    wallet_transactions_partial = False
    tx_result = client.list_billing_transactions(limit=20, user_id=user_id)
    if tx_result.ok:
        all_tx = [t for t in tx_result.data.get("transactions") or [] if isinstance(t, dict)]
        wallet_transactions = [t for t in all_tx if str(t.get("user_id") or "") == str(user_id)]
        wallet_transactions_partial = len(wallet_transactions) < len(all_tx)

    context = _base_context()
    context.update(
        {
            "user": user,
            "user_id": user_id,
            "wallet_balance": wallet_balance,
            "wallet_transactions": wallet_transactions,
            "wallet_transactions_partial": wallet_transactions_partial,
            "error": result.error,
        }
    )
    # An unknown member is a 404, not a 200 page that only says "user not found".
    status = 404 if not result.ok and result.status_code == 404 else 200
    return render(request, "control_panel/user_detail.html", context, status=status)


@require_POST
def user_suspend(request: HttpRequest, user_id: str) -> HttpResponse:
    reason = (request.POST.get("reason") or "").strip()
    try:
        days = int(request.POST.get("days") or 0)
    except ValueError:
        days = 0

    if not reason:
        messages.error(request, "Suspension reason is required.")
        return redirect("user_detail", user_id=user_id)

    client = GoBFFClient()
    result = client.suspend_user(user_id, reason, days)
    if result.ok:
        messages.success(request, f"User {user_id} suspended.")
    else:
        messages.error(request, f"Failed to suspend user: {result.error}")
    return redirect("user_detail", user_id=user_id)


@require_POST
def user_unsuspend(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.unsuspend_user(user_id)
    if result.ok:
        messages.success(request, f"User {user_id} unsuspended.")
    else:
        messages.error(request, f"Failed to unsuspend user: {result.error}")
    return redirect("user_detail", user_id=user_id)


@require_POST
def user_ban(request: HttpRequest, user_id: str) -> HttpResponse:
    reason = (request.POST.get("reason") or "").strip()
    if not reason:
        messages.error(request, "Ban reason is required.")
        return redirect("user_detail", user_id=user_id)

    client = GoBFFClient()
    result = client.ban_user(user_id, reason)
    if result.ok:
        messages.success(request, f"User {user_id} banned.")
    else:
        messages.error(request, f"Failed to ban user: {result.error}")
    return redirect("user_detail", user_id=user_id)


@require_POST
def user_unban(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.unban_user(user_id)
    if result.ok:
        messages.success(request, f"User {user_id} unbanned.")
    else:
        messages.error(request, f"Failed to unban user: {result.error}")
    return redirect("user_detail", user_id=user_id)


@require_POST
def user_force_verify(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.force_verify_user(user_id)
    if result.ok:
        messages.success(request, f"User {user_id} force-verified.")
    else:
        messages.error(request, f"Failed to verify user: {result.error}")
    return redirect("user_detail", user_id=user_id)


@require_POST
def user_grant_coins(request: HttpRequest, user_id: str) -> HttpResponse:
    try:
        coins = int(request.POST.get("coins") or 0)
    except ValueError:
        coins = 0
    reason = (request.POST.get("reason") or "admin_grant").strip()

    if coins < 1:
        messages.error(request, "Coins must be at least 1.")
        return redirect("user_detail", user_id=user_id)

    # The audited operator grant (FR-07), the same call as Billing's quick
    # grant. This used to post {"coins": ...} to the member top-up route
    # /wallet/{id}/coins/top-up, which reads "amount", so every grant failed,
    # and that route is outside /admin and so outside the operator audit log.
    client = GoBFFClient()
    result = client.admin_grant_coins(user_id, coins, reason)
    if result.ok:
        new_balance = result.data.get("new_balance") if isinstance(result.data, dict) else None
        balance = f" New balance: {new_balance}." if new_balance is not None else ""
        messages.success(request, f"Granted {coins} coins to {user_id}.{balance}")
    else:
        messages.error(request, f"Failed to grant coins: {result.error}")
    return redirect("user_detail", user_id=user_id)


# ── Feature Flags ─────────────────────────────────────────────────────────────

@require_GET
def config_flags(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    result = client.list_config_flags()

    context = _base_context()
    context.update(
        {
            "flags": result.data.get("flags", []) if result.ok else [],
            "error": result.error,
        }
    )
    return render(request, "control_panel/config_flags.html", context)


@require_POST
def config_flag_toggle(request: HttpRequest, key: str) -> HttpResponse:
    value = request.POST.get("value") == "1"
    client = GoBFFClient()
    # Go stores updated_by as sent; it used to be the literal "admin" for
    # every operator, so the flag row never said who changed it.
    operator = str(request.session.get("operator_username") or "").strip() or "operator"
    result = client.update_config_flag(key, value, updated_by=operator)
    if result.ok:
        state = "enabled" if value else "disabled"
        messages.success(request, f"Flag '{key}' {state}.")
    else:
        messages.error(request, f"Failed to update flag '{key}': {result.error}")
    return redirect("config_flags")


# ── Engagement Prompts ────────────────────────────────────────────────────────

PROMPT_CATEGORIES = ["icebreaker", "deep_dive", "fun", "values", "lifestyle"]


def _prompt_rows(result) -> list[dict]:
    """Prompts as the templates read them. Go stores the text as
    ``question_text``; the templates say ``prompt_text``."""
    data = result.data if result.ok and isinstance(result.data, dict) else {}
    rows = []
    for prompt in data.get("prompts") or []:
        if isinstance(prompt, dict):
            rows.append({**prompt, "prompt_text": prompt.get("question_text") or prompt.get("prompt_text") or ""})
    return rows


@require_GET
def engagement_prompts(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    result = client.list_engagement_prompts()

    context = _base_context()
    context.update(
        {
            "prompts": _prompt_rows(result),
            "error": result.error,
        }
    )
    return render(request, "control_panel/engagement_prompts.html", context)


@require_http_methods(["GET", "POST"])
def engagement_prompt_new(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        # Go reads the text from "question_text" (adminCreateEngagementPrompt);
        # sending "prompt_text" made every create fail with a 400.
        payload = {
            "question_text": request.POST.get("prompt_text", "").strip(),
            "category": request.POST.get("category", "icebreaker").strip(),
            "is_active": True,
        }
        if not payload["question_text"]:
            messages.error(request, "Prompt text is required.")
        else:
            client = GoBFFClient()
            result = client.create_engagement_prompt(payload)
            if result.ok:
                messages.success(request, "Prompt created successfully.")
                return redirect("engagement_prompts")
            messages.error(request, f"Failed to create prompt: {result.error}")

    context = _base_context()
    context["categories"] = PROMPT_CATEGORIES
    return render(request, "control_panel/engagement_prompt_edit.html", context)


@require_http_methods(["GET", "POST"])
def engagement_prompt_edit(request: HttpRequest, prompt_id: str) -> HttpResponse:
    client = GoBFFClient()

    if request.method == "POST":
        text = request.POST.get("prompt_text", "").strip()
        if not text:
            messages.error(request, "Prompt text is required.")
        else:
            # "question_text" is the field Go updates; "prompt_text" was
            # silently dropped, so text edits were lost while the console
            # reported success.
            payload = {
                "question_text": text,
                "category": request.POST.get("category", "icebreaker").strip(),
            }
            result = client.update_engagement_prompt(prompt_id, payload)
            if result.ok:
                messages.success(request, "Prompt updated successfully.")
                return redirect("engagement_prompts")
            messages.error(request, f"Failed to update prompt: {result.error}")

    all_prompts = client.list_engagement_prompts()
    prompt = next((p for p in _prompt_rows(all_prompts) if str(p.get("id")) == prompt_id), None)
    if all_prompts.ok and prompt is None:
        # Never show the "new prompt" form for an id that does not exist.
        raise Http404("Prompt not found")
    if not all_prompts.ok:
        messages.error(request, f"Could not load this prompt: {all_prompts.error}")
    context = _base_context()
    context.update(
        {
            "prompt": prompt,
            "prompt_id": prompt_id,
            "categories": PROMPT_CATEGORIES,
        }
    )
    return render(request, "control_panel/engagement_prompt_edit.html", context)


@require_POST
def engagement_prompt_activate(request: HttpRequest, prompt_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.activate_engagement_prompt(prompt_id)
    if result.ok:
        messages.success(request, "Prompt activated as today's daily prompt.")
    else:
        messages.error(request, f"Failed to activate prompt: {result.error}")
    return redirect("engagement_prompts")


@require_GET
def engagement_nudges(request: HttpRequest) -> HttpResponse:
    context = _base_context()
    result = GoBFFClient().list_engagement_nudges()
    context["nudges"] = result.data.get("nudges", []) if result.ok else []
    context["nudge_count"] = result.data.get("count", 0) if result.ok else 0
    context["clicked_count"] = result.data.get("clicked", 0) if result.ok else 0
    context["by_type"] = result.data.get("by_type", {}) if result.ok else {}
    # Unknown when the BFF cannot answer, not "Disabled".
    context["nudges_enabled"] = result.data.get("enabled", True) if result.ok else None
    context["error"] = result.error if not result.ok else ""
    return render(request, "control_panel/engagement_nudges.html", context)


# ── Billing ───────────────────────────────────────────────────────────────────

@require_GET
def billing_dashboard(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    plans_result = client.list_billing_plans()
    packages_result = client.list_coin_packages()
    tx_result = client.list_billing_transactions(limit=10)
    stats_result = client.get_billing_stats()

    coin_packages = packages_result.data.get("packages", []) if packages_result.ok else []
    active_packages = sum(1 for p in coin_packages if p.get("is_active"))
    transaction_count = tx_result.data.get("total", 0) if tx_result.ok else 0

    stats = stats_result.data if stats_result.ok and isinstance(stats_result.data, dict) else {}

    context = _base_context()
    context.update(
        {
            "plans": plans_result.data.get("plans", []) if plans_result.ok else [],
            "plans_error": plans_result.error,
            "coin_packages": coin_packages,
            "packages_error": packages_result.error,
            "active_packages": active_packages,
            "transaction_count": transaction_count,
            "total_coins_purchased": stats.get("total_coins_purchased", 0),
            "total_revenue_minor": stats.get("total_revenue_minor", 0),
            "revenue_by_currency": stats.get("revenue_by_currency", []) or [],
            "unique_buyers": stats.get("unique_buyers", 0),
            "stats_window": stats.get("window", {}) or {},
            # Unavailable, never zero (KPI contract): the tiles show a dash
            # and this banner instead of 0 coins / 0.00 revenue.
            "stats_error": "" if stats_result.ok else (stats_result.error or "Billing stats are unavailable."),
        }
    )
    return render(request, "control_panel/billing.html", context)


@require_POST
def billing_package_toggle(request: HttpRequest, package_id: str) -> HttpResponse:
    is_active = request.POST.get("is_active") == "1"
    client = GoBFFClient()
    result = client.toggle_coin_package(package_id, is_active=is_active)
    if result.ok:
        state = "activated" if is_active else "deactivated"
        messages.success(request, f"Coin package {state}.")
    else:
        messages.error(request, f"Failed to toggle package: {result.error}")
    return redirect("billing_dashboard")


# ── Billing lists: server-side paging, search, filters, Excel ────────────────

def _money_minor(row: dict, key: str = "amount_minor"):
    value = row.get(key)
    return round(value / 100, 2) if isinstance(value, (int, float)) and not isinstance(value, bool) else None


BILLING_TRANSACTIONS = listing.ListSpec(
    name="coin-purchases", search_label="Search member ID or reference",
    filters=(listing.Filter("source", "Source", kind="text", max_length=40),
             listing.Filter("provider", "Provider", kind="text", max_length=40), listing.Filter("from", "From (UTC)", kind="date"), listing.Filter("to", "To (UTC)", kind="date")),
    columns=(listing.Column("purchase_ref", "Purchase reference", width=30), listing.Column("user_id", "Member ID", width=38),
             listing.Column("coins", "Coins", width=10), listing.Column("amount", "Amount", _money_minor, width=12),
             listing.Column("currency", "Currency", width=10), listing.Column("source", "Source"),
             listing.Column("provider", "Provider"), listing.Column("created_at", "Created (UTC)", width=22)),
)
BILLING_SUBSCRIPTIONS = listing.ListSpec(
    name="subscriptions", search_label="Search member ID or reference",
    filters=(listing.Filter("status", "Status", (("active", "Active"), ("cancelled", "Cancelled"), ("expired", "Expired"),
                                                  ("past_due", "Past due"), ("incomplete", "Incomplete"), ("paused", "Paused"))),
             listing.Filter("plan_code", "Plan", kind="text", max_length=60), listing.Filter("from", "From (UTC)", kind="date"), listing.Filter("to", "To (UTC)", kind="date")),
    columns=(listing.Column("user_id", "Member ID", width=38), listing.Column("plan_code", "Plan", width=18),
             listing.Column("billing_cycle", "Cycle"), listing.Column("status", "Status"),
             listing.Column("provider", "Provider"), listing.Column("provider_subscription_id", "Provider reference", width=30),
             listing.Column("start_date", "Started (UTC)", width=22), listing.Column("current_period_end", "Period end (UTC)", width=22),
             listing.Column("end_date", "Ended (UTC)", width=22), listing.Column("auto_renew", "Auto-renew", width=10),
             listing.Column("cancel_at_period_end", "Ending", width=10)),
)
BILLING_PAYMENTS = listing.ListSpec(
    name="payments", search_label="Search member ID or reference",
    filters=(listing.Filter("status", "Status", (("created", "Created"), ("captured", "Captured"), ("success", "Success"),
                                                  ("failed", "Failed"), ("refunded", "Refunded"))), listing.Filter("from", "From (UTC)", kind="date"), listing.Filter("to", "To (UTC)", kind="date")),
    columns=(listing.Column("user_id", "Member ID", width=38),
             listing.Column("amount", "Amount", lambda r: _money_minor(r, "amount_paise"), width=12),
             listing.Column("currency", "Currency", width=10), listing.Column("status", "Status"),
             listing.Column("provider_order_id", "Provider order", width=30),
             listing.Column("provider_payment_id", "Provider payment", width=30),
             listing.Column("created_at", "Created (UTC)", width=22), listing.Column("paid_at", "Paid (UTC)", width=22)),
)
BILLING_WEBHOOKS = listing.ListSpec(
    name="webhook-events", search_label="Search event ID or reference",
    filters=(listing.Filter("status", "Status", (("processed", "Processed"), ("ignored", "Ignored"), ("failed", "Failed"),
                                                  ("received", "Received"))),
             listing.Filter("event_type", "Event type", kind="text", max_length=80), listing.Filter("from", "From (UTC)", kind="date"), listing.Filter("to", "To (UTC)", kind="date")),
    columns=(listing.Column("event_id", "Event ID", width=38), listing.Column("provider", "Provider"),
             listing.Column("event_type", "Event type", width=30), listing.Column("status", "Status"),
             listing.Column("error", "Error", width=40), listing.Column("received_at", "Received (UTC)", width=22)),
)


@require_GET
def billing_transactions(request: HttpRequest) -> HttpResponse:
    return listing.simple_view(request, BILLING_TRANSACTIONS, GoBFFClient().list_billing_transactions,
                               items_key="transactions", template="control_panel/billing_transactions.html",
                               title="Coin purchases", base_context=_base_context, context_name="transactions")


@require_http_methods(["GET", "POST"])
def billing_package_new(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        try:
            coin_amount = int(request.POST.get("coin_amount") or 0)
        except ValueError:
            coin_amount = 0
        try:
            price_usd = float(request.POST.get("price_usd") or 0)
        except ValueError:
            price_usd = 0
        try:
            bonus_percent = float(request.POST.get("bonus_percent") or 0)
        except ValueError:
            bonus_percent = 0
        try:
            sort_order = int(request.POST.get("sort_order") or 0)
        except ValueError:
            sort_order = 0

        payload = {
            "label": request.POST.get("label", "").strip(),
            "coin_amount": coin_amount,
            "price_usd": price_usd,
            "bonus_percent": bonus_percent,
            "sort_order": sort_order,
            "description": request.POST.get("description", "").strip(),
            "is_active": True,
        }
        if not payload["label"] or coin_amount < 1 or price_usd <= 0:
            messages.error(request, "Label, coin amount (≥1), and price (>0) are required.")
        else:
            client = GoBFFClient()
            result = client.create_coin_package(payload)
            if result.ok:
                messages.success(request, f"Package '{payload['label']}' created.")
                return redirect("billing_dashboard")
            messages.error(request, f"Failed to create package: {result.error}")

    context = _base_context()
    return render(request, "control_panel/coin_package_edit.html", context)


@require_http_methods(["GET", "POST"])
def billing_package_edit(request: HttpRequest, package_id: str) -> HttpResponse:
    client = GoBFFClient()

    if request.method == "POST":
        try:
            coin_amount = int(request.POST.get("coin_amount") or 0)
        except ValueError:
            coin_amount = 0
        try:
            price_usd = float(request.POST.get("price_usd") or 0)
        except ValueError:
            price_usd = 0
        try:
            bonus_percent = float(request.POST.get("bonus_percent") or 0)
        except ValueError:
            bonus_percent = 0
        try:
            sort_order = int(request.POST.get("sort_order") or 0)
        except ValueError:
            sort_order = 0

        payload = {
            "label": request.POST.get("label", "").strip(),
            "coin_amount": coin_amount,
            "price_usd": price_usd,
            "bonus_percent": bonus_percent,
            "sort_order": sort_order,
            "description": request.POST.get("description", "").strip(),
        }
        result = client.update_coin_package(package_id, payload)
        if result.ok:
            messages.success(request, "Package updated.")
            return redirect("billing_dashboard")
        messages.error(request, f"Failed to update package: {result.error}")

    # Fetch current package for pre-fill
    all_pkgs = client.list_coin_packages()
    pkgs_data = all_pkgs.data if all_pkgs.ok and isinstance(all_pkgs.data, dict) else {}
    package = next(
        (p for p in pkgs_data.get("packages") or [] if isinstance(p, dict) and str(p.get("id")) == package_id),
        None,
    )
    if all_pkgs.ok and package is None:
        # Never show the "new package" form for an id that does not exist.
        raise Http404("Coin package not found")
    if not all_pkgs.ok:
        messages.error(request, f"Could not load this package: {all_pkgs.error}")
    context = _base_context()
    context.update(
        {
            "package": package,
            "package_id": package_id,
        }
    )
    return render(request, "control_panel/coin_package_edit.html", context)


# ── Billing: Admin Coin Grant (FR-07) ─────────────────────────────────────────

@require_POST
def billing_grant_coins(request: HttpRequest) -> HttpResponse:
    user_id = (request.POST.get("user_id") or "").strip()
    reason = (request.POST.get("reason") or "admin_grant").strip()
    try:
        amount = int(request.POST.get("amount") or 0)
    except ValueError:
        amount = 0

    if not user_id:
        messages.error(request, "User ID is required.")
        return redirect("billing_dashboard")
    if amount < 1:
        messages.error(request, "Coin amount must be at least 1.")
        return redirect("billing_dashboard")

    client = GoBFFClient()
    result = client.admin_grant_coins(user_id, amount, reason)
    if result.ok:
        new_bal = result.data.get("new_balance", "?")
        messages.success(request, f"Granted {amount} coins to {user_id}. New balance: {new_bal}.")
    else:
        messages.error(request, f"Failed to grant coins: {result.error}")
    return redirect("billing_dashboard")


# ── Billing: Subscriptions (FR-09) ────────────────────────────────────────────

@require_GET
def billing_subscriptions(request: HttpRequest) -> HttpResponse:
    return listing.simple_view(request, BILLING_SUBSCRIPTIONS, GoBFFClient().list_subscriptions,
                               items_key="subscriptions", template="control_panel/billing_subscriptions.html",
                               title="Subscriptions", base_context=_base_context, context_name="subscriptions")


# ── Billing: Payments (FR-09) ─────────────────────────────────────────────────

@require_GET
def billing_payments(request: HttpRequest) -> HttpResponse:
    return listing.simple_view(request, BILLING_PAYMENTS, GoBFFClient().list_payments,
                               items_key="payments", template="control_panel/billing_payments.html",
                               title="Payments", base_context=_base_context, context_name="payments")


# ── Billing: reconciliation (PEN-02) ─────────────────────────────────────────

@require_GET
def billing_reconciliation(request: HttpRequest) -> HttpResponse:
    since = request.GET.get("since", "").strip()
    until = request.GET.get("until", "").strip()
    client = GoBFFClient()
    result = client.get_billing_reconciliation(since=since, until=until)
    frozen_result = client.list_frozen_wallets()
    fraud_result = client.list_economy_fraud_cases(status="open", limit=100)
    fraud_rules_result = client.list_economy_fraud_rules()
    report = result.data if result.ok else {}

    def money(minor: object) -> str:
        try:
            return f"{int(minor) / 100:,.2f}"
        except (TypeError, ValueError):
            return "0.00"

    revenue = report.get("revenue", {}) if isinstance(report, dict) else {}
    context = _base_context()
    context.update(
        {
            "report": report,
            "revenue": {key: money(value) for key, value in revenue.items() if key != "note"},
            "revenue_note": revenue.get("note", ""),
            "currency": report.get("currency", ""),
            "anomalies": report.get("anomalies", []) or [],
            "payments_by_status": report.get("payments_by_status", []) or [],
            "wallet": report.get("wallet", {}) or {},
            "subscriptions": (report.get("subscriptions", {}) or {}).get("by_status", {}),
            "webhooks": report.get("webhooks", {}) or {},
            "checkouts": report.get("checkouts", {}) or {},
            "since": since,
            "until": until,
            "error": result.error,
            "frozen_wallets": frozen_result.data.get("wallets", []) if frozen_result.ok else [],
            "frozen_wallets_error": frozen_result.error,
            "fraud_cases": fraud_result.data.get("cases", []) if fraud_result.ok and isinstance(fraud_result.data, dict) else [],
            "fraud_cases_error": fraud_result.error if fraud_result.ok is False else "",
            "fraud_rules": fraud_rules_result.data.get("rules", []) if fraud_rules_result.ok and isinstance(fraud_rules_result.data, dict) else [],
            "fraud_rules_error": fraud_rules_result.error if fraud_rules_result.ok is False else "",
        }
    )
    return render(request, "control_panel/billing_reconciliation.html", context)


@require_POST
def billing_gift_reverse(request: HttpRequest) -> HttpResponse:
    send_id = (request.POST.get("gift_send_id") or "").strip()
    reason = (request.POST.get("reason") or "").strip()
    if not send_id:
        messages.error(request, "Gift send ID is required.")
        return redirect("billing_reconciliation")
    if not 3 <= len(reason) <= 500:
        messages.error(request, "A reversal reason between 3 and 500 characters is required.")
        return redirect("billing_reconciliation")
    result = GoBFFClient().reverse_gift_send(send_id, reason)
    if result.ok:
        messages.success(
            request,
            f"Gift {send_id} refunded; {result.data.get('coins_refunded', 0)} coins returned. "
            f"Message retracted: {'yes' if result.data.get('message_retracted') else 'no'}.",
        )
    else:
        messages.error(request, f"Gift reversal failed: {result.error}")
    return redirect("billing_reconciliation")


@require_POST
def billing_wallet_review(request: HttpRequest, user_id: str) -> HttpResponse:
    action = (request.POST.get("action") or "").strip()
    note = (request.POST.get("note") or "").strip()
    if action not in {"collect_and_unfreeze", "write_off_and_unfreeze"}:
        messages.error(request, "Choose a valid wallet review action.")
        return redirect("billing_reconciliation")
    if not 10 <= len(note) <= 1000:
        messages.error(request, "A review note between 10 and 1000 characters is required.")
        return redirect("billing_reconciliation")
    result = GoBFFClient().review_frozen_wallet(user_id, action=action, note=note)
    if result.ok:
        messages.success(
            request,
            f"Wallet reviewed: {result.data.get('debt_collected', 0)} coins collected and "
            f"{result.data.get('debt_written_off', 0)} written off.",
        )
    else:
        messages.error(request, f"Wallet review failed: {result.error}")
    return redirect("billing_reconciliation")


@require_POST
def billing_fraud_case_resolve(request: HttpRequest, case_id: str) -> HttpResponse:
    resolution = (request.POST.get("resolution") or "").strip()
    note = (request.POST.get("note") or "").strip()
    if resolution not in {"cleared", "confirmed"} or not 10 <= len(note) <= 1000:
        messages.error(request, "Choose cleared or confirmed and provide a 10–1000 character review note.")
        return redirect("billing_reconciliation")
    result = GoBFFClient().resolve_economy_fraud_case(case_id, resolution=resolution, note=note)
    if result.ok:
        messages.success(request, f"Fraud case {case_id} marked {resolution}.")
    else:
        messages.error(request, f"Fraud case review failed: {result.error}")
    return redirect("billing_reconciliation")


@require_POST
def billing_fraud_rule_update(request: HttpRequest, rule_code: str) -> HttpResponse:
    try:
        payload = {
            "trigger_value": int(request.POST.get("trigger_value", "0")),
            "window_seconds": int(request.POST.get("window_seconds", "0")),
            "response_action": (request.POST.get("response_action") or "").strip(),
            "lock_seconds": int(request.POST.get("lock_seconds", "0")),
            "severity": (request.POST.get("severity") or "").strip(),
            "enabled": request.POST.get("enabled") == "on",
        }
    except ValueError:
        messages.error(request, "Fraud rule values must be valid numbers.")
        return redirect("billing_reconciliation")
    result = GoBFFClient().update_economy_fraud_rule(rule_code, payload)
    if result.ok:
        messages.success(request, f"Fraud rule {rule_code} updated.")
    else:
        messages.error(request, f"Fraud rule update failed: {result.error}")
    return redirect("billing_reconciliation")


# ── Billing: provider webhook ledger (PEN-01) ────────────────────────────────

@require_GET
def billing_webhook_events(request: HttpRequest) -> HttpResponse:
    return listing.simple_view(request, BILLING_WEBHOOKS, GoBFFClient().list_billing_webhook_events,
                               items_key="events", template="control_panel/billing_webhook_events.html",
                               title="Webhook events", base_context=_base_context, context_name="events")


# ── Revenue Analytics (FR-10) ─────────────────────────────────────────────────

@require_GET
def billing_revenue_analytics(request: HttpRequest) -> HttpResponse:
    """Windowed, per-currency revenue with live and sandbox kept apart.

    Definitions match the reconciliation report and the Business reports
    (documents/BUSINESS_REPORTS_2026-10-01.md)."""
    params: dict[str, str] = {}
    for key in ("since", "until"):
        value = request.GET.get(key, "").strip()
        if len(value) == 10 and value[4] == "-" and value[7] == "-":
            params[key] = value
    tz = request.GET.get("tz", "").strip()
    if tz in ("UTC", "Asia/Kolkata"):
        params["tz"] = tz
    mode = request.GET.get("mode", "").strip()
    if mode in ("live", "sandbox", "all"):
        params["mode"] = mode
    client = GoBFFClient()
    result = client.get_revenue_analytics(params)

    data = result.data if result.ok else {}
    context = _base_context()
    context.update(
        {
            "revenue": data.get("revenue", []) or [],
            "payments": data.get("payments", {}) or {},
            "coin_stats": data.get("coin_purchases", {}) or {},
            "sub_stats": data.get("subscriptions", {}) or {},
            "local_activations": data.get("local_activations", []) or [],
            "data_status": data.get("data_status", {}) or {},
            "window": data.get("window", {}) or {},
            "mode": data.get("mode", params.get("mode", "live")),
            "filters": params,
            "error": result.error,
        }
    )
    return render(request, "control_panel/billing_revenue.html", context)


# ── Safety / SOS ──────────────────────────────────────────────────────────────

@require_GET
def safety_sos(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    result = client.list_sos_alerts()
    alerts = [a for a in (result.data.get("alerts") or [] if result.ok and isinstance(result.data, dict) else []) if isinstance(a, dict)]

    context = _base_context()
    context.update(
        {
            "alerts": alerts,
            # The banner counts alerts still open, not resolved ones.
            "active_count": sum(1 for a in alerts if not a.get("resolved_at")),
            "error": result.error,
        }
    )
    return render(request, "control_panel/safety_sos.html", context)


@require_POST
def safety_sos_resolve(request: HttpRequest, alert_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.resolve_sos_alert(alert_id)
    if result.ok:
        messages.success(request, f"SOS alert {alert_id} resolved.")
    else:
        messages.error(request, f"Failed to resolve alert: {result.error}")
    return redirect("safety_sos")


# ── Account recovery (PEN-06) ─────────────────────────────────────────────────

RECOVERY_IDENTITY_CHECKS = [
    ("verified_identity_match", "Matched the identity verification on file"),
    ("account_detail_match", "Member confirmed account details only they would know"),
    ("other", "Other (describe in the note)"),
]


@require_GET
def account_recovery_queue(request: HttpRequest) -> HttpResponse:
    status = (request.GET.get("status") or "open").strip()
    client = GoBFFClient()
    result = client.list_account_recovery(status=status)
    context = _base_context()
    context.update(
        {
            "status_filter": status,
            "requests": result.data.get("requests", []) if result.ok else [],
            "identity_checks": RECOVERY_IDENTITY_CHECKS,
            "error": result.error,
        }
    )
    return render(request, "control_panel/account_recovery.html", context)


@require_POST
@never_cache
def account_recovery_resolve(request: HttpRequest, request_id: str) -> HttpResponse:
    action = (request.POST.get("action") or "").strip()
    identity_check = (request.POST.get("identity_check") or "").strip()
    note = (request.POST.get("resolution_note") or "").strip()
    client = GoBFFClient()
    result = client.resolve_account_recovery(
        request_id, action=action, identity_check=identity_check, resolution_note=note
    )
    if not result.ok:
        messages.error(request, f"Could not resolve recovery request: {result.error}")
        return redirect("account_recovery_queue")
    if action != "issue_recovery_code":
        messages.success(request, "Recovery request declined.")
        return redirect("account_recovery_queue")
    # The code is rendered once in this response and never stored in the
    # session, messages framework or logs.
    context = _base_context()
    context.update(
        {
            "recovery_code": result.data.get("recovery_code", ""),
            "code_expires_at": result.data.get("code_expires_at", ""),
        }
    )
    response = render(request, "control_panel/account_recovery_code.html", context)
    response["Cache-Control"] = "no-store"
    return response


# ── Level / XP progression ───────────────────────────────────────────────────

@require_GET
def progression_admin(request: HttpRequest) -> HttpResponse:
    status = (request.GET.get("status") or "open").strip()
    client = GoBFFClient()
    overview = client.progression_overview()
    fraud = client.list_progression_fraud(status=status)
    data = overview.data if overview.ok else {}
    context = _base_context()
    context.update(
        {
            "metrics": data.get("metrics", {}),
            "policies": data.get("policies", []),
            "experiments": data.get("experiments", []),
            "fraud_rules": data.get("fraud_rules", []),
            "fraud_cases": fraud.data.get("cases", []) if fraud.ok else [],
            "status_filter": status,
            "error": overview.error,
            "fraud_error": fraud.error,
        }
    )
    return render(request, "control_panel/progression.html", context)


@require_POST
def progression_policy_update(request: HttpRequest, source: str) -> HttpResponse:
    try:
        payload = {
            "base_xp": int(request.POST.get("base_xp") or 0),
            "daily_xp_cap": int(request.POST.get("daily_xp_cap") or 0),
            "daily_event_cap": int(request.POST.get("daily_event_cap") or 1),
            "cooldown_seconds": int(request.POST.get("cooldown_seconds") or 0),
            "enabled": request.POST.get("enabled") == "on",
        }
    except ValueError:
        messages.error(request, "XP policy values must be whole numbers.")
        return redirect("progression_admin")
    result = GoBFFClient().update_progression_policy(source, payload)
    if result.ok:
        messages.success(request, f"XP policy {source} updated.")
    else:
        messages.error(request, f"Policy update failed: {result.error}")
    return redirect("progression_admin")


@require_POST
def progression_experiment_update(request: HttpRequest, key: str) -> HttpResponse:
    status = (request.POST.get("status") or "draft").strip()
    stage = (request.POST.get("rollout_stage") or "draft").strip()
    stage_percent = {
        "draft": 0,
        "dogfood": 1,
        "five_percent": 5,
        "twenty_five_percent": 25,
        "general_availability": 100,
    }
    try:
        rollout = int(request.POST.get("rollout_percent") or stage_percent.get(stage, -1))
    except (TypeError, ValueError):
        rollout = -1
    owner = (request.POST.get("safety_stop_owner") or "").strip()
    evidence_uri = (request.POST.get("evidence_uri") or "").strip()
    decision_note = (request.POST.get("decision_note") or "").strip()
    if stage not in stage_percent or rollout != stage_percent[stage]:
        messages.error(request, "Choose a fixed rollout stage and its matching percentage.")
        return redirect("progression_admin")
    result = GoBFFClient().update_progression_experiment(
        key,
        status=status,
        rollout_stage=stage,
        rollout_percent=rollout,
        safety_stop_owner=owner,
        evidence_uri=evidence_uri,
        decision_note=decision_note,
    )
    if result.ok:
        messages.success(request, f"Experiment {key} updated.")
    else:
        messages.error(request, f"Experiment update failed: {result.error}")
    return redirect("progression_admin")


@require_POST
def progression_fraud_rule_update(request: HttpRequest, rule_code: str) -> HttpResponse:
    try:
        payload = {
            "rejected_attempt_threshold": int(request.POST.get("rejected_attempt_threshold") or 0),
            "window_seconds": int(request.POST.get("window_seconds") or 0),
            "review_sla_minutes": int(request.POST.get("review_sla_minutes") or 0),
            "severity": (request.POST.get("severity") or "").strip(),
            "enabled": request.POST.get("enabled") == "on",
            "tuning_note": (request.POST.get("tuning_note") or "").strip(),
        }
    except ValueError:
        messages.error(request, "Fraud policy limits must be whole numbers.")
        return redirect("progression_admin")
    result = GoBFFClient().update_progression_fraud_rule(rule_code, payload)
    if result.ok:
        messages.success(request, f"Fraud rule {rule_code} updated for review-only enforcement.")
    else:
        messages.error(request, f"Fraud rule update failed: {result.error}")
    return redirect("progression_admin")


@require_POST
def progression_fraud_resolve(request: HttpRequest, case_id: str) -> HttpResponse:
    status = (request.POST.get("status") or "").strip()
    resolution = (request.POST.get("resolution") or "").strip()
    if status not in {"dismissed", "confirmed"} or not resolution:
        messages.error(request, "A final status and resolution are required.")
        return redirect("progression_admin")
    result = GoBFFClient().resolve_progression_fraud(case_id, status, resolution)
    if result.ok:
        messages.success(request, f"Fraud case {case_id} resolved.")
    else:
        messages.error(request, f"Fraud case update failed: {result.error}")
    return redirect("progression_admin")


@require_POST
def progression_user_adjust(request: HttpRequest) -> HttpResponse:
    user_id = (request.POST.get("user_id") or "").strip()
    reason = (request.POST.get("reason") or "").strip()
    try:
        amount = int(request.POST.get("amount") or 0)
    except ValueError:
        amount = 0
    if not user_id or amount == 0 or len(reason) < 10:
        messages.error(
            request, "User ID, a non-zero amount, and a 10-character reason are required."
        )
        return redirect("progression_admin")
    result = GoBFFClient().adjust_user_xp(user_id, amount, reason)
    if result.ok:
        messages.success(request, f"Posted an audited {amount:+d} XP adjustment.")
    else:
        messages.error(request, f"XP adjustment failed: {result.error}")
    return redirect("progression_admin")


@require_POST
def progression_user_control(request: HttpRequest) -> HttpResponse:
    user_id = (request.POST.get("user_id") or "").strip()
    reason = (request.POST.get("reason") or "").strip()
    try:
        risk = float(request.POST.get("risk_multiplier") or 1)
    except ValueError:
        risk = 0
    if not user_id or risk < 0.5 or risk > 1:
        messages.error(request, "User ID and a risk multiplier from 0.5 to 1.0 are required.")
        return redirect("progression_admin")
    result = GoBFFClient().set_user_progression_control(
        user_id,
        progression_frozen=request.POST.get("progression_frozen") == "on",
        risk_multiplier=risk,
        reason=reason,
    )
    if result.ok:
        messages.success(request, "User progression control updated.")
    else:
        messages.error(request, f"Progression control failed: {result.error}")
    return redirect("progression_admin")
