from __future__ import annotations

import time

import pytest

from api_client import extract_items, first_id


def _first_match(api_client, qa_user_id: str) -> dict:
    """Return the first match as the API reports it.

    The counterparty name comes from here rather than a hardcoded list, so the
    suite follows whatever the database actually holds.
    """
    response = api_client.get(f"/matches/{qa_user_id}").require_status(200)
    matches = extract_items(response.body, "matches")
    assert matches, f"No seeded match found: {response.body}"
    return matches[0]


def _first_match_id(api_client, qa_user_id: str) -> str:
    match = _first_match(api_client, qa_user_id)
    match_id = first_id([match], "match_id", "id")
    assert match_id, f"Match has no id: {match}"
    return str(match_id)


def _first_unlocked_match(api_client, qa_user_id: str) -> dict:
    matches = extract_items(api_client.get(f"/matches/{qa_user_id}").require_status(200).body, "matches")
    for match in matches:
        match_id = first_id([match], "match_id", "id")
        if match_id and _chat_is_unlocked(api_client, match_id)[0]:
            return match
    raise AssertionError("Chat persistence requires a synthetic match with an approved quest")


def _match_display_name(match: dict) -> str | None:
    for key in ("userName", "user_name", "name", "display_name"):
        value = match.get(key)
        if value and str(value).strip() and str(value) != "<nil>":
            return str(value).strip()
    return None


UNLOCKED_STATE = "conversation_unlocked"


def _chat_is_unlocked(api_client, match_id: str) -> tuple[bool, str]:
    """Ask the backend whether this match may exchange messages yet.

    `GET /matches/{id}/unlock-state` is the authoritative read-only answer: it
    calls the same `isChatUnlocked` gate the send endpoint uses. The coarse
    `unlock_state` on the matches list disagrees with it (it reports "matched"
    where the gate computes "quest_pending"), so the list must not be used for
    this decision.
    """
    body = (
        api_client.get(f"/matches/{match_id}/unlock-state")
        .require_status(200)
        .body
    )
    body = body if isinstance(body, dict) else {}
    return bool(body.get("chat_unlocked")), str(body.get("unlock_state") or "unknown")


def _message_exists(api_client, match_id: str, message_text: str) -> bool:
    response = api_client.get(
        f"/chat/{match_id}/messages",
        query={"limit": 50},
    ).require_status(200, 423)
    if response.status == 423:
        return False
    messages = extract_items(response.body, "messages", "items", "data")
    return any(
        message_text in str(item.get("content") or item.get("message") or item.get("text") or "")
        for item in messages
    )


def _open_first_chat(app, match_name: str | None = None, match_id: str | None = None) -> None:
    """Open a match's chat from Matches → Conversations.

    With intentional dating on, the Matches tab opens on its "Discover" view
    (the swipe deck) and remembers the last view, so the Conversations chip
    is picked explicitly. Rows there carry `qa.matches.match_row.<id>`; the
    display name from the API is the fallback.
    """
    app.open_matches_view("Conversations")
    opened = False
    if match_id:
        locator = f"qa.matches.match_row.{match_id}"
        if not app.is_qa_visible(locator, timeout=5):
            # A match created moments ago: pull to refresh the list once.
            size = app.driver.get_window_size()
            x = size["width"] // 2
            app.driver.swipe(x, int(size["height"] * 0.35), x, int(size["height"] * 0.8), 600)
            time.sleep(2)
        try:
            app.scroll_to_text(locator, timeout=20)
            app.tap_qa(locator, timeout=5)
            opened = True
        except Exception:  # noqa: BLE001 - fall back to the visible name
            opened = False
    if not opened and match_name:
        opened = app.maybe_tap_contains(match_name, timeout=5)
    assert opened, f"Could not open the chat row for match {match_id or match_name!r}"
    app.assert_any_text_visible("Write a message…", "qa.chat.composer", "qa.chat.locked_banner", timeout=20)


def _send_from_composer(app, text: str) -> None:
    app.type_into_qa("qa.chat.composer", text, timeout=8)
    app.hide_keyboard()
    if not app.maybe_tap_qa("qa.chat.send_button", timeout=3):
        app.tap_first_visible_text(["Send message"], timeout=10)


