"""Happy paths for catalog ``*.api_contract`` cases that had no API-level test:
account settings toggles, discovery pause and graduation, circles, daily prompt,
coffee polls, progression, match nudges, voice icebreakers, mini activities,
calls, gift telemetry, billing (sandbox provider only), date-plan sharing, SOS,
profile views, identity verification, and the flag-gated support and city
pilot routes.

The error paths for the same cases live in test_19_catalog_api_contracts.py
under the same ``case`` ids.
"""

from __future__ import annotations

import datetime as dt
import struct
import uuid
from urllib.parse import urlparse

import pytest
import requests

from client import API_BASE, Api, png_bytes, wait_for
from journeys import befriend, match


pytestmark = pytest.mark.journey("catalog_engagement_billing_safety")


def _flags(member):
    return {f["key"]: f["value_bool"] for f in member.get("/config/flags").ok()["flags"]}


def _wav(seconds: float = 0.5, rate: int = 8000) -> bytes:
    data = b"\x00\x00" * int(rate * seconds)
    return (b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVEfmt "
            + struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16) + b"data" + struct.pack("<I", len(data)) + data)


@pytest.fixture(scope="module")
def couple(make_member):
    a, b = make_member("ce_a", "F", "M"), make_member("ce_b", "M", "F")
    return a, b, match(a, b)


# --- auth and account settings ------------------------------------------------------------

@pytest.mark.case("auth.account_recovery.recovery_submit.api_contract")
def test_recovery_assistance_answers_the_same_for_known_and_unknown_usernames(couple):
    a, _, _ = couple
    known = Api().post("/auth/recovery/assistance", {"username": a.username, "message": "e2e: lost my phone"})
    unknown = Api().post("/auth/recovery/assistance", {"username": f"e2e_nobody_{uuid.uuid4().hex[:8]}"})
    assert known.status == unknown.status == 202, (known.text, unknown.text)
    assert known["accepted"] is True and known["message"] == unknown["message"], "no username enumeration"
    assert "password" not in known.text.lower() or "never ask for your password" in known.text.lower()


@pytest.mark.case("auth.user_agreement.terms_continue_button.api_contract")
def test_terms_agreement_round_trip(make_member):
    member = make_member("tm_a", "F", "M")
    path = f"/users/{member.user_id}/agreements/terms"
    current = member.get(path).ok()["agreement"]
    assert current["accepted"] is True and current["terms_version"] == "v1" and current["accepted_at"]
    saved = member.patch(path, {"accepted": True, "terms_version": "v1"}).ok()["agreement"]
    assert saved["accepted"] is True and saved["user_id"] == member.user_id
    assert member.get(f"/auth/signup/workflow/{member.user_id}").ok()["state"] == "completed"


@pytest.mark.case("common.language_picker.use_device_language.api_contract",
                  "common.language_picker.check_circle_rounded_icon_check.api_contract")
def test_language_choice_and_device_language_round_trip(couple):
    a, _, _ = couple
    path = f"/settings/{a.user_id}"
    assert a.patch(path, {"locale": "fr"}).ok()["settings"]["locale"] == "fr"
    assert a.get(path).ok()["settings"]["locale"] == "fr"
    # An empty locale returns the member to the device language.
    assert a.patch(path, {"locale": ""}).ok()["settings"]["locale"] == ""
    assert a.get(path).ok()["settings"]["locale"] == ""


@pytest.mark.parametrize("key", [
    pytest.param("show_age", marks=pytest.mark.case("common.privacy_safety.privacy_show_age.api_contract"), id="show_age"),
    pytest.param("show_exact_distance", marks=pytest.mark.case("common.privacy_safety.privacy_show_exact_distance.api_contract"),
                 id="show_exact_distance"),
    pytest.param("show_online_status", marks=pytest.mark.case("common.privacy_safety.privacy_show_online_status.api_contract"),
                 id="show_online_status"),
])
def test_privacy_toggle_round_trip(couple, key):
    a, _, _ = couple
    path = f"/settings/{a.user_id}"
    before = a.get(path).ok()["settings"][key]
    assert a.patch(path, {key: not before}).ok()["settings"][key] is (not before)
    assert a.get(path).ok()["settings"][key] is (not before)
    assert a.patch(path, {key: before}).ok()["settings"][key] is before


NOTIFICATION_KEYS = [
    ("in_app_notifications_enabled", "common.notification_settings.notifications_in_app.api_contract"),
    ("push_notifications_enabled", "common.notification_settings.notifications_push.api_contract"),
    ("notify_new_match", "common.notification_settings.notifications_new_matches.api_contract"),
    ("notify_new_message", "common.notification_settings.notifications_new_messages.api_contract"),
    ("notify_likes", "common.notification_settings.notifications_likes.api_contract"),
    ("notify_match_nudges", "common.notification_settings.notifications_match_nudges.api_contract"),
    ("notify_incoming_calls", "common.notification_settings.notifications_incoming_calls.api_contract"),
    ("notify_safety", "common.notification_settings.notifications_safety.api_contract"),
    ("notify_friend_plans", "common.notification_settings.notifications_friend_plans.api_contract"),
]


