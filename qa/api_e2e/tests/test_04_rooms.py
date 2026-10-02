"""Conversation Rooms: list, create, join, live chat, host moderation, leave."""

from __future__ import annotations

import uuid

import pytest


pytestmark = pytest.mark.journey("rooms")


@pytest.fixture(scope="module")
def people(make_member):
    return make_member("rm_host", "F", "M"), make_member("rm_guest", "M", "F"), \
        make_member("rm_out", "F", "M")


@pytest.fixture(scope="module")
def room(people):
    host, _, _ = people
    created = host.post("/rooms", {"title": "E2E sunset walkers",
                                   "description": "Evening walks and the people we meet",
                                   "category": "active", "duration_minutes": 60,
                                   "capacity": 10})
    assert created.status == 201, created.text
    return created["room"]


def _send(member, channel_id, body):
    return member.post(f"/social/channels/{channel_id}/messages",
                       {"client_message_id": str(uuid.uuid4()), "body": body})


def test_room_directory_lists_categories_and_rooms(people):
    host, _, _ = people
    directory = host.get("/rooms").ok()
    assert {c["key"] for c in directory["categories"]} >= {"talk", "interests", "active", "city"}
    assert directory["count"] == len(directory["rooms"]) and directory["count"] > 0


def test_created_room_makes_creator_host(room):
    assert room["is_host"] is True and room["my_role"] == "host" and room["can_moderate"]
    assert room["lifecycle_state"] == "active" and room["participant_count"] == 1


def test_room_creation_validation(people):
    host, _, _ = people
    bad_category = host.post("/rooms", {"title": "x room", "category": "nightclub",
                                        "duration_minutes": 60})
    assert bad_category.status == 400, bad_category.text
    bad_time = host.post("/rooms", {"title": "Timed room", "category": "talk",
                                    "starts_at": "tomorrow"})
    assert bad_time.status == 400, bad_time.text


def test_join_chat_and_members(room, people):
    host, guest, _ = people
    joined = guest.post(f"/rooms/{room['id']}/join", {"user_id": guest.user_id}).ok()
    assert joined["joined"] is True and joined["channel_id"]
    channel = joined["channel_id"]
    _send(guest, channel, "Hello room!").ok()
    _send(host, channel, "Welcome!").ok()
    bodies = [m["body"] for m in host.get(f"/social/channels/{channel}/messages").ok()["messages"]]
    assert {"Hello room!", "Welcome!"} <= set(bodies)
    members = host.get(f"/rooms/{room['id']}/members").ok()
    assert {m["user_id"] for m in members["members"]} >= {host.user_id, guest.user_id}
    guest.post(f"/rooms/{room['id']}/presence", {}).ok()


def test_outsider_cannot_read_room_chat(room, people):
    host, _, outsider = people
    channel = host.get(f"/rooms/{room['id']}").ok()["room"]["channel_id"]
    assert outsider.get(f"/social/channels/{channel}/messages").status in (403, 404)
    assert _send(outsider, channel, "sneaky").status in (403, 404)


def test_host_mute_blocks_guest_messages_until_unmuted(room, people):
    host, guest, _ = people
    channel = host.get(f"/rooms/{room['id']}").ok()["room"]["channel_id"]
    host.post(f"/rooms/{room['id']}/moderate", {"target_user_id": guest.user_id,
                                                "action": "mute", "duration_minutes": 10,
                                                "reason": "e2e"}).ok()
    muted = _send(guest, channel, "can you hear me?")
    assert muted.status == 403 and muted["error_code"] == "CHANNEL_READ_ONLY", muted.text
    assert muted["read_only_until"]
    host.post(f"/rooms/{room['id']}/moderate", {"target_user_id": guest.user_id,
                                                "action": "unmute"}).ok()
    _send(guest, channel, "back again").ok()


def test_guest_cannot_moderate(room, people):
    host, guest, _ = people
    denied = guest.post(f"/rooms/{room['id']}/moderate", {"target_user_id": host.user_id,
                                                          "action": "mute",
                                                          "duration_minutes": 10})
    assert denied.status == 403, denied.text


def test_member_can_mute_room_notifications(room, people):
    host, guest, _ = people
    channel = host.get(f"/rooms/{room['id']}").ok()["room"]["channel_id"]
    assert guest.put(f"/social/channels/{channel}/mute", {"duration": "1h"}).ok()["muted"] is True
    assert guest.delete(f"/social/channels/{channel}/mute").ok()["muted"] is False


def test_leave_revokes_chat_access(room, people):
    host, guest, _ = people
    channel = host.get(f"/rooms/{room['id']}").ok()["room"]["channel_id"]
    assert guest.post(f"/rooms/{room['id']}/leave", {"user_id": guest.user_id}).ok()["left"] is True
    assert _send(guest, channel, "after leave").status == 404
    members = {m["user_id"] for m in host.get(f"/rooms/{room['id']}/members").ok()["members"]}
    assert guest.user_id not in members


def test_join_validates_actor(room, people):
    host, guest, _ = people
    spoof = guest.post(f"/rooms/{room['id']}/join", {"user_id": host.user_id})
    assert spoof.status == 403, spoof.text
    assert guest.post(f"/rooms/{uuid.uuid4()}/join", {"user_id": guest.user_id}).status == 404


def test_host_can_remove_a_member(room, people):
    host, _, outsider = people
    outsider.post(f"/rooms/{room['id']}/join", {"user_id": outsider.user_id}).ok()
    host.post(f"/rooms/{room['id']}/moderate", {"target_user_id": outsider.user_id,
                                                "action": "remove", "reason": "e2e"}).ok()
    members = {m["user_id"] for m in host.get(f"/rooms/{room['id']}/members").ok()["members"]}
    assert outsider.user_id not in members
    rejoin = outsider.post(f"/rooms/{room['id']}/join", {"user_id": outsider.user_id})
    assert rejoin.status in (403, 409), f"removed member re-joined: {rejoin.status} {rejoin.text[:200]}"


def test_host_closes_room_and_it_leaves_the_directory(room, people):
    host, guest, _ = people
    host.post(f"/rooms/{room['id']}/moderate", {"action": "close", "reason": "e2e cleanup"}).ok()
    detail = host.get(f"/rooms/{room['id']}").ok()["room"]
    assert detail["lifecycle_state"] == "closed"
    assert room["id"] not in [r["id"] for r in guest.get("/rooms").ok()["rooms"]]
    assert guest.post(f"/rooms/{room['id']}/join", {"user_id": guest.user_id}).status in (403, 404, 409)
