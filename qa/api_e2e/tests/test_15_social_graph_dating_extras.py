"""Friend-request rules, vouches, friend intros, date plans, graduation and the
conversation copilot.

Friend rules (friend_requests.go): never downgrade, crossing requests accept,
7-day cooldown for a declined requester only, 30 requests per rolling 24h
(cancelling does not give one back).
"""

from __future__ import annotations

import datetime as dt
import uuid

import pytest

from journeys import befriend, match


pytestmark = pytest.mark.journey("social_graph")


def _request(a, b, source="search"):
    return a.post(f"/friends/{a.user_id}", {"friend_user_id": b.user_id if hasattr(b, "user_id") else b,
                                            "source": source})


def _decide(me, requester, decision):
    return me.post(f"/friends/{me.user_id}/{requester.user_id}/decision", {"decision": decision})


def _status(me, other):
    rows = [f for f in me.get(f"/friends/{me.user_id}").ok()["friends"] if f["friend_user_id"] == other.user_id]
    return rows[0]["status"] if rows else None


# --- friend request rules -----------------------------------------------------------

def test_request_to_an_existing_friend_never_downgrades(make_member):
    a, b = make_member("fr2_a", "F", "M"), make_member("fr2_b", "M", "F")
    befriend(a, b)
    again = _request(a, b).ok()
    assert again["friend"]["status"] == "accepted"
    assert _request(b, a).ok()["friend"]["status"] == "accepted"
    assert _status(a, b) == _status(b, a) == "accepted"


def test_asking_someone_who_asked_you_accepts(make_member):
    a, b = make_member("fr2_c", "F", "M"), make_member("fr2_d", "M", "F")
    assert _request(a, b).ok()["friend"]["status"] == "pending"
    assert _request(b, a).ok()["friend"]["status"] == "accepted"
    assert _status(a, b) == "accepted"


def test_decline_cooldown_applies_to_the_declined_requester_only(make_member):
    a, b = make_member("fr2_e", "F", "M"), make_member("fr2_f", "M", "F")
    _request(a, b).ok()
    _decide(b, a, "decline").ok()
    retry = _request(a, b)
    assert retry.status == 429, retry.text
    # The member who declined may still reach out.
    reverse = _request(b, a).ok()
    assert reverse["friend"]["status"] == "pending"
    _decide(a, b, "accept").ok()
    assert _status(a, b) == "accepted"


def test_cancelling_your_own_request_has_no_cooldown(make_member):
    a, b = make_member("fr2_g", "F", "M"), make_member("fr2_h", "M", "F")
    _request(a, b).ok()
    a.delete(f"/friends/{a.user_id}/{b.user_id}").ok()
    assert _status(b, a) is None
    assert _request(a, b).ok()["friend"]["status"] == "pending"


def test_removing_an_incoming_request_counts_as_a_decline(make_member):
    a, b = make_member("fr2_i", "F", "M"), make_member("fr2_j", "M", "F")
    _request(a, b).ok()
    b.delete(f"/friends/{b.user_id}/{a.user_id}").ok()
    assert _request(a, b).status == 429


def test_decisions_on_requests_that_are_not_open(make_member):
    a, b = make_member("fr2_k", "F", "M"), make_member("fr2_l", "M", "F")
    _request(a, b).ok()
    assert _decide(a, b, "accept").status == 404, "accepting your own outgoing request"
    _decide(b, a, "accept").ok()
    assert _decide(b, a, "accept").status == 404, "accepting twice"
    assert _decide(b, a, "decline").status == 404


@pytest.mark.parametrize("target", [str(uuid.uuid4()), "not-a-uuid", ""])
def test_requests_to_unknown_members(make_member, target):
    a = getattr(test_requests_to_unknown_members, "member", None) or make_member("fr2_u", "F", "M")
    test_requests_to_unknown_members.member = a
    response = _request(a, target)
    assert response.status in (400, 404), response.text


@pytest.mark.quota
def test_thirty_friend_requests_per_day(make_member):
    a, b = make_member("fr2_q", "F", "M"), make_member("fr2_r", "M", "F")
    for n in range(30):
        sent = _request(a, b)
        assert sent.status == 200, f"request {n + 1}: {sent.status} {sent.text[:200]}"
        a.delete(f"/friends/{a.user_id}/{b.user_id}").ok()
    over = _request(a, b)
    assert over.status == 429 and "30" in over["error"], over.text


