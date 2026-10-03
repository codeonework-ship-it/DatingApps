"""Report, block and appeal on the Android device (journeys.e2e.safety_report_block).

The device member (QA_EXISTING_USERNAME) is driven through the UI. A fresh
synthetic counterpart (verify_signup_workflow.sh) is matched and befriended
through the API first, so the member has somewhere to see them. Every
outcome is checked twice: on screen, and in server state through the API
(the member's own API session, the counterpart's, and the local operator's
moderation queue for things only an operator can read).

Surfaces, from app source:
- Report a member: Matches > Conversations > "Conversation options for
  {name}" > Report (`qa.matches.report_action`) > report sheet > "Submit
  report" -> POST /safety/report; snack "Report submitted. Thank you.".
- Block a member: Settings > Friends & Connections > "More for {name}" >
  Block > "Block {name}?" > "Block member" -> POST /safety/block.
- Blocked list: Settings > Privacy & Safety > Blocked Users.
- Appeal: Settings > Privacy & Safety > Moderation Appeals
  (moderation_appeals_screen.dart) -> POST /moderation/appeals. The backend
  only accepts an appeal from the member a report is ABOUT, naming that
  report (safety_repository_postgres.go submitModerationAppealPostgres), so
  the appeal case has the counterpart report the device member first.

The operator steps use the local operator account from
backend/scripts/provision_local_operator.sh (LOCAL_OPERATOR_USERNAME /
LOCAL_OPERATOR_PASSWORD, or that script's local default), the same mechanism
qa/seed/seed_dataset.py uses. Without it these cases skip: the report and the
appeal review are only readable from the moderation queue.
"""

from __future__ import annotations

import os
import re
import time
import uuid
from pathlib import Path

import pytest
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import TimeoutException

from api_client import ApiClient, extract_items
from seed_members import friend_status, make_friends, remove_friend

pytestmark = [pytest.mark.requires_appium, pytest.mark.verification_safety]

REPO_ROOT = Path(__file__).resolve().parents[3]
OPERATOR_SCRIPT = REPO_ROOT / "backend" / "scripts" / "provision_local_operator.sh"

REPORT_HINT = "Add context to help review your report"
REPORT_SUBMITTED = "Report submitted. Thank you."  # matchesReportSubmitted
APPEAL_SUBMITTED = "Appeal submitted successfully."  # appealsSubmitted


# --------------------------------------------------------------------------
# Operator (moderation queue) access
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
    """The local operator, signed in through the public login route."""
    username = os.getenv("LOCAL_OPERATOR_USERNAME", "local_control_admin")
    client = ApiClient(appium_config.api_base_url)
    try:
        client.authenticate(username, _operator_password())
    except AssertionError as exc:
        pytest.skip(
            "Precondition missing: the local operator cannot sign in "
            f"({str(exc)[:160]}); run backend/scripts/provision_local_operator.sh"
        )
    probe = client.get("/admin/moderation/reports", query={"limit": 1})
    if probe.status != 200:
        pytest.skip(
            "Precondition missing: the local operator cannot read the moderation queue "
            f"(GET /admin/moderation/reports -> {probe.status})"
        )
    return client


# --------------------------------------------------------------------------
# API helpers
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


def _reports_between(operator: ApiClient, reporter_id: str, reported_id: str) -> list[dict]:
    body = operator.get(
        "/admin/moderation/reports",
        query={"reporter_user_id": reporter_id, "reported_user_id": reported_id, "limit": 50},
    ).require_status(200).body
    return extract_items(body, "reports", "items")


def _blocked_rows(member) -> list[dict]:
    body = member.api.get(f"/blocked-users/{member.user_id}").require_status(200).body
    return extract_items(body, "blocked_users", "items", "users")


def _is_blocked(member, other_id: str) -> bool:
    # Row keys differ between storage paths; match the id anywhere in the row,
    # as qa/api_e2e/tests/test_14_safety_trust.py does.
    return any(other_id in str(row) for row in _blocked_rows(member))


def _search_ids(member, query: str) -> list[str]:
    body = member.api.get(f"/friends/{member.user_id}/search", query={"q": query}).require_status(200).body
    return [str(r.get("user_id")) for r in body.get("results", [])]


def _match_ids(member) -> list[str]:
    body = member.api.get(f"/matches/{member.user_id}").require_status(200).body
    return [str(m.get("id") or m.get("match_id")) for m in extract_items(body, "matches")]


def _make_match(device_member, other) -> str:
    device_member.api.post(
        "/swipe", {"user_id": device_member.user_id, "target_user_id": other.user_id, "is_like": True}
    ).require_status(200, 201)
    second = other.api.post(
        "/swipe", {"user_id": other.user_id, "target_user_id": device_member.user_id, "is_like": True}
    ).require_status(200, 201).body
    match_id = str(second.get("match_id") or "")
    assert second.get("mutual_match") is True and match_id, f"mutual like did not create a match: {second}"
    return match_id


