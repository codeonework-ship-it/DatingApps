"""Conversation Rooms as live chat rooms (CONVERSATION_ROOMS_LIVE_CHAT_2026-10-01).

List -> join by tapping -> live message -> leave on the device, with a
synthetic counterpart in the same room reading the messages through the chat
engine API. A second spec has the counterpart host a room and mute the device
member, which must close the composer, and unmute, which must reopen it.
"""

from __future__ import annotations

import time
import uuid

import pytest

pytestmark = [pytest.mark.requires_appium, pytest.mark.rooms]

SEEDED_ROOM = "Green flags only"


def _wait_api(predicate, timeout: float = 15, interval: float = 1.0):
    deadline = time.time() + timeout
    value = None
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    return value


def _rooms(member) -> list[dict]:
    return member.api.get("/rooms", query={"limit": 100}).require_status(200).body.get("rooms", [])


def _room(member, room_id: str) -> dict:
    return member.api.get(f"/rooms/{room_id}").require_status(200).body.get("room", {})


def _messages(member, channel_id: str) -> list[str]:
    response = member.api.get(f"/social/channels/{channel_id}/messages").require_status(200)
    return [str(m.get("body") or "") for m in response.body.get("messages", [])]


def _open_rooms(app) -> None:
    app.open_engage_entry("Conversation Rooms")
    app.assert_any_text_visible("LIVE CHAT", timeout=20)
    app.wait_for_text("Find your room", timeout=20)


def _leave_via_api(member, room_id: str) -> None:
    member.api.post(f"/rooms/{room_id}/leave", {})


def test_rooms_list_join_send_and_leave(app, device_member, counterpart_factory):
    room = next(r for r in _rooms(device_member) if r.get("title") == SEEDED_ROOM)
    room_id = room["id"]
    if room.get("is_participant"):
        _leave_via_api(device_member, room_id)
    counterpart_factory.cleanups.append(lambda: _leave_via_api(device_member, room_id))

    listener = counterpart_factory("rl", "Lena Listener")
    joined = listener.api.post(f"/rooms/{room_id}/join", {}).require_status(200, 201).body
    channel_id = joined["channel_id"]
    counterpart_factory.cleanups.append(lambda: _leave_via_api(listener, room_id))

    _open_rooms(app)
    # Every seeded always-on room from the API is offered (spot-check the first ones).
    api_titles = [r["title"] for r in _rooms(device_member) if r.get("always_on")]
    assert SEEDED_ROOM in api_titles
    # "Your rooms" and "Live now" sit above the browse list, so the browse
    # tiles can start below the fold: scroll to each one.
    for title in api_titles[:3]:
        app.scroll_to_text(f"{title}.", timeout=30)

    tile = app.scroll_into_middle(f"{SEEDED_ROOM}.")
    assert "Join." in (tile.get_attribute("content-desc") or ""), tile.get_attribute("content-desc")
    tile.click()

    # Tapping joins and opens the chat.
    app.assert_any_text_visible(SEEDED_ROOM, timeout=20)
    app.wait_for_text_contains("here now", timeout=15)
    assert _wait_api(lambda: _room(device_member, room_id).get("is_participant") is True), _room(device_member, room_id)
    app.save_artifact("rooms_chat_open")

    message = f"Hi room from Android {int(time.time())}"
    app.type_into_hint("Write a message", message)
    app.tap_text("Send")
    app.wait_for_text(message, timeout=15)
    assert _wait_api(lambda: message in _messages(listener, channel_id)), _messages(listener, channel_id)

    # Live: the listener's message arrives in the open chat.
    reply = f"Welcome from Lena {int(time.time())}"
    listener.api.post(
        f"/social/channels/{channel_id}/messages",
        {"body": reply, "client_message_id": str(uuid.uuid4())},
    ).require_status(200, 201)
    app.wait_for_text(reply, timeout=20)

    # People here lists the listener with an Add friend action.
    app.tap_text("People in this room")
    app.wait_for_text("Lena Listener", timeout=15)
    app.wait_for_text("Add friend", timeout=10)
    app.save_artifact("rooms_people_sheet")
    app.dismiss_sheet()

    # Leave from the room menu, confirmed.
    app.tap_text("Room options")
    app.tap_text("Leave room")
    app.wait_for_text(f"Leave {SEEDED_ROOM}?", timeout=10)
    app.tap_text("Leave room")
    assert _wait_api(lambda: _room(device_member, room_id).get("is_participant") is False), _room(device_member, room_id)
    app.wait_for_text("Find your room", timeout=20)


def test_room_host_mute_closes_and_reopens_composer(app, device_member, counterpart_factory):
    host = counterpart_factory("rh", "Hana Host")
    title = f"QA mute room {int(time.time()) % 100000}"
    created = host.api.post(
        "/rooms",
        {"title": title, "description": "Android QA mute check", "category": "talk", "duration_minutes": 30},
    ).require_status(200, 201).body["room"]
    room_id = created["id"]
    counterpart_factory.cleanups.append(
        lambda: host.api.post(
            f"/rooms/{room_id}/moderate",
            {"target_user_id": host.user_id, "action": "close_room", "reason": "QA cleanup"},
        )
    )
    host.api.post(f"/rooms/{room_id}/presence", {"state": "here"})

    _open_rooms(app)
    tile = app.scroll_into_middle(f"{title}.")
    tile.click()
    app.assert_any_text_visible(title, timeout=20)
    assert _wait_api(lambda: _room(device_member, room_id).get("is_participant") is True)
    composer = app.wait_for_field_hint("Write a message", timeout=10)
    assert composer.get_attribute("enabled") == "true"

    host.api.post(
        f"/rooms/{room_id}/moderate",
        {"target_user_id": device_member.user_id, "action": "mute_user", "duration": "1h", "reason": "QA mute check"},
    ).require_status(200, 201)
    app.wait_for_text_contains("You’re muted in this room", timeout=25)
    # The composer is closed: Flutter drops the disabled field from the
    # accessibility tree and the Send button is disabled.
    send = app.driver.find_element(*app.ui_desc("Send"))
    assert send.get_attribute("enabled") == "false", "Send still enabled while muted"
    assert not app.driver.find_elements(*app.ui_class("android.widget.EditText")), "composer still editable"
    app.save_artifact("rooms_muted_composer")
    channel = device_member.api.get(f"/social/channels/{created.get('channel_id') or _room(device_member, room_id)['channel_id']}").body.get("channel", {})
    assert channel.get("read_only") is True, channel

    host.api.post(
        f"/rooms/{room_id}/moderate",
        {"target_user_id": device_member.user_id, "action": "unmute_user", "reason": "QA unmute"},
    ).require_status(200, 201)
    reopened = app.wait_for_field_hint("Write a message", timeout=25)
    assert reopened.get_attribute("enabled") == "true"
    app.wait_for_text_gone("You’re muted in this room", timeout=10)