@pytest.mark.parametrize("key", [pytest.param(k, id=k, marks=pytest.mark.case(c)) for k, c in NOTIFICATION_KEYS])
def test_notification_preference_toggle_round_trip(couple, key):
    a, _, _ = couple
    path = f"/notifications/{a.user_id}/preferences"
    assert a.get(path).ok()["preferences"][key] is True, "every category defaults on"
    saved = a.patch(path, {key: False}).ok()["preferences"]
    assert saved[key] is False
    others = {k for k, _ in NOTIFICATION_KEYS if k != key}
    assert all(saved[k] is True for k in others), f"turning off {key} changed another category: {saved}"
    assert a.get(path).ok()["preferences"][key] is False
    assert a.patch(path, {key: True}).ok()["preferences"][key] is True


@pytest.mark.case("engagement.trust_filter.save_trust_filters_onrefresh.api_contract")
def test_trust_filter_is_readable_with_the_badge_catalogue(couple):
    a, _, _ = couple
    body = a.get(f"/discovery/{a.user_id}/filters/trust").ok()
    codes = {b["badge_code"] for b in body["available_badges"]}
    assert {"consistent_profile", "verified_active"} <= codes
    assert all(b["badge_label"] and b["status"] for b in body["available_badges"])
    saved = a.patch(f"/discovery/{a.user_id}/filters/trust", {"enabled": True,
                                                             "required_badge_codes": ["consistent_profile"]}).ok()
    reread = a.get(f"/discovery/{a.user_id}/filters/trust").ok()
    assert reread["trust_filter"]["enabled"] is True, reread.text
    assert reread["trust_filter"]["required_badge_codes"] == saved["trust_filter"]["required_badge_codes"]
    a.patch(f"/discovery/{a.user_id}/filters/trust", {"enabled": False}).ok()


# --- discovery pause and graduation ----------------------------------------------------------

PAUSE_CASES = ("common.privacy_safety.graduation_discovery_pause.api_contract",
               "common.privacy_safety.graduation_discovery_resume.api_contract",
               "intentional_dating.dating_rhythm.pause_introductions.api_contract")


@pytest.mark.case(*PAUSE_CASES)
def test_discovery_pause_hides_the_member_until_resumed(make_member):
    member, viewer = make_member("dp_m", "M", "F"), make_member("dp_v", "F", "M")

    def visible():
        deck = viewer.get(f"/discovery/{viewer.user_id}", params={"limit": 300}).ok()["candidates"]
        return member.user_id in [c.get("id") or c.get("user_id") for c in deck]

    assert member.get(f"/account/{member.user_id}/discovery/pause").ok()["paused"] is False
    assert visible()
    paused = member.post(f"/account/{member.user_id}/discovery/pause", {"reason": "manual"}).ok()
    assert paused["paused"] is True and paused["pause"]["reason"] == "manual" and paused["pause"]["paused_at"]
    state = member.get(f"/account/{member.user_id}/discovery/pause").ok()
    assert state["paused"] is True
    assert not visible(), "a paused member must leave other members' discovery"
    resumed = member.post(f"/account/{member.user_id}/discovery/resume", {}).ok()
    assert resumed["paused"] is False and resumed["pause"]["resumed_at"]
    assert visible()


@pytest.mark.case("graduation.propose_graduation_sheet.graduation_submit.api_contract",
                  "graduation.graduation_banner.graduation_withdraw.api_contract",
                  "graduation.graduation_banner.graduation_decline.api_contract",
                  "graduation.graduation_celebration.graduation_celebration_done.api_contract",
                  "graduation.graduation_banner.graduation_withdraw.api_contract_route",
                  "graduation.graduation_banner.graduation_decline.api_contract_route", *PAUSE_CASES)
def test_graduation_withdraw_then_confirm_pauses_both_members(make_member):
    a, b = make_member("gd_a", "F", "M"), make_member("gd_b", "M", "F")
    match_id = match(a, b)
    base = f"/matches/{match_id}/graduation"
    state = a.get(base).ok()
    assert state["graduated"] is False and state["can_propose"] is True and state["graduation"] is None
    first = a.post(base, {"note": "Shall we close our apps?", "share_with_friends": False}).ok(201)["graduation"]
    assert first["status"] == "proposed" and first["viewer_role"] == "proposer"
    assert b.get(base).ok()["graduation"]["next_action"] == "decide"
    assert b.post(f"{base}/{first['id']}/withdraw").status == 403, "only the proposer withdraws"
    withdrawn = a.post(f"{base}/{first['id']}/withdraw").ok()["graduation"]
    assert withdrawn["status"] == "withdrawn"
    second = a.post(base, {"note": "Trying again \U0001F496"}).ok(201)["graduation"]
    confirmed = b.post(f"{base}/{second['id']}/decision", {"decision": "confirm"}).ok()["graduation"]
    assert confirmed["status"] == "confirmed"
    for member in (a, b):
        after = member.get(base).ok()
        assert after["graduated"] is True and after["discovery_paused"] is True, after.text
        pause = member.get(f"/account/{member.user_id}/discovery/pause").ok()
        assert pause["paused"] is True
        member.post(f"/account/{member.user_id}/discovery/resume", {}).ok()
        assert member.get(f"/account/{member.user_id}/discovery/pause").ok()["paused"] is False


# --- circles, daily prompt, coffee polls, progression ------------------------------------------

@pytest.mark.case("engagement.circle_challenges.circles_join_x.api_contract",
                  "engagement.circle_challenges.submit_entry_onrefresh.api_contract",
                  "engagement.circle_challenges.circles_submit_x.api_contract")
