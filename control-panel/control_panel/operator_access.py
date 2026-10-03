"""Which console pages an operator can use, for the sidebar (CON-05).

The console has no permission decorators of its own: Go's security middleware
(``principalCanAccessAdminRoute`` in
backend/internal/bff/mobile/server_security.go) allows or refuses every
/v1/admin/... call, and a console page is only as usable as the BFF reads it
makes. So the sidebar is derived from that one rule:

* ``can_access_admin_route`` is a line-for-line mirror of the Go function.
  Change both together.
* ``NAV_ITEMS`` names, for each sidebar link, the BFF admin path(s) its page
  reads (the paths in services/go_client.py). A link is shown when Go would
  allow at least one of them.

Go does not report an operator's own roles, so ``resolve_operator_roles``
works them out at login (see its docstring) and the login view stores them in
the session. When roles are unknown every link is shown, as before; Go still
enforces every request either way.
"""
from __future__ import annotations

from typing import Any, Iterable, NamedTuple

from .operator_context import OPERATOR_ROLE_LABELS

ROLES_SESSION_KEY = "operator_roles"

_READ_METHODS = {"GET", "HEAD", "OPTIONS"}
_LOG_READ_PREFIXES = ("users", "activities", "activity", "members/", "audit-events", "events", "analytics/")
_TS_ROUTE_PREFIXES = ("moderation/", "verifications", "safety/", "support/", "growth/fraud-graph")
_TS_USER_ACTIONS = ("/suspend", "/unsuspend", "/ban", "/unban", "/verify")
_FINANCE_READ_PREFIXES = (
    "billing/stats", "billing/transactions", "billing/subscriptions", "billing/payments",
    "billing/webhook-events", "billing/reconciliation", "billing/revenue-analytics", "billing/plans",
    "billing/coin-packages",
)
_OPS_ADMIN_PREFIXES = ("catalog/", "config/", "engagement/", "billing/", "progression", "support/", "growth/", "system/")
_ANALYST_READ_PREFIXES = (
    "analytics/", "activities", "activity", "members/", "audit-events", "events", "billing/stats", "billing/transactions",
    "billing/subscriptions", "billing/payments", "billing/webhook-events", "billing/reconciliation",
    "billing/revenue-analytics", "users", "system/requests", "system/capacity", "system/third-party",
)


def can_access_admin_route(roles: Iterable[str], method: str, path: str) -> bool:
    """Mirror of Go ``principalCanAccessAdminRoute``. ``path`` is relative to
    /v1/admin/, e.g. ``billing/stats``."""
    has = set(roles)
    if "admin" in has:
        return True
    path = path.strip("/")
    is_read = method.upper() in _READ_METHODS
    if path == "client-errors" or path.startswith("client-errors/"):
        return "ops_admin" in has or (is_read and "analyst" in has)
    if path == "support" or path.startswith("support/"):
        if has & {"support", "ops_admin", "trust_safety", "moderator"}:
            return True
        return is_read and "analyst" in has and path == "support/dashboard"
    if "support" in has and is_read and path == "analytics/overview":
        return True
    if path.startswith("analytics/") and path != "analytics/overview":
        return is_read and "analyst" in has and not path.startswith("analytics/excluded-accounts")
    if path.startswith("growth/city-pilot") and "trust_safety" in has:
        return is_read or path.endswith("/stage") or path.endswith("/cancel")
    if path.startswith("growth/city-pilot") and "analyst" in has and is_read:
        return True
    if "trust_safety" in has and (
        path.startswith("billing/fraud/cases") or (is_read and path.startswith("billing/fraud/rules"))
    ):
        return True
    if has & {"trust_safety", "moderator"}:
        if path.startswith(_TS_ROUTE_PREFIXES):
            return True
        if is_read and path.startswith(_LOG_READ_PREFIXES):
            return True
        if path.startswith("users/") and path.endswith(_TS_USER_ACTIONS):
            return True
    if path.startswith("business/"):
        if is_read:
            return bool(has & {"finance", "ops_admin", "analyst"})
        if path.startswith("business/marketing-spend"):
            return "finance" in has
        if path == "business/markets":
            return bool(has & {"finance", "ops_admin"})
        return False
    if "finance" in has and is_read:
        if path.startswith(_FINANCE_READ_PREFIXES) or path == "analytics/overview":
            return True
    if "ops_admin" in has:
        if path.startswith(_OPS_ADMIN_PREFIXES):
            return True
        if is_read and path.startswith(_LOG_READ_PREFIXES):
            return True
    if "analyst" in has and is_read:
        return path.startswith(_ANALYST_READ_PREFIXES)
    return False


