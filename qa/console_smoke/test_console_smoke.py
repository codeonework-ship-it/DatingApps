"""Live, read-only smoke tests for the Django operator console.

Run (console on 8765, BFF on 18081):
    CONSOLE_BASE_URL=http://127.0.0.1:8765 .venv/bin/python -m pytest qa/console_smoke -q

No operator mutations are performed: every request is a GET, apart from the
login form itself and a CSRF-less POST that must be rejected.
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

@pytest.mark.parametrize("path", ["/", "/moderation/rooms/", "/client-errors/", "/billing/", "/analytics/funnel/"])
def test_logged_out_request_redirects_to_login(path):
    response = requests.get(f"{BASE_URL}{path}", allow_redirects=False, timeout=15)
    assert response.status_code == 302
    assert response.headers["Location"] == f"/login/?next={path}"


def test_login_page_renders_csrf_protected_form():
    session = requests.Session()
    response = session.get(f"{BASE_URL}/login/", timeout=15)
    assert response.status_code == 200
    assert 'name="username"' in response.text and 'name="password"' in response.text
    assert csrf_token(session)
    assert "csrftoken" in session.cookies


def test_login_without_csrf_token_is_rejected():
    response = requests.post(
        f"{BASE_URL}/login/", data={"username": "nobody", "password": "x"}, allow_redirects=False, timeout=15
    )
    assert response.status_code == 403


def test_unknown_operator_is_refused_without_session():
    session = requests.Session()
    response = login(session, f"qa_no_such_operator_{int(time.time())}", "not-a-real-password-1A!")
    assert response.status_code == 200, "bad credentials must re-render the login page"
    assert "alert-glass" in response.text
    follow = session.get(f"{BASE_URL}/", allow_redirects=False, timeout=15)
    assert follow.status_code == 302 and follow.headers["Location"].startswith("/login/")


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
        "/moderation/rooms/00000000-0000-4000-8000-000000000000/",
        "/client-errors/00000000-0000-4000-8000-000000000000/",
        "/users/00000000-0000-4000-8000-000000000000/",
        "/console-smoke-no-such-page/",
    ],
)
def test_missing_records_return_404_not_500(operator, path):
    response = operator.get(f"{BASE_URL}{path}", timeout=60)
    assert response.status_code == 404, f"{path} returned HTTP {response.status_code}"
    assert "Traceback" not in response.text


@pytest.mark.parametrize("list_path,pattern", [
    ("/business/", r'href="(/business/csv/[^"]+)"'),
    ("/analytics/", r'href="(/analytics/export/[^"]+)"'),
])
def test_report_csv_export(operator, list_path, pattern):
    path = _first_link(operator, list_path, pattern)
    if not path:
        pytest.skip(f"no CSV export link on {list_path}")
    response = operator.get(f"{BASE_URL}{html.unescape(path)}", timeout=60)
    assert response.status_code == 200, f"{path}: HTTP {response.status_code}"
    assert "csv" in response.headers.get("Content-Type", ""), response.headers.get("Content-Type")
    assert "Traceback" not in response.text and not GO_STRUCT_LEAK.search(response.text)