def test_circle_join_weekly_challenge_and_one_entry_per_week(make_member):
    member = make_member("cc_a", "F", "M")
    circle = "circle-blr-fitness"
    joined = member.post(f"/engagement/circles/{circle}/join", {"user_id": member.user_id}).ok()["membership"]
    assert joined["circle_id"] == circle and joined["user_id"] == member.user_id and joined["is_joined"] is True
    state = member.get(f"/engagement/circles/{circle}/challenge").ok()["circle_challenge"]
    challenge = state["challenge"]
    assert state["is_joined"] is True and challenge["circle_id"] == circle and challenge["prompt_text"]
    assert challenge["id"] == f"{circle}-{challenge['week_key']}"
    entry = member.post(f"/engagement/circles/{circle}/challenge/entries", {
        "user_id": member.user_id, "challenge_id": challenge["id"],
        "entry_text": "Ran 5K before work three times."}).ok()
    assert entry["entry"]["challenge_id"] == challenge["id"] and entry["entry"]["user_id"] == member.user_id
    assert entry["circle_challenge"]["user_entry"]["entry_text"] == "Ran 5K before work three times."
    again = member.post(f"/engagement/circles/{circle}/challenge/entries",
                        {"user_id": member.user_id, "entry_text": "A second entry"})
    assert again.status == 409, again.text


@pytest.mark.case("engagement.daily_prompt.update_answer_onrefresh.api_contract",
                  "engagement.daily_prompt.daily_prompt_submit.api_contract")
def test_daily_prompt_answer_edit_and_responders(couple):
    a, b, _ = couple
    prompt = a.get(f"/engagement/daily-prompt/{a.user_id}").ok()["daily_prompt"]
    assert prompt["prompt"]["prompt_text"] and prompt["prompt"]["max_chars"] == 240
    answered = a.post(f"/engagement/daily-prompt/{a.user_id}/answer",
                      {"answer_text": "We take a walk and talk it through."}).ok()["daily_prompt"]
    assert answered["answer"]["answer_text"] == "We take a walk and talk it through."
    assert answered["answer"]["edit_window_until"] and answered["streak"]["current_days"] >= 1
    edited = a.post(f"/engagement/daily-prompt/{a.user_id}/answer",
                    {"answer_text": "A walk, then tea, then we talk."}).ok()["daily_prompt"]
    assert edited["answer"]["answer_text"] == "A walk, then tea, then we talk."
    b.post(f"/engagement/daily-prompt/{b.user_id}/answer", {"answer_text": "A walk helps me too."}).ok()
    responders = a.get(f"/engagement/daily-prompt/{a.user_id}/responders", params={"limit": 50}).ok()
    page = responders["pagination"]
    assert page["prompt_id"] == prompt["prompt"]["id"] and page["limit"] == 50
    assert a.user_id not in [r["user_id"] for r in responders["responders"]], "I am not my own responder"
    assert a.get(f"/engagement/daily-prompt/{a.user_id}").ok()["daily_prompt"]["spark"]["participants_today"] >= 2


@pytest.mark.case("engagement.group_coffee_polls.coffee_create.api_contract", "engagement.group_coffee_polls.coffee_vote.api_contract",
                  "engagement.group_coffee_polls.coffee_finalize_x.api_contract",
                  "engagement.group_coffee_polls.finalize_poll_onrefresh.api_contract",
                  "engagement.group_coffee_polls.coffee_vote.api_contract_route")
