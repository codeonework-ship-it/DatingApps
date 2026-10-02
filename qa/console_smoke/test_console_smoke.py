"""Live, read-only smoke tests for the Django operator console.

Run (console on 8765, BFF on 18081):
    CONSOLE_BASE_URL=http://127.0.0.1:8765 .venv/bin/python -m pytest qa/console_smoke -q

No operator mutations are performed: every request is a GET, apart from the
login form itself and POSTs that must be refused before any view runs
(anonymous, or without a CSRF token).

Tests carry ``@pytest.mark.case(<catalog case id>)`` (qa/catalog/feature_catalog.json).
"""
from __future__ import annotations

import html
import re
import time

import pytest
import requests

from conftest import BASE_URL, csrf_token, login

# Pages operators rely on; they must stay reachable from the sidebar.
KEY_PAGES = {
    "/moderation/rooms/": "rooms moderation",
    "/moderation/group-covers/": "group covers",
    "/client-errors/": "client errors",
    "/analytics/": "analytics",
    "/business/": "business reports",
    "/billing/": "billing",
    "/engagement/photo-themes/": "photo themes",
    "/moderation/blog/": "blog moderation",
}

SERVER_ERROR_MARKERS = [
    "Traceback (most recent call last)",
    "Server Error (500)",
    "Exception Value:",
    "TemplateSyntaxError",
    "VariableDoesNotExist",
    "NoReverseMatch",
    "SQLSTATE",
    "goroutine ",
    "panic:",
]
# A Go pgtype.Numeric (or similar struct) leaked through fmt.Sprint, e.g. "{499 -2 false finite true}".
GO_STRUCT_LEAK = re.compile(r"\{-?\d+ -?\d+ (?:true|false) (?:finite|infinity|-infinity) (?:true|false)\}")
# Banners the console uses for failed data loads. Informational banners are allowlisted by text.
BANNER = re.compile(
    r'<div[^>]*class="[^"]*alert-glass(?:\s+|-)(?:alert-glass-)?(?:warning|error)[^"]*"[^>]*>(.*?)</div>',
    re.S,
)
INFORMATIONAL_BANNERS = re.compile(r"Member appeal|active SOS alert", re.I)
EMPTY_STATE = re.compile(
    r"\bNo\b[^<.]{0,80}\b(?:found|yet|match|waiting|in this queue|recorded|in this window|requests|alerts|issues|covers|"
    r"payments|appeals|reports|runs|events|members|entries|data)\b|All clear",
    re.I,
)
CONTENT_MARKER = re.compile(r"<table\b|<form\b|class=\"[^\"]*(?:metric-tile|glass-card|stat-card)")


def _text(fragment: str) -> str:
    fragment = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", fragment, flags=re.S)
    return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", fragment))).strip()


def page_problems(response: requests.Response) -> list[str]:
    problems: list[str] = []
    body = response.text
    if response.status_code != 200:
        problems.append(f"HTTP {response.status_code}")
    if "/login/" in response.url and "/login/" not in response.request.path_url:
        problems.append("bounced to login")
    for marker in SERVER_ERROR_MARKERS:
        index = body.find(marker)
        if index >= 0:
            context = _text(body[max(0, index - 200): index + 60])[-160:]
            problems.append(f"server error marker {marker!r}: …{context}")
    leak = GO_STRUCT_LEAK.search(body)
    if leak:
        problems.append(f"Go struct leaked into page: {leak.group(0)!r}")
    for banner in BANNER.findall(body):
        text = _text(banner)
        if text and not INFORMATIONAL_BANNERS.search(text):
            problems.append(f"error banner: {text[:200]!r}")
    main = body.split('class="page-body"', 1)[-1]
    if not (CONTENT_MARKER.search(main) or EMPTY_STATE.search(_text(main))):
        problems.append("no data table, form, card or empty state rendered")
    return problems


