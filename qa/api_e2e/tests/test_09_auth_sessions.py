"""Sessions: refresh rotation and reuse, logout, revoke-all, password change,
recovery codes, lockout, malformed credentials, and the account lifecycle.

Every test that changes credentials uses its own member so other modules keep
working with the shared test password.
"""

from __future__ import annotations

import datetime as dt

import pytest

from client import PASSWORD, RUN_ID, Api, login


pytestmark = [pytest.mark.journey("auth_sessions"), pytest.mark.security]

# A different local test-only password for the change/recover journeys.
NEW_PASSWORD = PASSWORD + "9"


def _works(token: str, user_id: str) -> int:
    return Api(token).get(f"/settings/{user_id}").status


# --- tokens -----------------------------------------------------------------------

@pytest.mark.parametrize("header", [
    "Bearer", "Bearer ", "Basic dXNlcjpwYXNz", "bearer not-a-real-token",
    "Bearer " + "A" * 4000, "Bearer ééé", "Token abc",
], ids=["empty-bearer", "bearer-space", "basic", "unknown-token", "huge-token", "non-ascii", "wrong-scheme"])
def test_malformed_or_unknown_credentials_are_401(make_member, header):
    member = make_member("ses_hdr", "F", "M") if not hasattr(test_malformed_or_unknown_credentials_are_401, "m") \
        else test_malformed_or_unknown_credentials_are_401.m
    test_malformed_or_unknown_credentials_are_401.m = member
    try:
        response = Api().get(f"/settings/{member.user_id}", headers={"Authorization": header})
    except UnicodeEncodeError:
        pytest.skip("HTTP client refuses non-latin-1 header values")
    assert response.status == 401, f"{header[:20]!r}: {response.status} {response.text[:200]}"


def test_login_returns_rotating_session_pair(make_member):
    member = make_member("ses_a", "F", "M")
    session = login(member.username).ok()
    assert session["access_token"] and session["refresh_token"]
    assert session["access_token"] != session["refresh_token"]
    assert session["expires_in"] == 1800
    # A refresh token is not an access token.
    assert _works(session["refresh_token"], member.user_id) == 401


def test_refresh_rotates_and_revokes_the_previous_pair(make_member):
    member = make_member("ses_b", "F", "M")
    first = login(member.username).ok()
    second = Api().post("/auth/refresh", {"refresh_token": first["refresh_token"]}).ok()
    assert second["access_token"] != first["access_token"]
    assert second["refresh_token"] != first["refresh_token"]
    assert _works(first["access_token"], member.user_id) == 401
    assert _works(second["access_token"], member.user_id) == 200
    replay = Api().post("/auth/refresh", {"refresh_token": first["refresh_token"]})
    assert replay.status == 401, replay.text


@pytest.mark.known_defect("SEC-01")
@pytest.mark.xfail(strict=True, reason="SEC-01: refresh-token reuse does not revoke the token family")
def test_refresh_token_reuse_revokes_the_family(make_member):
    """OAuth 2.0 BCP: a replayed (stolen) refresh token should end the whole chain."""
    member = make_member("ses_c", "F", "M")
    first = login(member.username).ok()
    second = Api().post("/auth/refresh", {"refresh_token": first["refresh_token"]}).ok()
    Api().post("/auth/refresh", {"refresh_token": first["refresh_token"]})  # reuse
    assert _works(second["access_token"], member.user_id) == 401


def test_refresh_validation():
    for body in ({}, {"refresh_token": ""}, {"refresh_token": "x" * 5000}, {"refresh_token": 12345}):
        response = Api().post("/auth/refresh", body)
        assert response.status in (400, 401), f"{body!r}: {response.status} {response.text[:200]}"


def test_logout_only_ends_the_current_session(make_member):
    member = make_member("ses_d", "F", "M")
    phone, laptop = login(member.username).ok(), login(member.username).ok()
    Api(phone["access_token"]).post("/auth/logout").ok()
    assert _works(phone["access_token"], member.user_id) == 401
    assert _works(laptop["access_token"], member.user_id) == 200
    # The refresh token of the logged-out session is dead too.
    assert Api().post("/auth/refresh", {"refresh_token": phone["refresh_token"]}).status == 401


def test_revoke_all_sessions_signs_out_everywhere(make_member):
    member = make_member("ses_e", "F", "M")
    phone, laptop = login(member.username).ok(), login(member.username).ok()
    revoked = Api(phone["access_token"]).post("/auth/sessions/revoke", {"all_sessions": True}).ok()
    assert revoked["all_sessions"] is True
    for session in (phone, laptop):
        assert _works(session["access_token"], member.user_id) == 401
        assert Api().post("/auth/refresh", {"refresh_token": session["refresh_token"]}).status == 401
    assert login(member.username).status == 200