def test_coffee_poll_create_vote_and_finalize(make_member):
    a, b, c = make_member("cp_a", "F", "M"), make_member("cp_b", "M", "F"), make_member("cp_c", "F", "M")
    befriend(a, b)
    befriend(a, c)
    poll = a.post("/engagement/group-coffee-polls", {
        "creator_user_id": a.user_id, "participant_user_ids": [b.user_id, c.user_id],
        "options": [{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Indiranagar"},
                    {"day": "Sunday", "time_window": "16:00-18:00", "neighborhood": "Koramangala"}]}).ok()["poll"]
    assert poll["status"] == "open" and poll["creator_user_id"] == a.user_id
    assert set(poll["participant_user_ids"]) == {a.user_id, b.user_id, c.user_id}
    sunday = next(o for o in poll["options"] if o["day"] == "Sunday")
    for voter in (b, c):
        voted = voter.post(f"/engagement/group-coffee-polls/{poll['id']}/votes",
                           {"user_id": voter.user_id, "option_id": sunday["id"]}).ok()["poll"]
    assert next(o for o in voted["options"] if o["id"] == sunday["id"])["votes_count"] == 2
    assert b.get(f"/engagement/group-coffee-polls/{poll['id']}").ok()["poll"]["id"] == poll["id"]
    listed = b.get("/engagement/group-coffee-polls", params={"user_id": b.user_id}).ok()["polls"]
    assert poll["id"] in [p["id"] for p in listed]
    final = a.post(f"/engagement/group-coffee-polls/{poll['id']}/finalize", {"user_id": a.user_id}).ok()
    assert final["poll"]["status"] == "finalized" and final["selected_option"]["id"] == sunday["id"]
    assert final["poll"]["finalized_option_id"] == sunday["id"]


@pytest.mark.case("engagement.level_progression.progression_is_paused_while_an_a_onrefresh.api_contract",
                  "engagement.level_progression.level_retry_retry_2.api_contract",
                  "engagement.level_progression.level_claim_x_claim.api_contract")
def test_progression_state_ledger_and_a_locked_reward(make_member):
    member = make_member("lp_a", "F", "M")
    state = member.get(f"/progression/{member.user_id}").ok()["progression"]
    assert state["current_level"] == 1 and state["level_name"] == "Onboarded"
    assert [lvl["level"] for lvl in state["levels"]][:2] == [1, 2]
    locked = [r for r in state["rewards"] if r["level"] > state["current_level"]]
    assert locked and not any(r["claimed"] for r in locked)
    ledger = member.get(f"/progression/{member.user_id}/ledger").ok()
    assert ledger["count"] == len(ledger["entries"]) >= 1
    assert "profile_completed" in [e["source"] for e in ledger["entries"]]
    claim = member.post(f"/progression/{member.user_id}/rewards/claim", {"reward_key": locked[0]["reward_key"]},
                        headers={"Idempotency-Key": f"e2e-{uuid.uuid4()}"})
    assert claim.status == 409 and "level" in claim["error"], claim.text
    after = member.get(f"/progression/{member.user_id}").ok()["progression"]
    assert not any(r["claimed"] for r in after["rewards"] if r["reward_key"] == locked[0]["reward_key"])


# --- matches: nudges, voice icebreakers, mini activities, calls, gifts ------------------------------

@pytest.mark.case("engagement.match_nudges.nudges_send_x.api_contract", "matching.matches_list.matches_nudge_action.api_contract",
                  "matching.matches_list.matches_match_row_x_options.api_contract",
                  "matching.matches_list.matches_person_x_options_options.api_contract")
def test_match_nudge_send_and_click(make_member):
    a, b = make_member("mn_a", "F", "M"), make_member("mn_b", "M", "F")
    match_id = match(a, b)
    nudge = a.post("/engagement/match-nudges/send", {"match_id": match_id, "user_id": a.user_id,
                                                      "counterparty_user_id": b.user_id}).ok()["nudge"]
    assert nudge["match_id"] == match_id and nudge["user_id"] == a.user_id
    assert nudge["counterparty_user_id"] == b.user_id and nudge["nudge_type"] == "stalled_24h" and nudge["sent_at"]
    clicked = a.post(f"/engagement/match-nudges/{nudge['id']}/click", {"user_id": a.user_id}).ok()["nudge"]
    assert clicked["clicked_at"]
    assert b.post(f"/engagement/match-nudges/{nudge['id']}/click", {"user_id": b.user_id}).status == 403
    a.post("/engagement/match-nudges/send", {"match_id": match_id, "user_id": a.user_id,
                                              "counterparty_user_id": b.user_id}).ok()
    third = a.post("/engagement/match-nudges/send", {"match_id": match_id, "user_id": a.user_id,
                                                      "counterparty_user_id": b.user_id})
    assert third.status == 429, f"at most two nudges per UTC day: {third.status} {third.text[:200]}"


@pytest.mark.case("engagement.voice_icebreakers.voice_reload_prompts.api_contract",
                  "engagement.voice_icebreakers.voice_share.api_contract",
                  "engagement.voice_icebreakers.voice_listen_x.api_contract")
def test_voice_icebreaker_start_send_and_play(make_member):
    a, b = make_member("vo_a", "F", "M"), make_member("vo_b", "M", "F")
    match_id = match(a, b)
    prompts = a.get("/engagement/voice-icebreakers/prompts").ok()["prompts"]
    assert prompts and prompts[0]["id"] and prompts[0]["prompt_text"]
    started = a.post("/engagement/voice-icebreakers/start", {
        "match_id": match_id, "sender_user_id": a.user_id, "receiver_user_id": b.user_id,
        "prompt_id": prompts[0]["id"]}).ok()["voice_icebreaker"]
    assert started["status"] == "started" and started["has_audio"] is False
    sent = a.api.call("POST", f"/engagement/voice-icebreakers/{started['id']}/send", files={
        "audio": ("hello.wav", _wav(), "audio/wav"), "sender_user_id": (None, a.user_id),
        "transcript": (None, "Hi! A calm Sunday is coffee and a long walk."), "duration_seconds": (None, "25")})
    if sent.status == 422:
        pytest.fail(f"voice moderation did not approve the recording on this stack: {sent.text[:200]}")
    sent = sent.ok()["voice_icebreaker"]
    assert sent["status"] == "sent" and sent["has_audio"] is True and sent["duration_seconds"] == 25
    played = b.post(f"/engagement/voice-icebreakers/{started['id']}/play", {"user_id": b.user_id}).ok()["voice_icebreaker"]
    assert played["audio_url"] and played["audio_expires_at"] and played["play_count"] >= 1
    again = a.post("/engagement/voice-icebreakers/start", {"match_id": match_id, "sender_user_id": a.user_id,
                                                            "receiver_user_id": b.user_id})
    assert again.status == 409, "one voice icebreaker per match and sender per UTC day"


@pytest.mark.case("matching.activity_session.activity_restart.api_contract",
                  "matching.activity_session.activity_submit.api_contract",
                  "matching.activity_session.activity_time_up_load.api_contract",
                  "matching.activity_session.activity_refresh_summary.api_contract")
def test_mini_activity_start_submit_and_summary(couple):
    a, b, match_id = couple
    session = a.post("/activities/sessions/start", {"match_id": match_id, "initiator_user_id": a.user_id,
                                                    "participant_user_id": b.user_id,
                                                    "activity_type": "co_op_prompt"}).ok()["session"]
    assert session["status"] == "active" and set(session["participant_user_ids"]) >= {a.user_id, b.user_id}
    a.post(f"/activities/sessions/{session['id']}/submit", {"user_id": a.user_id, "responses": ["Pancakes"]}).ok()
    done = b.post(f"/activities/sessions/{session['id']}/submit", {"user_id": b.user_id,
                                                                   "responses": ["Waffles"]}).ok()["session"]
    assert done["status"] == "completed", done
    summary = a.get(f"/activities/sessions/{session['id']}/summary").ok()
    assert summary["summary"]["session_id"] == session["id"]
    assert summary["summary"]["responses_submitted"] == 2 and summary["summary"]["participants_pending"] == 0
    assert b.post(f"/activities/sessions/{session['id']}/submit", {"user_id": b.user_id,
                                                                    "responses": ["again"]}).status == 409


@pytest.mark.case("calls.call_history.join_live_room_onrefresh.api_contract", "calls.call_session.calls_try_again.api_contract",
                  "calls.call_session.calls_end.api_contract")
def test_call_start_end_and_history(couple):
    a, b, match_id = couple
    started = a.post("/calls/start", {"match_id": match_id, "initiator_user_id": a.user_id,
                                      "recipient_user_id": b.user_id}).ok()
    call = started["session"]
    assert started["accepted"] is True and call["status"] == "started" and call["match_id"] == match_id
    assert call["initiator_id"] == a.user_id and call["recipient_id"] == b.user_id
    ended = b.post(f"/calls/{call['id']}/end", {"ended_by_user_id": b.user_id}).ok()["session"]
    assert ended["status"] == "ended" and ended["ended_by_user_id"] == b.user_id and ended["ended_at"]
    again = a.post(f"/calls/{call['id']}/end", {"ended_by_user_id": a.user_id}).ok()["session"]
    assert again["ended_by_user_id"] == b.user_id, "ending twice keeps the first ending"
    for member in (a, b):
        history = member.get(f"/calls/history/{member.user_id}").ok()["history"]
        assert call["id"] in [h["id"] for h in history]


@pytest.mark.billing
@pytest.mark.case("messaging.chat.chat_sidebar_gift_gift.api_contract", "messaging.chat.chat_gift_tray_button_gift.api_contract",
                  "messaging.chat.chat_gift_tray_close.api_contract")
def test_gift_tray_telemetry_events_are_accepted(couple):
    a, _, match_id = couple
    for event in ("gift_panel_opened", "gift_preview_opened", "gift_send_attempted", "gift_send_failed"):
        response = a.post(f"/chat/{match_id}/gifts/events", {"event_name": event, "user_id": a.user_id,
                                                             "gift_id": "rose_red_single"})
        assert response.status == 202 and response["accepted"] is True, f"{event}: {response.text}"


@pytest.mark.billing
@pytest.mark.safety
@pytest.mark.case("messaging.chat.chat_gift_receiver_actions_giftactions.api_contract",
                  "messaging.chat.chat_message_x_longpress.api_contract")
def test_receiver_hides_a_gift_from_their_chat(make_member):
    a, b = make_member("gh_a", "F", "M"), make_member("gh_b", "M", "F")
    match_id = match(a, b)
    gift = a.post(f"/chat/{match_id}/gifts/send", {"gift_id": "rose_red_single", "sender_user_id": a.user_id}).ok()
    message_id = gift["message"]["id"]
    assert message_id in [m["id"] for m in b.get(f"/chat/{match_id}/messages").ok()["messages"]]
    hidden = b.post(f"/chat/{match_id}/messages/{message_id}/gift/hide").ok()
    assert hidden.get("hidden") is True or hidden.status == 200
    assert message_id not in [m["id"] for m in b.get(f"/chat/{match_id}/messages").ok()["messages"]]
    assert message_id in [m["id"] for m in a.get(f"/chat/{match_id}/messages").ok()["messages"]], \
        "hiding is the receiver's choice; the sender's history is unchanged"
    assert b.post(f"/chat/{match_id}/messages/{message_id}/gift/hide").status in (200, 409)


# --- billing (sandbox provider only; no real money moves) -----------------------------------------

BILLING_READ_CASES = ("payment.subscription.your_plan_renews_automatically_a_onrefresh.api_contract",
                      "payment.subscription.payment_check_status_x_check.api_contract",
                      "payment.subscription.payment_resume_checkout_x_resume.api_contract",
                      "web.web_membership_page.retry.api_contract")


@pytest.mark.billing
@pytest.mark.case(*BILLING_READ_CASES)
def test_billing_state_reads_for_a_free_member(make_member):
    member = make_member("bl_r", "F", "M")
    plans = Api().get("/billing/plans").ok()["plans"]
    ids = [p["id"] for p in plans]
    assert "free" in ids and len(ids) > 1 and all(p["name"] for p in plans)
    sub = member.get(f"/billing/subscription/{member.user_id}").ok()["subscription"]
    assert sub["plan_id"] == "free" and sub["is_paid"] is False and sub["status"] == "active"
    assert sub["auto_renew"] is False and sub["entitled"] is True
    assert member.get(f"/billing/payments/{member.user_id}").ok()["payments"] == []
    account = member.get("/billing/account").ok()["account"]
    assert account["user_id"] == member.user_id and account["provider"] and account["mode"] in ("sandbox", "test", "disabled", "live")
    assert isinstance(account["pending_checkouts"], list)


def _sandbox_pay(checkout_url: str, card: str = "4242424242424242") -> requests.Response:
    session_id = urlparse(checkout_url).path.rstrip("/").rsplit("/", 1)[-1]
    return requests.post(f"{API_BASE}/billing/sandbox/checkout/{session_id}",
                         data={"card_number": card, "exp_month": "12", "exp_year": "2035", "cvc": "123",
                               "name": "E2E Sandbox"}, allow_redirects=False, timeout=20)


@pytest.mark.billing
@pytest.mark.case("payment.subscription.membership_plan_x_subscribe.api_contract",
                  "payment.subscription.membership_update_card_updatecard.api_contract",
                  "payment.wallet_payment.wallet_buy_x_buy.api_contract",
                  "payment.subscription.membership_auto_renew_autorenewchanged.api_contract",
                  "payment.subscription.membership_plan_x_switch.api_contract",
                  "payment.subscription.membership_sandbox_x_event.api_contract", *BILLING_READ_CASES)
def test_sandbox_subscription_auto_renew_plan_switch_and_renewal(make_member):
    member = make_member("bl_s", "F", "M")
    if member.get("/billing/coin-packages").ok().get("mode") != "sandbox":
        pytest.skip("billing provider is not the sandbox; refusing to touch a real provider")
    base = f"/billing/subscription/{member.user_id}"
    assert member.post(f"{base}/cancel").status == 404, "a free member has no auto-renew to change"
    assert member.post(f"{base}/resume").status == 404
    checkout = member.post("/billing/checkout", {"plan_id": "bronze", "billing_cycle": "monthly"},
                           headers={"Idempotency-Key": f"e2e-{uuid.uuid4()}"}).ok(201)["checkout"]
    assert checkout["kind"] == "subscription" and checkout["plan_code"] == "bronze"
    pending = member.get(f"/billing/checkout/{checkout['id']}").ok()["checkout"]
    assert pending["id"] == checkout["id"] and pending["user_id"] == member.user_id and pending["status"] != "completed"
    paid = _sandbox_pay(checkout["checkout_url"])
    assert paid.status_code == 303 and "status=success" in paid.headers.get("Location", ""), paid.text[:200]
    completed = member.get(f"/billing/checkout/{checkout['id']}").ok()["checkout"]
    assert completed["status"] == "completed" and completed["completed_at"]
    sub = member.get(base).ok()["subscription"]
    assert sub["plan_id"] == "bronze" and sub["is_paid"] is True and sub["auto_renew"] is True
    try:
        off = member.post(f"{base}/cancel").ok()["subscription"]
        assert off["auto_renew"] is False and off["cancel_at_period_end"] is True
        on = member.post(f"{base}/resume").ok()["subscription"]
        assert on["auto_renew"] is True and on["cancel_at_period_end"] is False
        switched = member.post(f"{base}/change-plan", {"plan_id": "silver", "billing_cycle": "monthly"}).ok()["subscription"]
        assert switched["plan_id"] == "silver"
        assert member.post(f"{base}/change-plan", {"plan_id": "silver", "billing_cycle": "monthly"}).status == 409
        before = len(member.get(f"/billing/payments/{member.user_id}").ok()["payments"])
        renewed = member.post(f"/billing/sandbox/subscriptions/{member.user_id}/simulate", {"event": "renewal_paid"}).ok()
        assert renewed["subscription"]["status"] == "active"
        assert len(member.get(f"/billing/payments/{member.user_id}").ok()["payments"]) > before
        assert member.post(f"/billing/sandbox/subscriptions/{member.user_id}/simulate",
                           {"event": "free_money"}).status == 400
    finally:
        member.post(f"{base}/cancel")


# --- date plan sharing ---------------------------------------------------------------------------

@pytest.mark.case("plans.plan_sharing_sheet.plan_sharing_reload.api_contract",
                  "plans.plan_sharing_sheet.plan_sharing_save.api_contract",
                  "plans.plans.nothing_shared_yet_onrefresh.api_contract",
                  "plans.plans.no_plans_yet_onrefresh.api_contract")
def test_date_plan_shared_with_a_trusted_friend(make_member):
    a, b, friend = make_member("ps_a", "F", "M"), make_member("ps_b", "M", "F"), make_member("ps_f", "F", "M")
    match_id = match(a, b)
    befriend(a, friend)
    assert friend.get(f"/friends/{friend.user_id}/plans").ok()["plans"] == []
    start = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=3)).replace(microsecond=0)
    plan = a.post(f"/matches/{match_id}/plans", {
        "window_start": start.isoformat().replace("+00:00", "Z"),
        "window_end": (start + dt.timedelta(hours=2)).isoformat().replace("+00:00", "Z"),
        "venue_category": "coffee", "venue_name": "Corner Café"}).ok(201)["plan"]
    base = f"/matches/{match_id}/plans/{plan['id']}/sharing"
    try:
        empty = a.get(base).ok()
        assert empty["contact_ids"] == [] and empty["version"] == 0
        shared = a.post(base, {"contact_ids": [friend.user_id], "expected_version": 0}).ok()
        assert shared["contact_ids"] == [friend.user_id] and shared["version"] == 1
        assert [c["id"] for c in shared["contacts"]] == [friend.user_id]
        assert a.get(base).ok()["contact_ids"] == [friend.user_id]
        assert plan["id"] in str(friend.get(f"/friends/{friend.user_id}/plans").ok().body), \
            "a trusted friend sees the plan shared with them"
        assert a.post(base, {"contact_ids": [], "expected_version": 0}).status == 409
        cleared = a.post(base, {"contact_ids": [], "expected_version": 1}).ok()
        assert cleared["contact_ids"] == [] and cleared["version"] == 2
    finally:
        a.post(f"/matches/{match_id}/plans/{plan['id']}/cancel", {"reason": "e2e cleanup"})


