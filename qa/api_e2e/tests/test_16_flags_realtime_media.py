"""Feature-flag off-states, realtime streams, media upload limits, room
capacity and group covers.
"""

from __future__ import annotations

import json
import time
import uuid

import pytest
import websocket

from client import API_BASE, Api, png_bytes
from journeys import befriend, match


pytestmark = pytest.mark.journey("flags_realtime_media")

WS_BASE = API_BASE.replace("http://", "ws://").replace("https://", "wss://")


def _flags(member):
    return {f["key"]: f["value_bool"] for f in member.get("/config/flags").ok()["flags"]}


# --- feature flags ------------------------------------------------------------------

@pytest.mark.flags
def test_support_ticketing_gate_holds_while_the_flag_is_off(make_member):
    member = make_member("flag_a", "F", "M")
    if _flags(member).get("support_ticketing_enabled", True):
        pytest.skip("support_ticketing_enabled is on in this stack")
    attempts = [
        member.get("/support/tickets"),
        member.post("/support/tickets", {"subject": "Help please", "body": "e2e flag check", "category": "account"}),
        member.get(f"/support/tickets/{uuid.uuid4()}"),
        member.api.call("POST", "/support/attachments", files={"file": ("a.png", png_bytes(), "image/png")}),
        Api().post("/support/contact", {"email": "qa@example.test", "subject": "Hello there",
                                        "message": "e2e flag check", "name": "QA"}),
    ]
    for response in attempts:
        assert response.status == 403, f"{response.method} {response.url} -> {response.status} {response.text[:200]}"
        assert response["error_code"] == "FEATURE_DISABLED"
        assert response["feature_flag"] == "support_ticketing_enabled"


@pytest.mark.flags
@pytest.mark.parametrize("flag,method,path", [
    ("referrals_enabled", "GET", "/growth/referrals/me"),
    ("referrals_enabled", "POST", "/growth/referrals/redeem"),
    ("growth_events_enabled", "GET", "/growth/events"),
    ("partnerships_enabled", "GET", "/growth/partnerships"),
    ("member_history_enabled", "GET", "/growth/history"),
    ("recommendation_graph_enabled", "GET", "/growth/recommendations"),
    ("admirer_gifts_enabled", "GET", "/growth/admirer-gifts"),
    ("paid_xp_enabled", "GET", "/growth/paid-xp"),
    ("social_imports_enabled", "GET", "/growth/imports/consents"),
])
def test_disabled_growth_modules_refuse_members(make_member, flag, method, path):
    member = getattr(test_disabled_growth_modules_refuse_members, "m", None) or make_member("flag_g", "F", "M")
    test_disabled_growth_modules_refuse_members.m = member
    if _flags(member).get(flag, False):
        pytest.skip(f"{flag} is on in this stack")
    response = member.api.call(method, path, json={} if method != "GET" else None)
    assert response.status == 403 and response["error_code"] == "FEATURE_DISABLED", response.text[:200]
    assert response["feature_flag"] == flag


@pytest.mark.flags
def test_city_pilot_is_closed_while_its_flag_is_off(make_member):
    member = make_member("flag_c", "F", "M")
    if _flags(member).get("city_pilot_enabled", False):
        pytest.skip("city_pilot_enabled is on")
    state = member.get("/city-pilot").ok()
    assert state["can_join"] is False
    join = member.post("/city-pilot/membership", {"action": "join"})
    assert join.status in (400, 403, 409), join.text
    assert state["membership"] == "none"


@pytest.mark.flags
def test_flag_listing_is_readable_but_not_writable_by_members(make_member):
    member = make_member("flag_d", "F", "M")
    flags = _flags(member)
    assert "support_ticketing_enabled" in flags and isinstance(flags["support_ticketing_enabled"], bool)
    assert member.patch("/admin/config/flags/support_ticketing_enabled", {"value_bool": True}).status == 403
    assert _flags(member)["support_ticketing_enabled"] == flags["support_ticketing_enabled"]


# --- realtime -------------------------------------------------------------------------

def _connect(path, token):
    return websocket.create_connection(f"{WS_BASE}{path}", header=[f"Authorization: Bearer {token}"], timeout=8)