def _unblock(device_member, other) -> None:
    device_member.api.post(
        "/safety/unblock", {"user_id": device_member.user_id, "blocked_user_id": other.user_id}
    )


def _dismiss_report(operator: ApiClient, report_id: str) -> None:
    operator.post(
        f"/admin/moderation/reports/{report_id}/action",
        {"status": "rejected", "action": "qa_cleanup"},
    )


# --------------------------------------------------------------------------
# Device helpers
# --------------------------------------------------------------------------


def _tap_button(app, label: str, timeout: int = 10) -> None:
    """Tap a dialog/sheet button whose own label is exactly `label`."""
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


def _type_field(app, hint: str, index: int, text: str) -> None:
    """Type into the EditText labelled/hinted `hint`, else the index-th field."""
    try:
        app.type_into_hint(hint, text, timeout=6)
    except TimeoutException:
        app.type_into_edit_text(index, text)


def _open_conversation_row(app, match_id: str) -> None:
    app.open_matches_view("Conversations")
    locator = f"qa.matches.match_row.{match_id}"
    if not app.is_qa_visible(locator, timeout=5):
        # A match created moments ago: pull to refresh once.
        size = app.driver.get_window_size()
        x = size["width"] // 2
        app.driver.swipe(x, int(size["height"] * 0.35), x, int(size["height"] * 0.8), 600)
        time.sleep(2)
    app.scroll_into_middle(locator, timeout=30)


def _open_privacy_entry(app, title: str, landmark: str) -> None:
    app.open_settings_entry("Privacy & Safety")
    app.wait_for_text("Privacy & Safety", timeout=15)
    app.scroll_into_middle(title, timeout=25)
    app.tap_text(title)
    app.wait_for_text_contains(landmark, timeout=20)


def _refresh_list_below(app, element) -> None:
    """Pull-to-refresh starting on a list row (RefreshIndicator)."""
    rect = element.rect
    size = app.driver.get_window_size()
    x = size["width"] // 2
    start = int(rect["y"] + rect["height"] / 2)
    end = min(size["height"] - 10, start + int(size["height"] * 0.35))
    app.driver.swipe(x, start, x, end, 700)
    time.sleep(2.5)


def _label_just_above(app, anchor, label: str, max_gap: int = 220):
    """A node showing exactly `label` placed directly above `anchor` (same card)."""
    own = f"{anchor.get_attribute('content-desc') or ''}\n{anchor.get_attribute('text') or ''}"
    if label in own.split("\n"):
        return anchor  # the card's texts were merged into one node
    anchor_y = anchor.rect["y"]
    for node in app.driver.find_elements(*app.ui_text(label)) + app.driver.find_elements(*app.ui_desc(label)):
        try:
            y = node.rect["y"]
        except Exception:  # noqa: BLE001 - node went stale while the list rebuilt
            continue
        if 0 <= anchor_y - y <= max_gap:
            return node
    return None


# --------------------------------------------------------------------------
# Fixtures
# --------------------------------------------------------------------------


@pytest.fixture
def matched_friend(device_member, counterpart_factory):
    """A fresh counterpart who is both a match and an accepted friend of the device member."""
    name = f"Rhea Blockcase {int(time.time()) % 100000}"
    other = counterpart_factory("rb", name)
    match_id = _make_match(device_member, other)
    make_friends(other, device_member)
    # Cleanups run in reverse: unblock first, then unfriend and unmatch.
    counterpart_factory.cleanups.append(
        lambda: device_member.api.request(
            "DELETE", f"/matches/{match_id}", query={"user_id": device_member.user_id}
        )
    )
    counterpart_factory.cleanups.append(lambda: remove_friend(device_member, other.user_id))
    counterpart_factory.cleanups.append(lambda: _unblock(device_member, other))
    return other, name, match_id


# --------------------------------------------------------------------------
# Tests
# --------------------------------------------------------------------------


