from __future__ import annotations

import binascii
import struct
import uuid
import zlib

import pytest

from helpers import generated_username


def _solid_png(red: int, green: int, blue: int, size: int = 320) -> bytes:
    def chunk(kind: bytes, payload: bytes) -> bytes:
        checksum = binascii.crc32(kind + payload) & 0xFFFFFFFF
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", checksum)

    scanlines = b"".join(b"\x00" + bytes((red, green, blue)) * size for _ in range(size))
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(scanlines))
        + chunk(b"IEND", b"")
    )


_PNG_RED = _solid_png(205, 45, 72)
_PNG_BLUE = _solid_png(49, 120, 198)


def _random_name(prefix: str) -> str:
    return f"{prefix} {uuid.uuid4().hex[:8]}"


def _tap_or_fallback(app, qa_id: str, text_candidates: list[str], timeout: int = 10) -> None:
    if app.maybe_tap_qa(qa_id, timeout=4):
        return
    app.tap_scroll_text(text_candidates[0], timeout=timeout)


def _type_or_fallback(app, qa_id: str, index: int, value: str) -> None:
    try:
        app.type_into_qa(qa_id, value, timeout=4)
    except Exception:  # noqa: BLE001 - text-index fallback for accessibility drift
        app.type_into_edit_text(index, value)


def _signup_to_profile_setup(app, appium_config, name: str = "Appium Setup User") -> None:
    app.open_welcome_signup()
    app.assert_any_text_visible("Create your account", "Unique username", timeout=20)

    _type_or_fallback(app, "qa.signup.username_field", 0, generated_username("setup"))
    app.set_signup_password_visibility(visible=True)
    _type_or_fallback(
        app,
        "qa.signup.confirm_password_field",
        2,
        appium_config.signup_password,
    )
    _type_or_fallback(app, "qa.signup.password_field", 1, appium_config.signup_password)
    app.set_signup_password_visibility(visible=False)
    _type_or_fallback(app, "qa.signup.name_field", 3, name)
    app.hide_keyboard()
    _tap_or_fallback(app, "qa.signup.dob_field", ["Select date"])
    app.tap_first_visible_text(["OK", "Save"], timeout=10)
    _tap_or_fallback(app, "qa.signup.gender_woman", ["Woman"])
    _tap_or_fallback(
        app,
        "qa.signup.create_account_button",
        ["Create account"],
        timeout=10,
    )

    app.accept_terms_if_present(timeout=15)
    app.assert_any_text_visible("Add your photos", "Continue to About", timeout=45)


def _upload_one_gallery_photo(app, filename: str, png_bytes: bytes) -> str:
    app.upload_gallery_png_via_picker(
        trigger_qa_id="qa.setup.photos.gallery_button",
        trigger_texts=["Gallery", "Photos"],
        filename=filename,
        png_bytes=png_bytes,
    )
    return app.assert_any_text_visible(
        "Add your photos",
        "Your photos",
        "Primary",
        "Bio",
        "Tell people about you",
        timeout=45,
    )


@pytest.mark.requires_appium
@pytest.mark.profile_setup
@pytest.mark.profile_setup_edge
def test_profile_setup_signup_lands_on_photo_step(app, appium_config):
    _signup_to_profile_setup(app, appium_config, name=_random_name("Appium Photo Entry"))
    app.assert_any_text_visible("Add your photos", "Choose source", timeout=10)
    app.assert_any_text_visible("Gallery", "Camera", timeout=10)


@pytest.mark.requires_appium
@pytest.mark.profile_setup
@pytest.mark.profile_setup_edge
@pytest.mark.negative
def test_profile_setup_zero_photos_blocks_preferences(app, appium_config):
    _signup_to_profile_setup(app, appium_config, name=_random_name("Appium Photo Gate"))
    if not app.maybe_tap_qa("qa.setup.photos.next_button", timeout=4):
        app.tap_scroll_text("Continue to About", timeout=10)
    app.assert_any_text_visible("Please upload at least", "Add your photos", timeout=10)


@pytest.mark.requires_appium
@pytest.mark.profile_setup
@pytest.mark.profile_setup_edge
def test_profile_setup_photo_step_survives_background_foreground(app, appium_config):
    _signup_to_profile_setup(app, appium_config, name=_random_name("Appium Setup Resume"))
    app.driver.background_app(2)
    app.driver.activate_app(appium_config.app_package)
    app.assert_any_text_visible("Add your photos", "Continue to About", timeout=20)
    app.assert_any_text_visible("Gallery", "Camera", timeout=10)


@pytest.mark.requires_appium
@pytest.mark.profile_setup
@pytest.mark.profile_setup_edge
def test_profile_setup_uploads_gallery_photos_and_continues(app, appium_config):
    _signup_to_profile_setup(app, appium_config, name=_random_name("Appium Gallery User"))
    _upload_one_gallery_photo(app, f"appium_profile_{uuid.uuid4().hex}_1.png", _PNG_RED)
    second_upload_state = _upload_one_gallery_photo(
        app,
        f"appium_profile_{uuid.uuid4().hex}_2.png",
        _PNG_BLUE,
    )
    if second_upload_state != "Bio":
        app.assert_any_text_visible("Primary", "Your photos", "2 /", timeout=20)
        if not app.maybe_tap_qa("qa.setup.photos.next_button", timeout=5):
            app.tap_scroll_text("Continue to About", timeout=10)
    app.assert_any_text_visible("Bio", "Tell people about you", timeout=30)


@pytest.mark.requires_appium
@pytest.mark.signup
@pytest.mark.profile_setup
@pytest.mark.signup_workflow
def test_complete_username_signup_profile_workflow(app, appium_config):
    _signup_to_profile_setup(app, appium_config, name=_random_name("Appium Complete"))
    _upload_one_gallery_photo(
        app,
        f"appium_complete_{uuid.uuid4().hex}_1.png",
        _PNG_RED,
    )
    second_upload_state = _upload_one_gallery_photo(
        app,
        f"appium_complete_{uuid.uuid4().hex}_2.png",
        _PNG_BLUE,
    )

    if second_upload_state != "Bio":
        _tap_or_fallback(
            app,
            "qa.setup.photos.next_button",
            ["Continue to About"],
            timeout=15,
        )
    app.assert_any_text_visible("Bio", "Tell people about you", timeout=30)
    _type_or_fallback(
        app,
        "qa.setup.about.bio_field",
        0,
        "Automated profile created by the local PostgreSQL release gate.",
    )
    app.hide_keyboard()
    _tap_or_fallback(
        app,
        "qa.setup.about.continue_button",
        ["Continue"],
        timeout=15,
    )
    app.assert_any_text_visible("Preview your profile", "Complete Profile", timeout=30)
    _tap_or_fallback(
        app,
        "qa.setup.preview.complete_button",
        ["Complete Profile"],
        timeout=15,
    )
    app.wait_for_authenticated_surface(timeout=60)
