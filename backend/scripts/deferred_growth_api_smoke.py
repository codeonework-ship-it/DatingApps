#!/usr/bin/env python3
"""Local-only acceptance for the non-monetized deferred-growth foundations."""

from __future__ import annotations

import atexit
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid


API = os.getenv("GROWTH_API_BASE_URL", "http://127.0.0.1:18080/v1").rstrip("/")
DATABASE_URL = os.getenv(
    "LOCAL_DATABASE_URL",
    "postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable",
)
PSQL = os.getenv("PSQL_BIN", "/opt/homebrew/opt/postgresql@17/bin/psql")
MEMBER_USERNAME = os.getenv("GROWTH_MEMBER_USERNAME", "workflow_qa_20260803_final")
MEMBER_PASSWORD = os.getenv("GROWTH_MEMBER_PASSWORD", "Password123!")
OPERATOR_USERNAME = os.getenv("GROWTH_OPERATOR_USERNAME", "local_control_admin")
OPERATOR_PASSWORD = os.getenv("GROWTH_OPERATOR_PASSWORD", "LocalAdmin123!")

if "127.0.0.1" not in API and "localhost" not in API:
    raise SystemExit("growth API smoke accepts loopback services only")
if "127.0.0.1" not in DATABASE_URL and "localhost" not in DATABASE_URL:
    raise SystemExit("growth API smoke accepts a loopback database only")


def sql(statement: str) -> str:
    result = subprocess.run(
        [PSQL, DATABASE_URL, "-X", "-v", "ON_ERROR_STOP=1", "-Atq"],
        input=statement,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "psql failed")
    return result.stdout.strip()