@pytest.mark.case("journeys.e2e.safety_report_block")
def test_report_then_block_member_disappears(
    operator_api, app, device_member, matched_friend, counterpart_factory
):
    """Report a match on device, block them on device, and they are gone for the member."""
    other, name, match_id = matched_friend

    # Positive controls: before the block the counterpart is reachable, so the
    # "gone" assertions after it are meaningful.
    assert friend_status(device_member, other.user_id) == "accepted", "precondition: friends"
    assert match_id in _match_ids(device_member), "precondition: the match is listed"
    assert device_member.api.get(f"/profile/{other.user_id}").status == 200, "precondition: profile readable"
    assert other.api.get(f"/profile/{device_member.user_id}").status == 200, "precondition: member readable"
    assert other.user_id in _search_ids(device_member, other.username), "precondition: found by friend search"
    # The device member can opt out of friend search (Privacy & Safety); only
    # assert the reverse direction disappears if it was findable to begin with.
    member_findable = device_member.user_id in _search_ids(other, device_member.username)
    before = other.api.post(
        f"/chat/{match_id}/messages", {"text": f"QA hello before block {uuid.uuid4().hex[:6]}",
                                       "sender_id": other.user_id},
    )
    assert before.status in (200, 201), f"precondition: the counterpart can message the match: {before.raw[:300]}"
    assert not _is_blocked(device_member, other.user_id), "precondition: not blocked yet"

    # 1. Report from Matches > Conversations > options.
    detail = f"QA device report {uuid.uuid4().hex[:10]}"
    app.sign_in_existing_user()
    _open_conversation_row(app, match_id)
    app.tap_text(f"Conversation options for {name}", timeout=10)
    app.tap_qa("qa.matches.report_action", timeout=10)
    app.wait_for_text("Submit report", timeout=15)
    # Keep the keyboard up: hiding it sends BACK, which closes the sheet unsent.
    _type_field(app, REPORT_HINT, 0, detail)
    app.tap_text("Submit report", timeout=10)
    app.wait_for_text(REPORT_SUBMITTED, timeout=15)
    app.save_artifact("report_block_report_submitted")

    reports = _wait_api(
        lambda: [r for r in _reports_between(operator_api, device_member.user_id, other.user_id)
                 if r.get("description") == detail],
        timeout=20,
    )
    assert reports, (
        "the report never reached the moderation queue: "
        f"{_reports_between(operator_api, device_member.user_id, other.user_id)}"
    )
    report = reports[0]
    counterpart_factory.cleanups.append(lambda: _dismiss_report(operator_api, str(report["id"])))
    assert report.get("reason") == "inappropriate", report  # the sheet's default reason
    assert report.get("status") == "pending", report

    # 2. Block from Friends & Connections > More for {name}.
    app.go_today()
    app.open_settings_entry("Friends & Connections")
    app.scroll_to_text(f"@{other.username}", timeout=25)
    app.tap_text(f"More for {name}", timeout=10)
    app.tap_text("Block", timeout=10)
    app.wait_for_text(f"Block {name}?", timeout=10)
    assert not _is_blocked(device_member, other.user_id), "blocked before confirming"
    _tap_button(app, "Block member")

    assert _wait_api(lambda: _is_blocked(device_member, other.user_id)), (
        f"block not persisted: {device_member.api.get(f'/blocked-users/{device_member.user_id}').raw[:500]}"
    )
    app.wait_for_text_gone(f"@{other.username}", timeout=15)
    app.save_artifact("report_block_friends_after_block")

    # 3. Gone for the member, and the member gone for them (server state).
    assert _wait_api(lambda: friend_status(device_member, other.user_id) == "none"), (
        f"friendship survived the block: {friend_status(device_member, other.user_id)!r}"
    )
    assert friend_status(other, device_member.user_id) == "none"
    assert device_member.api.get(f"/profile/{other.user_id}").status == 404, "blocked profile still readable"
    assert other.api.get(f"/profile/{device_member.user_id}").status == 404, "blocker's profile still readable"
    assert other.user_id not in _search_ids(device_member, other.username), "blocked member still in friend search"
    if member_findable:
        assert device_member.user_id not in _search_ids(other, device_member.username), (
            "the blocked member can still find the blocker"
        )
    after = other.api.post(
        f"/chat/{match_id}/messages", {"text": "QA message after block", "sender_id": other.user_id},
    )
    assert after.status == 403, f"the blocked member can still message the old match: {after.status} {after.raw[:300]}"
    again = other.api.post(f"/friends/{other.user_id}", {"friend_user_id": device_member.user_id, "source": "profile"})
    assert again.status not in (200, 201), f"the blocked member could re-send a friend request: {again.raw[:300]}"

    # 4. Privacy & Safety > Blocked Users lists them on device.
    _open_privacy_entry(app, "Blocked Users", "Blocked Users")
    app.wait_for_text(name, timeout=20)
    app.wait_for_text("Unblock", timeout=5)
    app.save_artifact("report_block_blocked_users")


