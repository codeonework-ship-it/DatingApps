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
def test_system_back_from_tab_returns_to_today(app, tab):
    app.go_today()
    app.open_tab(tab)
    app.wait_for_tab(tab)
    app.press_back()
    app.wait_for_tab("today")
    assert app.app_state() == 4, "back on a secondary tab must not leave the app"
    app.wait_for_text_contains("TODAY", timeout=10)


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
