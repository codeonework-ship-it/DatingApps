"""Identity verification approved by an operator, on the Android device
(journeys.e2e.verification): upload ID + selfie -> pending -> approved.

The shared QA account cannot be returned to "never verified" (the operator
routes only approve or reject: verification_repository_postgres.go), so this
journey signs a fresh disposable member in on the device instead, and signs
the shared QA member back in afterwards.

Steps, from app source:
- Settings > Government Verification (verification_landing_screen.dart):
  "Verify with confidence" + "Start secure verification".
- Upload ID (`qa.verification.id.gallery_button`, `qa.verification.id.next_button`),
  Selfie (`qa.verification.selfie.gallery_button`, `qa.verification.selfie.submit_button`)
  -> POST /verification/{id}/submit (multipart) -> Verification Status
  "Pending" (`qa.verification.status.Pending`).
  The backend refuses images under 300 x 300 px (media_validation.go), so the
  gallery fixtures are 480 px PNGs, not the 1 px ones test_12 uses.
- Operator: POST /admin/verifications/{userID}/approve, as the local operator
  from backend/scripts/provision_local_operator.sh (the mechanism
  qa/seed/seed_dataset.py uses). Locally the identity provider is disabled,
  so a submission waits for this manual review.
- Back on device: Verification Status "Verified" (`qa.verification.status.Verified`)
  and the verified badge on the member's own profile hero, whose spoken name
  is "{name}, {age}, Verified" (cinematic_profile.dart).
"""

from __future__ import annotations

import binascii
import os
import re
import struct
import time
import uuid
import zlib
from pathlib import Path

import pytest
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import TimeoutException

from api_client import ApiClient, extract_items
from seed_members import signup_script_password

pytestmark = [pytest.mark.requires_appium, pytest.mark.verification_safety]

REPO_ROOT = Path(__file__).resolve().parents[3]
OPERATOR_SCRIPT = REPO_ROOT / "backend" / "scripts" / "provision_local_operator.sh"
NOT_STARTED = ("unverified", "not_submitted", "none", "", None)


def _png(rgb: tuple[int, int, int], size: int = 480) -> bytes:
    """A solid-colour PNG large enough for the 300 px evidence minimum."""
    raw = b"".join(b"\x00" + bytes(rgb) * size for _ in range(size))

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (struct.pack(">I", len(payload)) + kind + payload
                + struct.pack(">I", binascii.crc32(kind + payload) & 0xFFFFFFFF))

    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


# --------------------------------------------------------------------------
# Operator access
# --------------------------------------------------------------------------


def _operator_password() -> str:
    explicit = os.getenv("LOCAL_OPERATOR_PASSWORD", "")
    if explicit:
        return explicit
    try:
        text = OPERATOR_SCRIPT.read_text(encoding="utf-8")
    except OSError:
        return ""
    match = re.search(r'password="\$\{LOCAL_OPERATOR_PASSWORD:-([^}]*)\}"', text)
    return match.group(1) if match else ""


@pytest.fixture
def operator_api(appium_config) -> ApiClient:
    username = os.getenv("LOCAL_OPERATOR_USERNAME", "local_control_admin")
    client = ApiClient(appium_config.api_base_url)
    try:
        client.authenticate(username, _operator_password())
    except AssertionError as exc:
        pytest.skip(
            "Precondition missing: the local operator cannot sign in "
            f"({str(exc)[:160]}); run backend/scripts/provision_local_operator.sh"
        )
    probe = client.get("/admin/verifications", query={"limit": 1})
    if probe.status != 200:
        pytest.skip(
            "Precondition missing: the local operator cannot read verifications "
            f"(GET /admin/verifications -> {probe.status})"
        )
    return client


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------


def _wait_api(predicate, timeout: float = 15, interval: float = 1.0):
    deadline = time.time() + timeout
    value = None
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    return value


def _verification(member) -> dict:
    body = member.api.get(f"/verification/{member.user_id}").require_status(200).body
    return body if isinstance(body, dict) else {}


def _profile_verified(member) -> bool:
    body = member.api.get(f"/profile/{member.user_id}").require_status(200).body
    profile = body.get("profile", body) if isinstance(body, dict) else {}
    return profile.get("is_verified") is True


