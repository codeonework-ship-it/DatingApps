"""Date plan from a match chat, driven on the device (journeys.e2e.date_plan).

Propose → share with a trusted friend → the partner accepts → friend fan-out
→ check in after the date → debrief, all from the plan card at the top of the
chat (app/lib/features/plans/widgets/date_plan_card.dart).

The device member (QA_EXISTING_USERNAME) proposes on screen. Two synthetic
counterparts play the other people: the date (a fresh mutual match) accepts
and debriefs through the API, and a friend of the device member is the trusted
contact. Fan-out is asserted from the friend's side: GET /friends/{id}/plans
reads the feed rows written by matching.notify_date_plan_status, so each
`latest_update` there is a delivered update, not a status read-through.

"After the date" is real time, not a fixture: the plan is proposed for a few
minutes from now (the propose sheet only accepts a future start; the server's
check-in and debrief open at window_start), so the test waits ~4-5 minutes
for the window to start.

Day and time are chosen with Flutter's Material date and time pickers; the
locators for those dialogs follow Flutter's MaterialLocalizations (English):
"Switch to text input mode", "AM"/"PM", "OK", day cells labelled with the full
date ("Saturday, October 3, 2026").
"""

from __future__ import annotations

import datetime as dt
import math
import time

import pytest
from appium.webdriver.common.appiumby import AppiumBy

from seed_members import make_friends, remove_friend
from tests.test_04_matches_chat import _chat_is_unlocked, _open_first_chat

pytestmark = [pytest.mark.requires_appium, pytest.mark.chat]

CASE = "journeys.e2e.date_plan"

# English copy (app_en.arb).
PROPOSE = "Propose"  # planProposeButton
PROPOSE_SHEET_HEADLINE = "A plan you both look forward to."  # planProposeHeadline
WHEN_TITLE = "When would feel right?"  # planWhenTitle
SEND_PLAN = "Send the plan"  # planSendButton
FUTURE_ERROR = "Pick a time in the future."  # planFutureTimeError
CHOOSE_UPDATES = "Choose who gets your updates"  # planChooseUpdates
SHARING_TITLE = "Your plan. Your people."  # planSharingTitle
SHARE_SELECTED = "Share with selected contacts"  # planSharingShareSelected
SHARING_SAVED = "Your selected contacts can now see this plan."  # planSharingSavedSnack
HEADLINE_UPCOMING = "It is a plan"  # planHeadlineUpcoming
HEADLINE_CHECKIN = "How did it go?"  # planHeadlineCheckin
HEADLINE_DEBRIEF = "How was it?"  # planHeadlineDebrief
IM_SAFE = "I'm safe"  # planImSafe
DEBRIEF_BUTTON = "Ten-second debrief"  # planDebriefButton
Q_HAPPENED = "Did the date happen?"  # debriefHappened
Q_AGAIN = "Would you meet again?"  # debriefMeetAgain
Q_SAFE = "Did you feel safe?"  # debriefFeltSafe
SAVE_DEBRIEF = "Save debrief"  # debriefSave
YES = "Yes"  # commonYes

# Flutter MaterialLocalizations (English).
TIME_INPUT_MODE = "Switch to text input mode"
PREVIOUS_MONTH = "Previous month"
OK = "OK"

LEAD_MINUTES = 4  # how far ahead the plan starts


# --- API helpers ------------------------------------------------------------------------


def _wait_api(predicate, timeout: float = 20, interval: float = 1.0):
    deadline = time.time() + timeout
    value = None
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    return value


def _require_flags(api, *keys: str) -> None:
    body = api.get("/config/flags").require_status(200).body
    flags = {row.get("key"): row.get("value_bool") for row in (body or {}).get("flags", [])}
    off = [key for key in keys if flags.get(key) is False]
    if off:
        pytest.skip(f"feature flag(s) off on this stack: {off}")


