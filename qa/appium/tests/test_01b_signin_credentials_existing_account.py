from __future__ import annotations

import pytest


@pytest.mark.requires_appium
@pytest.mark.signin
@pytest.mark.smoke
@pytest.mark.case("journeys.e2e.signin_existing")
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


def _type_credentials(app, username: str, password: str) -> None:
    # Visible mode so UiAutomator2's secure-field replacement is not lost.
    app.maybe_tap("Show password", timeout=2)
    try:
        app.type_into_qa("qa.signin.username_field", username, timeout=4)
        app.type_into_qa("qa.signin.password_field", password, timeout=4)
    except Exception:  # noqa: BLE001 - text-index fallback
        app.type_into_edit_text(0, username)
        app.type_into_edit_text(1, password)
    app.hide_keyboard()


@pytest.mark.requires_appium
@pytest.mark.signin
@pytest.mark.case("journeys.e2e.signin_existing")
def test_wrong_password_shows_error_then_correct_password_signs_in(app, appium_config):
    """A wrong password is refused with the member-facing reason and keeps the
    member on sign-in; the right one then lands on the signed-in shell."""
    app.open_welcome_signin()
    app.assert_any_text_visible("Sign in", "Account credentials", timeout=15)

    _type_credentials(app, appium_config.existing_username, appium_config.existing_password + "-wrong")
    if not app.maybe_tap_qa("qa.signin.login_button", timeout=4):
        app.tap_first_visible_text(["Sign in"], timeout=10)
    app.wait_for_text("Invalid username or password.", timeout=30)
    assert not app.is_authenticated_surface_visible(timeout=3), "a wrong password must not sign in"
    app.wait_for_qa("qa.signin.username_field", timeout=5)
    app.save_artifact("signin_wrong_password")

    _type_credentials(app, appium_config.existing_username, appium_config.existing_password)
    if not app.maybe_tap_qa("qa.signin.login_button", timeout=4):
        app.tap_first_visible_text(["Sign in"], timeout=10)
    app.accept_terms_if_present(timeout=10)
    app.wait_for_authenticated_surface(timeout=appium_config.long_timeout)
