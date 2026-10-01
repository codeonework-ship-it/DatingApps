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


def _open_first_chat(app, match_name: str | None = None) -> None:
    """Open the first match's chat.

    This used to hunt for a fixed list of names — "Seed", "Thane", "Mumbai",
    "Kalyan", "Member" — left over from an older seed set. Against a database
    whose match is called anything else the row is never found, and the test
    fails as though chat were broken. The name is now passed in from the API
    response, with the old list kept only as a fallback.
    """
    app.open_tab("Matches")
    app.assert_any_text_visible("Matches", "Your Matches", "New matches", timeout=25)

    opened = False
    if match_name:
        opened = app.maybe_tap_contains(match_name, timeout=5)
    if not opened:
        for candidate in ["Seed", "Thane", "Mumbai", "Kalyan", "Member"]:
            if app.maybe_tap_contains(candidate, timeout=2):
                opened = True
                break
    if not opened:
        app.tap_first_visible_text(["Chat", "Message", "Open"], timeout=10)

    app.assert_any_text_visible("Chat", "Type a message", "Message", timeout=20)


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

    app.sign_in_existing_user()
    _open_first_chat(app, _match_display_name(match))

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

    app.type_into_first_empty_edit_text(appium_config.chat_message)
    app.hide_keyboard()
    if not app.maybe_tap_qa("qa.chat.send_button", timeout=5):
        app.tap_first_visible_text(["Send", "➤"], timeout=10)
    app.assert_any_text_visible(appium_config.chat_message, "sent", "Delivered", timeout=20)
    assert _message_exists(api_client, match_id, appium_config.chat_message)


@pytest.mark.requires_appium
@pytest.mark.matches
@pytest.mark.chat
@pytest.mark.negative
def test_chat_empty_message_is_blocked(app, api_client, qa_user_id):
    match = _first_unlocked_match(api_client, qa_user_id)
    match_id = str(first_id([match], "match_id", "id"))
    app.sign_in_existing_user()
    _open_first_chat(app, _match_display_name(match))

    fields = app.edit_texts()
    assert fields and all(not field.get_attribute("text") for field in fields)
    before = extract_items(api_client.get(f"/chat/{match_id}/messages").require_status(200).body, "messages")
    # Unlocked chat leaves Send enabled but ignores an empty composer. Verify
    # the durable outcome, independently of the button's visual enabled state.
    app.tap_qa_coordinate("qa.chat.send_button", timeout=10)
    time.sleep(0.5)
    after = extract_items(api_client.get(f"/chat/{match_id}/messages").require_status(200).body, "messages")
    assert [item.get("id") for item in after] == [item.get("id") for item in before], (
        "Tapping Send with an empty composer must not persist a message"
    )


@pytest.mark.requires_appium
@pytest.mark.matches
@pytest.mark.chat
@pytest.mark.chat_matrix
def test_chat_message_persists_after_reopen(app, api_client, qa_user_id):
    match = _first_unlocked_match(api_client, qa_user_id)
    match_id = str(first_id([match], "match_id", "id"))
    match_name = _match_display_name(match)
    message = f"Appium persisted chat {int(time.time())}"

    app.sign_in_existing_user()
    _open_first_chat(app, match_name)
    app.type_into_qa("qa.chat.composer", message, timeout=8)
    app.hide_keyboard()
    if not app.maybe_tap_qa("qa.chat.send_button", timeout=5):
        app.tap_first_visible_text(["Send", "➤"], timeout=10)
    app.assert_any_text_visible(message, "sent", "Delivered", timeout=20)
    assert _message_exists(api_client, match_id, message)

    app.driver.back()
    app.assert_any_text_visible("Matches", "Your Matches", "New matches", timeout=20)
    _open_first_chat(app, match_name)
    app.assert_any_text_visible(message, timeout=20)