def _fresh_match(device_member, counterpart_factory, role: str, name: str):
    uid = device_member.user_id
    ent = device_member.api.get(f"/billing/entitlements/{uid}").require_status(200).body
    likes = ent.get("likes") or {}
    if ent.get("enforced", True) and not likes.get("unlimited") and int(likes.get("remaining", 1)) < 1:
        pytest.skip(
            "the shared QA member has used today's likes "
            f"({likes.get('used')}/{likes.get('limit')}); a fresh match needs one like. "
            f"Resets at {likes.get('resets_at')}"
        )
    other = counterpart_factory(role, name)
    other.api.post(
        "/swipe", {"user_id": other.user_id, "target_user_id": uid, "is_like": True}
    ).require_status(200, 201)
    body = device_member.api.post(
        "/swipe", {"user_id": uid, "target_user_id": other.user_id, "is_like": True}
    ).require_status(200, 201).body
    match_id = str(body.get("match_id") or "")
    assert body.get("mutual_match") is True and match_id, f"the mutual like did not create a match: {body}"
    counterpart_factory.cleanups.append(
        lambda: device_member.api.request("DELETE", f"/matches/{match_id}", query={"user_id": uid})
    )
    unlocked, state = _chat_is_unlocked(device_member.api, match_id)
    assert unlocked, f"a fresh match must be open for chat (and plans) by default, got {state!r}"
    return match_id, other


def _plans(api, match_id: str) -> dict:
    return api.get(f"/matches/{match_id}/plans").require_status(200).body


def _open_plan(api, match_id: str) -> dict | None:
    return _plans(api, match_id).get("plan")


def _plan_in_history(api, match_id: str, plan_id: str) -> dict | None:
    body = _plans(api, match_id)
    for plan in [body.get("plan") or {}, *(body.get("history") or [])]:
        if plan.get("id") == plan_id:
            return plan
    return None


def _friend_feed_row(friend, plan_id: str) -> dict | None:
    rows = friend.api.get(f"/friends/{friend.user_id}/plans").require_status(200).body.get("plans", [])
    return next((row for row in rows if row.get("plan_id") == plan_id), None)


def _feed_update_is(friend, plan_id: str, update: str):
    row = _friend_feed_row(friend, plan_id)
    return row if row and row.get("latest_update") == update else None


def _parse_utc(value: str) -> dt.datetime:
    return dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))


# --- device helpers ---------------------------------------------------------------------


def _device_now(app) -> dt.datetime:
    """The emulator's local wall clock with its UTC offset (the app builds the
    plan window from the device's local time)."""
    raw = str(app.shell("date", ["+%Y-%m-%d %H:%M:%S %z"])).strip().splitlines()[-1]
    return dt.datetime.strptime(raw.strip(), "%Y-%m-%d %H:%M:%S %z")


def _day_chip(day: dt.date) -> str:
    # describeDatePlanDay: DateFormat('EEE d MMM') → "Sun 4 Oct".
    return f"{day:%a} {day.day} {day:%b}"


def _full_date(day: dt.date) -> str:
    # MaterialLocalizations.formatFullDate (en): "Saturday, October 3, 2026".
    return f"{day:%B} {day.day}, {day.year}"


def _visible_one_of(app, texts) -> str | None:
    for text in texts:
        if app.is_text_visible(text, timeout=1):
            return text
    return None


def _swipe_card_area(app, upward: bool) -> None:
    """One swipe inside the plan card's scroll area (capped at 30% of the
    chat, under the header). `upward` moves the content up (reveals lower
    parts of the card)."""
    size = app.driver.get_window_size()
    x, low, high = size["width"] // 2, int(size["height"] * 0.30), int(size["height"] * 0.16)
    cards = app.find_qa_containing("qa.plan.card") or app.find_qa_containing("qa.plan.")
    if cards:
        rect = cards[0].rect
        if rect["height"] > 80:
            x = int(rect["x"] + rect["width"] / 2)
            low = int(rect["y"] + rect["height"] * 0.85)
            high = int(rect["y"] + rect["height"] * 0.15)
    y1, y2 = (low, high) if upward else (high, low)
    app.shell("input", ["swipe", str(x), str(y1), str(x), str(y2), "450"])
    time.sleep(0.8)


def _scan_card_area(app, texts, up: int = 4, down: int = 6) -> str | None:
    """Look for any of `texts`, scrolling the card area down, then back up."""
    found = _visible_one_of(app, texts)
    for upward, count in ((True, up), (False, down)):
        for _ in range(count):
            if found:
                return found
            _swipe_card_area(app, upward)
            found = _visible_one_of(app, texts)
    return found