# --- safety, profile views, verification ------------------------------------------------------------

@pytest.mark.safety
@pytest.mark.case("safety.sos.safety_activate_sos.api_contract", "safety.sos.resolution_note_onrefresh.api_contract")
def test_sos_alert_is_raised_and_listed_for_its_owner(make_member):
    """Raises one low-level alert for a fresh member with no emergency contacts or matches
    (local stack only). Members cannot resolve alerts; operators do, via /admin."""
    member = make_member("sos_r", "F", "M")
    assert member.get(f"/safety/sos/{member.user_id}").ok()["alerts"] == []
    raised = member.post("/safety/sos", {"user_id": member.user_id, "emergency_level": "low",
                                         "message": "E2E automated contract check - no action needed"}).ok()
    alert = raised["alert"]
    assert raised["accepted"] is True and alert["status"] == "active" and alert["emergency_level"] == "low"
    assert alert["user_id"] == member.user_id and alert["triggered_at"]
    listed = member.get(f"/safety/sos/{member.user_id}").ok()["alerts"]
    assert [a["id"] for a in listed] == [alert["id"]]


@pytest.mark.case("swipe.home_discovery.today_profile_x_openprofile.api_contract",
                  "swipe.home_discovery.spotlight_rail_row_x_openspotlightprofile.api_contract",
                  "swipe.home_discovery.discover_today_card_x_opentodayprofile.api_contract",
                  "swipe.home_discovery.discover_today_card_x_openprofile.api_contract",
                  "swipe.home_discovery.spotlight_rail_card_x_openprofile.api_contract",
                  "swipe.home_discovery.x_view_more_button_openprofile.api_contract",
                  "swipe.liked_me.liked_me_open_x_open.api_contract",
                  "profile.profile_view.profile_who_viewed.api_contract",
                  "profile.profile_view.who_viewed_my_profile.api_contract")
