from __future__ import annotations

from urllib.parse import quote_plus

from django.conf import settings
from django.contrib import messages
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect, render
from django.views.decorators.http import require_GET, require_POST

from .services.go_client import GoBFFClient


def _base_context() -> dict:
    return {
        "project_name": settings.PROJECT_DISPLAY_NAME,
    }


# ── Dashboard ─────────────────────────────────────────────────────────────────

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
            "pending_verifications": verifications.data.get("verifications", []) if verifications.ok else [],
            "verification_error": verifications.error,
            "activities": activities.data.get("activities", []) if activities.ok else [],
            "activity_error": activities.error,
            "dashboard_panels": analytics.data.get("metrics", {}).get("dashboard_panels", []) if analytics.ok else [],
            "event_taxonomy": analytics.data.get("metrics", {}).get("event_taxonomy", {}) if analytics.ok else {},
            "data_quality_checks": analytics.data.get("metrics", {}).get("data_quality_checks", {}) if analytics.ok else {},
            "spotlight_metrics": analytics.data.get("metrics", {}).get("spotlight_metrics", {}) if analytics.ok else {},
            "analytics_error": analytics.error,
            "focus_user_id": focus_user_id,
            "kibana_discover_index": settings.KIBANA_DISCOVER_INDEX,
            "kibana_kql": kibana_kql,
            "kibana_discover_url": kibana_discover_url,
            "kibana_dashboard_url": kibana_dashboard_url,
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
    try:
        limit = int(request.GET.get("limit", "200"))
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
    result = client.action_appeal(appeal_id, status, resolution_reason)
    if result.ok:
        messages.success(request, f"Appeal {appeal_id} updated to {status}.")
    else:
        messages.error(request, f"Failed to update appeal {appeal_id}: {result.error}")
    return redirect("appeal_queue")


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


