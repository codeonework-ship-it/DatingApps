"""Lifestyle groups and group chat (LIFESTYLE_GROUPS_AND_GROUP_CHAT_2026-10-01).

Create a private group from Friends, invite a second friend, a counterpart
accepts through the API, group chat round trip, leave (ownership hand-off);
and report a group the device member was invited to. Every persisted effect
is asserted through the API as the relevant member.
"""

from __future__ import annotations

import subprocess
import time
import uuid

import pytest

from config import CONFIG
from seed_members import friend_status, remove_friend

pytestmark = [pytest.mark.requires_appium, pytest.mark.groups]


def _wait_api(predicate, timeout: float = 15, interval: float = 1.0):
    deadline = time.time() + timeout
    value = None
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    return value


def _befriend_device(device_member, other) -> None:
    other.api.post(f"/friends/{other.user_id}", {"friend_user_id": device_member.user_id}).require_status(200, 201)
    device_member.api.post(
        f"/friends/{device_member.user_id}/{other.user_id}/decision", {"decision": "accept"}
    ).require_status(200, 201)
    assert friend_status(device_member, other.user_id) == "accepted"


def _my_groups(member) -> list[dict]:
    return member.api.get("/engagement/groups", query={"scope": "mine"}).require_status(200).body.get("groups", [])


def _group_named(member, name: str) -> dict | None:
    return next((g for g in _my_groups(member) if g.get("name") == name), None)


def _invites(member) -> list[dict]:
    return member.api.get("/engagement/group-invites").require_status(200).body.get("invites", [])


def _messages(member, channel_id: str) -> list[str]:
    response = member.api.get(f"/social/channels/{channel_id}/messages").require_status(200)
    return [str(m.get("body") or "") for m in response.body.get("messages", [])]


def _device_clock() -> str:
    out = subprocess.run(
        ["adb", "-s", CONFIG.device_name, "shell", "date '+%m-%d %H:%M:%S.000'"],
        capture_output=True, text=True, check=False,
    )
    return out.stdout.strip()


def _app_api_log_since(since: str) -> str:
    out = subprocess.run(
        ["adb", "-s", CONFIG.device_name, "logcat", "-d", "-T", since, "-s", "flutter:I"],
        capture_output=True, text=True, check=False,
    )
    return out.stdout


def _open_friends(app) -> None:
    app.open_settings_entry("Friends & Connections")
    if not app.is_text_visible("Your people", timeout=8):
        # A tap that landed while the Settings list was still moving only
        # stops the list; tap the real tile once more.
        if app.is_text_visible("Friends & Connections", timeout=2):
            app.tap_text("Friends & Connections")
        app.scroll_to_text("Your people", timeout=20)