def test_opening_a_profile_records_a_view_the_owner_can_see(make_member):
    viewer, owner = make_member("pv_v", "F", "M"), make_member("pv_o", "M", "F")
    assert viewer.post("/profile/views", {"viewer_user_id": viewer.user_id,
                                          "viewed_user_id": owner.user_id}).ok()["success"] is True
    assert viewer.post("/profile/views", {"viewer_user_id": viewer.user_id,
                                          "viewed_user_id": viewer.user_id}).ok()["success"] is True

    def viewers():
        body = owner.get(f"/profile/{owner.user_id}/viewers").ok().body
        rows = body.get("viewers") or body.get("items") or []
        return [r.get("viewer_user_id") or r.get("user_id") for r in rows]

    assert wait_for(lambda: viewer.user_id in viewers(), timeout=10), viewers()
    assert viewer.user_id not in [r for r in (viewer.get(f"/profile/{viewer.user_id}/viewers").ok().body.get("viewers") or [])
                                  if r == viewer.user_id], "a self-view is not recorded"


@pytest.mark.safety
@pytest.mark.case("verification.verification_selfie.verification_selfie_submit_button.api_contract")
def test_identity_verification_submission_goes_to_review(make_member):
    member = make_member("idv_a", "F", "M")
    assert member.get(f"/verification/{member.user_id}").ok()["status"] in ("unverified", "not_submitted", "none", "")
    submitted = member.api.call("POST", f"/verification/{member.user_id}/submit", files={
        "id_document": ("id.png", png_bytes((20, 40, 60)), "image/png"),
        "selfie": ("selfie.png", png_bytes((60, 40, 20)), "image/png")}).ok()
    assert submitted["accepted"] is True and submitted["evidence_received"] is True
    assert submitted["status"] in ("pending", "verified") and submitted["submitted_at"]
    assert member.get(f"/verification/{member.user_id}").ok()["status"] == submitted["status"]


