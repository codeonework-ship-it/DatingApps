from __future__ import annotations

import pytest


def _type_or_fallback(app, qa_id: str, index: int, value: str) -> None:
    try:
        app.type_into_qa(qa_id, value, timeout=4)
    except Exception:  # noqa: BLE001 - keep text/index fallback for older APKs
        app.type_into_edit_text(index, value)


def _tap_or_fallback(app, qa_id: str, text_candidates: list[str], timeout: int = 10) -> None:
    if app.maybe_tap_qa(qa_id, timeout=4):
        return
    app.tap_scroll_text(text_candidates[0], timeout=timeout)


@pytest.mark.requires_appium
@pytest.mark.signup
@pytest.mark.profile_setup
@pytest.mark.smoke
def test_username_signup_reaches_profile_setup(app, appium_config):
    app.open_welcome_signup()
    app.assert_any_text_visible("Create your account", "Unique username", timeout=15)

    _type_or_fallback(app, "qa.signup.username_field", 0, appium_config.signup_username)
    app.set_signup_password_visibility(visible=True)
    _type_or_fallback(
        app, "qa.signup.confirm_password_field", 2, appium_config.signup_password
    )
    _type_or_fallback(app, "qa.signup.password_field", 1, appium_config.signup_password)
    app.set_signup_password_visibility(visible=False)
    _type_or_fallback(app, "qa.signup.name_field", 3, appium_config.signup_name)
    app.hide_keyboard()

    _tap_or_fallback(app, "qa.signup.dob_field", ["Select date"])
    app.tap_first_visible_text(["OK", "Save"], timeout=10)
    gender_key = f"qa.signup.gender_{appium_config.signup_gender.lower()}"
    _tap_or_fallback(app, gender_key, [appium_config.signup_gender])

    _tap_or_fallback(
        app,
        "qa.signup.create_account_button",
        ["Create account"],
        timeout=10,
    )

    app.accept_terms_if_present(timeout=15)

    app.assert_any_text_visible("Add your photos", "Step 2 of 4", timeout=45)
