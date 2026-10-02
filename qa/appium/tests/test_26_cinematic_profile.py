"""Cinematic profile (profile_view_screen.dart / profile_details_screen.dart, 2026-10-02).

Own profile (Profile tab): "STARRING" hero with the member's name, the owner
console "THIS IS HOW YOU APPEAR" with completeness and four tools (Edit
profile, Edit photos, Your stories, Who viewed you) that each push a screen
and return. Another member's profile: "INTRODUCING" hero, the floating
Message / Love dock, Report and Add friend in the top bar, and Android BACK
returns to where it was opened from. Both screens must open at the top.
"""

from __future__ import annotations

import time

import pytest

pytestmark = [pytest.mark.requires_appium, pytest.mark.profile_detail]

TOOLS = (
    ("Edit profile", "Edit Profile"),
    ("Edit photos", "Your photos"),
    ("Your stories", "A little more you"),
    ("Who viewed you", "Viewed My Profile"),
)


def _own_name(device_member) -> str:
    body = device_member.api.get(f"/profile/{device_member.user_id}/draft").require_status(200).body
    draft = body.get("draft", body) if isinstance(body, dict) else {}
    return str(draft.get("name") or "").strip()


def _assert_at_top(app, eyebrow: str) -> None:
    """The hero eyebrow is on screen in the upper part: the page opened at the top."""
    element = app.wait_for_text(eyebrow, timeout=20)
    rect = element.rect
    height = app.driver.get_window_size()["height"]
    assert rect["y"] < height * 0.75, f"{eyebrow} at y={rect['y']}: the screen did not open at the top"


def _open_own_profile(app) -> None:
    app.sign_in_existing_user()
    app.go_today()
    app.open_tab("Profile")
    app.wait_for_tab("profile")


def _scroll_to_top(app) -> None:
    """The Profile tab keeps its scroll offset between visits (AND-11)."""
    size = app.driver.get_window_size()
    x = size["width"] // 2
    for _ in range(10):
        if app.is_text_visible("STARRING", timeout=1):
            return
        app.driver.swipe(x, int(size["height"] * 0.3), x, int(size["height"] * 0.85), 300)
    time.sleep(1)


def test_own_profile_hero_console_and_tools(app, device_member):
    name = _own_name(device_member)
    _open_own_profile(app)
    _scroll_to_top(app)
    _assert_at_top(app, "STARRING")
    if name:
        app.wait_for_text_contains(name, timeout=10)
    app.save_artifact("profile_own_hero")

    app.scroll_into_middle("THIS IS HOW YOU APPEAR")
    app.wait_for_text("Members see your profile just like this.", timeout=10)
    app.wait_for_text_contains("% complete", timeout=10)
    app.save_artifact("profile_own_console")

    for tool, destination in TOOLS:
        app.scroll_into_middle(tool)
        app.tap_text(tool)
        app.wait_for_text_contains(destination, timeout=20)
        app.press_back()
        app.wait_for_tab("profile")
        app.wait_for_text("THIS IS HOW YOU APPEAR", timeout=15)


@pytest.mark.xfail(
    reason="AND-11: the shell keeps every tab alive (IndexedStack), so the Profile tab "
    "re-opens at the scroll offset it was left at, not at the STARRING hero. "
    "Product decision pending; a fresh open and other members' profiles do start at the top.",
    strict=False,
)
def test_own_profile_opens_at_top_on_each_visit(app):
    """Leave Profile scrolled down, switch tabs, come back: record where it opens."""
    _open_own_profile(app)
    _scroll_to_top(app)
    _assert_at_top(app, "STARRING")
    app.scroll_into_middle("YOUR CONNECTIONS")
    app.go_today()
    app.open_tab("Profile")
    app.wait_for_tab("profile")
    time.sleep(1)
    app.save_artifact("profile_own_reentry")
    _assert_at_top(app, "STARRING")


def _open_member_profile(app) -> str:
    """Open another member from Today's introductions, else from the Explore deck.

    Returns where it was opened from: "today" or "deck".
    """
    app.sign_in_existing_user()
    app.go_today()
    try:
        meet = app.scroll_into_middle("Meet ", timeout=40)
        label = meet.get_attribute("content-desc") or meet.get_attribute("text") or ""
        if label.startswith("Meet "):
            meet.click()
            return "today"
    except Exception:  # noqa: BLE001 - no introductions today
        pass
    app.open_discovery_deck()
    if not app.maybe_tap_qa("qa.discovery.view_more_button", timeout=10):
        pytest.skip("No introduction on Today and no profile in the Explore deck")
    return "deck"


def test_member_profile_introducing_dock_report_add_friend_and_back(app):
    origin = _open_member_profile(app)
    _assert_at_top(app, "INTRODUCING")
    app.wait_for_qa("qa.profile_detail.message_button", timeout=15)
    app.wait_for_qa("qa.profile_detail.love_button", timeout=10)
    app.wait_for_text("Message", timeout=5)
    app.wait_for_text("Love", timeout=5)
    app.wait_for_qa("qa.profile_detail.report_button", timeout=10)
    app.assert_any_text_visible("Add friend", "Requested", "Accept friend", "Message", timeout=10)
    assert app.driver.find_elements(*app.ui_desc("Add friend")) or app.driver.find_elements(
        *app.ui_desc("Requested")
    ), "the top bar has no Add friend action"
    app.save_artifact(f"profile_member_from_{origin}")

    # Report opens the report sheet; back closes it and keeps the profile.
    app.tap_qa("qa.profile_detail.report_button", timeout=10)
    app.assert_any_text_visible("Submit report", "Add context", timeout=15)
    app.press_back()
    app.wait_for_text("INTRODUCING", timeout=10)
    # AND-12: dismissing the sheet sends nothing, so nothing may claim it did.
    assert not app.is_text_visible("Report submitted.", timeout=3), (
        "closing the report sheet without submitting showed 'Report submitted.'"
    )

    # Android BACK returns to the previous screen.
    app.press_back()
    if origin == "today":
        app.wait_for_tab("today")
        app.wait_for_text_contains("TODAY", timeout=10)
    else:
        app.wait_for_tab("matches")
        app.assert_any_text_visible(*app.DECK_TITLES, timeout=15)
    assert not app.is_text_visible("INTRODUCING", timeout=2)
    assert app.app_state() == 4


def test_explore_profiles_on_today_opens_the_deck(app):
    """Today's "Explore profiles" / "Explore more profiles" lead to the swipe deck
    (Matches tab, Discover view), even when Matches was last left on Conversations."""
    app.open_matches_view("Conversations")
    app.go_today()
    label = None
    for candidate in ("Explore profiles", "Explore more profiles"):
        try:
            app.scroll_into_middle(candidate, timeout=30)
            label = candidate
            break
        except Exception:  # noqa: BLE001 - try the other wording
            continue
    if label is None:
        pytest.skip("Today shows no Explore entry right now")
    app.tap_text(label)
    app.wait_for_tab("matches")
    time.sleep(1)
    app.save_artifact("today_explore_profiles_target")
    app.assert_any_text_visible(*app.DECK_TITLES, timeout=15)