@pytest.mark.case("journeys.e2e.safety_report_block")
def test_reported_member_appeals_and_sees_operator_outcome(operator_api, app, device_member, counterpart_factory):
    """The member a report is about appeals it on device; the operator's decision shows on device."""
    other = counterpart_factory("ap", f"Ari Appealcase {int(time.time()) % 100000}")
    filed = other.api.post(
        "/safety/report",
        {"reporter_user_id": other.user_id, "reported_user_id": device_member.user_id,
         "reason": "fake", "description": f"QA appeal fixture {uuid.uuid4().hex[:8]}"},
    ).require_status(200, 201).body
    report_id = str((filed.get("report") or {}).get("id") or "")
    assert report_id, f"report against the device member was not created: {filed}"
    counterpart_factory.cleanups.append(lambda: _dismiss_report(operator_api, report_id))

    queued = _reports_between(operator_api, other.user_id, device_member.user_id)
    assert report_id in [str(r.get("id")) for r in queued], f"report not in the moderation queue: {queued}"

    reason = f"QA appeal {uuid.uuid4().hex[:10]}"
    context = "Submitted from the Android device journey."

    app.sign_in_existing_user()
    _open_privacy_entry(app, "Moderation Appeals", "Submit an appeal")
    _type_field(app, "Reason", 0, reason)
    _type_field(app, "Report ID", 1, report_id)
    _type_field(app, "Additional context", 2, context)
    app.hide_keyboard()
    app.tap_text("Submit appeal", timeout=10)
    app.wait_for_text(APPEAL_SUBMITTED, timeout=20)

    def my_appeal():
        body = device_member.api.get("/moderation/appeals").require_status(200).body
        return next((a for a in body.get("appeals", []) if a.get("reason") == reason), None)

    appeal = _wait_api(my_appeal)
    assert appeal, "the appeal submitted on device is not in the member's appeals"
    assert str(appeal.get("report_id")) == report_id, appeal
    assert appeal.get("status") == "submitted", appeal
    assert appeal.get("description") == context, appeal
    assert appeal.get("sla_deadline_at"), appeal
    appeal_id = str(appeal["id"])

    # The list on device shows the new appeal as Submitted.
    row = app.scroll_into_middle(reason, timeout=20)
    app.wait_for_text(f"Appeal ID: {appeal_id}", timeout=10)
    assert _label_just_above(app, row, "Submitted") is not None, "the new appeal is not shown as Submitted"
    app.save_artifact("appeal_submitted_on_device")

    # Operator reviews and reverses the decision.
    resolution = "QA: decision reversed on appeal"
    reviewed = operator_api.post(
        f"/admin/moderation/appeals/{appeal_id}/action",
        {"status": "resolved_reversed", "resolution_reason": resolution},
    ).require_status(200).body
    assert (reviewed.get("appeal") or {}).get("status") == "resolved_reversed", reviewed
    status = device_member.api.get(f"/moderation/appeals/{appeal_id}").require_status(200).body
    assert status.get("status") == "resolved_reversed", status

    # Pull to refresh on device: the same row now reads "Resolved (reversed)".
    shown = None
    for _ in range(2):
        app.wait_for_snackbar_gone(timeout=6)  # "Appeal updated" inbox banner
        row = app.scroll_into_middle(reason, timeout=20)
        _refresh_list_below(app, row)
        row = app.scroll_into_middle(reason, timeout=20)
        shown = _label_just_above(app, row, "Resolved (reversed)")
        if shown is not None:
            break
    assert shown is not None, "the operator's decision is not shown on the appeal after refreshing"
    app.wait_for_text_contains("Reviewed by:", timeout=10)
    app.save_artifact("appeal_resolved_on_device")


@pytest.mark.xfail(
    reason="Suspected gap, inferred from code and not yet observed on device: a block writes "
    "user_management.blocked_users only, and GET /matches/{userID} (services/matching ListMatches) "
    "does not filter blocked pairs, so the blocked member's match should still be listed "
    "under Matches > Conversations (writes into it are refused with 403 MATCH_BLOCKED).",
    strict=False,
)
def test_blocked_member_leaves_matches_and_conversations(app, device_member, matched_friend):
    """'Disappears everywhere' includes the Matches tab: after a block the match row is gone."""
    other, _name, match_id = matched_friend
    assert match_id in _match_ids(device_member), "precondition: the match is listed"
    device_member.api.post(
        "/safety/block", {"user_id": device_member.user_id, "blocked_user_id": other.user_id}
    ).require_status(200, 201)
    assert _wait_api(lambda: _is_blocked(device_member, other.user_id)), "block not persisted"

    app.sign_in_existing_user()
    app.open_matches_view("Conversations")
    size = app.driver.get_window_size()
    x = size["width"] // 2
    app.driver.swipe(x, int(size["height"] * 0.35), x, int(size["height"] * 0.8), 600)
    time.sleep(2.5)
    app.save_artifact("blocked_member_conversations")

    assert match_id not in _match_ids(device_member), "GET /matches still lists the blocked member's match"
    try:
        app.scroll_to_text(f"qa.matches.match_row.{match_id}", timeout=20)
        still_shown = True
    except TimeoutException:
        still_shown = False
    assert not still_shown, "Conversations still shows the blocked member"
