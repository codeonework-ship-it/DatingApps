"""Android system back across the signed-in shell.

Spec (main_navigation_screen.dart, CINEMATIC_EFFECTS_AND_THEMES_2026-10-01):
back on Matches, Engage, Profile or Settings returns to Today instead of
closing the app; screens pushed on top pop first; back on Today leaves the
app as usual (the activity goes to the background, the session survives).
"""

from __future__ import annotations

import time

import pytest

pytestmark = [pytest.mark.requires_appium, pytest.mark.back_navigation]


@pytest.mark.parametrize("tab", ["Matches", "Engage", "Profile", "Settings"])
@pytest.mark.case("journeys.e2e.back_navigation")
def test_system_back_from_tab_returns_to_today(app, tab):
    app.go_today()
    app.open_tab(tab)
    app.wait_for_tab(tab)
    app.press_back()
    app.wait_for_tab("today")
    assert app.app_state() == 4, "back on a secondary tab must not leave the app"
    app.wait_for_text_contains("TODAY", timeout=10)


@pytest.mark.case("journeys.e2e.back_navigation")
def test_back_pops_pushed_screen_before_switching_tab(app):
    app.open_settings_entry("Privacy & Safety")
    app.wait_for_text("Share crash reports", timeout=20)
    app.press_back()
    app.wait_for_tab("settings")
    app.press_back()
    app.wait_for_tab("today")


def test_back_on_today_leaves_app_and_session_survives(app, appium_config):
    app.go_today()
    app.press_back(settle=2)
    state = app.app_state()
    assert state in (2, 3), f"back on Today should leave the app (background), app state={state}"
    app.driver.activate_app(appium_config.app_package)
    time.sleep(4)
    # Still signed in: the shell comes back, no welcome screen.
    deadline = time.time() + 30
    while time.time() < deadline and app.selected_tab() is None:
        time.sleep(1)
    assert app.selected_tab() is not None, "the signed-in shell did not come back after relaunch"
    assert not app.is_text_visible("Already a member?", timeout=2)
    app.go_today()


# Settings entries that push a screen, each with text only that screen shows.
_PUSHED_FROM_SETTINGS = [
    ("Language", "Pick the language Connect uses"),
    ("Account & Data", "Take a break"),
    ("Privacy & Safety", "Share crash reports"),
    ("Friends & Connections", "Your people"),
    ("Call History", "Call history"),
    ("Government Verification", "Verify with confidence"),
]


@pytest.mark.case("journeys.e2e.back_navigation")
@pytest.mark.parametrize("entry,marker", _PUSHED_FROM_SETTINGS, ids=[e for e, _ in _PUSHED_FROM_SETTINGS])
def test_pushed_screen_on_screen_back_and_system_back_return_to_settings(app, entry, marker):
    """Each pushed screen shows a way back that returns to its opener, and
    Android back does the same."""
    # On-screen back (the AppBar / gold back control, spoken as "Back").
    app.open_settings_entry(entry)
    app.wait_for_text(marker, timeout=20)
    assert app.selected_tab() is None, f"{entry} should be pushed over the shell"
    app.tap_text("Back", timeout=10)
    app.wait_for_tab("settings")
    app.wait_for_text_gone(marker, timeout=10)
    assert app.app_state() == 4

    # Android system back.
    app.scroll_into_middle(entry)
    app.tap_text(entry)
    app.wait_for_text(marker, timeout=20)
    app.press_back()
    app.wait_for_tab("settings")
    app.wait_for_text_gone(marker, timeout=10)
    assert app.app_state() == 4
