from __future__ import annotations

import pytest


@pytest.mark.requires_appium
@pytest.mark.signin
@pytest.mark.smoke
def test_existing_account_username_signin_reaches_authenticated_surface(app, appium_config):
    app.open_welcome_signin()
    app.assert_any_text_visible("Sign in", "Account credentials", timeout=15)

    try:
        app.type_into_qa(
            "qa.signin.username_field", appium_config.existing_username, timeout=4
        )
        app.type_into_qa(
            "qa.signin.password_field", appium_config.existing_password, timeout=4
        )
    except Exception:  # noqa: BLE001 - text-index fallback
        app.type_into_edit_text(0, appium_config.existing_username)
        app.type_into_edit_text(1, appium_config.existing_password)
    app.hide_keyboard()

    if not app.maybe_tap_qa("qa.signin.login_button", timeout=4):
        app.tap_first_visible_text(["Sign in"], timeout=10)

    app.accept_terms_if_present(timeout=10)
    app.wait_for_authenticated_surface(timeout=appium_config.long_timeout)