@pytest.mark.case("journeys.e2e.rooms_groups")
def test_create_group_from_friends_invite_chat_and_leave(app, device_member, counterpart_factory):
    first = counterpart_factory("g1", "Ada Grouper")
    second = counterpart_factory("g2", "Ben Grouper")
    for other in (first, second):
        _befriend_device(device_member, other)
        counterpart_factory.cleanups.append(lambda other=other: remove_friend(other, device_member.user_id))
    name = f"QA Supper Club {int(time.time()) % 100000}"

    def cleanup_group():
        for member in (device_member, first, second):
            group = _group_named(member, name)
            if group:
                member.api.post(f"/engagement/groups/{group['id']}/leave", {})

    counterpart_factory.cleanups.append(cleanup_group)

    _open_friends(app)
    # Wait for the list fetched on open: Create a group offers the friends
    # on screen, so it must not be tapped while an older list is showing.
    app.scroll_to_text(f"@{first.username}", timeout=20)
    app.scroll_to_text(f"@{second.username}", timeout=10)
    app.scroll_to_text("Create a group", timeout=20)
    app.tap_text("Create a group")
    app.wait_for_text("Who’s in?", timeout=10)
    app.tap_text(f"@{first.username}")
    app.tap_text("Create a group with 1")

    # The create flow starts private with Ada preselected.
    app.assert_any_text_visible("Start a group", timeout=15)
    app.wait_for_text("Private group", timeout=10)
    app.type_into_hint("Group name", name)
    app.hide_keyboard()
    app.scroll_into_middle("Create group")
    app.wait_for_snackbar_gone()
    app.tap_text("Create group")

    app.wait_for_text(name, timeout=25)
    created = _wait_api(lambda: _group_named(device_member, name))
    assert created, f"group {name!r} not in the owner's groups"
    assert created["kind"] == "private" and created["my_role"] == "owner", created
    group_id = created["id"]
    assert _wait_api(lambda: any(i.get("group_id") == group_id for i in _invites(first))), _invites(first)
    app.save_artifact("groups_created_detail")

    # Invite the second friend from the detail screen.
    app.scroll_into_middle("Invite friends")
    app.tap_text("Invite friends")
    app.wait_for_text(f"Invite friends to {name}", timeout=10)
    app.scroll_sheet_to_text_or_fail("Ben Grouper")
    app.tap_text("Ben Grouper")
    app.tap_text("Send invitations (1)")
    app.wait_for_text("Invitation sent to Ben Grouper.", timeout=15)
    assert _wait_api(lambda: any(i.get("group_id") == group_id for i in _invites(second))), _invites(second)

    # Ada joins through the API; the device shows the new member count.
    first.api.post(f"/engagement/groups/{group_id}/invites/respond", {"decision": "accept"}).require_status(200)
    detail = device_member.api.get(f"/engagement/groups/{group_id}").require_status(200).body["group"]
    assert detail["member_count"] == 2, detail
    channel_id = detail["channel_id"]

    # Group chat round trip.
    app.scroll_into_middle("Group chat")
    app.tap_text("Group chat")
    message = f"Group hello from Android {int(time.time())}"
    app.type_into_hint("Write a message", message)
    app.tap_text("Send")
    app.wait_for_text(message, timeout=15)
    assert _wait_api(lambda: message in _messages(first, channel_id)), _messages(first, channel_id)
    reply = f"Ada here {int(time.time())}"
    first.api.post(
        f"/social/channels/{channel_id}/messages", {"body": reply, "client_message_id": str(uuid.uuid4())}
    ).require_status(200, 201)
    app.wait_for_text(reply, timeout=20)
    if app.driver.is_keyboard_shown():
        app.hide_keyboard()
    app.press_back()
    app.wait_for_text("Invite friends", timeout=15)

    # Leave: the owner hands the group to Ada.
    app.scroll_into_middle("Leave")
    app.tap_text("Leave")
    app.wait_for_text(f"Leave {name}?", timeout=10)
    app.wait_for_text_contains("Ownership passes", timeout=5)
    app.tap_text("Leave")
    assert _wait_api(lambda: _group_named(device_member, name) is None), _group_named(device_member, name)
    handed = _wait_api(lambda: _group_named(first, name))
    assert handed and handed["my_role"] == "owner", handed


def test_accept_invitation_and_report_group(app, device_member, counterpart_factory):
    owner = counterpart_factory("go", "Olu Owner")
    _befriend_device(device_member, owner)
    counterpart_factory.cleanups.append(lambda: remove_friend(owner, device_member.user_id))
    name = f"QA Reported Group {int(time.time()) % 100000}"
    group = owner.api.post(
        "/engagement/groups",
        {"kind": "private", "name": name, "description": "Android QA report check",
         "invitee_user_ids": [device_member.user_id]},
    ).require_status(200, 201).body["group"]
    group_id = group["id"]
    counterpart_factory.cleanups.append(lambda: device_member.api.post(f"/engagement/groups/{group_id}/leave", {}))
    counterpart_factory.cleanups.append(lambda: owner.api.post(f"/engagement/groups/{group_id}/leave", {}))

    app.open_engage_entry("Lifestyle communities and private friend groups")
    app.assert_any_text_visible("Find your people.", timeout=20)
    app.wait_for_text_contains("Olu Owner invited you", timeout=15)
    app.tap_text(f"Join {name}")
    assert _wait_api(lambda: _group_named(device_member, name)), "invitation accept did not persist"

    app.scroll_into_middle(name)
    app.tap_text(name)
    app.wait_for_text("Group chat", timeout=20)
    since = _device_clock()
    app.tap_text("More options")
    app.tap_text("Report group")
    app.wait_for_text("Report", timeout=10)
    app.tap_text("Submit report")
    app.wait_for_text_gone("Submit report", timeout=15)
    app.wait_for_text("Report submitted. Thank you.", timeout=10)
    app.save_artifact("groups_after_report")

    log = _app_api_log_since(since)
    reported = [
        line for line in log.splitlines()
        if f"/blog/reports/group/{group_id}" in line and '"api_response"' in line
    ]
    assert reported and '"status":200' in reported[-1], f"no successful report request in app log: {reported}"
    # One case per reporter per group: the API returns the existing case.
    again = device_member.api.post(
        f"/blog/reports/group/{group_id}", {"reason": "inappropriate", "description": "QA duplicate check"}
    ).require_status(200)
    assert again.body.get("accepted") is True and again.body.get("report", {}).get("id"), again.raw

    # Leave as a member.
    app.scroll_into_middle("Leave")
    app.tap_text("Leave")
    app.wait_for_text(f"Leave {name}?", timeout=10)
    app.tap_text("Leave")
    assert _wait_api(lambda: _group_named(device_member, name) is None)