def _drain_until(ws, predicate, seconds=8.0):
    deadline = time.time() + seconds
    seen = []
    while time.time() < deadline:
        try:
            raw = ws.recv()
        except websocket.WebSocketTimeoutException:
            break
        if not raw:
            break
        event = json.loads(raw)
        seen.append(event)
        if predicate(event):
            return event, seen
    return None, seen


@pytest.mark.security
def test_realtime_requires_a_bearer_session(make_member):
    member = make_member("rt_auth", "F", "M")
    for path in ("/realtime/chat", "/realtime/notifications"):
        for header in ([], ["Authorization: Bearer not-a-token"]):
            with pytest.raises(websocket.WebSocketBadStatusException) as refused:
                websocket.create_connection(f"{WS_BASE}{path}", header=header, timeout=5)
            assert refused.value.status_code == 401
        with pytest.raises(websocket.WebSocketBadStatusException) as query_token:
            websocket.create_connection(f"{WS_BASE}{path}?access_token={member.token}", timeout=5)
        assert query_token.value.status_code == 401, "tokens in URLs leak into logs"
    bad_cursor = Api(member.token).get("/realtime/chat", params={"after": "-5"})
    assert bad_cursor.status in (400, 401), bad_cursor.text[:200]


def test_realtime_chat_delivers_only_my_matches(make_member):
    a, b, outsider = make_member("rt_a", "F", "M"), make_member("rt_b", "M", "F"), make_member("rt_o", "F", "M")
    match_id = match(a, b)
    ws_b, ws_out = _connect("/realtime/chat", b.token), _connect("/realtime/chat", outsider.token)
    try:
        sent = a.post(f"/chat/{match_id}/messages", {"text": "realtime e2e", "sender_id": a.user_id}).ok()
        event, _ = _drain_until(ws_b, lambda e: e.get("type") == "message.created"
                                and e.get("payload", {}).get("message_id") == sent["message_id"])
        assert event, "partner did not receive message.created"
        leaked, seen = _drain_until(ws_out, lambda e: e.get("match_id") == match_id, seconds=3)
        assert leaked is None, f"outsider received another match's event: {leaked}"
    finally:
        ws_b.close()
        ws_out.close()


def test_realtime_notifications_stream_connects_and_replays(make_member):
    a, b = make_member("rt_n1", "F", "M"), make_member("rt_n2", "M", "F")
    ws = _connect("/realtime/notifications", b.token)
    try:
        a.post("/swipe", {"user_id": a.user_id, "target_user_id": b.user_id, "is_like": True}).ok()
        event, seen = _drain_until(ws, lambda e: "like" in json.dumps(e).lower(), seconds=8)
        assert seen, "no frames at all on the notifications stream"
    finally:
        ws.close()


@pytest.mark.security
@pytest.mark.lifecycle
def test_logout_ends_an_open_realtime_stream(make_member):
    from client import login

    member = make_member("rt_lo", "F", "M")
    session = login(member.username).ok()
    ws = _connect("/realtime/chat", session["access_token"])
    try:
        Api(session["access_token"]).post("/auth/logout").ok()
        deadline = time.time() + 20
        closed = False
        ws.settimeout(2)
        while time.time() < deadline and not closed:
            try:
                frame = ws.recv()
                closed = frame == ""
            except (websocket.WebSocketConnectionClosedException, ConnectionError, OSError):
                closed = True
            except websocket.WebSocketTimeoutException:
                continue
        assert closed, "a revoked session kept its realtime stream open for 20s"
    finally:
        ws.close()


# --- media limits ----------------------------------------------------------------------

def _upload_photo(member, data, name="p.png", ctype="image/png"):
    return member.api.call("POST", f"/profile/{member.user_id}/photos", files={"image": (name, data, ctype)})


def test_photo_upload_type_size_and_count_limits(make_member):
    member = make_member("ph_a", "F", "M")
    assert _upload_photo(member, b"plain text, not an image", "x.png").status == 415
    assert _upload_photo(member, b"GIF89a" + b"\x00" * 64, "x.gif", "image/gif").status == 415
    assert _upload_photo(member, png_bytes(size=120)).status == 422, "below the 300px minimum"
    assert _upload_photo(member, b"").status in (400, 415)
    not_multipart = member.post(f"/profile/{member.user_id}/photos", {"image": "base64?"})
    assert not_multipart.status == 415
    # A PNG renamed .jpg is judged by its bytes, not its name.
    assert _upload_photo(member, png_bytes((9, 9, 9)), "renamed.jpg", "image/jpeg").status == 200
    statuses = [_upload_photo(member, png_bytes((n, 40, 80))).status for n in range(2)]
    assert statuses == [200, 200], statuses
    sixth = _upload_photo(member, png_bytes((200, 10, 10)))
    assert sixth.status == 409, f"6th photo: {sixth.status} {sixth.text[:200]}"


