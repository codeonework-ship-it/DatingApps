from __future__ import annotations

import pytest


@pytest.mark.requires_appium
@pytest.mark.resilience
def test_background_foreground_preserves_discovery_state(app, driver, appium_config):
    app.sign_in_existing_user()
    app.open_tab("Discover")
    app.assert_any_text_visible("Discover Matches", "Find meaningful verified matches", timeout=25)

    driver.background_app(2)
    driver.activate_app(appium_config.app_package)
    app.assert_any_text_visible("Discover Matches", "Ready", "No profiles", timeout=25)


@pytest.mark.requires_appium
@pytest.mark.resilience
def test_process_death_restores_authenticated_session(app, driver, appium_config):
    app.sign_in_existing_user()
    app.open_tab("Discover")
    app.assert_any_text_visible("Discover Matches", "Find meaningful verified matches", timeout=25)

    assert driver.terminate_app(appium_config.app_package)
    driver.activate_app(appium_config.app_package)

    # Access credentials live only in memory; a cold start must use the stored,
    # rotating refresh credential and return to an authenticated route.
    app.wait_for_authenticated_surface(timeout=35)


@pytest.mark.requires_appium
@pytest.mark.resilience
def test_android_large_font_restart_keeps_primary_navigation_usable(
    app,
    driver,
    appium_config,
):
    app.sign_in_existing_user()
    try:
        driver.execute_script(
            "mobile: shell",
            {"command": "settings", "args": ["put", "system", "font_scale", "1.3"]},
        )
        driver.terminate_app(appium_config.app_package)
        driver.activate_app(appium_config.app_package)
        app.wait_for_authenticated_surface(timeout=35)
        app.open_tab("Matches")
        app.assert_any_text_visible("Matches", "Your Matches", "New matches", timeout=25)
    finally:
        driver.execute_script(
            "mobile: shell",
            {"command": "settings", "args": ["put", "system", "font_scale", "1.0"]},
        )