@pytest.mark.requires_appium
@pytest.mark.matches
@pytest.mark.chat
@pytest.mark.smoke
def test_matches_and_chat_message(app, appium_config, api_client, qa_user_id):
    """Open the first match and exercise whichever chat contract applies.

    Chat is gated: under the `require_quest_template` unlock policy a match
    cannot exchange messages until a quest has been submitted *and approved by
    the counterparty*. This test used to assume an open composer and assert the
    typed message appeared, which the product legitimately refuses — it was
    asserting a state the backend never grants.

    The branch is decided by the backend rather than guessed, so the test
    covers the real behaviour in either configuration.
    """
    match = _first_match(api_client, qa_user_id)
    match_id = _first_match_id(api_client, qa_user_id)
    unlocked, unlock_state = _chat_is_unlocked(api_client, match_id)

    _open_first_chat(app, _match_display_name(match), match_id)

    if not unlocked:
        # Locked contract: the banner explains the gate and nothing is stored.
        app.wait_for_qa("qa.chat.locked_banner", timeout=15)
        app.assert_any_text_visible(
            "Complete and get quest approval to unlock chat.",
            "Chat is temporarily locked",
            timeout=10,
        )
        assert not _message_exists(api_client, match_id, appium_config.chat_message), (
            f"chat reports {unlock_state!r} yet a message was stored"
        )
        return

    _send_from_composer(app, appium_config.chat_message)
    app.assert_any_text_visible(appium_config.chat_message, timeout=20)
    assert _message_exists(api_client, match_id, appium_config.chat_message)


@pytest.mark.requires_appium
@pytest.mark.matches
@pytest.mark.chat
@pytest.mark.negative
def test_chat_empty_message_is_blocked(app, api_client, qa_user_id):
    match = _first_unlocked_match(api_client, qa_user_id)
    match_id = str(first_id([match], "match_id", "id"))
    _open_first_chat(app, _match_display_name(match), match_id)

    composer = app.wait_for_field_hint("Write a message…", timeout=15)
    assert (composer.get_attribute("text") or "") in ("", "Write a message…"), "composer is not empty"
    before = extract_items(api_client.get(f"/chat/{match_id}/messages").require_status(200).body, "messages")
    # Send is disabled while the composer is blank (chat_chrome.dart canSend).
    # Tap its bounds anyway and verify the durable outcome.
    send = app.wait_for_text("Send message", timeout=10)
    assert (send.get_attribute("enabled") or "").lower() == "false", "Send must be disabled for an empty composer"
    app._shell_tap_element_center(send)
    time.sleep(0.8)
    after = extract_items(api_client.get(f"/chat/{match_id}/messages").require_status(200).body, "messages")
    assert [item.get("id") for item in after] == [item.get("id") for item in before], (
        "Tapping Send with an empty composer must not persist a message"
    )


@pytest.fixture
def fresh_match(api_client, qa_user_id, counterpart_factory):
    """A brand-new mutual match for the device member, removed afterwards.

    Chat is open by default (`DEFAULT_UNLOCK_POLICY_VARIANT=allow_without_template`),
    so a fresh match needs no quest: the first message must go through.
    """
    name = f"Fresh {int(time.time()) % 100000}"
    other = counterpart_factory("fm", name)
    api_client.post("/swipe", {"user_id": qa_user_id, "target_user_id": other.user_id, "is_like": True}).require_status(200, 201)
    second = other.api.post(
        "/swipe", {"user_id": other.user_id, "target_user_id": qa_user_id, "is_like": True}
    ).require_status(200, 201).body
    match_id = str(second.get("match_id") or "")
    assert second.get("mutual_match") is True and match_id, f"mutual like did not create a match: {second}"
    counterpart_factory.cleanups.append(
        lambda: api_client.request("DELETE", f"/matches/{match_id}", query={"user_id": qa_user_id})
    )
    return {"id": match_id, "name": name, "member": other}


@pytest.mark.requires_appium
@pytest.mark.matches
@pytest.mark.chat
@pytest.mark.chat_matrix
def test_chat_message_persists_after_reopen(app, api_client, fresh_match):
    match_id = fresh_match["id"]
    unlocked, state = _chat_is_unlocked(api_client, match_id)
    assert unlocked, f"a fresh match must be open for chat by default, got {state!r}"
    before = extract_items(api_client.get(f"/chat/{match_id}/messages").require_status(200).body, "messages")
    assert not before, f"a fresh match should have no messages yet: {before}"
    message = f"Appium first hello {int(time.time())}"

    _open_first_chat(app, fresh_match["name"], match_id)
    _send_from_composer(app, message)
    app.assert_any_text_visible(message, timeout=20)
    assert _message_exists(api_client, match_id, message)
    # The counterpart receives it too.
    assert _message_exists(fresh_match["member"].api, match_id, message)

    app.driver.back()
    app.wait_for_tab("matches")
    _open_first_chat(app, fresh_match["name"], match_id)
    app.assert_any_text_visible(message, timeout=20)
    app.save_artifact("chat_first_message_fresh_match")
    app.driver.back()
