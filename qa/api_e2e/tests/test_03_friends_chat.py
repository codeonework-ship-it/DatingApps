"""Friends: search, opt-out, request/accept/decline, friend chat, mute, remove."""

from __future__ import annotations

import uuid

import pytest

from journeys import befriend


pytestmark = pytest.mark.journey("friends")


@pytest.fixture(scope="module")
def trio(make_member):
    return (make_member("fr_a", "F", "M"), make_member("fr_b", "M", "F"),
            make_member("fr_c", "F", "M"))


def _search(member, q):
    return member.get(f"/friends/{member.user_id}/search", params={"q": q}).ok()["results"]


def test_search_finds_member_by_username_with_relationship(trio):
    a, b, _ = trio
    rows = _search(a, b.username)
    row = next(r for r in rows if r["user_id"] == b.user_id)
    assert row["relationship"] == "none"
    # Only card fields are exposed: no age, bio, gender or exact location.
    assert not {"age", "bio", "gender", "date_of_birth", "latitude"} & set(row)
    # A leading @ is ignored.
    assert any(r["user_id"] == b.user_id for r in _search(a, "@" + b.username))


def test_search_rejects_too_short_queries(trio):
    a, _, _ = trio
    response = a.get(f"/friends/{a.user_id}/search", params={"q": "e"})
    assert response.status == 400, response.text


def test_search_visibility_opt_out_hides_member_from_search(trio):
    a, b, _ = trio
    base = f"/friends/{b.user_id}/search-visibility"
    assert b.get(base).ok()["visible"] is True  # default on
    b.put(base, {"visible": False}).ok()
    try:
        assert b.get(base).ok()["visible"] is False
        assert b.user_id not in [r["user_id"] for r in _search(a, b.username)]
        # Opted-out members can still receive a request from someone who sees them elsewhere.
        sent = a.post(f"/friends/{a.user_id}", {"friend_user_id": b.user_id, "source": "profile"})
        assert sent.status == 200, sent.text
        a.delete(f"/friends/{a.user_id}/{b.user_id}").ok()
    finally:
        b.put(base, {"visible": True}).ok()
    assert b.user_id in [r["user_id"] for r in _search(a, b.username)]
    bad = b.put(base, {"visible": "nope"})
    assert bad.status == 400


def test_request_shows_outgoing_and_incoming_then_accept(trio):
    a, b, _ = trio
    sent = a.post(f"/friends/{a.user_id}", {"friend_user_id": b.user_id, "source": "search"}).ok()
    assert sent["friend"]["status"] == "pending"
    assert sent["friend"]["direction"] == "outgoing"
    assert next(r for r in _search(a, b.username) if r["user_id"] == b.user_id)["relationship"] == "outgoing"
    incoming = b.get(f"/friends/{b.user_id}").ok()["friends"]
    row = next(f for f in incoming if f["friend_user_id"] == a.user_id)
    assert row["status"] == "pending" and row["direction"] == "incoming"
    b.post(f"/friends/{b.user_id}/{a.user_id}/decision", {"decision": "accept"}).ok()
    for me, other in ((a, b), (b, a)):
        friends = me.get(f"/friends/{me.user_id}").ok()["friends"]
        assert next(f for f in friends if f["friend_user_id"] == other.user_id)["status"] == "accepted"


def test_invalid_source_and_decision_are_rejected(trio):
    a, _, c = trio
    bad_source = a.post(f"/friends/{a.user_id}", {"friend_user_id": c.user_id, "source": "spam"})
    assert bad_source.status == 400, bad_source.text
    bad_decision = c.post(f"/friends/{c.user_id}/{a.user_id}/decision", {"decision": "maybe"})
    assert 400 <= bad_decision.status < 500, bad_decision.text


def test_decline_leaves_no_friendship(trio):
    _, b, c = trio
    c.post(f"/friends/{c.user_id}", {"friend_user_id": b.user_id, "source": "room"}).ok()
    b.post(f"/friends/{b.user_id}/{c.user_id}/decision", {"decision": "decline"}).ok()
    statuses = [f["status"] for f in b.get(f"/friends/{b.user_id}").ok()["friends"]
                if f["friend_user_id"] == c.user_id]
    assert "accepted" not in statuses