def _queued_for_review(operator: ApiClient, user_id: str) -> bool:
    body = operator.get(
        "/admin/verifications", query={"user_id": user_id, "status": "pending", "limit": 20}
    ).require_status(200).body
    return any(user_id in str(row) for row in extract_items(body, "verifications", "items"))


def _tap_button(app, label: str, timeout: int = 10) -> None:
    locator = (
        AppiumBy.XPATH,
        f'//android.widget.Button[@content-desc="{label}" or @text="{label}"]',
    )
    deadline = time.time() + timeout
    while time.time() < deadline:
        found = app.driver.find_elements(*locator)
        if found:
            found[-1].click()
            return
        time.sleep(0.3)
    app.tap_text(label, timeout=3)


def _sign_out(app) -> None:
    """Settings > Account > Sign out, confirmed; ends on the welcome screen."""
    app.go_today()
    app.open_tab("Settings")
    app.wait_for_tab("settings")
    app.scroll_into_middle("End your session on this device", timeout=40)
    app.tap_text_contains("End your session on this device")
    app.wait_for_text("Sign out?", timeout=10)
    _tap_button(app, "Sign out")
    app.assert_any_text_visible("Already a member?", "qa.welcome.signin_button", timeout=30)


def _sign_in_as(app, username: str, password: str) -> None:
    """Welcome > Sign in with a synthetic local test member's credentials."""
    app.open_welcome_signin()
    app.assert_any_text_visible("Sign in", "SIGN IN", "Account credentials", timeout=15)
    revealed = app.maybe_tap("Show password", timeout=2)
    try:
        app.type_into_qa("qa.signin.username_field", username, timeout=6)
        app.type_into_qa("qa.signin.password_field", password, timeout=6)
    except Exception:  # noqa: BLE001 - text-index fallback, as sign_in_existing_user does
        app.type_into_edit_text(0, username)
        app.type_into_edit_text(1, password)
    app.hide_keyboard()
    if revealed:
        app.maybe_tap("Hide password", timeout=2)
    try:
        app.tap_qa_coordinate("qa.signin.login_button", timeout=4)
    except TimeoutException:
        app.tap_first_visible_text(["Sign in", "SIGN IN"], timeout=10)
    app.accept_terms_if_present(timeout=10)
    app.wait_for_authenticated_surface(timeout=app.config.long_timeout)


def _signed_in(app) -> bool:
    """Pop back to the signed-in shell; False when the device shows Welcome."""
    try:
        app.go_today()
        return True
    except AssertionError:
        return False


def _switch_device_to(app, username: str, password: str) -> None:
    if _signed_in(app):
        _sign_out(app)
    _sign_in_as(app, username, password)


def _restore_shared_member(app) -> None:
    """Sign the shared QA member back in for the specs that follow."""
    try:
        if _signed_in(app):
            _sign_out(app)
        app.sign_in_existing_user()
    except Exception as exc:  # noqa: BLE001 - must not mask the test result
        print(f"[restore shared QA member failed] {exc!r}")


def _restart_app(app) -> None:
    package = app.config.app_package
    app.driver.terminate_app(package)
    time.sleep(1.5)
    app.driver.activate_app(package)
    time.sleep(5)
    app.wait_for_authenticated_surface(timeout=app.config.long_timeout)


def _open_verification_landing(app) -> None:
    app.open_settings_entry("Government Verification")
    app.wait_for_text("Verify with confidence", timeout=20)


# --------------------------------------------------------------------------
# Test
# --------------------------------------------------------------------------


