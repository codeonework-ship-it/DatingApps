"""Notifications produced by social journeys (friends, groups) and read/dismiss handling."""

from __future__ import annotations

import pytest

from client import wait_for
from journeys import befriend


pytestmark = pytest.mark.journey("notifications")


def _events(member):
    body = member.get(f"/notifications/{member.user_id}", params={"limit": 50}).ok().body
    return body.get("notifications", [])


def test_friend_and_group_invite_notifications(make_member):
    a, b = make_member("nt_a", "F", "M"), make_member("nt_b", "M", "F")
    befriend(a, b)
    group = a.post("/engagement/groups", {"kind": "private", "name": "E2E notify group",
                                          "invitee_user_ids": [b.user_id]}).ok()
    try:
        got_b = wait_for(lambda: {"friend_request.received", "group.invite.received"}
                         <= {n["event_type"] for n in _events(b)})
        assert got_b, [n["event_type"] for n in _events(b)]
        got_a = wait_for(lambda: "friend_request.accepted" in {n["event_type"] for n in _events(a)})
        assert got_a, [n["event_type"] for n in _events(a)]
        for n in _events(b):
            assert n["title"] and n["action_route"], n
    finally:
        a.delete(f"/engagement/groups/{group['group']['id']}")


def test_mark_one_read_and_dismiss(make_member):
    a, b = make_member("nt_c", "F", "M"), make_member("nt_d", "M", "F")
    befriend(a, b)
    note = wait_for(lambda: next((n for n in _events(b) if n["event_type"] == "friend_request.received"), None))
    assert note, "no friend request notification"
    before = b.get(f"/notifications/{b.user_id}/unread-count").ok()["unread_count"]
    b.post(f"/notifications/{b.user_id}/{note['id']}/read").ok()
    after = b.get(f"/notifications/{b.user_id}/unread-count").ok()["unread_count"]
    assert after == before - 1
    b.delete(f"/notifications/{b.user_id}/{note['id']}").ok()
    assert note["id"] not in [n["id"] for n in _events(b)]


def test_notification_preference_mutes_category(make_member):
    """Turning off likes stops new like notifications being listed as unread pushes."""
    a, b = make_member("nt_e", "F", "M"), make_member("nt_f", "M", "F")
    prefs = f"/notifications/{b.user_id}/preferences"
    b.patch(prefs, {"notify_likes": False}).ok()
    try:
        a.post("/swipe", {"user_id": a.user_id, "target_user_id": b.user_id, "is_like": True}).ok()
        # The in-app inbox may still record the event; it must not be an unread alert.
        likes = wait_for(lambda: [n for n in _events(b) if n["event_type"] == "like.received"], timeout=3)
        assert not [n for n in (likes or []) if not n["is_read"]], likes
    finally:
        b.patch(prefs, {"notify_likes": True}).ok()