# (url name, sidebar section, BFF admin paths the page reads). An empty tuple
# means the page needs no admin route (the Command Center copes with any role).
NAV_ITEMS: tuple[tuple[str, str, tuple[str, ...]], ...] = (
    ("dashboard", "overview", ()),
    ("catalog_list", "content", ("catalog/gifts",)),
    ("engagement_prompts", "content", ("engagement/prompts",)),
    ("engagement_nudges", "content", ("engagement/nudges",)),
    ("progression_admin", "content", ("progression", "progression/fraud")),
    ("city_pilot", "content", ("growth/city-pilot",)),
    ("user_list", "users", ("users",)),
    ("verification_queue", "users", ("verifications",)),
    ("media_moderation_queue", "moderation", ("moderation/media",)),
    ("blog_reviews", "moderation", ("moderation/blog",)),
    ("photo_themes", "moderation", ("engagement/photo-themes",)),
    ("rooms", "moderation", ("moderation/rooms",)),
    ("group_covers", "moderation", ("moderation/group-covers",)),
    ("moderation_reports", "moderation", ("moderation/reports",)),
    ("appeal_queue", "moderation", ("moderation/appeals",)),
    ("support_queue", "support", ("support/tickets",)),
    ("support_dashboard", "support", ("support/dashboard",)),
    ("support_canned_responses", "support", ("support/canned-responses",)),
    ("report_catalog", "analytics", (
        "business/revenue", "business/subscriptions", "business/conversion", "business/coins",
        "business/referrals", "business/marketing-spend", "analytics/kpis", "analytics/trends",
    )),
    ("analytics_overview", "analytics", ("analytics/kpis", "analytics/trends")),
    ("analytics_funnel", "analytics", ("analytics/funnel",)),
    ("analytics_retention", "analytics", ("analytics/retention",)),
    ("analytics_engagement", "analytics", ("analytics/engagement",)),
    ("analytics_liquidity", "analytics", ("analytics/liquidity",)),
    ("analytics_safety", "analytics", ("analytics/safety",)),
    ("analytics_data", "analytics", ("analytics/snapshots", "analytics/excluded-accounts")),
    ("business_revenue", "business", ("business/revenue",)),
    ("business_subscriptions", "business", ("business/subscriptions",)),
    ("business_conversion", "business", ("business/conversion", "business/funnel")),
    ("business_coins", "business", ("business/coins",)),
    ("business_referrals", "business", ("business/referrals",)),
    ("business_markets", "business", ("business/markets",)),
    ("business_investor_pack", "business", ("business/investor-pack",)),
    ("business_spend", "business", ("business/marketing-spend",)),
    ("billing_dashboard", "platform", ("billing/plans", "billing/coin-packages", "billing/transactions", "billing/stats")),
    ("config_flags", "platform", ("config/flags",)),
    ("growth_governance", "platform", ("growth/fraud-graph",)),
    ("safety_sos", "safety", ("safety/sos-alerts",)),
    ("account_recovery_queue", "safety", ("safety/account-recovery",)),
    ("member_activity", "logs", ("activity",)),
    ("audit_log", "logs", ("audit-events",)),
    ("domain_events", "logs", ("events", "events/metrics")),
    ("client_errors", "logs", ("client-errors",)),
    ("system_events", "logs", ("system/events", "system/requests", "system/capacity", "system/third-party")),
)