def _reveal_on_card(app, text: str):
    """Bring `text` (a control on the plan card) on screen and return it."""
    assert _scan_card_area(app, [text]), f"{text!r} never appeared on the plan card"
    return app.wait_for_text(text, timeout=3)


def _relaunch_into_chat(app, match_id: str, partner_name: str) -> None:
    app.driver.terminate_app(app.config.app_package)
    time.sleep(1)
    app.driver.activate_app(app.config.app_package)
    time.sleep(4)
    _open_first_chat(app, partner_name, match_id)


def _card_shows(app, match_id: str, partner_name: str, *texts: str, timeout: int = 25) -> str:
    """Wait for the card to show one of `texts`.

    Changes made by the other person reach an open chat only through the
    connection poll; when the card has not caught up, reopen the chat, and
    as a last resort relaunch the app (a fresh provider reads the plan).
    """
    def seen(wait: int) -> str | None:
        deadline = time.time() + wait
        scanned = False
        while time.time() < deadline:
            found = _visible_one_of(app, texts)
            if found:
                return found
            if not scanned and time.time() > deadline - wait + 5:
                # The headline may be scrolled out of the card area.
                scanned = True
                found = _scan_card_area(app, texts, up=2, down=4)
                if found:
                    return found
            time.sleep(0.5)
        return None

    found = seen(timeout)
    if found:
        return found
    app.press_back(settle=1.5)
    _open_first_chat(app, partner_name, match_id)
    found = seen(15)
    if found:
        return found
    _relaunch_into_chat(app, match_id, partner_name)
    found = seen(30)
    assert found, f"the plan card never showed any of {texts}"
    return found


def _tap_yes_under(app, question: str) -> None:
    """Each debrief question has its own Yes/No chips; tap the Yes just below it."""
    app.scroll_sheet_to_text_or_fail(question)
    size = app.driver.get_window_size()
    x = size["width"] // 2
    for _ in range(3):
        qy = app.wait_for_text(question, timeout=5).rect["y"]
        chips = app.driver.find_elements(AppiumBy.XPATH, f'//*[@text="{YES}" or @content-desc="{YES}"]')
        below = [c for c in chips if c.rect["y"] > qy]
        if below:
            app._tap_element_center(min(below, key=lambda c: c.rect["y"]))
            time.sleep(0.6)
            return
        # The chips sit just under the fold: nudge the sheet up (forward only,
        # so the sheet is never dragged shut).
        app.shell("input", ["swipe", str(x), str(int(size["height"] * 0.7)),
                            str(x), str(int(size["height"] * 0.55)), "500"])
        time.sleep(0.8)
    raise AssertionError(f"no '{YES}' chip under {question!r}")


def _replace_focused_field(app, field, value: str) -> None:
    field.click()
    time.sleep(0.3)
    app.driver.press_keycode(123)  # KEYCODE_MOVE_END
    for _ in range(4):
        app.driver.press_keycode(67)  # KEYCODE_DEL
    app._type_focused_text(value)
    time.sleep(0.3)


def _pick_today(app, today: dt.date, tomorrow: dt.date) -> None:
    app.scroll_sheet_to_text_or_fail(_day_chip(tomorrow))
    app.tap_text(_day_chip(tomorrow), timeout=10)
    full = _full_date(today)
    if not app.is_text_visible(full, timeout=5):
        # The calendar opens on the default day (tomorrow); today can be in
        # the previous month.
        app.maybe_tap(PREVIOUS_MONTH, timeout=3)
    day = app.wait_for_text_contains(full, timeout=8)
    app._tap_element_center(day)
    app.tap_text(OK, timeout=8)
    app.wait_for_text(_day_chip(today), timeout=10)


def _pick_time(app, default_label: str, target: dt.datetime) -> None:
    app.scroll_sheet_to_text_or_fail(default_label)
    app.tap_text_contains(default_label, timeout=10)
    app.tap_text(TIME_INPUT_MODE, timeout=10)
    time.sleep(1)
    twelve_hour = app.is_text_visible("PM", timeout=2) or app.is_text_visible("AM", timeout=1)
    hour = (target.hour % 12 or 12) if twelve_hour else target.hour
    fields = app.edit_texts()
    assert len(fields) >= 2, f"the time picker's text input mode shows {len(fields)} field(s), expected hour and minute"
    _replace_focused_field(app, fields[0], f"{hour:02d}")
    fields = app.edit_texts()
    _replace_focused_field(app, fields[1], f"{target.minute:02d}")
    app.hide_keyboard()
    if twelve_hour:
        app.tap_text("PM" if target.hour >= 12 else "AM", timeout=5)
    app.tap_text(OK, timeout=8)
    # The chip reads "HH:MM–HH:MM" (describeDatePlanTime, 24-hour).
    app.wait_for_text_contains(f"{target:%H:%M}–", timeout=10)


