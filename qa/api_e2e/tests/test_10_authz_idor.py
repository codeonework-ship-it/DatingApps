"""Authorization: member A must never read or change member B's resources.

Covers self-scoped routes, actor fields in request bodies (including bodies sent
with a non-JSON Content-Type, API-06), match-scoped routes for a non-participant,
operator routes for a member, and identity headers a caller tries to forge.
"""

from __future__ import annotations

import json as jsonlib
import uuid

import pytest

from client import png_bytes
from journeys import match


pytestmark = [pytest.mark.journey("authorization"), pytest.mark.authz]

@pytest.fixture(scope="module")
def trio(make_member):
    a = make_member("az_a", "F", "M")
    b = make_member("az_b", "M", "F")
    c = make_member("az_c", "F", "M")
    match_id = match(a, b)
    return a, b, c, match_id


def _status(resp):
    return f"{resp.method} {resp.url} -> {resp.status} {resp.text[:200]}"


# --- self-scoped routes ------------------------------------------------------

SELF_SCOPED_READS = [
    "/settings/{v}", "/emergency-contacts/{v}", "/blocked-users/{v}", "/verification/{v}",
    "/wallet/{v}/coins", "/wallet/{v}/coins/audit", "/progression/{v}", "/progression/{v}/ledger",
    "/plans/{v}", "/friends/{v}", "/friends/{v}/vouches", "/friends/{v}/intros",
    "/notifications/{v}", "/notifications/{v}/unread-count", "/notifications/{v}/preferences",
    "/account/{v}/lifecycle", "/account/{v}/export", "/account/{v}/dating-preferences",
    "/discovery/{v}", "/discovery/{v}/today", "/discovery/{v}/liked-me", "/discovery/{v}/filters/trust",
    "/profile/{v}/draft", "/profile/{v}/summary", "/profile/{v}/viewers",
    "/billing/entitlements/{v}", "/billing/subscription/{v}", "/billing/payments/{v}",
    "/safety/sos/{v}", "/calls/history/{v}", "/engagement/daily-prompt/{v}",
    "/users/{v}/agreements/terms", "/auth/signup/workflow/{v}", "/matches/{v}",
]


@pytest.mark.parametrize("template", SELF_SCOPED_READS)
def test_member_cannot_read_another_members_private_route(trio, template):
    a, _, c, _ = trio
    response = c.get(template.format(v=a.user_id))
    assert response.status == 403, _status(response)


SELF_SCOPED_WRITES = [
    ("PATCH", "/settings/{v}", {"theme": "dark:gothic"}),
    ("PATCH", "/profile/{v}/draft", {"bio": "hijacked bio"}),
    ("POST", "/profile/{v}/complete", {}),
    ("PUT", "/profile/{v}", {"bio": "hijacked"}),
    ("POST", "/profile/{v}/photos/reorder", {"photo_ids": []}),
    ("POST", "/emergency-contacts/{v}", {"name": "Mallory", "phone": "+447700900123"}),
    ("PATCH", "/notifications/{v}/preferences", {"notify_likes": False}),
    ("POST", "/notifications/{v}/read-all", {}),
    ("POST", "/account/{v}/deactivate", {"reason": "idor"}),
    ("POST", "/account/{v}/deletion", {"reason": "idor"}),
    ("DELETE", "/account/{v}/deletion", None),
    ("POST", "/account/{v}/export", {}),
    ("POST", "/account/{v}/discovery/pause", {}),
    ("PUT", "/account/{v}/dating-preferences", {"intent": "long_term"}),
    ("PATCH", "/discovery/{v}/filters/trust", {"enabled": True}),
    ("PUT", "/friends/{v}/search-visibility", {"visible": False}),
    ("POST", "/friends/{v}", {"friend_user_id": "{c}", "source": "search"}),
    ("PATCH", "/users/{v}/agreements/terms", {"accepted": True, "terms_version": "v1"}),
    ("POST", "/billing/subscription/{v}/cancel", {}),
    ("POST", "/wallet/{v}/coins/buy", {"package_id": "x"}),
    ("POST", "/progression/{v}/rewards/claim", {}),
]


@pytest.mark.parametrize("method,template,body", SELF_SCOPED_WRITES,
                         ids=[f"{m} {t}" for m, t, _ in SELF_SCOPED_WRITES])
def test_member_cannot_change_another_members_resources(trio, method, template, body):
    a, _, c, _ = trio
    if body is not None:
        body = jsonlib.loads(jsonlib.dumps(body).replace("{c}", c.user_id))
    response = c.api.call(method, template.format(v=a.user_id), json=body)
    assert response.status == 403, _status(response)


def test_victim_state_is_unchanged_after_the_attempts(trio):
    a, _, _, _ = trio
    settings = a.get(f"/settings/{a.user_id}").ok()["settings"]
    assert settings["theme"] != "dark:gothic"
    assert a.get(f"/profile/{a.user_id}/draft").ok()["draft"].get("bio") != "hijacked bio"
    lifecycle = a.get(f"/account/{a.user_id}/lifecycle").ok()["lifecycle"]
    assert lifecycle["deactivated"] is False, lifecycle
    assert lifecycle.get("deletion_requested_at") in (None, ""), lifecycle