class ConsoleAction(NamedTuple):
    """The BFF admin call a console POST makes, and where to send the
    operator back to when their role cannot make it. ``path`` is formatted
    with the view's URL kwargs; ids that arrive in the form body are written
    as ``-`` because Go's rule only looks at the route's shape."""

    method: str
    path: str
    back: str


# Every console POST that changes something (url name -> the call it makes).
# ``OperatorRoleGateMiddleware`` refuses the POST up front when the operator's
# stored roles cannot make the call, so Go is never asked and the operator is
# told why; with unknown roles Go decides, as before. A test checks that every
# POST-accepting console route is listed here.
CONSOLE_ACTIONS: dict[str, ConsoleAction] = {
    # Analytics (admin only for rebuilds and test-account flags)
    "analytics_rebuild": ConsoleAction("POST", "analytics/snapshots/rebuild", "analytics_data"),
    "analytics_exclude": ConsoleAction("POST", "analytics/excluded-accounts", "analytics_data"),
    "analytics_include": ConsoleAction("DELETE", "analytics/excluded-accounts/{member_id}", "analytics_data"),
    # Business
    "business_market_save": ConsoleAction("POST", "business/markets", "business_markets"),
    "business_spend_save": ConsoleAction("POST", "business/marketing-spend", "business_spend"),
    "business_spend_delete": ConsoleAction("DELETE", "business/marketing-spend/{spend_id}", "business_spend"),
    # Engagement
    "photo_theme_save": ConsoleAction("POST", "engagement/photo-themes", "photo_themes"),
    "engagement_prompt_new": ConsoleAction("POST", "engagement/prompts", "engagement_prompts"),
    "engagement_prompt_edit": ConsoleAction("PUT", "engagement/prompts/{prompt_id}", "engagement_prompts"),
    "engagement_prompt_activate": ConsoleAction("POST", "engagement/prompts/{prompt_id}/activate", "engagement_prompts"),
    # Moderation
    "room_action": ConsoleAction("POST", "moderation/rooms/{room_id}/actions", "room_detail"),
    "room_role": ConsoleAction("POST", "moderation/rooms/{room_id}/roles", "room_detail"),
    "group_cover_decision": ConsoleAction("POST", "moderation/group-covers/{cover_id}/decision", "group_covers"),
    "blog_decision": ConsoleAction("POST", "moderation/blog/{case_id}", "blog_reviews"),
    "action_report": ConsoleAction("POST", "moderation/reports/{report_id}/action", "moderation_reports"),
    "media_moderation_decision": ConsoleAction("POST", "moderation/media/{photo_id}/decision", "media_moderation_queue"),
    "action_appeal": ConsoleAction("POST", "moderation/appeals/{appeal_id}/action", "appeal_queue"),
    "approve_verification": ConsoleAction("POST", "verifications/{user_id}/approve", "verification_queue"),
    "reject_verification": ConsoleAction("POST", "verifications/{user_id}/reject", "verification_queue"),
    # City pilot
    "city_pilot_save": ConsoleAction("POST", "growth/city-pilot", "city_pilot"),
    "city_pilot_stage": ConsoleAction("POST", "growth/city-pilot/{pilot_id}/stage", "city_pilot"),
    "city_pilot_experience_create": ConsoleAction("POST", "growth/city-pilot/{pilot_id}/experiences", "city_pilot"),
    "city_pilot_experience_cancel": ConsoleAction(
        "POST", "growth/city-pilot/{pilot_id}/experiences/{event_id}/cancel", "city_pilot"),
    # Logs
    "client_error_status": ConsoleAction("POST", "client-errors/{issue_id}/status", "client_error_detail"),
    # Support
    "support_bulk": ConsoleAction("POST", "support/tickets/bulk", "support_queue"),
    "support_canned_save": ConsoleAction("POST", "support/canned-responses", "support_canned_responses"),
    "support_canned_deactivate": ConsoleAction(
        "DELETE", "support/canned-responses/{response_id}", "support_canned_responses"),
    "support_ticket_reply": ConsoleAction("POST", "support/tickets/{ticket_id}/messages", "support_ticket_detail"),
    "support_ticket_update": ConsoleAction("PATCH", "support/tickets/{ticket_id}", "support_ticket_detail"),
    "support_ticket_claim": ConsoleAction("POST", "support/tickets/{ticket_id}/claim", "support_ticket_detail"),
    "support_ticket_merge": ConsoleAction("POST", "support/tickets/{ticket_id}/merge", "support_ticket_detail"),
    # Gift catalog
    "catalog_new": ConsoleAction("POST", "catalog/gifts", "catalog_list"),
    "catalog_edit": ConsoleAction("PUT", "catalog/gifts/{gift_id}", "catalog_list"),
    "catalog_toggle": ConsoleAction("POST", "catalog/gifts/{gift_id}/toggle", "catalog_list"),
    "catalog_delete": ConsoleAction("DELETE", "catalog/gifts/{gift_id}", "catalog_list"),
    # Users
    "user_create": ConsoleAction("POST", "users", "user_list"),
    "user_edit": ConsoleAction("PUT", "users/{user_id}", "user_detail"),
    "user_delete": ConsoleAction("DELETE", "users/{user_id}", "user_detail"),
    "user_suspend": ConsoleAction("POST", "users/{user_id}/suspend", "user_detail"),
    "user_unsuspend": ConsoleAction("POST", "users/{user_id}/unsuspend", "user_detail"),
    "user_ban": ConsoleAction("POST", "users/{user_id}/ban", "user_detail"),
    "user_unban": ConsoleAction("POST", "users/{user_id}/unban", "user_detail"),
    "user_force_verify": ConsoleAction("POST", "users/{user_id}/verify", "user_detail"),
    "user_grant_coins": ConsoleAction("POST", "billing/grant-coins", "user_detail"),
    # Platform
    "config_flag_toggle": ConsoleAction("PUT", "config/flags/{key}", "config_flags"),
    # Progression
    "progression_policy_update": ConsoleAction("PUT", "progression/policies/{source}", "progression_admin"),
    "progression_experiment_update": ConsoleAction("PUT", "progression/experiments/{key}", "progression_admin"),
    "progression_fraud_rule_update": ConsoleAction("PUT", "progression/fraud-rules/{rule_code}", "progression_admin"),
    "progression_fraud_resolve": ConsoleAction("POST", "progression/fraud/{case_id}/resolve", "progression_admin"),
    "progression_user_adjust": ConsoleAction("POST", "progression/users/-/adjust-xp", "progression_admin"),
    "progression_user_control": ConsoleAction("PUT", "progression/users/-/control", "progression_admin"),
    # Billing
    "billing_package_toggle": ConsoleAction("POST", "billing/coin-packages/{package_id}/toggle", "billing_dashboard"),
    "billing_package_new": ConsoleAction("POST", "billing/coin-packages", "billing_dashboard"),
    "billing_package_edit": ConsoleAction("PUT", "billing/coin-packages/{package_id}", "billing_dashboard"),
    "billing_grant_coins": ConsoleAction("POST", "billing/grant-coins", "billing_dashboard"),
    "billing_gift_reverse": ConsoleAction("POST", "billing/gift-sends/-/reverse", "billing_reconciliation"),
    "billing_wallet_review": ConsoleAction("POST", "billing/wallets/{user_id}/review", "billing_reconciliation"),
    "billing_fraud_case_resolve": ConsoleAction(
        "POST", "billing/fraud/cases/{case_id}/resolve", "billing_reconciliation"),
    "billing_fraud_rule_update": ConsoleAction("PUT", "billing/fraud/rules/{rule_code}", "billing_reconciliation"),
    # Safety
    "safety_sos_resolve": ConsoleAction("POST", "safety/sos-alerts/{alert_id}/resolve", "safety_sos"),
    "account_recovery_resolve": ConsoleAction(
        "POST", "safety/account-recovery/{request_id}/resolve", "account_recovery_queue"),
}