def _record(page_report, path, response, started, problems):
    page_report.append(
        {
            "path": path,
            "status": response.status_code,
            "seconds": round(time.monotonic() - started, 3),
            "tables": response.text.count("<table"),
            "problems": problems,
        }
    )


# ── Authentication ────────────────────────────────────────────────────────────

@pytest.mark.case("console.login.operator_login.authz")
@pytest.mark.parametrize("path", ["/", "/moderation/rooms/", "/client-errors/", "/billing/", "/analytics/funnel/"])
def test_logged_out_request_redirects_to_login(path):
    response = requests.get(f"{BASE_URL}{path}", allow_redirects=False, timeout=15)
    assert response.status_code == 302
    assert response.headers["Location"] == f"/login/?next={path}"


@pytest.mark.case("console.login.operator_login.authz")
def test_login_page_renders_csrf_protected_form():
    session = requests.Session()
    response = session.get(f"{BASE_URL}/login/", timeout=15)
    assert response.status_code == 200
    assert 'name="username"' in response.text and 'name="password"' in response.text
    assert csrf_token(session)
    assert "csrftoken" in session.cookies


@pytest.mark.case("console.login.operator_login.authz")
def test_login_without_csrf_token_is_rejected():
    response = requests.post(
        f"{BASE_URL}/login/", data={"username": "nobody", "password": "x"}, allow_redirects=False, timeout=15
    )
    assert response.status_code == 403


@pytest.mark.case("console.login.operator_login.authz")
def test_unknown_operator_is_refused_without_session():
    session = requests.Session()
    response = login(session, f"qa_no_such_operator_{int(time.time())}", "not-a-real-password-1A!")
    assert response.status_code == 200, "bad credentials must re-render the login page"
    assert "alert-glass" in response.text
    follow = session.get(f"{BASE_URL}/", allow_redirects=False, timeout=15)
    assert follow.status_code == 302 and follow.headers["Location"].startswith("/login/")


@pytest.mark.case("console.login.operator_login.performs")
def test_login_honours_next_and_rejects_offsite_next(operator):
    from conftest import operator_credentials

    username, password = operator_credentials()
    session = requests.Session()
    response = login(session, username, password, next_path="//evil.example/")
    assert response.status_code == 302
    assert response.headers["Location"] == "/"
    session = requests.Session()
    response = login(session, username, password, next_path="/client-errors/")
    assert response.status_code == 302 and response.headers["Location"] == "/client-errors/"


# ── Navigation ────────────────────────────────────────────────────────────────

def test_sidebar_exposes_key_pages(nav_links):
    missing = {path: name for path, name in KEY_PAGES.items() if path not in nav_links}
    assert not missing, f"sidebar is missing key pages: {missing}"
    assert len(nav_links) >= len(KEY_PAGES)


def test_nav_page_loads_cleanly(operator, nav_path, page_report):
    started = time.monotonic()
    response = operator.get(f"{BASE_URL}{nav_path}", timeout=60)
    problems = page_problems(response)
    if f'href="{nav_path}" class="nav-item-link active' not in response.text:
        problems.append("sidebar does not mark this page active")
    _record(page_report, nav_path, response, started, problems)
    assert not problems, f"{nav_path}: {problems}"


# ── Read-only detail pages ────────────────────────────────────────────────────

def _first_link(operator, list_path: str, pattern: str) -> str | None:
    page = operator.get(f"{BASE_URL}{list_path}", timeout=60)
    match = re.search(pattern, page.text)
    return match.group(1) if match else None


UUID = r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"


@pytest.mark.case("console.moderation_rooms.room_detail.renders")
def test_room_detail_with_members(operator, page_report):
    path = _first_link(operator, "/moderation/rooms/", rf'href="(/moderation/rooms/{UUID}/)"')
    if not path:
        pytest.skip("no rooms to open")
    started = time.monotonic()
    response = operator.get(f"{BASE_URL}{path}", timeout=60)
    problems = page_problems(response)
    if "Could not load members" in response.text:
        problems.append("members failed to load")
    _record(page_report, path, response, started, problems)
    assert not problems, f"{path}: {problems}"
    assert "Room id" in response.text