# --- flag-gated routes ---------------------------------------------------------------------------------

SUPPORT_CASES = ("common.help_support.if_someone_is_in_immediate_dange_onrefresh.api_contract",
                 "support.support_ticket_form.submit_support_ticket.api_contract",
                 "support.support_ticket_form.support_add_screenshot.api_contract",
                 "support.support_widgets.retry_upload.api_contract",
                 "support.support_ticket_thread.try_again.api_contract",
                 "support.support_ticket_thread.try_again_onrefresh.api_contract",
                 "support.support_ticket_thread.support_close_close.api_contract",
                 "support.support_ticket_thread.support_rating_submit_rate.api_contract",
                 "support.support_ticket_thread.support_reopen_reopen.api_contract",
                 "site.contact.api_contract")


@pytest.mark.flags
@pytest.mark.case(*SUPPORT_CASES)
def test_support_ticket_lifecycle(make_member):
    """With support_ticketing_enabled on: create, upload, read, close, rate and reopen a ticket.
    While the flag is off (the local default) every route answers 403 FEATURE_DISABLED."""
    member = make_member("sup_a", "F", "M")
    if not _flags(member).get("support_ticketing_enabled", False):
        for method, path, body in (("GET", "/support/tickets", None),
                                   ("POST", f"/support/tickets/{uuid.uuid4()}/close", {}),
                                   ("POST", f"/support/tickets/{uuid.uuid4()}/rating", {"rating": 5}),
                                   ("POST", f"/support/tickets/{uuid.uuid4()}/reopen", {})):
            gated = member.api.call(method, path, json=body)
            assert gated.status == 403 and gated["error_code"] == "FEATURE_DISABLED", gated.text
            assert gated["feature_flag"] == "support_ticketing_enabled"
        return
    upload = member.api.call("POST", "/support/attachments", files={"file": ("s.png", png_bytes(), "image/png")}).ok(201)
    created = member.post("/support/tickets", {"category": "technical", "subject": "E2E app question",
                                               "description": "Automated contract check, please ignore.",
                                               "attachment_ids": [upload["attachment"]["id"]]}).ok(200, 201)
    ticket = created["ticket"]
    assert ticket["status"] and ticket["reference"]
    assert ticket["id"] in [t["id"] for t in member.get("/support/tickets").ok()["tickets"]]
    assert member.get(f"/support/tickets/{ticket['id']}").ok()["ticket"]["id"] == ticket["id"]
    closed = member.post(f"/support/tickets/{ticket['id']}/close").ok()["ticket"]
    assert closed["status"] == "closed"
    rated = member.post(f"/support/tickets/{ticket['id']}/rating", {"rating": 5, "comment": "e2e"}).ok()["ticket"]
    assert rated["satisfaction"]["rating"] == 5
    reopened = member.post(f"/support/tickets/{ticket['id']}/reopen", {"reason": "e2e reopen"}).ok()["ticket"]
    assert reopened["status"] not in ("closed", "resolved")


