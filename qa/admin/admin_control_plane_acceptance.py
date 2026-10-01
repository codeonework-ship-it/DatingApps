#!/usr/bin/env python3
"""Live local-PostgreSQL acceptance gate for the eight-section operator plane."""

from __future__ import annotations

import json
import os
import subprocess
import urllib.error
import urllib.request
import uuid


API = os.getenv("ADMIN_ACCEPTANCE_API", "http://127.0.0.1:18081/v1").rstrip("/")
DATABASE_URL = os.getenv(
    "LOCAL_DATABASE_URL",
    "postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable",
)
PSQL = os.getenv("PSQL_BIN", "/opt/homebrew/opt/postgresql@17/bin/psql")
ADMIN_USERNAME = os.getenv("LOCAL_OPERATOR_USERNAME", "local_control_admin")
ADMIN_PASSWORD = os.getenv("LOCAL_OPERATOR_PASSWORD", "LocalAdmin123!")
ANALYST_USERNAME = os.getenv("LOCAL_ANALYST_USERNAME", "local_control_analyst")
ANALYST_PASSWORD = os.getenv("LOCAL_ANALYST_PASSWORD", "LocalAnalyst123!")


def request(method: str, path: str, token: str = "", payload=None) -> tuple[int, dict]:
    body = None if payload is None else json.dumps(payload).encode()
    headers = {"Content-Type": "application/json", "X-Correlation-ID": "admin-acceptance"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if method not in {"GET", "HEAD", "OPTIONS"}:
        headers["Idempotency-Key"] = f"admin-acceptance-{uuid.uuid4()}"
    req = urllib.request.Request(f"{API}/{path.lstrip('/')}", body, headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.status, json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as exc:
        return exc.code, json.loads(exc.read() or b"{}")


def login(username: str, password: str) -> str:
    code, payload = request("POST", "/auth/login", payload={"username": username, "password": password})
    token = str(payload.get("access_token") or "")
    assert code == 200 and payload.get("success") is True and token, (code, payload)
    return token


def audit_count() -> int:
    output = subprocess.check_output(
        [PSQL, DATABASE_URL, "-X", "-Atqc", "SELECT count(*) FROM audit.operator_action_log"],
        text=True,
    )
    return int(output.strip())


def main() -> None:
    admin = login(ADMIN_USERNAME, ADMIN_PASSWORD)
    analyst = login(ANALYST_USERNAME, ANALYST_PASSWORD)

    sections = {
        "dashboard": "/admin/analytics/overview",
        "operator_audit": "/admin/audit-events",
        "gift_catalog": "/admin/catalog/gifts",
        "users": "/admin/users",
        "moderation": "/admin/moderation/reports",
        "engagement": "/admin/engagement/prompts",
        "billing": "/admin/billing/stats",
        "feature_flags": "/admin/config/flags",
        "safety_sos": "/admin/safety/sos-alerts",
    }
    for name, path in sections.items():
        code, payload = request("GET", path, admin)
        assert code == 200, (name, code, payload)

    assert request("GET", "/admin/engagement/nudges", admin)[0] == 200
    assert request("GET", "/admin/verifications", admin)[0] == 200
    assert request("GET", "/admin/analytics/overview", analyst)[0] == 200
    assert request("GET", "/admin/audit-events", analyst)[0] == 200
    users_code, users = request("GET", "/admin/users?limit=1", admin)
    assert users_code == 200 and users.get("kpis", {}).get("scope") == "all_users", users
    assert request(
        "PUT", "/admin/config/flags/match_nudges_enabled", analyst, {"value_bool": False}
    )[0] == 403

    before = audit_count()
    try:
        code, _ = request(
            "PUT", "/admin/config/flags/match_nudges_enabled", admin, {"value_bool": False}
        )
        assert code == 200
        code, runtime = request("GET", "/config/flags", admin)
        values = {item["key"]: item["value_bool"] for item in runtime.get("flags", [])}
        assert code == 200 and values.get("match_nudges_enabled") is False
    finally:
        request("PUT", "/admin/config/flags/match_nudges_enabled", admin, {"value_bool": True})
    after = audit_count()
    assert after >= before + 2, (before, after)

    immutable = subprocess.run(
        [
            PSQL,
            DATABASE_URL,
            "-X",
            "-v",
            "ON_ERROR_STOP=1",
            "-Atqc",
            "UPDATE audit.security_events SET payload='{}'::jsonb WHERE id=(SELECT id FROM audit.security_events LIMIT 1)",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    assert immutable.returncode != 0 and "append-only" in immutable.stderr.lower()
    print(json.dumps({"success": True, "sections": list(sections), "audit_events_added": after - before}))


if __name__ == "__main__":
    main()
