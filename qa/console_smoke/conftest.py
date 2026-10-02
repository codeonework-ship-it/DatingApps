"""Live smoke fixtures for the Django operator console (control-panel/).

Environment (all optional):
  CONSOLE_BASE_URL            console under test (default http://127.0.0.1:8765)
  CONSOLE_OPERATOR_USERNAME   operator username (falls back to LOCAL_OPERATOR_USERNAME,
                              then the provisioning script's local default)
  CONSOLE_OPERATOR_PASSWORD   operator password (falls back to LOCAL_OPERATOR_PASSWORD,
                              then the provisioning script's local default; never printed)
  CONSOLE_PROVISION           1 (default) = run backend/scripts/provision_local_operator.sh
                              when the first login fails; 0 = never provision
  CONSOLE_DATABASE_URL        DB for provisioning (default local stack on 55433)
  CONSOLE_BFF_BASE_URL        BFF for provisioning (default http://127.0.0.1:18081/v1)
  CONSOLE_SMOKE_EXCLUDE       comma-separated nav paths to skip (default "/support/")
  CONSOLE_RESULTS_DIR         where the JSON page report goes (default qa/results/console)

Only loopback consoles are accepted: the suite logs in with local credentials.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import time
from pathlib import Path
from urllib.parse import urlparse

import pytest
import requests

REPO_ROOT = Path(__file__).resolve().parents[2]
PROVISION_SCRIPT = REPO_ROOT / "backend" / "scripts" / "provision_local_operator.sh"
BASE_URL = os.environ.get("CONSOLE_BASE_URL", "http://127.0.0.1:8765").rstrip("/")
RESULTS_DIR = Path(os.environ.get("CONSOLE_RESULTS_DIR", REPO_ROOT / "qa" / "results" / "console"))
EXCLUDED_NAV = {
    p.strip() for p in os.environ.get("CONSOLE_SMOKE_EXCLUDE", "/support/").split(",") if p.strip()
}
NAV_LINK = re.compile(r'<a\s+href="(/[^"#?]*)"\s+class="nav-item-link[^"]*"')
CSRF_INPUT = re.compile(r'name="csrfmiddlewaretoken"\s+value="([^"]+)"')


def _script_default(var: str) -> str:
    """Read `${VAR:-default}` from the provisioning script so local defaults live in one place."""
    try:
        text = PROVISION_SCRIPT.read_text()
    except OSError:
        return ""
    match = re.search(r"\$\{" + re.escape(var) + r":-([^}]*)\}", text)
    return match.group(1) if match else ""


def operator_credentials() -> tuple[str, str]:
    username = (
        os.environ.get("CONSOLE_OPERATOR_USERNAME")
        or os.environ.get("LOCAL_OPERATOR_USERNAME")
        or _script_default("LOCAL_OPERATOR_USERNAME")
    )
    password = (
        os.environ.get("CONSOLE_OPERATOR_PASSWORD")
        or os.environ.get("LOCAL_OPERATOR_PASSWORD")
        or _script_default("LOCAL_OPERATOR_PASSWORD")
    )
    return username, password


def _assert_loopback(url: str) -> None:
    host = urlparse(url).hostname or ""
    if host not in {"127.0.0.1", "localhost", "::1"} and not host.endswith(".localhost"):
        pytest.exit(f"console smoke only runs against loopback consoles, not {host!r}", returncode=2)


def console_reachable() -> bool:
    try:
        requests.get(f"{BASE_URL}/login/", timeout=5)
        return True
    except requests.RequestException:
        return False


def csrf_token(session: requests.Session, path: str = "/login/") -> str:
    response = session.get(f"{BASE_URL}{path}", timeout=15)
    match = CSRF_INPUT.search(response.text)
    assert match, f"no CSRF token rendered on {path}"
    return match.group(1)


def login(session: requests.Session, username: str, password: str, next_path: str = "/") -> requests.Response:
    token = csrf_token(session)
    return session.post(
        f"{BASE_URL}/login/",
        data={"csrfmiddlewaretoken": token, "username": username, "password": password, "next": next_path},
        headers={"Referer": f"{BASE_URL}/login/"},
        allow_redirects=False,
        timeout=30,
    )


def _provision(username: str, password: str) -> None:
    env = dict(os.environ)
    env["LOCAL_OPERATOR_USERNAME"] = username
    env["LOCAL_OPERATOR_PASSWORD"] = password
    # The script's own DB default points at another project's port; always pin the local stack.
    env["LOCAL_DATABASE_URL"] = os.environ.get(
        "CONSOLE_DATABASE_URL", "postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable"
    )
    env["OPERATOR_API_BASE_URL"] = os.environ.get("CONSOLE_BFF_BASE_URL", "http://127.0.0.1:18081/v1")
    result = subprocess.run(
        ["bash", str(PROVISION_SCRIPT)], env=env, capture_output=True, text=True, timeout=120
    )
    if result.returncode != 0:
        pytest.fail(f"operator provisioning failed (exit {result.returncode}): {result.stderr.strip()[:300]}")


# Catalog case each sidebar page proves when it loads cleanly (qa/catalog/feature_catalog.json).
NAV_CASES = {
    "/": "console.dashboard.dashboard.renders",
    "/catalog/": "console.catalog.catalog_list.renders",
    "/engagement/prompts/": "console.engagement.engagement_prompts.renders",
    "/engagement/nudges/": "console.engagement.engagement_nudges.renders",
    "/engagement/photo-themes/": "console.engagement.photo_themes.renders",
    "/progression/": "console.progression.progression_admin.renders",
    "/city-pilot/": "console.city_pilot.city_pilot.renders",
    "/users/": "console.users.user_list.renders",
    "/verifications/": "console.verifications.verification_queue.renders",
    "/moderation/media/": "console.moderation_media.media_moderation_queue.renders",
    "/moderation/blog/": "console.moderation_blog.blog_reviews.renders",
    "/moderation/rooms/": "console.moderation_rooms.rooms.renders",
    "/moderation/group-covers/": "console.moderation_group_covers.group_covers.renders",
    "/moderation/reports/": "console.moderation_reports.moderation_reports.renders",
    "/appeals/": "console.appeals.appeal_queue.renders",
    "/support/": "console.support.support_queue.renders",
    "/support/dashboard/": "console.support.support_dashboard.renders",
    "/support/canned/": "console.support.support_canned_responses.renders",
    "/analytics/": "console.analytics.analytics_overview.renders",
    "/analytics/funnel/": "console.analytics.analytics_funnel.renders",
    "/analytics/retention/": "console.analytics.analytics_retention.renders",
    "/analytics/engagement/": "console.analytics.analytics_engagement.renders",
    "/analytics/liquidity/": "console.analytics.analytics_liquidity.renders",
    "/analytics/safety/": "console.analytics.analytics_safety.renders",
    "/analytics/data/": "console.analytics.analytics_data.renders",
    "/business/": "console.business.business_revenue.renders",
    "/business/subscriptions/": "console.business.business_subscriptions.renders",
    "/business/conversion/": "console.business.business_conversion.renders",
    "/business/coins/": "console.business.business_coins.renders",
    "/business/referrals/": "console.business.business_referrals.renders",
    "/business/markets/": "console.business.business_markets.renders",
    "/business/investor-pack/": "console.business.business_investor_pack.renders",
    "/business/spend/": "console.business.business_spend.renders",
    "/billing/": "console.billing.billing_dashboard.renders",
    "/config/flags/": "console.config.config_flags.renders",
    "/growth/governance/": "console.growth.growth_governance.renders",
    "/safety/sos/": "console.safety.safety_sos.renders",
    "/account-recovery/": "console.account_recovery.account_recovery_queue.renders",
    "/activities/": "console.activities.activity_feed.renders",
    "/audit/": "console.audit.audit_log.renders",
    "/events/": "console.events.domain_events.renders",
    "/client-errors/": "console.client_errors.client_errors.renders",
}


_SESSION_CACHE: dict[str, requests.Session] = {}


def operator_session() -> requests.Session:
    """A logged-in console session, provisioning the local operator once if needed."""
    if "operator" in _SESSION_CACHE:
        return _SESSION_CACHE["operator"]
    _assert_loopback(BASE_URL)
    username, password = operator_credentials()
    if not username or not password:
        pytest.skip("no operator credentials configured")
    session = requests.Session()
    response = login(session, username, password)
    if response.status_code != 302 and os.environ.get("CONSOLE_PROVISION", "1") == "1":
        _provision(username, password)
        session = requests.Session()
        response = login(session, username, password)
    assert response.status_code == 302, (
        f"operator login did not redirect (HTTP {response.status_code}); "
        "check CONSOLE_OPERATOR_USERNAME/CONSOLE_OPERATOR_PASSWORD"
    )
    _SESSION_CACHE["operator"] = session
    return session


_NAV_CACHE: list[str] = []


def discover_nav_links() -> list[str]:
    """Every sidebar link rendered on the command center, in page order."""
    if _NAV_CACHE:
        return _NAV_CACHE
    page = operator_session().get(f"{BASE_URL}/", timeout=60)
    assert page.status_code == 200, f"dashboard returned HTTP {page.status_code}"
    seen: list[str] = []
    for href in NAV_LINK.findall(page.text):
        if href not in seen:
            seen.append(href)
    _NAV_CACHE.extend(seen)
    return _NAV_CACHE


def pytest_generate_tests(metafunc):
    if "nav_path" not in metafunc.fixturenames:
        return
    if not console_reachable():
        metafunc.parametrize("nav_path", [pytest.param("/", marks=pytest.mark.skip(reason=f"{BASE_URL} unreachable"))])
        return
    try:
        links = discover_nav_links()
    except BaseException as exc:  # surface discovery failure as a test failure, not a collection error
        message = f"nav discovery failed: {exc}"
        metafunc.parametrize("nav_path", [pytest.param("<discovery>", marks=pytest.mark.xfail(reason=message, strict=True))])
        return
    params = []
    for link in links:
        marks = [pytest.mark.skip(reason="excluded via CONSOLE_SMOKE_EXCLUDE")] if link in EXCLUDED_NAV else []
        if link in NAV_CASES:
            marks.append(pytest.mark.case(NAV_CASES[link]))
        params.append(pytest.param(link, marks=marks, id=link))
    metafunc.parametrize("nav_path", params)


@pytest.fixture(scope="session", autouse=True)
def _require_console():
    _assert_loopback(BASE_URL)
    if not console_reachable():
        pytest.skip(f"console not reachable at {BASE_URL}")


@pytest.fixture(scope="session")
def base_url() -> str:
    return BASE_URL


@pytest.fixture(scope="session")
def operator() -> requests.Session:
    return operator_session()


@pytest.fixture(scope="session")
def nav_links() -> list[str]:
    return discover_nav_links()


@pytest.fixture(scope="session")
def page_report():
    records: list[dict] = []
    yield records
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    out = RESULTS_DIR / f"console_smoke_{time.strftime('%Y%m%dT%H%M%S')}.json"
    out.write_text(json.dumps({"base_url": BASE_URL, "pages": records}, indent=2))