def test_password_change_rules_and_effects(make_member):
    member = make_member("ses_f", "F", "M")
    session = login(member.username).ok()
    other = login(member.username).ok()
    api = Api(session["access_token"])
    wrong = api.post("/auth/password/change", {"current_password": PASSWORD + "x",
                                               "new_password": NEW_PASSWORD})
    assert wrong.status == 400, wrong.text
    for weak in ("short1", "lettersonly", "1234567890", "a1" * 40):
        response = api.post("/auth/password/change", {"current_password": PASSWORD, "new_password": weak})
        assert response.status == 400, f"{weak!r} accepted: {response.text}"
    assert _works(session["access_token"], member.user_id) == 200, "a rejected change must not sign out"

    changed = api.post("/auth/password/change", {"current_password": PASSWORD,
                                                 "new_password": NEW_PASSWORD}).ok()
    assert changed["reauthentication_required"] is True
    for s in (session, other):
        assert _works(s["access_token"], member.user_id) == 401
    assert login(member.username, PASSWORD).status == 401
    assert login(member.username, NEW_PASSWORD).status == 200


def test_recovery_code_rotation_and_password_recovery(make_member):
    member = make_member("ses_g", "F", "M")
    session = login(member.username).ok()
    first = Api(session["access_token"]).post("/auth/recovery-code/rotate").ok()
    second = Api(session["access_token"]).post("/auth/recovery-code/rotate").ok()
    assert first["recovery_code"] != second["recovery_code"] and second["display_once"] is True

    stale = Api().post("/auth/password/recover", {"username": member.username,
                                                  "recovery_code": first["recovery_code"],
                                                  "new_password": NEW_PASSWORD})
    assert stale.status == 400, "a rotated-out recovery code must not work"
    weak = Api().post("/auth/password/recover", {"username": member.username,
                                                 "recovery_code": second["recovery_code"],
                                                 "new_password": "weak"})
    assert weak.status == 400
    wrong_user = Api().post("/auth/password/recover", {"username": f"e2e_{RUN_ID}_nobody",
                                                       "recovery_code": second["recovery_code"],
                                                       "new_password": NEW_PASSWORD})
    assert wrong_user.status == 400
    Api().post("/auth/password/recover", {"username": member.username,
                                          "recovery_code": second["recovery_code"],
                                          "new_password": NEW_PASSWORD}).ok()
    assert _works(session["access_token"], member.user_id) == 401, "recovery must end sessions"
    assert login(member.username, NEW_PASSWORD).status == 200
    reuse = Api().post("/auth/password/recover", {"username": member.username,
                                                  "recovery_code": second["recovery_code"],
                                                  "new_password": PASSWORD})
    assert reuse.status == 400, "a recovery code is single-use"


# Regression guard: API-10 (fixed, verified live 2026-10-02)
def test_recovery_code_is_not_replayed_from_the_idempotency_ledger(make_member):
    """API-10 (S2): the display-once code was cached in plaintext and replayed."""
    import uuid

    member = make_member("ses_h", "F", "M")
    headers = {"Idempotency-Key": f"e2e-{uuid.uuid4()}"}
    first = member.post("/auth/recovery-code/rotate", headers=headers).ok()
    replay = member.post("/auth/recovery-code/rotate", headers=headers)
    assert replay.headers.get("X-Idempotent-Replay") != "true"
    assert replay.get("recovery_code") != first["recovery_code"]


def test_failed_logins_lock_the_account_for_a_while(make_member):
    member = make_member("ses_lock", "F", "M")
    statuses = [login(member.username, PASSWORD + "wrong").status for _ in range(5)]
    assert statuses == [401] * 5, statuses
    locked = login(member.username, PASSWORD)
    assert locked.status == 401 and "locked" in locked.text.lower(), locked.text
    # The existing session is unaffected by the lock.
    assert _works(member.token, member.user_id) == 200


@pytest.mark.parametrize("body", [
    {}, {"username": "", "password": ""}, {"username": "x" * 300, "password": "y"},
    {"username": "' OR 1=1 --", "password": "' OR 1=1 --"}, {"username": ["a"], "password": {"b": 1}},
], ids=["empty", "blank", "huge", "sql", "wrong-types"])
def test_login_input_validation(body):
    response = Api().post("/auth/login", body)
    assert response.status in (400, 401), f"{body!r}: {response.status} {response.text[:200]}"
    assert "access_token" not in response.text