def test_member_cannot_upload_or_delete_another_members_photos(trio):
    a, _, c, _ = trio
    upload = c.api.call("POST", f"/profile/{a.user_id}/photos",
                        files={"image": ("x.png", png_bytes((1, 2, 3)), "image/png")})
    assert upload.status == 403, _status(upload)
    photos = a.get(f"/profile/{a.user_id}").ok()["profile"].get("photos") or []
    photo_id = photos[0]["id"] if photos and isinstance(photos[0], dict) else str(uuid.uuid4())
    delete = c.delete(f"/profile/{a.user_id}/photos/{photo_id}")
    assert delete.status == 403, _status(delete)


# --- actor fields in request bodies -------------------------------------------

def test_actor_fields_in_json_bodies_must_be_the_caller(trio):
    a, b, c, match_id = trio
    attempts = [
        ("/swipe", {"user_id": a.user_id, "target_user_id": c.user_id, "is_like": True}),
        ("/safety/block", {"user_id": a.user_id, "blocked_user_id": c.user_id}),
        ("/safety/report", {"reporter_user_id": a.user_id, "reported_user_id": b.user_id,
                            "reason": "spam", "description": "idor"}),
        (f"/chat/{match_id}/messages", {"text": "as a", "sender_id": a.user_id}),
    ]
    for path, body in attempts:
        response = b.post(path, body)
        assert response.status == 403, _status(response)


def test_identity_headers_cannot_be_forged(trio):
    a, _, c, _ = trio
    forged = c.get(f"/settings/{a.user_id}", headers={"X-User-ID": a.user_id,
                                                      "X-Admin-User": a.user_id})
    assert forged.status == 403, _status(forged)
    admin = c.get("/admin/users", headers={"X-Admin-User": "admin", "X-User-Roles": "admin"})
    assert admin.status == 403, _status(admin)


@pytest.mark.security
# Regression guard: API-06 (fixed, verified live 2026-10-02)
@pytest.mark.parametrize("content_type,suffix", [
    ("text/plain", ""),
    (None, ""),
    ("multipart/form-data; boundary=x", ""),
    ("application/json", " trailing"),
], ids=["text-plain", "no-content-type", "multipart-label", "json-trailing-bytes"])
def test_actor_spoofing_cannot_hide_behind_content_type(make_member, content_type, suffix):
    """API-06 (S1): the actor check only ran for application/json bodies."""
    tag = (content_type or "none").split("/")[0][:4] + str(len(suffix))
    attacker = make_member(f"az6{tag}_x", "F", "M")
    victim = make_member(f"az6{tag}_v", "M", "F")
    body = jsonlib.dumps({"user_id": victim.user_id, "target_user_id": attacker.user_id,
                          "is_like": True}) + suffix
    headers = {"Content-Type": content_type} if content_type else {}
    response = attacker.api.call("POST", "/swipe", data=body.encode(), headers=headers)
    liked_me = attacker.get(f"/discovery/{attacker.user_id}/liked-me").ok()["profiles"]
    forged = victim.user_id in [p.get("user_id") or p.get("id") for p in liked_me]
    assert response.status in (400, 403) and not forged, (
        f"forged like as the victim: {_status(response)}; victim in attacker's liked-me: {forged}")


@pytest.mark.security
# Regression guard: API-06 (fixed, verified live 2026-10-02)
def test_chat_sender_cannot_be_spoofed_with_text_plain(trio):
    a, b, _, match_id = trio
    body = jsonlib.dumps({"text": "I am A (forged by B)", "sender_id": a.user_id})
    response = b.api.call("POST", f"/chat/{match_id}/messages", data=body.encode(),
                          headers={"Content-Type": "text/plain"})
    messages = a.get(f"/chat/{match_id}/messages", params={"limit": 50}).ok()["messages"]
    forged = [m for m in messages if m["text"] == "I am A (forged by B)" and m["sender_id"] == a.user_id]
    assert response.status == 403 and not forged, _status(response)


# Regression guard: API-07 (fixed, verified live 2026-10-02)
def test_match_participant_cannot_delete_the_partners_message(trio):
    """API-07 (S2): DELETE trusted requester_user_id, so B could delete A's messages."""
    a, b, _, match_id = trio
    sent = a.post(f"/chat/{match_id}/messages", {"text": "A's own words", "sender_id": a.user_id}).ok()
    message_id = sent["message_id"]
    spoof = b.delete(f"/chat/{match_id}/messages/{message_id}", {"requester_user_id": a.user_id})
    still_there = [m for m in a.get(f"/chat/{match_id}/messages", params={"limit": 50}).ok()["messages"]
                   if m["id"] == message_id and not m.get("is_deleted")]
    assert spoof.status == 403 and still_there, _status(spoof)


