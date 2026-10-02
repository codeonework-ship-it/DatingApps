"""Trust & safety: what a block really stops, reports, appeals, emergency
contacts, verification and trust badges.

SOS alerts are not raised here: they page operators and fan out to emergency
contacts, so only their authorization is checked.
"""

from __future__ import annotations

import uuid

import pytest

from client import items, png_bytes
from journeys import befriend, match


pytestmark = [pytest.mark.journey("safety_trust"), pytest.mark.safety]


def _block(blocker, blocked):
    return blocker.post("/safety/block", {"user_id": blocker.user_id, "blocked_user_id": blocked.user_id})


def _unblock(blocker, blocked):
    return blocker.post("/safety/unblock", {"user_id": blocker.user_id, "blocked_user_id": blocked.user_id})


@pytest.fixture(scope="module")
def blocked_match(make_member):
    """A matched pair, friends too, then the woman blocks the man."""
    woman, man = make_member("blk2_w", "F", "M"), make_member("blk2_m", "M", "F")
    match_id = match(woman, man)
    befriend(woman, man)
    woman.post(f"/chat/{match_id}/messages", {"text": "before the block", "sender_id": woman.user_id}).ok()
    _block(woman, man).ok()
    yield woman, man, match_id
    _unblock(woman, man)


def test_block_is_idempotent_and_listed(blocked_match):
    woman, man, _ = blocked_match
    assert _block(woman, man).status == 200
    listed = items(woman.get(f"/blocked-users/{woman.user_id}").ok().body, "blocked_users", "items", "users")
    assert sum(man.user_id in str(row) for row in listed) == 1


def test_blocked_member_cannot_see_the_blocker(blocked_match):
    woman, man, _ = blocked_match
    assert man.get(f"/profile/{woman.user_id}").status == 404
    assert woman.get(f"/profile/{man.user_id}").status == 404
    deck = man.get(f"/discovery/{man.user_id}", params={"limit": 300}).ok()["candidates"]
    assert woman.user_id not in [c.get("id") for c in deck]
    found = man.get(f"/friends/{man.user_id}/search", params={"q": woman.username}).ok()["results"]
    assert woman.user_id not in [r["user_id"] for r in found]


def test_block_removes_the_friendship_and_friend_chat(blocked_match):
    woman, man, _ = blocked_match
    assert not [f for f in man.get(f"/friends/{man.user_id}").ok()["friends"]
                if f["friend_user_id"] == woman.user_id]
    again = man.post(f"/friends/{man.user_id}", {"friend_user_id": woman.user_id, "source": "profile"})
    assert again.status == 404, again.text
    channel = man.post(f"/social/friends/{woman.user_id}/channel")
    assert channel.status in (403, 404), channel.text


# Regression guard: API-11 (fixed, verified live 2026-10-02)
def test_blocked_member_cannot_message_or_gift_in_an_old_match(blocked_match):
    woman, man, match_id = blocked_match
    send = man.post(f"/chat/{match_id}/messages", {"text": "why did you block me", "sender_id": man.user_id})
    gift = man.post(f"/chat/{match_id}/gifts/send", {"gift_id": "rose_red_single", "sender_user_id": man.user_id})
    texts = [m["text"] for m in woman.get(f"/chat/{match_id}/messages").ok()["messages"]]
    assert send.status == 403 and gift.status == 403, (send.status, gift.status)
    assert "why did you block me" not in texts


# Regression guard: API-12 (fixed, verified live 2026-10-02)
def test_likes_across_a_block_never_make_a_match(make_member):
    a, b = make_member("blk3_a", "F", "M"), make_member("blk3_b", "M", "F")
    _block(a, b).ok()
    try:
        first = b.post("/swipe", {"user_id": b.user_id, "target_user_id": a.user_id, "is_like": True})
        second = a.post("/swipe", {"user_id": a.user_id, "target_user_id": b.user_id, "is_like": True})
        assert second.get("mutual_match") is not True, second.text
        assert first.status == 404 and second.status == 404, (first.status, second.status)
    finally:
        _unblock(a, b)