def test_photo_reorder_and_delete(make_member):
    member = make_member("ph_b", "F", "M")
    _upload_photo(member, png_bytes((1, 100, 1))).ok()
    photos = member.get(f"/profile/{member.user_id}/draft").ok()["draft"]["photos"]
    ids = [p["id"] for p in photos]
    reordered = member.post(f"/profile/{member.user_id}/photos/reorder", {"photo_ids": list(reversed(ids))}).ok()
    assert [p["id"] for p in reordered["draft"]["photos"]] == list(reversed(ids))
    assert member.post(f"/profile/{member.user_id}/photos/reorder", {"photo_ids": []}).status == 400
    member.delete(f"/profile/{member.user_id}/photos/{ids[-1]}").ok()
    assert member.delete(f"/profile/{member.user_id}/photos/{uuid.uuid4()}").status == 404


# Regression guard: API-21 (fixed, verified live 2026-10-02)
def test_photo_reorder_with_wrong_ids_is_a_400(make_member):
    member = make_member("ph_c", "F", "M")
    photos = member.get(f"/profile/{member.user_id}/draft").ok()["draft"]["photos"]
    response = member.post(f"/profile/{member.user_id}/photos/reorder",
                           {"photo_ids": [photos[0]["id"], str(uuid.uuid4())]})
    assert response.status == 400, response.text


# --- rooms and group covers ----------------------------------------------------------------

def test_room_capacity_and_one_open_room_per_host(make_member):
    host, g1, g2 = make_member("cap_h", "F", "M"), make_member("cap_1", "M", "F"), make_member("cap_2", "F", "M")
    room = host.post("/rooms", {"title": "E2E tiny room", "category": "talk", "capacity": 2,
                                "duration_minutes": 30})
    assert room.status == 201, room.text
    room_id = room["room"]["id"]
    try:
        second = host.post("/rooms", {"title": "E2E second room", "category": "talk"})
        assert second.status == 409, second.text
        g1.post(f"/rooms/{room_id}/join", {"user_id": g1.user_id}).ok()
        full = g2.post(f"/rooms/{room_id}/join", {"user_id": g2.user_id})
        assert full.status == 409 and full["error_code"] == "ROOM_CAPACITY_REACHED", full.text
    finally:
        host.post(f"/rooms/{room_id}/moderate", {"action": "close", "reason": "e2e cleanup"})


def test_group_cover_upload_rules(make_member):
    owner, friend = make_member("cov_o", "F", "M"), make_member("cov_f", "M", "F")
    befriend(owner, friend)
    group = owner.post("/engagement/groups", {"kind": "private", "name": "E2E cover crew",
                                              "invitee_user_ids": [friend.user_id]})
    assert group.status == 201, group.text
    gid = group["group"]["id"]
    path = f"/engagement/groups/{gid}/cover"
    try:
        friend.post(f"/engagement/groups/{gid}/invites/respond", {"decision": "accept"}).ok()
        member_try = friend.api.call("PUT", path, files={"image": ("c.png", png_bytes(), "image/png")})
        assert member_try.status == 403, member_try.text
        assert owner.api.call("PUT", path, files={"image": ("c.txt", b"hello", "text/plain")}).status == 415
        assert owner.api.call("PUT", path, files={"image": ("c.png", png_bytes(size=100), "image/png")}).status == 422
        ok = owner.api.call("PUT", path, files={"image": ("c.png", png_bytes((10, 120, 60)), "image/png"),
                                                "cover_id": (None, str(uuid.uuid4()))})
        assert ok.status == 200, ok.text
        assert ok["cover"]["status"] in ("pending", "approved", "pending_review")
    finally:
        owner.delete(f"/engagement/groups/{gid}")