# --- test -------------------------------------------------------------------------------


@pytest.mark.case(CASE)
def test_propose_share_accept_checkin_and_debrief_a_date(app, device_member, counterpart_factory):
    api, uid = device_member.api, device_member.user_id
    _require_flags(api, "date_plans_enabled")
    suffix = int(time.time()) % 100000

    # The trusted friend (sorts early in the contact list) and the date.
    friend = counterpart_factory("pf", f"Aa Trusted {suffix}")
    make_friends(friend, device_member)
    counterpart_factory.cleanups.append(lambda: remove_friend(friend, uid))
    match_id, partner = _fresh_match(device_member, counterpart_factory, "dp", f"Dana Planner {suffix}")
    assert _open_plan(api, match_id) is None and _plans(api, match_id).get("can_propose") is True

    # The plan starts a few minutes from the emulator's clock.
    now = _device_now(app)
    target = (now + dt.timedelta(minutes=LEAD_MINUTES)).replace(second=0, microsecond=0) + dt.timedelta(minutes=1)
    tomorrow = now.date() + dt.timedelta(days=1)

    # 1. Propose from the plan card.
    _open_first_chat(app, partner.name, match_id)
    app.dismiss_snackbars()
    _reveal_on_card(app, PROPOSE)
    app.tap_text(PROPOSE, timeout=10)
    app.wait_for_text(PROPOSE_SHEET_HEADLINE, timeout=15)
    app.scroll_sheet_to_text_or_fail(WHEN_TITLE)
    if target.date() != tomorrow:  # the sheet defaults to tomorrow 18:00
        _pick_today(app, now.date(), tomorrow)
    _pick_time(app, "18:00–", target)
    app.save_artifact("date_plan_propose_sheet_filled")
    app.scroll_sheet_to_text_or_fail(SEND_PLAN)
    app.tap_text(SEND_PLAN, timeout=10)
    if app.is_text_visible(FUTURE_ERROR, timeout=3):
        raise AssertionError(f"the sheet refused the start time {target:%H:%M} as not in the future")
    app.wait_for_text_gone(PROPOSE_SHEET_HEADLINE, timeout=20)

    plan = _wait_api(lambda: _open_plan(api, match_id))
    assert plan, "the proposed plan is not on the server"
    plan_id = plan["id"]
    counterpart_factory.cleanups.append(
        lambda: api.post(f"/matches/{match_id}/plans/{plan_id}/cancel", {"reason": "appium cleanup"})
    )
    assert plan["status"] == "proposed" and plan["proposer_user_id"] == uid, plan
    assert plan["next_action"] == "await_decision", plan
    start_utc = _parse_utc(plan["window_start"])
    assert start_utc == target.astimezone(dt.timezone.utc), (
        f"window_start {plan['window_start']} is not the picked {target.isoformat()}"
    )
    partner_view = _open_plan(partner.api, match_id)
    assert partner_view and partner_view["id"] == plan_id and partner_view["next_action"] == "decide", partner_view
    _card_shows(app, match_id, partner.name, f"Waiting for {partner.name}")  # planHeadlineWaiting
    app.save_artifact("date_plan_proposed_card")

    # 2. Share the plan with the trusted friend.
    _reveal_on_card(app, CHOOSE_UPDATES)
    app.tap_text(CHOOSE_UPDATES, timeout=10)
    app.wait_for_text(SHARING_TITLE, timeout=15)
    app.scroll_sheet_to_text_or_fail(friend.name)
    app.tap_text(friend.name, timeout=10)
    app.scroll_sheet_to_text_or_fail(SHARE_SELECTED)
    app.tap_text(SHARE_SELECTED, timeout=10)
    app.wait_for_text_contains(SHARING_SAVED, timeout=15)
    sharing = api.get(f"/matches/{match_id}/plans/{plan_id}/sharing").require_status(200).body
    assert sharing.get("contact_ids") == [friend.user_id], sharing
    row = _wait_api(lambda: _feed_update_is(friend, plan_id, "proposed"))
    assert row, f"the friend was not told about the proposal: {_friend_feed_row(friend, plan_id)}"
    assert row.get("friend_user_id") == uid, row

    # 3. The partner accepts; the friend hears about it.
    version = _open_plan(partner.api, match_id).get("lock_version", 0)
    decided = partner.api.post(
        f"/matches/{match_id}/plans/{plan_id}/decision", {"decision": "accept", "expected_version": version}
    ).require_status(200).body["plan"]
    assert decided["status"] == "accepted", decided
    row = _wait_api(lambda: _feed_update_is(friend, plan_id, "accepted"))
    assert row and row.get("status") == "accepted", f"accept was not fanned out to the friend: {_friend_feed_row(friend, plan_id)}"
    _card_shows(app, match_id, partner.name, HEADLINE_UPCOMING, HEADLINE_CHECKIN)
    app.save_artifact("date_plan_accepted_card")

    # 4. After the window starts: check in safe.
    wait_s = max(0.0, (start_utc - dt.datetime.now(dt.timezone.utc)).total_seconds()) + 90
    due = _wait_api(
        lambda: (_open_plan(api, match_id) or {}).get("next_action") == "checkin",
        timeout=math.ceil(wait_s), interval=5,
    )
    assert due, f"check-in never opened: {_open_plan(api, match_id)}"
    _card_shows(app, match_id, partner.name, HEADLINE_CHECKIN, timeout=20)
    _reveal_on_card(app, IM_SAFE)
    app.tap_text(IM_SAFE, timeout=10)
    checked = _wait_api(
        lambda: any(c.get("user_id") == uid and c.get("status") == "safe"
                    for c in (_open_plan(api, match_id) or {}).get("checkins", []))
    )
    assert checked, f"the safe check-in is not on the server: {_open_plan(api, match_id)}"
    row = _wait_api(lambda: _feed_update_is(friend, plan_id, "safe"))
    assert row, f"the safe check-in was not fanned out to the friend: {_friend_feed_row(friend, plan_id)}"
    assert any(c.get("status") == "safe" for c in row.get("checkins", [])), row

    # 5. Debrief after the date.
    _card_shows(app, match_id, partner.name, HEADLINE_DEBRIEF, timeout=20)
    _reveal_on_card(app, DEBRIEF_BUTTON)
    app.tap_text(DEBRIEF_BUTTON, timeout=10)
    app.wait_for_text(f"How was it with {partner.name}?", timeout=15)  # debriefTitle
    _tap_yes_under(app, Q_HAPPENED)
    _tap_yes_under(app, Q_AGAIN)
    _tap_yes_under(app, Q_SAFE)
    app.scroll_sheet_to_text_or_fail(SAVE_DEBRIEF)
    app.tap_text(SAVE_DEBRIEF, timeout=10)
    app.wait_for_text_gone(SAVE_DEBRIEF, timeout=20)
    own = _wait_api(lambda: (_open_plan(api, match_id) or {}).get("debrief"))
    assert own, f"the debrief is not on the server: {_open_plan(api, match_id)}"
    assert own.get("happened") is True and own.get("would_meet_again") is True and own.get("felt_safe") is True, own
    assert own.get("user_id") == uid, own
    _card_shows(app, match_id, partner.name, f"Waiting for {partner.name}'s debrief", "Debrief complete")
    app.save_artifact("date_plan_debriefed_card")

    # The partner's debrief resolves the plan as a date that happened.
    partner.api.post(
        f"/matches/{match_id}/plans/{plan_id}/debrief",
        {"happened": True, "would_meet_again": True, "felt_safe": True},
    ).require_status(200)
    resolved = _wait_api(lambda: (lambda p: p if p and p.get("status") == "completed" else None)(
        _plan_in_history(api, match_id, plan_id)))
    assert resolved, f"the plan did not resolve as completed: {_plan_in_history(api, match_id, plan_id)}"
    row = _wait_api(lambda: _feed_update_is(friend, plan_id, "completed"))
    assert row, f"the completed date was not fanned out to the friend: {_friend_feed_row(friend, plan_id)}"