def action_allowed(roles: Iterable[str] | None, url_name: str, kwargs: dict[str, Any] | None = None) -> bool:
    """Whether Go would let these roles make the call behind a console POST.
    Unknown roles (None) and routes that are not console actions are allowed:
    Go still decides."""
    action = CONSOLE_ACTIONS.get(url_name)
    if roles is None or action is None:
        return True
    values = {key: str(value) for key, value in (kwargs or {}).items()}
    try:
        path = action.path.format(**values)
    except (KeyError, IndexError):
        path = action.path
    return can_access_admin_route(roles, action.method, path)


def refusal_message(roles: Iterable[str]) -> str:
    names = ", ".join(OPERATOR_ROLE_LABELS.get(r, r) for r in roles) or "no operator role"
    return (
        f"Your operator role ({names}) cannot make this change, so it was not sent. "
        "Ask an admin if you need it."
    )


def stored_roles(session: Any) -> list[str] | None:
    """Roles saved at login, or None when they are unknown."""
    roles = session.get(ROLES_SESSION_KEY) if session is not None else None
    if not isinstance(roles, list):
        return None
    return [r for r in roles if isinstance(r, str)]


def nav_visibility(roles: Iterable[str] | None) -> dict[str, bool]:
    """``{url_name: visible, "section_<name>": any item visible}``."""
    visible: dict[str, bool] = {}
    for url_name, section, paths in NAV_ITEMS:
        shown = roles is None or not paths or any(can_access_admin_route(roles, "GET", p) for p in paths)
        visible[url_name] = shown
        key = f"section_{section}"
        visible[key] = visible.get(key, False) or shown
    return visible