def test_blocked_liker_is_hidden_from_liked_me(make_member):
    a, b = make_member("blk4_a", "F", "M"), make_member("blk4_b", "M", "F")
    b.post("/swipe", {"user_id": b.user_id, "target_user_id": a.user_id, "is_like": True}).ok()
    def likers():
        return [p.get("user_id") or p.get("id")
                for p in a.get(f"/discovery/{a.user_id}/liked-me").ok()["profiles"]]

    assert b.user_id in likers()
    _block(a, b).ok()
    try:
        assert b.user_id not in likers()
    finally:
        _unblock(a, b).ok()


# Regression guard: API-13 (fixed, verified live 2026-10-02)
def test_safety_mistakes_are_client_errors(make_member):
    a = make_member("blk5_a", "F", "M")
    stranger = str(uuid.uuid4())
    checks = {
        "self block": a.post("/safety/block", {"user_id": a.user_id, "blocked_user_id": a.user_id}),
        "self report": a.post("/safety/report", {"reporter_user_id": a.user_id,
                                                 "reported_user_id": a.user_id, "reason": "spam"}),
        "unblock never blocked": a.post("/safety/unblock", {"user_id": a.user_id, "blocked_user_id": stranger}),
        "report unknown member": a.post("/safety/report", {"reporter_user_id": a.user_id,
                                                           "reported_user_id": stranger, "reason": "spam"}),
        "block malformed id": a.post("/safety/block", {"user_id": a.user_id, "blocked_user_id": "nope"}),
    }
    assert {k: v.status for k, v in checks.items() if not 400 <= v.status < 500} == {}


def test_report_validation(make_member):
    a, b = make_member("rep_a", "F", "M"), make_member("rep_b", "M", "F")
    assert a.post("/safety/report", {"reporter_user_id": a.user_id, "reason": "spam"}).status == 400
    assert a.post("/safety/report", {"reporter_user_id": a.user_id,
                                     "reported_user_id": b.user_id}).status == 400
    report = a.post("/safety/report", {"reporter_user_id": a.user_id, "reported_user_id": b.user_id,
                                       "reason": "harassment", "description": "<b>e2e</b> \U0001F6A9"}).ok()
    assert report["report"]["status"] == "pending"
    assert report["report"]["description"] == "<b>e2e</b> \U0001F6A9"


def test_appeals_only_by_the_reported_member(make_member):
    reporter, reported, other = (make_member("ap_r", "F", "M"), make_member("ap_d", "M", "F"),
                                 make_member("ap_o", "F", "M"))
    report_id = reporter.post("/safety/report", {"reporter_user_id": reporter.user_id,
                                                 "reported_user_id": reported.user_id,
                                                 "reason": "spam", "description": "e2e"}).ok()["report"]["id"]
    assert other.post("/moderation/appeals", {"report_id": report_id, "reason": "not me"}).status == 400
    assert reporter.post("/moderation/appeals", {"report_id": report_id, "reason": "x"}).status == 400
    assert reported.post("/moderation/appeals", {"report_id": str(uuid.uuid4()), "reason": "x"}).status == 400
    appeal = reported.post("/moderation/appeals", {"report_id": report_id, "reason": "not me",
                                                   "description": "e2e appeal"}).ok()["appeal"]
    assert appeal["status"] == "submitted" and appeal["sla_deadline_at"]
    assert reported.get(f"/moderation/appeals/{appeal['id']}").status == 200
    assert other.get(f"/moderation/appeals/{appeal['id']}").status == 404
    assert appeal["id"] in [x["id"] for x in reported.get("/moderation/appeals").ok()["appeals"]]


@pytest.mark.authz
# Regression guard: API-14 (fixed, verified live 2026-10-02)
def test_member_cannot_list_another_members_appeals(make_member):
    reporter, reported = make_member("ap2_r", "F", "M"), make_member("ap2_d", "M", "F")
    report_id = reporter.post("/safety/report", {"reporter_user_id": reporter.user_id,
                                                 "reported_user_id": reported.user_id,
                                                 "reason": "spam"}).ok()["report"]["id"]
    reported.post("/moderation/appeals", {"report_id": report_id, "reason": "not me"}).ok()
    leak = reporter.get("/moderation/appeals", params={"user_id": reported.user_id})
    assert leak.status == 403 or leak.get("appeals") == [], leak.text[:300]