@pytest.mark.case("console.client_errors.client_error_detail.renders")
def test_client_error_detail(operator, page_report):
    path = _first_link(operator, "/client-errors/?status=all", rf'href="(/client-errors/{UUID}/)"')
    if not path:
        pytest.skip("no client error issues recorded")
    started = time.monotonic()
    response = operator.get(f"{BASE_URL}{path}", timeout=60)
    problems = page_problems(response)
    _record(page_report, path, response, started, problems)
    assert not problems, f"{path}: {problems}"
    assert "Fingerprint" in response.text


@pytest.mark.case("console.users.user_detail.renders")
def test_user_detail(operator, page_report):
    path = _first_link(operator, "/users/", rf'href="(/users/{UUID}/)"')
    if not path:
        pytest.skip("no members listed")
    started = time.monotonic()
    response = operator.get(f"{BASE_URL}{path}", timeout=60)
    problems = page_problems(response)
    _record(page_report, path, response, started, problems)
    assert not problems, f"{path}: {problems}"


@pytest.mark.parametrize(
    "path",
    [
        pytest.param("/moderation/rooms/00000000-0000-4000-8000-000000000000/",
                     marks=pytest.mark.case("console.moderation_rooms.room_detail.renders")),
        pytest.param("/client-errors/00000000-0000-4000-8000-000000000000/",
                     marks=pytest.mark.case("console.client_errors.client_error_detail.renders")),
        pytest.param("/users/00000000-0000-4000-8000-000000000000/",
                     marks=pytest.mark.case("console.users.user_detail.renders")),
        "/console-smoke-no-such-page/",
    ],
)
def test_missing_records_return_404_not_500(operator, path):
    response = operator.get(f"{BASE_URL}{path}", timeout=60)
    assert response.status_code == 404, f"{path} returned HTTP {response.status_code}"
    assert "Traceback" not in response.text


@pytest.mark.parametrize("list_path,pattern", [
    pytest.param("/business/", r'href="(/business/csv/[^"]+)"', marks=pytest.mark.case("console.business.business_csv.renders")),
    pytest.param("/analytics/", r'href="(/analytics/export/[^"]+)"', marks=pytest.mark.case("console.analytics.analytics_export.renders")),
])
def test_report_csv_export(operator, list_path, pattern):
    path = _first_link(operator, list_path, pattern)
    if not path:
        pytest.skip(f"no CSV export link on {list_path}")
    response = operator.get(f"{BASE_URL}{html.unescape(path)}", timeout=60)
    assert response.status_code == 200, f"{path}: HTTP {response.status_code}"
    assert "csv" in response.headers.get("Content-Type", ""), response.headers.get("Content-Type")
    assert "Traceback" not in response.text and not GO_STRUCT_LEAK.search(response.text)


# ── Pages reached from inside a section (not sidebar links) ───────────────────

SECONDARY_PAGES = {
    "/billing/transactions/": "console.billing.billing_transactions.renders",
    "/billing/subscriptions/": "console.billing.billing_subscriptions.renders",
    "/billing/payments/": "console.billing.billing_payments.renders",
    "/billing/webhooks/": "console.billing.billing_webhook_events.renders",
    "/billing/reconciliation/": "console.billing.billing_reconciliation.renders",
    "/billing/revenue/": "console.billing.billing_revenue_analytics.renders",
}


@pytest.mark.parametrize("path", [pytest.param(p, marks=pytest.mark.case(c), id=p) for p, c in SECONDARY_PAGES.items()])
def test_secondary_page_loads_cleanly(operator, path, page_report):
    started = time.monotonic()
    response = operator.get(f"{BASE_URL}{path}", timeout=60)
    problems = page_problems(response)
    _record(page_report, path, response, started, problems)
    assert not problems, f"{path}: {problems}"