def test_partner_cannot_delete_a_message_naming_themselves(trio):
    a, b, _, match_id = trio
    sent = a.post(f"/chat/{match_id}/messages", {"text": "keep me", "sender_id": a.user_id}).ok()
    response = b.delete(f"/chat/{match_id}/messages/{sent['message_id']}",
                        {"requester_user_id": b.user_id})
    assert response.status in (403, 404), _status(response)
    assert response.get("deleted") is not True


# --- match-scoped routes for a non-participant --------------------------------

MATCH_READS = ["/chat/{m}/messages", "/matches/{m}/unlock-state", "/matches/{m}/plans",
               "/matches/{m}/connection", "/matches/{m}/graduation", "/matches/{m}/trust",
               "/matches/{m}/timeline", "/matches/{m}/chapter", "/matches/{m}/voice-introductions",
               "/matches/{m}/quest-workflow"]


@pytest.mark.parametrize("template", MATCH_READS)
def test_outsider_cannot_read_a_match(trio, template):
    _, _, c, match_id = trio
    response = c.get(template.format(m=match_id))
    assert response.status in (403, 404), _status(response)


def test_outsider_cannot_write_to_a_match(trio):
    a, _, c, match_id = trio
    attempts = [
        ("POST", f"/chat/{match_id}/messages", {"text": "intruder", "sender_id": c.user_id}),
        ("POST", f"/matches/{match_id}/read", {"user_id": c.user_id}),
        ("DELETE", f"/matches/{match_id}", None),
        ("PUT", f"/matches/{match_id}/quest-template", {"creator_user_id": c.user_id,
                                                         "prompt_template": "Tell me a secret please",
                                                         "min_chars": 20, "max_chars": 200}),
        ("POST", f"/matches/{match_id}/plans", {"title": "intrusion"}),
        ("POST", f"/matches/{match_id}/copilot/draft", {}),
        ("POST", f"/chat/{match_id}/gifts/send", {"gift_id": "rose_red_single",
                                                    "sender_user_id": c.user_id,
                                                    "receiver_user_id": a.user_id}),
    ]
    for method, path, body in attempts:
        response = c.api.call(method, path, json=body, params={"user_id": c.user_id}
                              if method == "DELETE" else None)
        assert response.status in (403, 404), _status(response)
    texts = [m["text"] for m in a.get(f"/chat/{match_id}/messages").ok()["messages"]]
    assert "intruder" not in texts


def test_unknown_match_id_is_refused(trio):
    _, _, c, _ = trio
    response = c.get(f"/chat/{uuid.uuid4()}/messages")
    assert response.status in (403, 404), _status(response)


# Regression guard: API-08 (fixed, verified live 2026-10-02)
@pytest.mark.parametrize("match_id", ["not-a-uuid", "' OR '1'='1"])
def test_malformed_match_id_is_a_client_error_not_503(trio, match_id):
    """API-08 (S3): a malformed match id failed the uuid cast in Postgres -> 503."""
    _, _, c, _ = trio
    response = c.get(f"/chat/{match_id}/messages")
    assert response.status in (400, 403, 404), _status(response)


# --- operator routes ------------------------------------------------------------

ADMIN_ROUTES = [
    ("GET", "/admin/users"), ("GET", "/admin/analytics/overview"), ("GET", "/admin/analytics/kpis"),
    ("GET", "/admin/business/revenue"), ("GET", "/admin/billing/stats"),
    ("GET", "/admin/billing/transactions"), ("GET", "/admin/support/tickets"),
    ("GET", "/admin/client-errors"), ("GET", "/admin/moderation/reports"),
    ("GET", "/admin/config/flags"), ("GET", "/admin/audit-events"),
    ("POST", "/admin/billing/grant-coins"), ("PATCH", "/admin/config/flags/support_ticketing_enabled"),
    ("POST", "/admin/users/{v}/ban"), ("POST", "/admin/users/{v}/verify"),
    ("POST", "/admin/analytics/snapshots/rebuild"), ("GET", "/admin/users/{v}/wallet"),
]


@pytest.mark.parametrize("method,template", ADMIN_ROUTES, ids=[f"{m} {t}" for m, t in ADMIN_ROUTES])
def test_member_cannot_use_operator_routes(trio, method, template):
    a, _, c, _ = trio
    body = {"user_id": c.user_id, "coins": 1000, "value_bool": True, "reason": "idor"} \
        if method != "GET" else None
    response = c.api.call(method, template.format(v=a.user_id), json=body)
    assert response.status == 403, _status(response)


def test_member_analytics_view_is_operator_only(trio):
    a, _, _, _ = trio
    assert a.get(f"/analytics/{a.user_id}").status == 403


def test_member_cannot_grant_themselves_coins(trio):
    a, _, _, _ = trio
    before = a.get(f"/wallet/{a.user_id}/coins").ok()["wallet"]["coin_balance"]
    top_up = a.post(f"/wallet/{a.user_id}/coins/top-up", {"coins": 5000, "user_id": a.user_id,
                                                         "reason": "free money"})
    assert top_up.status in (400, 403, 404, 405), _status(top_up)
    after = a.get(f"/wallet/{a.user_id}/coins").ok()["wallet"]["coin_balance"]
    assert after == before
