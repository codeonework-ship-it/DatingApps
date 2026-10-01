"""City pilot operations. Authorization and experiment gates are enforced by the BFF."""
from datetime import datetime, timezone
import uuid

from django.contrib import messages
from django.shortcuts import redirect, render
from django.views.decorators.http import require_GET, require_POST

from .services.go_client import GoBFFClient


def _utc(value):
    parsed = datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.isoformat()


@require_GET
def city_pilot(request):
    client = GoBFFClient()
    result = client.city_pilot()
    data = result.data if result.ok else {}
    pilot = data.get("pilot")
    experiences = []
    error = result.error
    if pilot:
        events = client.city_pilot_experiences(pilot["id"])
        experiences = events.data.get("experiences", []) if events.ok else []
        error = error or events.error
    return render(request, "control_panel/city_pilot.html", {
        **data, "project_name": "AegisConnect", "pilot": pilot,
        "experiences": experiences, "error": error,
        "experience_id": str(uuid.uuid4()),
    })


@require_POST
def city_pilot_save(request):
    try:
        payload = {key: request.POST.get(key, "").strip() for key in ("id", "city", "country", "owner", "safety_owner")}
        for key in ("version", "capacity", "minimum_pairs", "conversation_target", "plan_target", "date_target"):
            payload[key] = int(request.POST.get(key) or "0")
        for key in ("starts_at", "closes_at"):
            payload[key] = _utc(request.POST.get(key, ""))
    except (ValueError, TypeError):
        messages.error(request, "Use valid UTC dates and whole-number targets.")
        return redirect("city_pilot")
    result = GoBFFClient().save_city_pilot(payload)
    (messages.success if result.ok else messages.error)(request, "Pilot draft saved." if result.ok else result.error)
    return redirect("city_pilot")


@require_POST
def city_pilot_stage(request, pilot_id):
    try:
        version = int(request.POST.get("version", "0"))
    except ValueError:
        messages.error(request, "Refresh the pilot before changing its stage.")
        return redirect("city_pilot")
    result = GoBFFClient().transition_city_pilot(pilot_id, {
        "status": request.POST.get("status", ""), "version": version,
        "note": request.POST.get("note", "").strip(),
        "safety_ready": request.POST.get("safety_ready") == "on",
    })
    (messages.success if result.ok else messages.error)(request, "Pilot stage updated." if result.ok else result.error)
    return redirect("city_pilot")


@require_POST
def city_pilot_experience_create(request, pilot_id):
    try:
        payload = {key: request.POST.get(key, "").strip() for key in ("id", "title", "summary", "venue", "host", "accessibility", "safety_contact")}
        payload["capacity"] = int(request.POST.get("capacity", "0"))
        payload["host_vetted"] = request.POST.get("host_vetted") == "on"
        for key in ("starts_at", "ends_at", "registration_closes_at"):
            payload[key] = _utc(request.POST.get(key, ""))
    except (ValueError, TypeError):
        messages.error(request, "Use valid UTC dates and a capacity from 2 to 30.")
        return redirect("city_pilot")
    result = GoBFFClient().create_city_pilot_experience(pilot_id, payload)
    (messages.success if result.ok else messages.error)(request, "Free experience published to pilot members." if result.ok else result.error)
    return redirect("city_pilot")


@require_POST
def city_pilot_experience_cancel(request, pilot_id, event_id):
    result = GoBFFClient().cancel_city_pilot_experience(pilot_id, event_id)
    (messages.success if result.ok else messages.error)(request, "Experience cancelled." if result.ok else result.error)
    return redirect("city_pilot")
