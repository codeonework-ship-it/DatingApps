#!/usr/bin/env python3
"""Authenticated HTTP browser-surface gate for every command-center screen."""

from __future__ import annotations

import os
import re

import requests


BASE_URL = os.getenv("COMMAND_CENTER_URL", "http://127.0.0.1:19000").rstrip("/")
USERNAME = os.getenv("LOCAL_OPERATOR_USERNAME", "local_control_admin")
PASSWORD = os.getenv("LOCAL_OPERATOR_PASSWORD", "LocalAdmin123!")

SCREENS = [
    "/",
    "/users/",
    "/verifications/",
    "/moderation/media/",
    "/moderation/reports/",
    "/appeals/",
    "/catalog/",
    "/engagement/prompts/",
    "/engagement/nudges/",
    "/progression/",
    "/billing/",
    "/billing/transactions/",
    "/billing/subscriptions/",
    "/billing/payments/",
    "/billing/revenue/",
    "/billing/webhooks/",
    "/billing/reconciliation/",
    "/config/flags/",
    "/safety/sos/",
    "/activities/?action=auth&status=success",
    "/audit/?event_type=admin.request&limit=10",
    "/events/?producer=matching&limit=10",
]


def main() -> None:
    session = requests.Session()
    login = session.get(f"{BASE_URL}/login/", timeout=10)
    login.raise_for_status()
    token = re.search(r'name="csrfmiddlewaretoken" value="([^"]+)"', login.text)
    assert token, "operator login page did not contain a CSRF token"

    response = session.post(
        f"{BASE_URL}/login/",
        data={
            "csrfmiddlewaretoken": token.group(1),
            "username": USERNAME,
            "password": PASSWORD,
            "next": "/",
        },
        headers={"Referer": f"{BASE_URL}/login/"},
        timeout=15,
    )
    assert response.url == f"{BASE_URL}/", response.url
    assert "Operations command center" in response.text
    assert "Operator audit" in response.text

    for path in SCREENS:
        page = session.get(f"{BASE_URL}{path}", timeout=20)
        assert page.status_code == 200, (path, page.status_code)
        assert "Internal Server Error" not in page.text, path
        assert "Traceback" not in page.text, path

    print(f"command-center screen gate passed: {len(SCREENS)} screens")


if __name__ == "__main__":
    main()