@pytest.mark.case("journeys.e2e.verification")
def test_id_and_selfie_pending_then_operator_approves(operator_api, app, counterpart_factory):
    name = f"Vera Verifycase {int(time.time()) % 100000}"
    member = counterpart_factory("vf", name)
    start = _verification(member)
    assert start.get("status") in NOT_STARTED, f"precondition: a never-verified member, got {start}"
    assert not _profile_verified(member), "precondition: no verified flag yet"

    try:
        _switch_device_to(app, member.username, signup_script_password())
        # The device is really this member, not the shared account.
        app.go_today()
        app.open_tab("Settings")
        app.wait_for_tab("settings")
        app.scroll_into_middle(f"Signed in as @{member.username}", timeout=40)

        # 1. Landing: a never-verified member is offered the start button.
        _open_verification_landing(app)
        app.wait_for_text("Start secure verification", timeout=10)
        assert not app.is_text_visible("View review status", timeout=2)
        if not app.maybe_tap_qa("qa.verification.landing.start_button", timeout=5):
            app.tap_text("Start secure verification")
        app.assert_any_text_visible("Upload ID", "Take or upload a clear photo", timeout=15)

        # 2. ID from the gallery, then Next.
        app.upload_gallery_png_via_picker(
            trigger_qa_id="qa.verification.id.gallery_button",
            trigger_texts=["Gallery"],
            filename=f"appium_verify_id_{uuid.uuid4().hex}.png",
            png_bytes=_png((24, 72, 140)),
        )
        app.wait_for_text("Next", timeout=20)
        if not app.maybe_tap_qa("qa.verification.id.next_button", timeout=5):
            app.tap_text("Next", timeout=10)
        app.assert_any_text_visible("Take a clear selfie.", timeout=20)

        # 3. Selfie from the gallery, then Submit.
        app.upload_gallery_png_via_picker(
            trigger_qa_id="qa.verification.selfie.gallery_button",
            trigger_texts=["Gallery"],
            filename=f"appium_verify_selfie_{uuid.uuid4().hex}.png",
            png_bytes=_png((160, 96, 40)),
        )
        app.wait_for_text("Submit", timeout=20)
        if not app.maybe_tap_qa("qa.verification.selfie.submit_button", timeout=5):
            app.tap_text("Submit", timeout=10)

        # 4. Pending, on screen and on the server.
        try:
            app.wait_for_qa("qa.verification.status.Pending", timeout=45)
        except TimeoutException:
            failed = app.is_text_visible("We could not upload your evidence", timeout=2)
            raise AssertionError(
                "the status screen never showed Pending"
                + (" (the app reported the upload failed)" if failed else "")
            ) from None
        app.wait_for_text("Review in progress.", timeout=10)
        app.save_artifact("verification_pending")

        pending = _wait_api(lambda: _verification(member).get("status") == "pending")
        state = _verification(member)
        assert pending, f"server status is not pending after submit: {state}"
        assert state.get("evidence_received") is True, state
        assert _wait_api(lambda: _queued_for_review(operator_api, member.user_id)), (
            "the submission is not in the operator's pending verification queue"
        )
        assert not _profile_verified(member), "verified before any review"

        # 5. The operator approves.
        approved = operator_api.post(f"/admin/verifications/{member.user_id}/approve", {})
        assert approved.status == 200, f"operator approval failed: {approved.status} {approved.raw[:400]}"
        assert _wait_api(lambda: _verification(member).get("status") == "verified"), (
            f"server status after approval: {_verification(member)}"
        )
        assert _wait_api(lambda: _profile_verified(member)), "profile is_verified not set by the approval"

        # 6. Back on device after a cold start: verified status and badge.
        _restart_app(app)
        _open_verification_landing(app)
        app.wait_for_text("View verified status", timeout=15)
        app.tap_text("View verified status")
        app.wait_for_qa("qa.verification.status.Verified", timeout=20)
        app.wait_for_text("Your verification is complete.", timeout=10)
        app.save_artifact("verification_verified_status")

        app.go_today()
        app.open_tab("Profile")
        app.wait_for_tab("profile")
        app.wait_for_text("STARRING", timeout=20)
        badge = (
            AppiumBy.XPATH,
            f'//*[contains(@content-desc, "{name}") and contains(@content-desc, ", Verified")]',
        )
        deadline = time.time() + 20
        while time.time() < deadline and not app.driver.find_elements(*badge):
            time.sleep(0.5)
        app.save_artifact("verification_profile_badge")
        assert app.driver.find_elements(*badge), (
            "the member's own profile hero does not carry the Verified badge"
        )
    finally:
        _restore_shared_member(app)
