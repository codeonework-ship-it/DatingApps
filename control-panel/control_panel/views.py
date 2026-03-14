from __future__ import annotations

from urllib.parse import quote_plus

from django.conf import settings
from django.contrib import messages
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect, render
from django.views.decorators.http import require_GET, require_POST

from .services.go_client import GoBFFClient


def _base_context() -> dict[str, str]:
    return {
        "project_name": settings.PROJECT_DISPLAY_NAME,
    }


@require_GET
def dashboard(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    health = client.health()
    readiness = client.readiness()
    verifications = client.list_verifications(limit=25, status="pending")
    activities = client.list_activities(limit=25)
    analytics = client.analytics_overview()

    focus_user_id = (request.GET.get("user_id") or "").strip()
    kibana_kql = "*"
    if focus_user_id:
        kibana_kql = f'user_id : "{focus_user_id}" or userId : "{focus_user_id}"'
    kibana_discover_url = (
        f"{settings.KIBANA_BASE_URL}/app/discover#/?_g=(time:(from:now-24h,to:now))"
        f"&_a=(query:(language:kuery,query:'{quote_plus(kibana_kql)}'))"
    )
    kibana_dashboard_url = (
        f"{settings.KIBANA_BASE_URL}{settings.KIBANA_DASHBOARD_PATH}"
        f"?_g=(time:(from:now-24h,to:now))&user_id={quote_plus(focus_user_id)}"
    )

    context = _base_context()
    context.update(
        {
            "health": health.data if health.ok else {"status": "unreachable"},
            "health_error": health.error,
            "readiness": readiness.data if readiness.ok else {"status": "unreachable"},
            "readiness_error": readiness.error,
            "pending_verifications": verifications.data.get("verifications", [])
            if verifications.ok
            else [],
            "verification_error": verifications.error,
            "activities": activities.data.get("activities", []) if activities.ok else [],
            "activity_error": activities.error,
            "dashboard_panels": analytics.data.get("metrics", {}).get("dashboard_panels", [])
            if analytics.ok
            else [],
            "event_taxonomy": analytics.data.get("metrics", {}).get("event_taxonomy", {})
            if analytics.ok
            else {},
            "data_quality_checks": analytics.data.get("metrics", {}).get("data_quality_checks", {})
            if analytics.ok
            else {},
            "spotlight_metrics": analytics.data.get("metrics", {}).get("spotlight_metrics", {})
            if analytics.ok
            else {},
            "analytics_error": analytics.error,
            "focus_user_id": focus_user_id,
            "kibana_discover_index": settings.KIBANA_DISCOVER_INDEX,
            "kibana_kql": kibana_kql,
            "kibana_discover_url": kibana_discover_url,
            "kibana_dashboard_url": kibana_dashboard_url,
        }
    )
    return render(request, "control_panel/dashboard.html", context)


@require_GET
def verification_queue(request: HttpRequest) -> HttpResponse:
    status = request.GET.get("status", "").strip()
    limit_raw = request.GET.get("limit", "100").strip()
    try:
        limit = int(limit_raw)
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


@require_GET
def activity_feed(request: HttpRequest) -> HttpResponse:
    limit_raw = request.GET.get("limit", "200").strip()
    try:
        limit = int(limit_raw)
    except ValueError:
        limit = 200

    client = GoBFFClient()
    result = client.list_activities(limit=limit)

    context = _base_context()
    context.update(
        {
            "limit": limit,
            "activities": result.data.get("activities", []) if result.ok else [],
            "error": result.error,
        }
    )
    return render(request, "control_panel/activities.html", context)


@require_GET
def appeal_queue(request: HttpRequest) -> HttpResponse:
    status = request.GET.get("status", "").strip()
    limit_raw = request.GET.get("limit", "100").strip()
    try:
        limit = int(limit_raw)
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
    result = client.action_appeal(appeal_id, status, resolution_reason)
    if result.ok:
        messages.success(request, f"Appeal {appeal_id} updated to {status}.")
    else:
        messages.error(request, f"Failed to update appeal {appeal_id}: {result.error}")
    return redirect("appeal_queue")