@require_POST
def action_report(request: HttpRequest, report_id: str) -> HttpResponse:
    action = (request.POST.get("action") or "").strip()
    reason = (request.POST.get("reason") or "").strip()

    if not action:
        messages.error(request, "Action is required.")
        return redirect("moderation_reports")

    client = GoBFFClient()
    result = client.action_report(report_id, action, reason)
    if result.ok:
        messages.success(request, f"Report {report_id} marked as {action}.")
    else:
        messages.error(request, f"Failed to action report {report_id}: {result.error}")
    return redirect("moderation_reports")


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
            "categories": ["roses", "sparkle", "playful", "luxury", "seasonal", "themed_pack", "reaction", "experience", "exclusive"],
            "rarity_tiers": ["free", "common", "uncommon", "rare", "epic", "legendary"],
            "prev_offset": max(0, offset - limit),
            "next_offset": offset + limit,
        }
    )
    return render(request, "control_panel/catalog.html", context)


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
            import os, uuid
            ext = os.path.splitext(uploaded.name)[1] or ".png"
            fname = f"gifts/{uuid.uuid4().hex}{ext}"
            dest = os.path.join("static", "uploads", fname)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as f:
                for chunk in uploaded.chunks():
                    f.write(chunk)
            gif_url = f"/static/uploads/{fname}"

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
    context["categories"] = ["roses", "sparkle", "playful", "luxury", "seasonal"]
    context["tiers"] = ["free", "common", "uncommon", "rare", "epic", "legendary"]
    return render(request, "control_panel/catalog_edit.html", context)


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
        if uploaded:
            import os, uuid
            ext = os.path.splitext(uploaded.name)[1] or ".png"
            fname = f"gifts/{uuid.uuid4().hex}{ext}"
            dest = os.path.join("static", "uploads", fname)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as f:
                for chunk in uploaded.chunks():
                    f.write(chunk)
            gif_url = f"/static/uploads/{fname}"

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
        result = client.update_catalog_gift(gift_id, payload)
        if result.ok:
            messages.success(request, "Gift updated successfully.")
            return redirect("catalog_list")
        messages.error(request, f"Failed to update gift: {result.error}")

    all_gifts = client.list_catalog_gifts()
    gift = next(
        (g for g in all_gifts.data.get("gifts", []) if str(g.get("id")) == gift_id),
        None,
    )
    context = _base_context()
    context.update(
        {
            "gift": gift,
            "gift_id": gift_id,
            "categories": ["roses", "sparkle", "playful", "luxury", "seasonal"],
            "tiers": ["free", "common", "uncommon", "rare", "epic", "legendary"],
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

@require_GET
def user_list(request: HttpRequest) -> HttpResponse:
    q = request.GET.get("q", "").strip()
    status = request.GET.get("status", "").strip()
    gender = request.GET.get("gender", "").strip()
    verified = request.GET.get("verified", "").strip()
    try:
        offset = int(request.GET.get("offset", "0"))
    except ValueError:
        offset = 0
    limit = 50

    client = GoBFFClient()
    result = client.list_users(limit=limit, offset=offset, q=q, status=status, gender=gender, verified=verified)

    users = result.data.get("users", []) if result.ok else []
    total = result.data.get("total", 0) if result.ok else 0

    # Compute KPI counts from returned users
    active_count = sum(1 for u in users if not u.get("suspended_at") and not u.get("is_banned"))
    suspended_count = sum(1 for u in users if u.get("suspended_at"))
    banned_count = sum(1 for u in users if u.get("is_banned"))
    verified_count = sum(1 for u in users if u.get("is_verified"))
    verified_pct = round(verified_count / len(users) * 100) if users else 0

    context = _base_context()
    context.update(
        {
            "q": q,
            "status_filter": status,
            "gender_filter": gender,
            "verified_filter": verified,
            "offset": offset,
            "limit": limit,
            "users": users,
            "total": total,
            "active_count": active_count,
            "suspended_count": suspended_count,
            "banned_count": banned_count,
            "verified_pct": verified_pct,
            "error": result.error,
            "prev_offset": max(0, offset - limit),
            "next_offset": offset + limit,
        }
    )
    return render(request, "control_panel/users.html", context)


def user_create(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        payload = {
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

        if not payload["name"] or not payload["phone_number"]:
            messages.error(request, "Name and Phone are required.")
            ctx = _base_context()
            ctx["form_data"] = payload
            return render(request, "control_panel/user_form.html", ctx)

        client = GoBFFClient()
        result = client.create_user(payload)
        if result.ok:
            messages.success(request, f"User '{payload['name']}' created successfully.")
            return redirect("user_list")
        messages.error(request, f"Failed to create user: {result.error}")
        ctx = _base_context()
        ctx["form_data"] = payload
        return render(request, "control_panel/user_form.html", ctx)

    context = _base_context()
    context["form_data"] = {}
    return render(request, "control_panel/user_form.html", context)


def user_edit(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()

    if request.method == "POST":
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
    user = result.data.get("user", {}) if result.ok else {}

    context = _base_context()
    context.update({"form_data": user, "user_id": user_id, "editing": True})
    return render(request, "control_panel/user_form.html", context)


@require_POST
def user_delete(request: HttpRequest, user_id: str) -> HttpResponse:
    client = GoBFFClient()
    result = client.delete_user(user_id)
    if result.ok:
        messages.success(request, f"User {user_id} deleted.")
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

    wallet_transactions = []
    tx_result = client.list_billing_transactions(limit=20)
    if tx_result.ok:
        all_tx = tx_result.data.get("transactions", [])
        wallet_transactions = [t for t in all_tx if t.get("user_id") == user_id]

    context = _base_context()
    context.update(
        {
            "user": user,
            "user_id": user_id,
            "wallet_balance": wallet_balance,
            "wallet_transactions": wallet_transactions,
            "error": result.error,
        }
    )
    return render(request, "control_panel/user_detail.html", context)


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

    client = GoBFFClient()
    result = client.grant_coins(user_id, coins, reason)
    if result.ok:
        messages.success(request, f"Granted {coins} coins to {user_id}.")
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
    result = client.update_config_flag(key, value)
    if result.ok:
        state = "enabled" if value else "disabled"
        messages.success(request, f"Flag '{key}' {state}.")
    else:
        messages.error(request, f"Failed to update flag '{key}': {result.error}")
    return redirect("config_flags")


# ── Engagement Prompts ────────────────────────────────────────────────────────

@require_GET
def engagement_prompts(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    result = client.list_engagement_prompts()

    context = _base_context()
    context.update(
        {
            "prompts": result.data.get("prompts", []) if result.ok else [],
            "error": result.error,
        }
    )
    return render(request, "control_panel/engagement_prompts.html", context)


def engagement_prompt_new(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        payload = {
            "prompt_text": request.POST.get("prompt_text", "").strip(),
            "category": request.POST.get("category", "icebreaker").strip(),
            "is_active": True,
        }
        if not payload["prompt_text"]:
            messages.error(request, "Prompt text is required.")
        else:
            client = GoBFFClient()
            result = client.create_engagement_prompt(payload)
            if result.ok:
                messages.success(request, "Prompt created successfully.")
                return redirect("engagement_prompts")
            messages.error(request, f"Failed to create prompt: {result.error}")

    context = _base_context()
    context["categories"] = ["icebreaker", "deep_dive", "fun", "values", "lifestyle"]
    return render(request, "control_panel/engagement_prompt_edit.html", context)


def engagement_prompt_edit(request: HttpRequest, prompt_id: str) -> HttpResponse:
    client = GoBFFClient()

    if request.method == "POST":
        payload = {
            "prompt_text": request.POST.get("prompt_text", "").strip(),
            "category": request.POST.get("category", "icebreaker").strip(),
        }
        result = client.update_engagement_prompt(prompt_id, payload)
        if result.ok:
            messages.success(request, "Prompt updated successfully.")
            return redirect("engagement_prompts")
        messages.error(request, f"Failed to update prompt: {result.error}")

    all_prompts = client.list_engagement_prompts()
    prompt = next(
        (p for p in all_prompts.data.get("prompts", []) if str(p.get("id")) == prompt_id),
        None,
    )
    context = _base_context()
    context.update(
        {
            "prompt": prompt,
            "prompt_id": prompt_id,
            "categories": ["icebreaker", "deep_dive", "fun", "values", "lifestyle"],
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
    context["coming_soon"] = True
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

    stats = stats_result.data if stats_result.ok else {}

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
            "unique_buyers": stats.get("unique_buyers", 0),
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


@require_GET
def billing_transactions(request: HttpRequest) -> HttpResponse:
    try:
        offset = int(request.GET.get("offset", "0"))
    except ValueError:
        offset = 0
    limit = 50

    client = GoBFFClient()
    result = client.list_billing_transactions(limit=limit, offset=offset)

    context = _base_context()
    context.update(
        {
            "transactions": result.data.get("transactions", []) if result.ok else [],
            "total": result.data.get("total", 0) if result.ok else 0,
            "offset": offset,
            "limit": limit,
            "error": result.error,
            "prev_offset": max(0, offset - limit),
            "next_offset": offset + limit,
        }
    )
    return render(request, "control_panel/billing_transactions.html", context)


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
    package = next(
        (p for p in all_pkgs.data.get("packages", []) if str(p.get("id")) == package_id),
        None,
    )
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
    try:
        offset = int(request.GET.get("offset", "0"))
    except ValueError:
        offset = 0
    limit = 50
    status_filter = request.GET.get("status", "").strip()
    plan_filter = request.GET.get("plan_code", "").strip()

    client = GoBFFClient()
    result = client.list_subscriptions(limit=limit, offset=offset, status=status_filter, plan_code=plan_filter)

    context = _base_context()
    context.update(
        {
            "subscriptions": result.data.get("subscriptions", []) if result.ok else [],
            "total": result.data.get("total", 0) if result.ok else 0,
            "offset": offset,
            "limit": limit,
            "status_filter": status_filter,
            "plan_filter": plan_filter,
            "error": result.error,
            "prev_offset": max(0, offset - limit),
            "next_offset": offset + limit,
        }
    )
    return render(request, "control_panel/billing_subscriptions.html", context)


# ── Billing: Payments (FR-09) ─────────────────────────────────────────────────

@require_GET
def billing_payments(request: HttpRequest) -> HttpResponse:
    try:
        offset = int(request.GET.get("offset", "0"))
    except ValueError:
        offset = 0
    limit = 50
    status_filter = request.GET.get("status", "").strip()

    client = GoBFFClient()
    result = client.list_payments(limit=limit, offset=offset, status=status_filter)

    context = _base_context()
    context.update(
        {
            "payments": result.data.get("payments", []) if result.ok else [],
            "total": result.data.get("total", 0) if result.ok else 0,
            "offset": offset,
            "limit": limit,
            "status_filter": status_filter,
            "error": result.error,
            "prev_offset": max(0, offset - limit),
            "next_offset": offset + limit,
        }
    )
    return render(request, "control_panel/billing_payments.html", context)


# ── Revenue Analytics (FR-10) ─────────────────────────────────────────────────

@require_GET
def billing_revenue_analytics(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    result = client.get_revenue_analytics()

    data = result.data if result.ok else {}
    coin_stats = data.get("coin_purchases", {})
    sub_stats = data.get("subscriptions", {})
    pay_stats = data.get("payments", {})

    context = _base_context()
    context.update(
        {
            "coin_stats": coin_stats,
            "sub_stats": sub_stats,
            "pay_stats": pay_stats,
            "error": result.error,
        }
    )
    return render(request, "control_panel/billing_revenue.html", context)


# ── Safety / SOS ──────────────────────────────────────────────────────────────

@require_GET
def safety_sos(request: HttpRequest) -> HttpResponse:
    client = GoBFFClient()
    result = client.list_sos_alerts()

    context = _base_context()
    context.update(
        {
            "alerts": result.data.get("alerts", []) if result.ok else [],
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