def operator_nav(request) -> dict[str, Any]:
    """Template context processor. base.html hides a link only when
    ``nav_hidden.<url name>`` is true, so a page rendered without this
    context still shows the full sidebar."""
    session = getattr(request, "session", None)
    roles = stored_roles(session) if session is not None else None
    # QA Lab has no Go route: the console decides (qa_lab.visible), and the
    # link is only drawn when ``qa_lab_nav`` is true (hidden by default).
    from . import qa_lab

    return {"nav_hidden": {key: not shown for key, shown in nav_visibility(roles).items()},
            "qa_lab_nav": qa_lab.visible(roles)}


def _ok(result: Any) -> bool:
    return getattr(result, "ok", False) is True


def _denied(result: Any) -> bool:
    return getattr(result, "status_code", 0) == 403


def resolve_operator_roles(client: Any, user_id: str) -> list[str] | None:
    """Work out an operator's roles from what Go allows them to read.

    Go exposes no "my roles" endpoint, so: the support agent list (open to the
    admin, ops_admin, support, trust_safety and moderator roles) names this
    operator's roles among those five; a 403 there means none of them. Analyst
    and finance are then told apart by one read only each of them can make.
    Returns None (show everything) whenever an answer is unclear.
    """
    uid = str(user_id or "").strip()
    roles: set[str] = set()
    agents = client.support_agents()
    if _ok(agents):
        data = agents.data if isinstance(agents.data, dict) else {}
        found = False
        for agent in data.get("agents") or []:
            if isinstance(agent, dict) and uid and str(agent.get("id") or "") == uid:
                found = True
                roles |= {r for r in agent.get("roles") or [] if isinstance(r, str) and r in OPERATOR_ROLE_LABELS}
        if not found:
            return None
    elif not _denied(agents):
        return None
    if "admin" in roles:
        return ["admin"]
    # analytics/<report> is analyst-only (admin aside); see can_access_admin_route.
    analyst = client.analytics_definitions()
    if _ok(analyst):
        roles.add("analyst")
    elif not _denied(analyst):
        return None
    # billing/coin-packages is readable by finance, and by ops_admin through billing/.
    if "ops_admin" not in roles:
        finance = client.list_coin_packages()
        if _ok(finance):
            roles.add("finance")
        elif not _denied(finance):
            return None
    return sorted(roles)
