from __future__ import annotations

import base64
import uuid

import pytest
from selenium.common.exceptions import TimeoutException


_PNG_ID = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC"
)
_PNG_SELFIE = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYPgPAAEDAQAt0VIbAAAAAElFTkSuQmCC"
)


def _open_settings(app) -> None:
    app.sign_in_existing_user()
    app.open_tab("Settings")
    app.assert_any_text_visible("Settings", "Privacy & Safety", timeout=20)


def _open_verification_landing(app) -> None:
    _open_settings(app)
    if not app.maybe_tap_qa("qa.settings.government_verification", timeout=5):
        try:
            app.tap_scroll_text("Government Verification", timeout=10)
        except TimeoutException:
            pytest.skip("Government Verification settings entry is not visible in this build")
    app.assert_any_text_visible("Government Verification", "Verify with confidence", timeout=15)


def _open_verification_upload(app) -> None:
    _open_settings(app)
    if not app.maybe_tap_qa("qa.verification.shortcut_upload", timeout=5) and not app.maybe_tap_qa(
        "qa.settings.verification_upload", timeout=5
    ):
        try:
            app.tap_scroll_text("QA Verification Upload", timeout=10)
        except TimeoutException:
            pytest.skip(
                "QA Verification Upload entry requires a debug build with ENABLE_QA_AUTOMATION=true"
            )
    app.assert_any_text_visible("Upload ID", "Take or upload a clear photo", timeout=15)


def _upload_id_and_continue_to_selfie(app) -> None:
    app.upload_gallery_png_via_picker(
        trigger_qa_id="qa.verification.id.gallery_button",
        trigger_texts=["Gallery"],
        filename=f"appium_verification_id_{uuid.uuid4().hex}.png",
        png_bytes=_PNG_ID,
    )
    app.assert_any_text_visible("Upload ID", "Next", timeout=20)
    if not app.maybe_tap_qa("qa.verification.id.next_button", timeout=5):
        app.tap_first_visible_text(["Next"], timeout=10)
    app.assert_any_text_visible("Selfie", "Take a clear selfie", timeout=20)


def _open_profile_detail(app) -> None:
    app.open_discovery_deck()

    opened = app.maybe_tap_qa("qa.discovery.view_more_button", timeout=8)
    if not opened:
        opened = app.maybe_tap_contains("View more", timeout=8)
    if not opened:
        pytest.skip("No visible discovery profile detail entry point in current deck")
    app.assert_any_text_visible("Message", "Love", "Read more", timeout=20)


@pytest.mark.requires_appium
@pytest.mark.verification_safety
def test_verification_landing_renders(app):
    _open_verification_landing(app)

    # verification_landing_screen.dart: the "Verification Paused" notice was
    # replaced by the secure-verification landing (title, explainer and one
    # action that depends on the member's current verification status).
    app.wait_for_text("Government Verification", timeout=15)
    app.wait_for_text("Verify with confidence", timeout=15)
    app.wait_for_text_contains("government identity document", timeout=10)
    app.assert_any_text_visible(
        "Start secure verification",
        "View review status",
        "View verified status",
        timeout=15,
    )
    app.save_artifact("verification_landing")
    app.press_back()


@pytest.mark.requires_appium
@pytest.mark.verification_safety
def test_verification_upload_id_from_gallery_reaches_selfie_step(app):
    _open_verification_upload(app)

    _upload_id_and_continue_to_selfie(app)

    app.assert_any_text_visible("Selfie", "Gallery", "Camera", "Submit", timeout=15)


@pytest.mark.requires_appium
@pytest.mark.verification_safety
def test_verification_selfie_from_gallery_submit_reaches_status(app):
    _open_verification_upload(app)
    _upload_id_and_continue_to_selfie(app)

    app.upload_gallery_png_via_picker(
        trigger_qa_id="qa.verification.selfie.gallery_button",
        trigger_texts=["Gallery"],
        filename=f"appium_verification_selfie_{uuid.uuid4().hex}.png",
        png_bytes=_PNG_SELFIE,
    )
    app.assert_any_text_visible("Selfie", "Submit", timeout=20)
    if not app.maybe_tap_qa("qa.verification.selfie.submit_button", timeout=5):
        app.tap_first_visible_text(["Submit"], timeout=10)

    app.assert_any_text_visible(
        "Verification Status",
        "Pending",
        "Review in progress",
        "Retry",
        timeout=30,
    )


@pytest.mark.requires_appium
@pytest.mark.verification_safety
def test_profile_report_submit_success(app):
    _open_profile_detail(app)

    app.tap_qa("qa.profile_detail.report_button", timeout=10)
    app.assert_any_text_visible("Report", "Submit report", "Add context", timeout=15)
    try:
        app.type_into_edit_text(0, "Appium safety report smoke context")
        app.hide_keyboard()
    except TimeoutException:
        pass
    try:
        app.tap_first_visible_text(["Submit report"], timeout=10)
    except TimeoutException:
        # The submit can complete while the accessibility node disappears.
        # Accept only the actual success acknowledgement, never merely a
        # return to the detail page (which Cancel would also satisfy).
        app.assert_any_text_visible("Report submitted.", timeout=3)
    app.assert_any_text_visible("Report submitted.", timeout=10)