CITY_PILOT_CASES = ("city_pilot.city_pilot.city_pilot_join.api_contract",
                    "city_pilot.city_pilot.city_pilot_leave.api_contract",
                    "city_pilot.city_pilot.city_pilot_cancel_event.api_contract",
                    "city_pilot.city_pilot.city_pilot_reserve_event.api_contract",
                    "city_pilot.city_pilot.city_pilot_feedback_event.api_contract")


@pytest.mark.flags
@pytest.mark.case(*CITY_PILOT_CASES)
def test_city_pilot_member_state_and_routes_without_a_running_pilot(make_member):
    """No pilot can be opened through the API inside a run (stage gates need real dates and an
    operator), so this asserts the member contract against the stack's real state: the member view,
    and that membership, booking and feedback calls for pilots/events that do not exist are 404."""
    member = make_member("pil_a", "F", "M")
    state = member.get("/city-pilot").ok()
    assert set(state.body) >= {"pilot", "membership", "can_join", "experiences"}
    assert state["membership"] in ("none", "joined", "withdrawn") and isinstance(state["experiences"], list)
    if not _flags(member).get("city_pilot_enabled", False):
        assert state["can_join"] is False and all(not e.get("can_register") for e in state["experiences"])
    ghost = str(uuid.uuid4())
    assert member.post("/city-pilot/membership", {"pilot_id": ghost, "consent_version": "city-pilot-v1"}).status == 404
    assert member.post("/city-pilot/membership", {"pilot_id": ghost, "consent_version": "v0"}).status in (400, 404)
    assert member.delete("/city-pilot/membership", {"pilot_id": ghost}).status == 404
    assert member.post(f"/city-pilot/events/{ghost}/registration", {"safety_terms_accepted": True}).status == 404
    assert member.delete(f"/city-pilot/events/{ghost}/registration").status == 404
    assert member.post(f"/city-pilot/events/{ghost}/feedback", {"attended": True, "worthwhile": True}).status == 404
    assert member.get("/city-pilot").ok()["membership"] == state["membership"]


# --- room host warning --------------------------------------------------------------------------------

@pytest.mark.case("engagement.room_chat.room_member_warn.api_contract", "engagement.room_chat.room_chat_menu.api_contract")
def test_room_host_warns_a_participant(make_member):
    host, guest = make_member("rw_h", "F", "M"), make_member("rw_g", "M", "F")
    room = host.post("/rooms", {"title": "E2E warn room", "category": "talk", "duration_minutes": 30}).ok(201)["room"]
    try:
        guest.post(f"/rooms/{room['id']}/join", {"user_id": guest.user_id}).ok()
        warned = host.post(f"/rooms/{room['id']}/moderate", {"target_user_id": guest.user_id, "action": "warn",
                                                             "reason": "please keep it kind"}).ok()
        action = warned["moderation_action"]
        assert action["action"] == "warn_user" and action["target_user_id"] == guest.user_id
        assert action["moderator_user_id"] == host.user_id and action["reason"] == "please keep it kind"
        members = {m["user_id"] for m in host.get(f"/rooms/{room['id']}/members").ok()["members"]}
        assert guest.user_id in members, "a warning does not remove the participant"
        assert guest.post(f"/rooms/{room['id']}/moderate", {"target_user_id": host.user_id,
                                                           "action": "warn"}).status == 403
    finally:
        host.post(f"/rooms/{room['id']}/moderate", {"action": "close", "reason": "e2e cleanup"})