@pytest.mark.parametrize("dob,ok", [
    ((dt.date.today().replace(year=dt.date.today().year - 18) - dt.timedelta(days=1)).isoformat(), True),
    ((dt.date.today().replace(year=dt.date.today().year - 18) + dt.timedelta(days=1)).isoformat(), False),
    ("1900-01-01", False), ("2000-02-30", False), ("01/02/1990", False),
], ids=["just-18", "one-day-short-of-18", "too-old", "invalid-date", "wrong-format"])
def test_signup_bootstrap_age_gate(dob, ok):
    username = f"e2e_{RUN_ID}_age{abs(hash(dob)) % 10000}"[:30].lower()
    signup = Api().post("/auth/signup", {"username": username, "password": PASSWORD}).ok()
    api = Api(signup["access_token"])
    response = api.post("/auth/signup/bootstrap", {"user_id": signup["user_id"], "username": username,
                                                   "name": "Age Gate", "date_of_birth": dob,
                                                   "gender": "F"})
    try:
        if ok:
            assert response.status == 200, response.text
        else:
            assert response.status == 400, f"{dob}: {response.status} {response.text[:200]}"
    finally:
        if response.status == 200:
            api.post(f"/account/{signup['user_id']}/deletion", {"reason": "api e2e cleanup"})


@pytest.mark.parametrize("gender", ["X", "", "robot"])
def test_signup_bootstrap_rejects_unknown_gender(gender):
    username = f"e2e_{RUN_ID}_g{gender or 'none'}"[:30].lower()
    signup = Api().post("/auth/signup", {"username": username, "password": PASSWORD}).ok()
    response = Api(signup["access_token"]).post("/auth/signup/bootstrap", {
        "user_id": signup["user_id"], "username": username, "name": "Gender Gate",
        "date_of_birth": "1990-01-01", "gender": gender})
    assert response.status == 400, response.text


def test_signup_tokens_cannot_bootstrap_someone_else(make_member):
    victim = make_member("ses_boot", "F", "M")
    username = f"e2e_{RUN_ID}_boot_x"[:30].lower()
    signup = Api().post("/auth/signup", {"username": username, "password": PASSWORD}).ok()
    response = Api(signup["access_token"]).post("/auth/signup/bootstrap", {
        "user_id": victim.user_id, "username": victim.username, "name": "Hijack",
        "date_of_birth": "1990-01-01", "gender": "M"})
    assert response.status in (401, 403), response.text
    assert victim.get(f"/profile/{victim.user_id}").ok()["profile"]["name"] != "Hijack"


# --- account lifecycle -----------------------------------------------------------

@pytest.mark.lifecycle
def test_deactivated_member_leaves_discovery_and_reactivates(make_member):
    member = make_member("lc_a", "M", "F")
    viewer = make_member("lc_v", "F", "M")

    def visible():
        body = viewer.get(f"/discovery/{viewer.user_id}", params={"limit": 300}).ok().body
        return member.user_id in [c.get("id") or c.get("user_id") for c in body["candidates"]]

    assert visible()
    member.post(f"/account/{member.user_id}/deactivate", {"reason": "api e2e"}).ok()
    lifecycle = member.get(f"/account/{member.user_id}/lifecycle").ok()["lifecycle"]
    assert lifecycle["deactivated"] is True
    assert not visible()
    assert viewer.get(f"/profile/{member.user_id}").status in (403, 404) or \
        viewer.get(f"/profile/{member.user_id}").get("found") is False
    member.post(f"/account/{member.user_id}/reactivate", {}).ok()
    assert member.get(f"/account/{member.user_id}/lifecycle").ok()["lifecycle"]["deactivated"] is False
    assert visible()


@pytest.mark.lifecycle
def test_deletion_request_is_cancellable_once(make_member):
    member = make_member("lc_b", "F", "M")
    requested = member.post(f"/account/{member.user_id}/deletion", {"reason": "api e2e"})
    assert requested.status == 202, requested.text
    assert requested["grace_days"] == 14
    assert member.post(f"/account/{member.user_id}/deletion", {"reason": "again"}).status == 409
    member.delete(f"/account/{member.user_id}/deletion").ok()
    assert member.delete(f"/account/{member.user_id}/deletion").status == 409
    assert member.get(f"/account/{member.user_id}/lifecycle").ok()["lifecycle"]["deactivated"] is False


@pytest.mark.lifecycle
def test_data_export_contains_only_my_data(make_member):
    member = make_member("lc_c", "F", "M")
    assert member.get(f"/account/{member.user_id}/export").status == 404
    created = member.post(f"/account/{member.user_id}/export")
    assert created.status == 201, created.text
    export = member.get(f"/account/{member.user_id}/export").ok()["export"]
    assert member.user_id in str(export)
    assert "password" not in str(export).lower() or "password_hash" not in str(export).lower()
    assert "access_token" not in str(export) and "refresh_token" not in str(export)