# --- vouches ------------------------------------------------------------------------------

def test_vouch_lifecycle(make_member):
    a, b, c = make_member("vo_a", "F", "M"), make_member("vo_b", "M", "F"), make_member("vo_c", "F", "M")
    befriend(a, b)
    base = f"/friends/{a.user_id}/vouches"
    assert a.post(base, {"for_user_id": b.user_id, "text": "too short"}).status == 400
    assert a.post(base, {"for_user_id": b.user_id, "text": "x" * 201}).status == 400
    assert a.post(base, {"for_user_id": a.user_id, "text": "I am great company, honestly."}).status == 400
    stranger = c.post(f"/friends/{c.user_id}/vouches", {"for_user_id": b.user_id,
                                                         "text": "Never met him but he seems kind."})
    assert stranger.status == 409 and stranger["error_code"] == "FRIEND_REQUIRED", stranger.text
    vouch = a.post(base, {"for_user_id": b.user_id, "text": "Kind, punctual and very funny."})
    assert vouch.status == 201, vouch.text
    vouch_id = vouch["vouch"]["id"]
    dup = a.post(base, {"for_user_id": b.user_id, "text": "Saying it twice to be sure."})
    assert dup.status == 409 and dup["error_code"] == "VOUCH_EXISTS"
    def public_texts():
        return [v.get("text") for v in c.get(f"/users/{b.user_id}/vouches").ok()["vouches"]]

    assert "Kind, punctual and very funny." not in public_texts(), "pending vouches must not be public"
    assert a.post(f"/friends/{a.user_id}/vouches/{vouch_id}/decision", {"decision": "approve"}).status in (403, 404)
    b.post(f"/friends/{b.user_id}/vouches/{vouch_id}/decision", {"decision": "approve"}).ok()
    assert "Kind, punctual and very funny." in public_texts()
    a.delete(f"/friends/{a.user_id}/vouches/{vouch_id}").ok()
    assert "Kind, punctual and very funny." not in public_texts()


# --- friend intros ---------------------------------------------------------------------------

def _allow_intros(member, allow=True):
    base = f"/account/{member.user_id}/dating-preferences"
    current = member.get(base).ok()["preferences"]
    member.put(base, {**{k: current[k] for k in ("intent", "pace", "activities", "share_pace",
                                                  "share_availability", "availability")},
                      "allow_friend_intros": allow, "version": current["version"]}).ok()


def test_friend_intro_needs_consent_then_both_accepts_make_a_match(make_member):
    host = make_member("in_h", "F", "M")
    x, y = make_member("in_x", "F", "M"), make_member("in_y", "M", "F")
    befriend(host, x)
    befriend(host, y)
    base = f"/friends/{host.user_id}/intros"
    body = {"first_user_id": x.user_id, "second_user_id": y.user_id, "message": "You both love trails!"}
    no_consent = host.post(base, body)
    assert no_consent.status == 409 and no_consent["error_code"] in ("INTRO_UNAVAILABLE", "FRIEND_REQUIRED"), no_consent.text
    assert host.post(base, {**body, "second_user_id": host.user_id}).status == 400
    _allow_intros(x)
    _allow_intros(y)
    intro = host.post(base, body)
    assert intro.status == 201, intro.text
    intro_id = intro["intro"]["id"]
    assert host.post(base, body).status == 409, "a second open intro for the same pair"
    assert host.post(f"/friends/{host.user_id}/intros/{intro_id}/decision", {"decision": "accept"}).status == 403
    x.post(f"/friends/{x.user_id}/intros/{intro_id}/decision", {"decision": "accept"}).ok()
    y.post(f"/friends/{y.user_id}/intros/{intro_id}/decision", {"decision": "accept"}).ok()
    assert y.user_id in [m["userId"] for m in x.get(f"/matches/{x.user_id}").ok()["matches"]]


# --- date plans ------------------------------------------------------------------------------

def _window(days=2, hours=2):
    start = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=days)).replace(microsecond=0)
    return start.isoformat().replace("+00:00", "Z"), (start + dt.timedelta(hours=hours)).isoformat().replace("+00:00", "Z")


