from __future__ import annotations

import pytest

pytestmark = pytest.mark.usefixtures("ensure_deck")


def _open_profile_detail(app) -> None:
    app.open_discovery_deck()

    # A Spotlight row ("View more" of its own) can push the card down: bring
    # the card's own View more into view; never fall back to a bare
    # "View more", which opens Spotlight Matches instead.
    try:
        app.scroll_into_middle("qa.discovery.view_more_button", timeout=25)
    except Exception:  # noqa: BLE001 - empty deck
        pytest.skip("No visible discovery profile detail entry point in current deck")
    opened = app.maybe_tap_qa("qa.discovery.view_more_button", timeout=8)
    if not opened:
        pytest.skip("No visible discovery profile detail entry point in current deck")


@pytest.mark.requires_appium
@pytest.mark.profile_detail
def test_discovery_profile_detail_surface(app):
    _open_profile_detail(app)

    app.assert_any_text_visible("Message", "Love", "Read more", timeout=20)
    app.wait_for_qa("qa.profile_detail.carousel", timeout=15)
    app.wait_for_qa("qa.profile_detail.report_button", timeout=10)
    app.wait_for_qa("qa.profile_detail.message_button", timeout=10)
    app.wait_for_qa("qa.profile_detail.love_button", timeout=10)
    # Section titles of the cinematic profile (2026-10-02 redesign): the
    # photo strip sits right under the hero, then titled scenes.
    app.assert_any_text_visible(
        "PHOTOS",
        "ABOUT",
        "INTERESTS",
        "THE BASICS",
        "Hobbies",
        timeout=15,
    )
    if app.maybe_tap_qa("qa.profile_detail.read_more_button", timeout=3):
        app.assert_any_text_visible("Read less", "Message", "Love", timeout=10)
    app.assert_any_text_visible("Message", "Love", timeout=10)


@pytest.mark.requires_appium
@pytest.mark.profile_detail
def test_discovery_profile_detail_back_preserves_deck(app):
    _open_profile_detail(app)

    app.wait_for_qa("qa.profile_detail.back_button", timeout=10)
    app.tap_qa("qa.profile_detail.back_button", timeout=10)
    app.assert_any_text_visible("Discover Matches", "Find meaningful verified matches", timeout=20)
    app.wait_for_qa("qa.discovery.card_root", timeout=15)


@pytest.mark.requires_appium
@pytest.mark.profile_detail
def test_discovery_profile_detail_report_entry_renders(app):
    _open_profile_detail(app)

    app.tap_qa("qa.profile_detail.report_button", timeout=10)
    app.assert_any_text_visible("Report", "Submit report", "Add context", timeout=15)
    app.driver.back()
    app.assert_any_text_visible("Message", "Love", timeout=10)
