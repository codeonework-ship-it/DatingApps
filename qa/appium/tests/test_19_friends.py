"""Friends and friend chat on the Android device (FRIENDS_AND_FRIEND_CHAT_2026-10-01).

The device member (QA_EXISTING_USERNAME) is driven through the UI; synthetic
counterparts created with verify_signup_workflow.sh play the other side via
the API. Persisted state is always asserted through the API, never through
on-screen text alone.
"""

from __future__ import annotations

import time
import uuid

import pytest

from seed_members import friend_status, remove_friend

pytestmark = [pytest.mark.requires_appium, pytest.mark.friends]


def _open_friends(app) -> None:
    app.open_settings_entry("Friends & Connections")
    if not app.is_text_visible("Your people", timeout=8):
        # A tap that landed while the Settings list was still moving only
        # stops the list; tap the real tile once more.
        if app.is_text_visible("Friends & Connections", timeout=2):
            app.tap_text("Friends & Connections")
        app.scroll_to_text("Your people", timeout=20)


def _wait_api(predicate, timeout: float = 15, interval: float = 1.0):
    deadline = time.time() + timeout
    value = None
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    return value


def _channel_messages(member, channel_id: str) -> list[str]:
    response = member.api.get(f"/social/channels/{channel_id}/messages").require_status(200)
    return [str(m.get("body") or "") for m in response.body.get("messages", [])]


@pytest.mark.case("journeys.e2e.friends_social_chat")
def test_friend_search_sends_request_to_counterpart(app, device_member, counterpart_factory):
    other = counterpart_factory("fs", "Cora Searchable")
    counterpart_factory.cleanups.append(lambda: remove_friend(other, device_member.user_id))

    _open_friends(app)
    app.tap_text("Add friend")
    app.assert_any_text_visible("Find someone you know", timeout=10)
    # Keep the keyboard up: system back dismisses the whole sheet.
    app.type_into_hint("Name or @username", other.username)
    app.wait_for_text(f"@{other.username}", timeout=15)
    app.wait_for_text("Cora Searchable", timeout=5)
    app.tap_text("Add friend")
    app.wait_for_text("Requested", timeout=15)
    app.save_artifact("friends_search_requested")

    status = _wait_api(lambda: friend_status(other, device_member.user_id) == "pending:incoming")
    assert status, (
        "Counterpart did not receive the request: "
        f"{friend_status(other, device_member.user_id)!r}"
    )
    row = next(
        r for r in other.api.get(f"/friends/{other.user_id}").body["friends"]
        if r["friend_user_id"] == device_member.user_id
    )
    assert row.get("source") == "search", row

    # The Friends screen lists the outgoing request once the sheet closes.
    app.dismiss_sheet()
    app.assert_any_text_visible("Waiting on others", timeout=10)
    app.wait_for_text("Request sent · Found you by name", timeout=10)


@pytest.mark.case("journeys.e2e.friends_social_chat")
def test_incoming_request_accept_and_friend_chat(app, device_member, counterpart_factory):
    other = counterpart_factory("fc", "Mira Chatwell")
    counterpart_factory.cleanups.append(lambda: remove_friend(other, device_member.user_id))
    app.go_today()
    other.api.post(
        f"/friends/{other.user_id}",
        {"friend_user_id": device_member.user_id, "source": "search"},
    ).require_status(200, 201)

    # The in-app banner for friend_request.received routes to Friends.
    banner = "Mira Chatwell wants to be friends"
    app.wait_for_text_contains(banner, timeout=20)
    app.save_artifact("friends_request_banner")
    app.tap_text("Open")
    # The banner opens the inbox; the inbox row routes friend_request.* to Friends.
    app.assert_any_text_visible("Notifications", timeout=10)
    app.tap_text_contains(banner, timeout=10)
    app.assert_any_text_visible("Your people", timeout=15)
    app.assert_any_text_visible("Waiting on you", timeout=15)
    app.wait_for_text("Mira Chatwell", timeout=10)
    app.wait_for_text("Wants to be friends · Found you by name", timeout=10)
    app.tap_text("Accept")

    assert _wait_api(lambda: friend_status(device_member, other.user_id) == "accepted"), (
        f"Accept did not persist: {friend_status(device_member, other.user_id)!r}"
    )
    assert friend_status(other, device_member.user_id) == "accepted"
    app.wait_for_text(f"@{other.username}", timeout=15)

    # Friend chat: Message opens the shared chat engine conversation.
    app.tap_text("Message Mira Chatwell")
    app.wait_for_text("Mira Chatwell", timeout=15)
    message = f"Hello from Android {int(time.time())}"
    app.type_into_hint("Write a message", message)
    app.tap_text("Send")
    app.wait_for_text(message, timeout=15)

    channel = other.api.post(f"/social/friends/{device_member.user_id}/channel", {}).require_status(200)
    channel_id = channel.body["channel"]["id"]
    assert _wait_api(lambda: message in _channel_messages(other, channel_id)), (
        f"Sent message not stored: {_channel_messages(other, channel_id)}"
    )

    # A reply from the counterpart reaches the open chat.
    reply = f"Reply from Mira {int(time.time())}"
    other.api.post(
        f"/social/channels/{channel_id}/messages",
        {"body": reply, "client_message_id": str(uuid.uuid4())},
    ).require_status(200, 201)
    app.wait_for_text(reply, timeout=20)
    app.save_artifact("friends_chat_reply")

    # Notification mute from the bell, verified on the channel for the device member.
    app.tap_text("Mute notifications")
    app.tap_text("For 8 hours")
    muted = _wait_api(
        lambda: device_member.api.get(f"/social/channels/{channel_id}").body.get("channel", {}).get("muted")
    )
    assert muted is True, device_member.api.get(f"/social/channels/{channel_id}").raw[:500]
    app.tap_text("Notifications muted")
    app.tap_text("Turn notifications back on")
    unmuted = _wait_api(
        lambda: device_member.api.get(f"/social/channels/{channel_id}").body.get("channel", {}).get("muted") is False
    )
    assert unmuted, device_member.api.get(f"/social/channels/{channel_id}").raw[:500]


def test_remove_friend_from_menu(app, device_member, counterpart_factory):
    other = counterpart_factory("fr", "Remy Removable")
    counterpart_factory.cleanups.append(lambda: remove_friend(other, device_member.user_id))
    other.api.post(f"/friends/{other.user_id}", {"friend_user_id": device_member.user_id}).require_status(200, 201)
    device_member.api.post(
        f"/friends/{device_member.user_id}/{other.user_id}/decision", {"decision": "accept"}
    ).require_status(200, 201)

    _open_friends(app)
    app.scroll_to_text(f"@{other.username}", timeout=20)
    app.tap_text("More for Remy Removable")
    app.tap_text("Remove friend")
    # Removal is confirmed before it happens.
    app.wait_for_text("Remove Remy Removable?", timeout=10)
    assert friend_status(device_member, other.user_id) == "accepted", "removed before confirming"
    app.tap_text("Remove friend")
    assert _wait_api(lambda: friend_status(device_member, other.user_id) == "none"), (
        f"Friend not removed: {friend_status(device_member, other.user_id)!r}"
    )
    app.wait_for_text_gone(f"@{other.username}", timeout=15)