# ── Console changes refuse unsafe requests (no change is ever made) ──────────
# Anonymous POST -> login redirect; GET on a POST-only action -> 405; a
# signed-in POST without a CSRF token -> 403. Every request here is refused
# before the view runs, so nothing reaches the BFF. Role refusals are covered
# by the Django suite (control_panel/tests), which can sign in as any role.

Z = "00000000-0000-4000-8000-000000000000"
ACTION_ROUTES = [
    # (path, POST-only, catalog case)
    ("/analytics/data/rebuild/", True, "console.analytics.analytics_rebuild.authz"),
    ("/analytics/data/exclusions/", True, "console.analytics.analytics_exclude.authz"),
    (f"/analytics/data/exclusions/{Z}/remove/", True, "console.analytics.analytics_include.authz"),
    ("/business/markets/save/", True, "console.business.business_market_save.authz"),
    ("/business/spend/save/", True, "console.business.business_spend_save.authz"),
    (f"/business/spend/{Z}/delete/", True, "console.business.business_spend_delete.authz"),
    ("/engagement/photo-themes/save/", True, "console.engagement.photo_theme_save.authz"),
    ("/engagement/prompts/new/", False, "console.engagement.engagement_prompt_new.authz"),
    (f"/engagement/prompts/{Z}/edit/", False, "console.engagement.engagement_prompt_edit.authz"),
    (f"/engagement/prompts/{Z}/activate/", True, "console.engagement.engagement_prompt_activate.authz"),
    (f"/moderation/rooms/{Z}/actions/", True, "console.moderation_rooms.room_action.authz"),
    (f"/moderation/rooms/{Z}/roles/", True, "console.moderation_rooms.room_role.authz"),
    (f"/moderation/group-covers/{Z}/decision/", True, "console.moderation_group_covers.group_cover_decision.authz"),
    (f"/moderation/blog/{Z}/decision/", True, "console.moderation_blog.blog_decision.authz"),
    (f"/moderation/reports/{Z}/action/", True, "console.moderation_reports.action_report.authz"),
    (f"/moderation/media/{Z}/decision/", True, "console.moderation_media.media_moderation_decision.authz"),
    (f"/appeals/{Z}/action/", True, "console.appeals.action_appeal.authz"),
    (f"/verifications/{Z}/approve/", True, "console.verifications.approve_verification.authz"),
    (f"/verifications/{Z}/reject/", True, "console.verifications.reject_verification.authz"),
    ("/city-pilot/save/", True, "console.city_pilot.city_pilot_save.authz"),
    (f"/city-pilot/{Z}/stage/", True, "console.city_pilot.city_pilot_stage.authz"),
    (f"/city-pilot/{Z}/experiences/", True, "console.city_pilot.city_pilot_experience_create.authz"),
    (f"/city-pilot/{Z}/experiences/{Z}/cancel/", True, "console.city_pilot.city_pilot_experience_cancel.authz"),
    (f"/client-errors/{Z}/status/", True, "console.client_errors.client_error_status.authz"),
    ("/support/bulk/", True, "console.support.support_bulk.authz"),
    ("/support/canned/save/", True, "console.support.support_canned_save.authz"),
    (f"/support/canned/{Z}/deactivate/", True, "console.support.support_canned_deactivate.authz"),
    (f"/support/tickets/{Z}/reply/", True, "console.support.support_ticket_reply.authz"),
    (f"/support/tickets/{Z}/update/", True, "console.support.support_ticket_update.authz"),
    (f"/support/tickets/{Z}/claim/", True, "console.support.support_ticket_claim.authz"),
    (f"/support/tickets/{Z}/merge/", True, "console.support.support_ticket_merge.authz"),
    ("/catalog/new/", False, "console.catalog.catalog_new.authz"),
    ("/catalog/console-smoke-gift/edit/", False, "console.catalog.catalog_edit.authz"),
    ("/catalog/console-smoke-gift/toggle/", True, "console.catalog.catalog_toggle.authz"),
    ("/catalog/console-smoke-gift/delete/", True, "console.catalog.catalog_delete.authz"),
    ("/users/new/", False, "console.users.user_create.authz"),
    (f"/users/{Z}/edit/", False, "console.users.user_edit.authz"),
    (f"/users/{Z}/delete/", True, "console.users.user_delete.authz"),
    (f"/users/{Z}/suspend/", True, "console.users.user_suspend.authz"),
    (f"/users/{Z}/unsuspend/", True, "console.users.user_unsuspend.authz"),
    (f"/users/{Z}/ban/", True, "console.users.user_ban.authz"),
    (f"/users/{Z}/unban/", True, "console.users.user_unban.authz"),
    (f"/users/{Z}/verify/", True, "console.users.user_force_verify.authz"),
    (f"/users/{Z}/grant-coins/", True, "console.users.user_grant_coins.authz"),
    ("/config/flags/console_smoke_flag/toggle/", True, "console.config.config_flag_toggle.authz"),
    ("/progression/policies/console_smoke/", True, "console.progression.progression_policy_update.authz"),
    ("/progression/experiments/console_smoke/", True, "console.progression.progression_experiment_update.authz"),
    ("/progression/fraud-rules/console_smoke/", True, "console.progression.progression_fraud_rule_update.authz"),
    (f"/progression/fraud/{Z}/", True, "console.progression.progression_fraud_resolve.authz"),
    ("/progression/users/adjust/", True, "console.progression.progression_user_adjust.authz"),
    ("/progression/users/control/", True, "console.progression.progression_user_control.authz"),
    ("/billing/packages/console-smoke/toggle/", True, "console.billing.billing_package_toggle.authz"),
    ("/billing/packages/new/", False, "console.billing.billing_package_new.authz"),
    ("/billing/packages/console-smoke/edit/", False, "console.billing.billing_package_edit.authz"),
    ("/billing/grant-coins/", True, "console.billing.billing_grant_coins.authz"),
    ("/billing/gifts/reverse/", True, "console.billing.billing_gift_reverse.authz"),
    (f"/billing/wallets/{Z}/review/", True, "console.billing.billing_wallet_review.authz"),
    (f"/billing/fraud/cases/{Z}/resolve/", True, "console.billing.billing_fraud_case_resolve.authz"),
    ("/billing/fraud/rules/console_smoke/", True, "console.billing.billing_fraud_rule_update.authz"),
    (f"/safety/sos/{Z}/resolve/", True, "console.safety.safety_sos_resolve.authz"),
    (f"/account-recovery/{Z}/resolve/", True, "console.account_recovery.account_recovery_resolve.authz"),
    ("/logout/", True, "console.logout.operator_logout.authz"),
]


@pytest.mark.parametrize(
    "path,post_only",
    [pytest.param(p, post_only, marks=pytest.mark.case(c), id=p) for p, post_only, c in ACTION_ROUTES],
)
def test_action_route_refuses_unsafe_requests(operator, path, post_only):
    url = f"{BASE_URL}{path}"
    if path != "/logout/":
        anonymous = requests.post(url, data={}, allow_redirects=False, timeout=15)
        assert anonymous.status_code == 302, f"anonymous POST {path}: HTTP {anonymous.status_code}"
        assert anonymous.headers["Location"].startswith("/login/?next="), anonymous.headers["Location"]
    if post_only:
        refused = operator.get(url, allow_redirects=False, timeout=15)
        assert refused.status_code == 405, f"GET {path}: HTTP {refused.status_code}"
    no_token = operator.post(url, data={"value": "1"}, allow_redirects=False, timeout=15)
    # 403 (not a login redirect) also shows the operator was signed in when refused.
    assert no_token.status_code == 403, f"POST {path} without a CSRF token: HTTP {no_token.status_code}"