def test_sos_routes_are_owner_only(make_member):
    a, b = make_member("sos_a", "F", "M"), make_member("sos_b", "M", "F")
    assert a.post("/safety/sos", {"user_id": b.user_id, "emergency_level": "high"}).status == 403
    assert a.get(f"/safety/sos/{b.user_id}").status == 403
    assert a.get(f"/safety/sos/{a.user_id}").ok()["alerts"] == []


# --- emergency contacts -------------------------------------------------------------

def test_emergency_contacts_crud_and_cap(make_member):
    member = make_member("ec_a", "F", "M")
    base = f"/emergency-contacts/{member.user_id}"
    assert member.post(base, {"name": "Mum"}).status == 400
    assert member.post(base, {"phone_number": "+447700900001"}).status == 400
    ids = []
    for n in range(3):
        contacts = member.post(base, {"name": f"Contact {n}", "phone_number": f"+44770090000{n}"}).ok()["contacts"]
        ids = [c["id"] for c in contacts]
    assert len(ids) == 3
    fourth = member.post(base, {"name": "Fourth", "phone_number": "+447700900009"})
    assert fourth.status != 200, "a fourth contact was saved"
    updated = member.put(f"{base}/{ids[0]}", {"name": "Mum", "phone_number": "+447700900111"}).ok()["contacts"]
    assert any(c["name"] == "Mum" and c["phone_number"] == "+447700900111" for c in updated)
    for contact_id in ids:
        member.delete(f"{base}/{contact_id}").ok()
    assert member.get(base).ok()["contacts"] == []


# Regression guard: API-16 (fixed, verified live 2026-10-02)
def test_fourth_emergency_contact_is_a_conflict_not_502(make_member):
    member = make_member("ec_b", "F", "M")
    base = f"/emergency-contacts/{member.user_id}"
    for n in range(3):
        member.post(base, {"name": f"C{n}", "phone_number": f"+44770090001{n}"}).ok()
    assert member.post(base, {"name": "C4", "phone_number": "+447700900199"}).status == 409


# --- verification and trust badges -----------------------------------------------------

def test_verification_submit_validation(make_member):
    member = make_member("ver_a", "F", "M")
    status = member.get(f"/verification/{member.user_id}").ok()
    assert "status" in status.body
    path = f"/verification/{member.user_id}/submit"
    assert member.post(path, {"selfie": "x"}).status in (403, 415)
    only_selfie = member.api.call("POST", path, files={"selfie": ("s.png", png_bytes(), "image/png")})
    assert only_selfie.status in (400, 403), only_selfie.text
    not_images = member.api.call("POST", path, files={
        "id_document": ("id.txt", b"hello world", "text/plain"),
        "selfie": ("s.txt", b"hello again", "text/plain")})
    assert not_images.status in (400, 403, 415), not_images.text


def test_trust_badges_and_filter(make_member):
    member = make_member("tb_a", "F", "M")
    badges = member.get(f"/users/{member.user_id}/trust-badges").ok()["badges"]
    assert {b["badge_code"] for b in badges} >= {"consistent_profile", "verified_active"}
    base = f"/discovery/{member.user_id}/filters/trust"
    saved = member.patch(base, {"enabled": True, "minimum_active_badges": 9,
                                "required_badge_codes": ["SHOWS_UP", "shows_up"]}).ok()["trust_filter"]
    assert saved["enabled"] is True and saved["required_badge_codes"] == ["shows_up"]
    assert saved["minimum_active_badges"] <= 1
    member.patch(base, {"enabled": False}).ok()


# Regression guard: API-20 (fixed, verified live 2026-10-02)
def test_unknown_trust_badge_code_is_a_400(make_member):
    member = make_member("tb_b", "F", "M")
    bad = member.patch(f"/discovery/{member.user_id}/filters/trust",
                       {"enabled": True, "required_badge_codes": ["made_up"]})
    assert bad.status == 400, bad.text