def test_date_plan_state_machine(make_member):
    a, b = make_member("dp_a", "F", "M"), make_member("dp_b", "M", "F")
    match_id = match(a, b)
    base = f"/matches/{match_id}/plans"
    start, end = _window()
    for bad in ({"window_start": start, "window_end": end, "venue_category": "nightclub"},
                {"window_start": end, "window_end": start, "venue_category": "coffee"},
                {"window_start": _window(hours=13)[0], "window_end": _window(hours=13)[1], "venue_category": "coffee"},
                {"window_start": _window(days=120)[0], "window_end": _window(days=120)[1], "venue_category": "coffee"},
                {"window_start": start, "window_end": end, "venue_category": "coffee", "note": "n" * 281}):
        assert a.post(base, bad).status == 400, bad
    plan = a.post(base, {"window_start": start, "window_end": end, "venue_category": "coffee",
                         "venue_name": "Corner Café ☕", "note": "<b>see you</b>"})
    assert plan.status == 201, plan.text
    plan = plan["plan"]
    again = a.post(base, {"window_start": start, "window_end": end, "venue_category": "walk"})
    assert again.status == 409 and again["error_code"] == "DATE_PLAN_ALREADY_OPEN"
    assert a.post(f"{base}/{plan['id']}/decision", {"decision": "accept"}).status == 403
    assert b.post(f"{base}/{plan['id']}/decision", {"decision": "maybe"}).status == 400
    decided = b.post(f"{base}/{plan['id']}/decision", {"decision": "accept",
                                                       "expected_version": plan.get("lock_version", 0)})
    assert decided.status == 200, decided.text
    early = a.post(f"{base}/{plan['id']}/checkin", {"status": "safe"})
    assert early.status == 409 and early["error_code"] == "DATE_PLAN_CHECKIN_TOO_EARLY"
    debrief = a.post(f"{base}/{plan['id']}/debrief", {"happened": True})
    assert debrief.status == 409 and debrief["error_code"] == "DATE_PLAN_DEBRIEF_TOO_EARLY"
    assert plan["id"] in str(a.get(f"/plans/{a.user_id}").ok().body)
    a.post(f"{base}/{plan['id']}/cancel", {"reason": "e2e cleanup"}).ok()
    gone = b.post(f"{base}/{plan['id']}/cancel", {"reason": "again"})
    assert gone.status == 409 and gone["error_code"] == "DATE_PLAN_NOT_OPEN"


# --- graduation and copilot -------------------------------------------------------------------

def test_graduation_propose_decline_withdraw(make_member):
    a, b = make_member("gr2_a", "F", "M"), make_member("gr2_b", "M", "F")
    match_id = match(a, b)
    base = f"/matches/{match_id}/graduation"
    assert a.post(base, {"note": "n" * 201}).status == 400
    grad = a.post(base, {"note": "Shall we close our apps? \U0001F496", "share_with_friends": False})
    assert grad.status == 201, grad.text
    gid = grad["graduation"]["id"]
    assert a.post(base, {"note": "again"}).status == 409
    assert a.post(f"{base}/{gid}/decision", {"decision": "confirm"}).status == 403
    assert b.post(f"{base}/{gid}/decision", {"decision": "perhaps"}).status == 400
    b.post(f"{base}/{gid}/decision", {"decision": "decline"}).ok()
    assert a.post(f"{base}/{gid}/withdraw").status == 409
    assert a.get(base).ok()["graduated"] is False


def test_copilot_draft_rules(make_member):
    a, b = make_member("cp_a", "F", "M"), make_member("cp_b", "M", "F")
    match_id = match(a, b)
    base = f"/matches/{match_id}/copilot/draft"
    assert a.post(base, {"kind": "love_letter"}).status == 400
    assert a.post(base, {"kind": "opener", "tone": "sarcastic"}).status == 400
    draft = a.post(base, {"kind": "opener", "tone": "warm"})
    if draft.status in (409, 503):
        pytest.skip(f"copilot provider unavailable locally: {draft.text[:120]}")
    assert draft.status == 200, draft.text
    assert draft["draft"]["text"] and draft["draft"]["disclosure"]
    assert draft["draft"]["drafts_remaining_today"] < 10
    sent = a.post(f"/chat/{match_id}/messages", {"text": draft["draft"]["text"], "sender_id": a.user_id,
                                                 "assist_draft_id": draft["draft"]["draft_id"]}).ok()
    assert sent["accepted"] is True
    trust = b.get(f"/matches/{match_id}/trust").ok()["trust"]
    assert trust["assisted_messages"] >= 1, "assisted messages must be disclosed to the partner"