def request(
    method: str,
    path: str,
    *,
    token: str,
    payload: dict | None = None,
    expected: tuple[int, ...] = (200,),
) -> dict:
    body = None if payload is None else json.dumps(payload).encode()
    headers = {"Authorization": f"Bearer {token}"}
    if body is not None:
        headers["Content-Type"] = "application/json"
    if method not in {"GET", "HEAD", "OPTIONS"}:
        headers["Idempotency-Key"] = f"growth-smoke-{uuid.uuid4()}"
    req = urllib.request.Request(f"{API}{path}", data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            status_code = response.status
            data = json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as error:
        status_code = error.code
        data = json.loads(error.read() or b"{}")
    if status_code not in expected:
        raise AssertionError(f"{method} {path}: HTTP {status_code}: {data}")
    return data


def login(username: str, password: str) -> str:
    req = urllib.request.Request(
        f"{API}/auth/login",
        data=json.dumps({"username": username, "password": password}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as response:
        data = json.loads(response.read())
    token = str(data.get("access_token") or "")
    if not token:
        raise AssertionError(f"login failed for {username}")
    return token


run_key = f"growth-smoke-{int(time.time())}-{uuid.uuid4().hex[:8]}"
fixture_ids: dict[str, str] = {}
member_id = ""
operator_id = ""


def cleanup() -> None:
    if not member_id:
        return
    event_id = fixture_ids.get("event", "00000000-0000-0000-0000-000000000000")
    partner_id = fixture_ids.get("partner", "00000000-0000-0000-0000-000000000000")
    recommendation_id = fixture_ids.get(
        "recommendation", "00000000-0000-0000-0000-000000000000"
    )
    fraud_id = fixture_ids.get("fraud", "00000000-0000-0000-0000-000000000000")
    preference_id = fixture_ids.get(
        "preference", "00000000-0000-0000-0000-000000000000"
    )
    checkin_id = fixture_ids.get("checkin", "00000000-0000-0000-0000-000000000000")
    referral_id = fixture_ids.get("referral", "00000000-0000-0000-0000-000000000000")
    try:
        sql(
            f"""
            UPDATE matching.platform_feature_flags SET value_bool=FALSE,updated_by='growth_smoke_cleanup',updated_at=NOW()
            WHERE key IN ('referrals_enabled','growth_events_enabled','partnerships_enabled',
              'social_imports_enabled','member_history_enabled','recommendation_graph_enabled');
            DELETE FROM growth.referral_redemptions WHERE code_id='{referral_id}'::uuid;
            DELETE FROM growth.referral_codes WHERE id='{referral_id}'::uuid;
            DELETE FROM growth.social_import_consents WHERE member_id='{member_id}'::uuid AND provider='manual';
            DELETE FROM growth.preference_history WHERE id='{preference_id}'::uuid;
            DELETE FROM growth.location_checkins WHERE id='{checkin_id}'::uuid;
            DELETE FROM growth.recommendation_edges WHERE id='{recommendation_id}'::uuid;
            DELETE FROM growth.fraud_graph_edges WHERE id='{fraud_id}'::uuid;
            DELETE FROM growth.events WHERE id='{event_id}'::uuid;
            DELETE FROM growth.partnerships WHERE id='{partner_id}'::uuid;
            """
        )
    except Exception as error:  # cleanup must report without hiding the original failure
        print(f"cleanup warning: {error}", file=sys.stderr)


atexit.register(cleanup)


def main() -> None:
    global member_id, operator_id
    member_token = login(MEMBER_USERNAME, MEMBER_PASSWORD)
    operator_token = login(OPERATOR_USERNAME, OPERATOR_PASSWORD)
    ids = sql(
        f"""
        SELECT
          (SELECT user_id::text FROM user_management.auth_credentials WHERE username='{MEMBER_USERNAME}'),
          (SELECT user_id::text FROM user_management.auth_credentials WHERE username='{OPERATOR_USERNAME}');
        """
    ).split("|")
    if len(ids) != 2 or not all(ids):
        raise AssertionError("member and operator database identities are required")
    member_id, operator_id = ids

    setup = sql(
        f"""
        UPDATE matching.platform_feature_flags SET value_bool=TRUE,updated_by='growth_smoke',updated_at=NOW()
        WHERE key IN ('referrals_enabled','growth_events_enabled','partnerships_enabled',
          'social_imports_enabled','member_history_enabled','recommendation_graph_enabled');
        WITH inserted AS (
          INSERT INTO growth.events(title,summary,city,venue_name,starts_at,registration_closes_at,
            capacity,safety_contact,status,created_by)
          VALUES('Growth acceptance event','A local free event used by automated growth acceptance.',
            'Bengaluru','Acceptance Studio',NOW()+INTERVAL '3 days',NOW()+INTERVAL '2 days',
            4,'Local safety desk','published','{operator_id}'::uuid) RETURNING id
        ) SELECT 'event|'||id::text FROM inserted;
        WITH inserted AS (
          INSERT INTO growth.partnerships(name,category,summary,website_url,status,due_diligence_completed_at)
          VALUES('{run_key}','safety','Local acceptance partner','https://example.invalid',
            'published',NOW()) RETURNING id
        ) SELECT 'partner|'||id::text FROM inserted;
        WITH inserted AS (
          INSERT INTO growth.recommendation_edges(member_id,candidate_id,score,reasons,model_version,expires_at)
          VALUES('{member_id}'::uuid,'{operator_id}'::uuid,0.7500,
            '[\"Shared city\",\"Compatible relationship intent\"]','rules-smoke-v1',NOW()+INTERVAL '1 day')
          ON CONFLICT(member_id,candidate_id,model_version) DO UPDATE SET score=EXCLUDED.score,reasons=EXCLUDED.reasons,expires_at=EXCLUDED.expires_at
          RETURNING id
        ) SELECT 'recommendation|'||id::text FROM inserted;
        WITH inserted AS (
          INSERT INTO growth.fraud_graph_edges(left_member_id,right_member_id,signal_type,confidence,evidence)
          VALUES('{member_id}'::uuid,'{operator_id}'::uuid,'account_pattern',0.5000,
            '{{\"fixture\":true}}'::jsonb) RETURNING id
        ) SELECT 'fraud|'||id::text FROM inserted;
        """
    )
    for row in setup.splitlines():
        key, value = row.split("|", 1)
        fixture_ids[key] = value

    events = request("GET", "/growth/events", token=member_token)
    assert any(item["id"] == fixture_ids["event"] for item in events["events"])
    request(
        "POST",
        f"/growth/events/{fixture_ids['event']}/registration",
        token=member_token,
        payload={"safety_terms_accepted": True},
    )
    request(
        "DELETE",
        f"/growth/events/{fixture_ids['event']}/registration",
        token=member_token,
    )

    referral = request("POST", "/growth/referrals/me", token=member_token)["referral"]
    fixture_ids["referral"] = referral["id"]
    assert referral["reward"] is None
    redemption = request(
        "POST",
        "/growth/referrals/redeem",
        token=operator_token,
        payload={"code": referral["code"]},
        expected=(201,),
    )
    assert redemption["reward_granted"] is False

    partners = request("GET", "/growth/partnerships", token=member_token)
    assert any(item["id"] == fixture_ids["partner"] for item in partners["partnerships"])
    recommendations = request("GET", "/growth/recommendations", token=member_token)
    edge = next(
        item
        for item in recommendations["recommendations"]
        if item["id"] == fixture_ids["recommendation"]
    )
    assert edge["reasons"] and recommendations["automated_adverse_action"] is False

    consent = request(
        "PUT",
        "/growth/imports/consents",
        token=member_token,
        payload={"provider": "manual"},
    )
    assert consent["contacts_ingested"] == 0
    request(
        "DELETE", "/growth/imports/consents/manual", token=member_token
    )

    preference = request(
        "POST", "/growth/history/preferences", token=member_token, expected=(201,)
    )
    fixture_ids["preference"] = preference["history_id"]
    checkin = request(
        "POST",
        "/growth/history/location-checkins",
        token=member_token,
        payload={"city": "Bengaluru", "state": "Karnataka", "country": "India"},
        expected=(201,),
    )["checkin"]
    fixture_ids["checkin"] = checkin["id"]
    assert checkin["source"] == "foreground_checkin"
    history = request("GET", "/growth/history", token=member_token)
    assert history["precise_location_stored"] is False

    fraud = request("GET", "/admin/growth/fraud-graph", token=operator_token)
    assert fraud["automatic_enforcement"] is False
    assert any(item["id"] == fixture_ids["fraud"] for item in fraud["edges"])
    resolved = request(
        "POST",
        f"/admin/growth/fraud-graph/{fixture_ids['fraud']}/resolve",
        token=operator_token,
        payload={"status": "dismissed"},
    )
    assert resolved["automatic_enforcement"] is False

    print(
        "deferred growth API smoke: PASS "
        "(events, referrals, partnerships, recommendations, consent, history, fraud review)"
    )


if __name__ == "__main__":
    main()
