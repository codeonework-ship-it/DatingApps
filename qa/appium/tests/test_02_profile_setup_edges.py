from __future__ import annotations

import pytest

from helpers import generated_username


def _type_or_fallback(app, qa_id: str, index: int, value: str) -> None:
    try:
        app.type_into_qa(qa_id, value, timeout=4)
    except Exception:  # noqa: BLE001 - text-index fallback for accessibility drift
        app.type_into_edit_text(index, value)


def _open_signup(app) -> None:
    app.open_welcome_signup()
    app.assert_any_text_visible("Create your account", "Unique username", timeout=20)


def _fill_credentials(
    app,
    *,
    username: str,
    password: str = "AppiumPass123",
    confirmation: str | None = None,
    name: str = "Appium Edge User",
) -> None:
    _type_or_fallback(app, "qa.signup.username_field", 0, username)
    app.set_signup_password_visibility(visible=True)
    _type_or_fallback(
        app,
        "qa.signup.confirm_password_field",
        2,
        password if confirmation is None else confirmation,
    )
    _type_or_fallback(app, "qa.signup.password_field", 1, password)
    app.set_signup_password_visibility(visible=False)
    _type_or_fallback(app, "qa.signup.name_field", 3, name)
    app.hide_keyboard()


def _select_adult_dob(app) -> None:
    if not app.maybe_tap_qa("qa.signup.dob_field", timeout=5):
        app.tap_first_visible_text(["Select date"], timeout=10)
    app.tap_first_visible_text(["OK", "Save"], timeout=10)


def _submit(app) -> None:
    if not app.maybe_tap_qa("qa.signup.create_account_button", timeout=5):
        app.tap_scroll_text("Create account", timeout=10)


def _assert_signup_retained(app) -> None:
    app.assert_any_text_visible("Create your account", "Unique username", timeout=10)
    assert not app.is_authenticated_surface_visible(timeout=2)


@pytest.mark.requires_appium
@pytest.mark.signup_edge
@pytest.mark.negative
def test_signup_validation_blocks_invalid_username(app):
    _open_signup(app)
    _fill_credentials(app, username="ab")
    _select_adult_dob(app)
    _submit(app)

    app.assert_any_text_visible("Username must be 3", timeout=8)
    _assert_signup_retained(app)


@pytest.mark.requires_appium
@pytest.mark.signup_edge
@pytest.mark.negative
def test_signup_validation_blocks_weak_password_and_short_name(app):
    _open_signup(app)
    _fill_credentials(app, username=generated_username(), password="short1", name="A")
    _select_adult_dob(app)
    _submit(app)
    app.assert_any_text_visible("Password must be at least 8", timeout=8)
    _assert_signup_retained(app)


@pytest.mark.requires_appium
@pytest.mark.signup_edge
@pytest.mark.negative
def test_signup_validation_blocks_mismatched_passwords(app):
    _open_signup(app)
    _fill_credentials(
        app,
        username=generated_username(),
        password="AppiumPass123",
        confirmation="DifferentPass123",
    )
    _select_adult_dob(app)
    _submit(app)

    app.assert_any_text_visible("Passwords do not match", timeout=8)
    _assert_signup_retained(app)


@pytest.mark.requires_appium
@pytest.mark.signup_edge
@pytest.mark.negative
def test_signup_validation_blocks_missing_date_of_birth(app):
    _open_signup(app)
    _fill_credentials(app, username=generated_username())
    _submit(app)

    app.assert_any_text_visible("Please select your date of birth", timeout=8)
    _assert_signup_retained(app)


@pytest.mark.requires_appium
@pytest.mark.signup_edge
@pytest.mark.negative
@pytest.mark.security_negative
def test_signup_validation_blocks_duplicate_username(app, appium_config):
    _open_signup(app)
    _fill_credentials(app, username=appium_config.existing_username)
    _select_adult_dob(app)
    _submit(app)

    app.scroll_to_text_contains("already", timeout=20)
    app.assert_any_text_visible(
        "already taken",
        "already exists",
        "already registered",
        "Username is unavailable",
        timeout=20,
    )
    assert not app.is_authenticated_surface_visible(timeout=2)