def test_cannot_friend_yourself(trio):
    a, _, _ = trio
    response = a.post(f"/friends/{a.user_id}", {"friend_user_id": a.user_id, "source": "search"})
    assert 400 <= response.status < 500, response.text


def test_friend_chat_send_list_unread_read_and_mute(trio):
    a, b, _ = trio
    channel = a.post(f"/social/friends/{b.user_id}/channel").ok()["channel"]
    assert channel["kind"] == "friend" and channel["peer_id"] == b.user_id
    cid = channel["id"]
    msg_id = str(uuid.uuid4())
    sent = a.post(f"/social/channels/{cid}/messages",
                  {"client_message_id": msg_id, "body": "Fancy a walk on Sunday?"}).ok()
    # Retrying with the same client_message_id must not duplicate the message.
    a.post(f"/social/channels/{cid}/messages",
           {"client_message_id": msg_id, "body": "Fancy a walk on Sunday?"}).ok()
    listed = b.get(f"/social/channels/{cid}/messages").ok()["messages"]
    assert [m["body"] for m in listed].count("Fancy a walk on Sunday?") == 1
    assert sent["message"]["sender_id"] == a.user_id

    row = next(c for c in b.get("/social/channels").ok()["channels"] if c["id"] == cid)
    assert row["unread_count"] >= 1 and row["last_message"] == "Fancy a walk on Sunday?"
    b.post(f"/social/channels/{cid}/read", {}).ok()
    row = next(c for c in b.get("/social/channels").ok()["channels"] if c["id"] == cid)
    assert row["unread_count"] == 0

    muted = b.put(f"/social/channels/{cid}/mute", {"duration": "8h"}).ok()
    assert muted["muted"] is True and muted["muted_until"]
    forever = b.put(f"/social/channels/{cid}/mute", {"duration": "forever"}).ok()
    assert forever["muted"] is True
    assert b.put(f"/social/channels/{cid}/mute", {"duration": "3d"}).status == 400
    assert b.delete(f"/social/channels/{cid}/mute").ok()["muted"] is False


def test_message_validation(trio):
    a, b, _ = trio
    cid = a.post(f"/social/friends/{b.user_id}/channel").ok()["channel"]["id"]
    not_uuid = a.post(f"/social/channels/{cid}/messages", {"client_message_id": "x", "body": "hi"})
    assert not_uuid.status == 400
    empty = a.post(f"/social/channels/{cid}/messages",
                   {"client_message_id": str(uuid.uuid4()), "body": "   "})
    assert empty.status == 400, empty.text


def test_non_friend_cannot_open_or_read_friend_chat(trio):
    a, b, c = trio
    cid = a.post(f"/social/friends/{b.user_id}/channel").ok()["channel"]["id"]
    assert c.get(f"/social/channels/{cid}/messages").status in (403, 404)
    assert c.post(f"/social/friends/{a.user_id}/channel").status in (403, 404)


def test_sender_can_delete_own_message(trio):
    a, b, _ = trio
    cid = a.post(f"/social/friends/{b.user_id}/channel").ok()["channel"]["id"]
    message = a.post(f"/social/channels/{cid}/messages",
                     {"client_message_id": str(uuid.uuid4()), "body": "typo msg"}).ok()["message"]
    assert b.delete(f"/social/channels/{cid}/messages/{message['id']}").status in (403, 404)
    a.delete(f"/social/channels/{cid}/messages/{message['id']}").ok()
    bodies = [m.get("body") for m in b.get(f"/social/channels/{cid}/messages").ok()["messages"]
              if m["id"] == message["id"]]
    assert bodies in ([], [""], [None]) or bodies[0] != "typo msg"


def test_remove_friend_closes_the_conversation(make_member):
    a, b = make_member("frx_a", "F", "M"), make_member("frx_b", "M", "F")
    befriend(a, b, source="match")
    cid = a.post(f"/social/friends/{b.user_id}/channel").ok()["channel"]["id"]
    a.delete(f"/friends/{a.user_id}/{b.user_id}").ok()
    assert not [f for f in b.get(f"/friends/{b.user_id}").ok()["friends"]
                if f["friend_user_id"] == a.user_id and f["status"] == "accepted"]
    after = b.post(f"/social/channels/{cid}/messages",
                   {"client_message_id": str(uuid.uuid4()), "body": "still there?"})
    assert after.status in (403, 404), after.text
