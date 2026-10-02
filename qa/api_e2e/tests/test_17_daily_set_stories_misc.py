"""Curated daily set, profile stories (rich text), notification ownership,
browser WebSocket subprotocol auth, and what a deactivated account can still do.
"""

from __future__ import annotations

import uuid

import pytest
import websocket

from client import API_BASE, Api, login, wait_for
from journeys import befriend, match


pytestmark = pytest.mark.journey("misc")

WS_BASE = API_BASE.replace("http://", "ws://")


# --- curated daily set -------------------------------------------------------------

def test_curated_daily_set_is_small_stable_and_safe(make_member):
    viewer, other = make_member("ds_v", "F", "M"), make_member("ds_o", "M", "F")
    first = viewer.get(f"/discovery/{viewer.user_id}/today").ok()
    ids = [c["id"] for c in first["candidates"]]
    assert len(ids) <= 5 and len(ids) == len(set(ids))
    assert viewer.user_id not in ids
    for c in first["candidates"]:
        assert c["gender"] == "male", "the daily set must respect seeking gender"
        assert c["reasons"], "every pick explains why"
    if ids:
        assert first["set_date"]
        again = viewer.get(f"/discovery/{viewer.user_id}/today").ok()
        assert [c["id"] for c in again["candidates"]] == ids or set(c["id"] for c in again["candidates"]) <= set(ids), \
            "the set must stay stable within the UTC day (it may only shrink)"
        # Blocking a pick removes it from today's set.
        blocked = ids[0]
        viewer.post("/safety/block", {"user_id": viewer.user_id, "blocked_user_id": blocked}).ok()
        try:
            after = [c["id"] for c in viewer.get(f"/discovery/{viewer.user_id}/today").ok()["candidates"]]
            assert blocked not in after
        finally:
            viewer.post("/safety/unblock", {"user_id": viewer.user_id, "blocked_user_id": blocked})


# --- profile stories ------------------------------------------------------------------

def test_profile_stories_versioning_and_rich_text_rules(make_member):
    owner, other = make_member("st_a", "F", "M"), make_member("st_b", "M", "F")
    base = f"/profile/{owner.user_id}/stories"
    prompts = owner.get(base).ok()["prompts"]
    prompt = sorted(prompts)[0]
    saved = owner.put(base, {"stories": [{"prompt_id": prompt, "text": "Small kindnesses, daily."}],
                             "published": True, "expected_version": 0})
    assert saved.status == 200, saved.text
    version = saved["version"]
    stale = owner.put(base, {"stories": [], "published": False, "expected_version": 0})
    assert stale.status == 409, stale.text
    for bad in ([{"prompt_id": "not_a_prompt", "text": "hello there"}],
                [{"prompt_id": prompt, "text": "y" * 401}],
                [{"prompt_id": prompt, "content": {"version": 1, "style": "modern", "blocks": [
                    {"type": "paragraph", "spans": [{"text": "x", "marks": ["link"],
                                                     "href": "javascript:alert(1)"}]}]}}],
                [{"prompt_id": p, "text": "one of too many"} for p in sorted(prompts)[:4]]):
        response = owner.put(base, {"stories": bad, "published": True, "expected_version": version})
        assert response.status == 400, f"{bad!r:.80}: {response.status} {response.text[:200]}"
    assert other.put(base, {"stories": [], "published": False, "expected_version": version}).status == 403
    assert owner.put(base, {"stories": [{"prompt_id": prompt, "text": "x"}], "published": True}).status == 400


# --- notifications ownership ---------------------------------------------------------------

@pytest.mark.authz
def test_member_cannot_touch_another_members_notification(make_member):
    a, b = make_member("nid_a", "F", "M"), make_member("nid_b", "M", "F")
    befriend(a, b)
    note = wait_for(lambda: next((n for n in b.get(f"/notifications/{b.user_id}").ok()["notifications"]
                                  if n["event_type"] == "friend_request.received"), None))
    assert note
    # Via a's own path with b's notification id: must not affect b's inbox.
    a.post(f"/notifications/{a.user_id}/{note['id']}/read")
    a.delete(f"/notifications/{a.user_id}/{note['id']}")
    still = next(n for n in b.get(f"/notifications/{b.user_id}").ok()["notifications"] if n["id"] == note["id"])
    assert still["is_read"] is False
    assert a.post(f"/notifications/{b.user_id}/{note['id']}/read").status == 403


# --- browser realtime auth ------------------------------------------------------------------

@pytest.mark.security
def test_browser_socket_subprotocol_auth(make_member):
    member = make_member("bws_a", "F", "M")
    same_origin = "http://127.0.0.1:18080"
    ws = websocket.create_connection(f"{WS_BASE}/realtime/chat", origin=same_origin,
                                     subprotocols=["connect.v1", f"bearer.{member.token}"], timeout=8)
    try:
        assert '"stream.connected"' in ws.recv()
    finally:
        ws.close()
    with pytest.raises(websocket.WebSocketBadStatusException) as cross:
        websocket.create_connection(f"{WS_BASE}/realtime/chat", origin="https://evil.example",
                                    subprotocols=["connect.v1", f"bearer.{member.token}"], timeout=8)
    assert cross.value.status_code in (401, 403)
    with pytest.raises(websocket.WebSocketBadStatusException):
        websocket.create_connection(f"{WS_BASE}/realtime/chat", origin=same_origin,
                                    subprotocols=["connect.v1", "bearer.not-a-real-token-value"], timeout=8)


# --- deactivated accounts ---------------------------------------------------------------------

@pytest.mark.lifecycle
def test_deactivated_member_is_invisible_but_can_return(make_member):
    member, other = make_member("deac_a", "F", "M"), make_member("deac_b", "M", "F")
    match_id = match(member, other)
    member.post(f"/account/{member.user_id}/deactivate", {"reason": "taking a break"}).ok()
    try:
        assert other.get(f"/profile/{member.user_id}").status in (403, 404)
        assert member.user_id not in [p.get("user_id") or p.get("id") for p in
                                      other.get(f"/discovery/{other.user_id}/liked-me").ok()["profiles"]]
        # Signing in again does not silently reactivate the account.
        assert login(member.username).status == 200
        assert member.get(f"/account/{member.user_id}/lifecycle").ok()["lifecycle"]["deactivated"] is True
    finally:
        member.post(f"/account/{member.user_id}/reactivate", {}).ok()
    assert other.get(f"/profile/{member.user_id}").status == 200
    assert match_id in [m["id"] for m in other.get(f"/matches/{other.user_id}").ok()["matches"]]


@pytest.mark.lifecycle
@pytest.mark.known_defect("OBS-02")
@pytest.mark.xfail(strict=True, reason="OBS-02 (product decision): a deactivated member can still send "
                                       "chat messages into existing matches")
def test_deactivated_member_cannot_message_matches(make_member):
    member, other = make_member("deac_c", "F", "M"), make_member("deac_d", "M", "F")
    match_id = match(member, other)
    member.post(f"/account/{member.user_id}/deactivate", {"reason": "break"}).ok()
    try:
        send = member.post(f"/chat/{match_id}/messages", {"text": "still here", "sender_id": member.user_id})
        assert send.status in (403, 409), send.text
    finally:
        member.post(f"/account/{member.user_id}/reactivate", {})
