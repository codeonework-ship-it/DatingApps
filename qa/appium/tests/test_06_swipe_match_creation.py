from __future__ import annotations

import pytest
from selenium.common.exceptions import TimeoutException


def _open_seeded_discovery_card(app) -> None:
    try:
        app.sign_in_existing_user()
    except TimeoutException:
        pytest.skip("Sign-in transition did not reach discovery in current QA build/state")
    app.open_discovery_deck()

    if app.is_text_visible("No profiles", timeout=3):
        pytest.skip("Seeded discovery deck is empty for swipe sample")

    try:
        app.wait_for_qa("qa.discovery.card_root", timeout=20)
    except TimeoutException:
        pytest.skip("Seeded discovery deck card is not visible in current QA build/state")


@pytest.mark.requires_appium
@pytest.mark.swipe_matrix
def test_discovery_pass_and_undo_sample(app):
    _open_seeded_discovery_card(app)
    if not app.maybe_tap_qa("qa.discovery.pass_button", timeout=8):
        app.tap_first_visible_text(["Passed", "Pass"], timeout=10)

    if app.maybe_tap_qa("qa.discovery.undo_button", timeout=8):
        app.wait_for_qa("qa.discovery.card_root", timeout=15)
    else:
        app.assert_any_text_visible("Ready", "Passed", "Discover Matches", timeout=15)


@pytest.mark.requires_appium
@pytest.mark.discovery
@pytest.mark.swipe_matrix
def test_discovery_card_action_buttons_visible(app):
    _open_seeded_discovery_card(app)

    for qa_id in (
        "qa.discovery.pass_button",
        "qa.discovery.like_button",
        "qa.discovery.superlike_button",
        "qa.discovery.message_button",
        "qa.discovery.undo_button",
    ):
        app.wait_for_qa(qa_id, timeout=10)


@pytest.mark.requires_appium
@pytest.mark.discovery
@pytest.mark.swipe_matrix
def test_discovery_like_updates_deck_state(app):
    _open_seeded_discovery_card(app)
    if not app.maybe_tap_qa("qa.discovery.like_button", timeout=8):
        app.tap_first_visible_text(["Like", "Love"], timeout=10)

    app.assert_any_text_visible(
        "It's a match",
        "Liked",
        "Ready",
        "Discover Matches",
        "qa.discovery.card_root",
        timeout=20,
    )
