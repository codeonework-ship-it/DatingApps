"""Dating loop edges, chat history/receipts/deletes, quotas, gifts, wallet and the
sandbox billing provider (local test cards only; no real money moves).
"""

from __future__ import annotations

import threading
import uuid
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlparse

import pytest
import requests

from client import API_BASE, PASSWORD, RUN_ID, Api, items
from journeys import match


pytestmark = pytest.mark.journey("dating_chat_gifts_billing")

FREE_GIFT = "rose_red_single"


def _like(member, target, like=True):
    return member.post("/swipe", {"user_id": member.user_id, "target_user_id": target.user_id
                                  if hasattr(target, "user_id") else target, "is_like": like})


def _liked_me_ids(member):
    return [p.get("user_id") or p.get("id")
            for p in member.get(f"/discovery/{member.user_id}/liked-me").ok()["profiles"]]


def _bare_member(tag):
    """Signup + bootstrap only (a valid swipe target, cheaper than a full profile)."""
    username = f"e2e_{RUN_ID}_{tag}"[:30].lower()
    signup = Api().post("/auth/signup", {"username": username, "password": PASSWORD}).ok()
    api = Api(signup["access_token"])
    api.post("/auth/signup/bootstrap", {"user_id": signup["user_id"], "username": username,
                                        "name": "Quota Target", "date_of_birth": "1993-03-03",
                                        "gender": "M"}).ok()
    return signup["user_id"], api


# --- swipes ---------------------------------------------------------------------------

def test_pass_is_recorded_without_a_like_or_quota(make_member):
    a, b = make_member("sw_a", "F", "M"), make_member("sw_b", "M", "F")
    before = a.get(f"/billing/entitlements/{a.user_id}").ok()["likes"]["used"]
    passed = _like(a, b, like=False).ok()
    assert passed["accepted"] is True and passed["mutual_match"] is False
    assert a.user_id not in _liked_me_ids(b)
    assert a.get(f"/billing/entitlements/{a.user_id}").ok()["likes"]["used"] == before
    # A pass followed by their like is not a match.
    assert _like(b, a).ok()["mutual_match"] is False


# Regression guard: API-13 (fixed, verified live 2026-10-02)
def test_self_like_is_a_client_error(make_member):
    a = make_member("sw_self", "F", "M")
    response = _like(a, a)
    assert response.status == 400, f"{response.status} {response.text[:200]}"


def test_swipe_validation(make_member):
    a = make_member("sw_val", "F", "M")
    for body in ({"user_id": a.user_id}, {"user_id": a.user_id, "target_user_id": "not-a-uuid", "is_like": True},
                 {"user_id": a.user_id, "target_user_id": str(uuid.uuid4()), "is_like": True}):
        response = a.post("/swipe", body)
        assert response.status < 500 or response.status == 502, response.text
        assert response.get("mutual_match") is not True


@pytest.mark.quota
def test_free_plan_daily_like_quota(make_member):
    liker = make_member("quota_l", "F", "M")
    ent = liker.get(f"/billing/entitlements/{liker.user_id}").ok()
    if not ent["enforced"] or ent["likes"]["unlimited"]:
        pytest.skip("daily like limits are not enforced on this stack")
    limit, used = ent["likes"]["limit"], ent["likes"]["used"]
    targets = [_bare_member(f"ql{n}") for n in range(limit - used + 1)]
    try:
        statuses = [liker.post("/swipe", {"user_id": liker.user_id, "target_user_id": uid,
                                          "is_like": True}).status for uid, _ in targets]
        assert statuses[:-1] == [200] * (len(statuses) - 1), statuses
        over = liker.post("/swipe", {"user_id": liker.user_id, "target_user_id": targets[-1][0],
                                     "is_like": True})
        assert over.status == 429 and over["error_code"] == "DAILY_LIKE_LIMIT_REACHED", over.text
        assert over["limit"] == limit and over["resets_at"].endswith("T00:00:00Z")
        # Passes are never limited.
        assert liker.post("/swipe", {"user_id": liker.user_id, "target_user_id": targets[-1][0],
                                     "is_like": False}).status == 200
    finally:
        for uid, api in targets:
            api.post(f"/account/{uid}/deletion", {"reason": "api e2e cleanup"})


@pytest.mark.quota
def test_free_plan_daily_message_quota(make_member):
    a, b = make_member("quota_ma", "F", "M"), make_member("quota_mb", "M", "F")
    ent = a.get(f"/billing/entitlements/{a.user_id}").ok()
    if not ent["enforced"] or ent["messages"]["unlimited"]:
        pytest.skip("daily message limits are not enforced on this stack")
    match_id = match(a, b)
    remaining = ent["messages"]["remaining"]
    for n in range(remaining):
        a.post(f"/chat/{match_id}/messages", {"text": f"quota {n}", "sender_id": a.user_id}).ok()
    over = a.post(f"/chat/{match_id}/messages", {"text": "one too many", "sender_id": a.user_id})
    assert over.status == 429 and over["error_code"] == "DAILY_MESSAGE_LIMIT_REACHED", over.text
    assert "one too many" not in [m["text"] for m in b.get(f"/chat/{match_id}/messages").ok()["messages"]]
    # The partner's own allowance is untouched.
    b.post(f"/chat/{match_id}/messages", {"text": "my turn", "sender_id": b.user_id}).ok()


# --- matches and chat -------------------------------------------------------------------

def test_unmatch_ends_chat_for_both(make_member):
    a, b = make_member("um_a", "F", "M"), make_member("um_b", "M", "F")
    match_id = match(a, b)
    a.post(f"/chat/{match_id}/messages", {"text": "before unmatch", "sender_id": a.user_id}).ok()
    a.delete(f"/matches/{match_id}", params={"user_id": a.user_id}).ok()
    for member in (a, b):
        send = member.post(f"/chat/{match_id}/messages", {"text": "after", "sender_id": member.user_id})
        assert send.status in (403, 404), send.text
        assert member.get(f"/chat/{match_id}/messages").status in (403, 404)
        assert match_id not in [m["id"] for m in member.get(f"/matches/{member.user_id}").ok()["matches"]]


@pytest.mark.known_defect("API-19")
@pytest.mark.xfail(strict=True, reason="API-19: liking again after an unmatch reports mutual_match "
                                       "with the dead match id (matching-svc UpsertMatch)")
def test_liking_again_after_unmatch_does_not_claim_a_dead_match(make_member):
    a, b = make_member("um_c", "F", "M"), make_member("um_d", "M", "F")
    match_id = match(a, b)
    a.delete(f"/matches/{match_id}", params={"user_id": a.user_id}).ok()
    again = _like(a, b).ok()
    listed = [m["id"] for m in a.get(f"/matches/{a.user_id}").ok()["matches"]]
    assert not again.get("mutual_match") or again["match_id"] in listed, (
        f"swipe reported mutual_match with {again.get('match_id')}, which neither member can open")


def test_read_receipts_and_unread_counts(make_member):
    a, b = make_member("rr_a", "F", "M"), make_member("rr_b", "M", "F")
    match_id = match(a, b)
    a.post(f"/chat/{match_id}/messages", {"text": "unread 1", "sender_id": a.user_id}).ok()
    a.post(f"/chat/{match_id}/messages", {"text": "unread 2", "sender_id": a.user_id}).ok()
    row = next(m for m in b.get(f"/matches/{b.user_id}").ok()["matches"] if m["id"] == match_id)
    assert row["unreadCount"] == 2
    b.post(f"/matches/{match_id}/read", {"user_id": b.user_id}).ok()
    messages = a.get(f"/chat/{match_id}/messages").ok()["messages"]
    assert all(m["read_at"] for m in messages if m["sender_id"] == a.user_id), messages
    # The reader's own outgoing messages are not marked read by their own read.
    b.post(f"/chat/{match_id}/messages", {"text": "reply", "sender_id": b.user_id}).ok()
    b.post(f"/matches/{match_id}/read", {"user_id": b.user_id}).ok()
    mine = [m for m in a.get(f"/chat/{match_id}/messages").ok()["messages"] if m["sender_id"] == b.user_id]
    assert mine and not mine[0]["read_at"]


def test_chat_history_is_newest_first_and_delete_window(make_member):
    a, b = make_member("hist_a", "F", "M"), make_member("hist_b", "M", "F")
    match_id = match(a, b)
    ids = [a.post(f"/chat/{match_id}/messages", {"text": f"h{n}", "sender_id": a.user_id}).ok()["message_id"]
           for n in range(3)]
    listed = b.get(f"/chat/{match_id}/messages", params={"limit": 50}).ok()["messages"]
    assert [m["id"] for m in listed][:3] == list(reversed(ids))
    a.delete(f"/chat/{match_id}/messages/{ids[0]}", {"requester_user_id": a.user_id}).ok()
    again = a.delete(f"/chat/{match_id}/messages/{ids[0]}", {"requester_user_id": a.user_id})
    assert again.status == 404, again.text
    assert ids[0] not in [m["id"] for m in b.get(f"/chat/{match_id}/messages").ok()["messages"]]
    assert a.delete(f"/chat/{match_id}/messages/{uuid.uuid4()}",
                    {"requester_user_id": a.user_id}).status == 404


# --- gifts ----------------------------------------------------------------------------------

@pytest.fixture(scope="module")
def gift_pair(make_member):
    a, b = make_member("gift_a", "F", "M"), make_member("gift_b", "M", "F")
    return a, b, match(a, b)


def _send_gift(member, match_id, gift_id, **extra):
    headers = extra.pop("headers", None)
    return member.post(f"/chat/{match_id}/gifts/send",
                       {"gift_id": gift_id, "sender_user_id": member.user_id, **extra}, headers=headers)


@pytest.mark.billing
def test_gift_catalogue(gift_pair):
    a, _, _ = gift_pair
    catalogue = a.get("/chat/gifts").ok()
    assert catalogue["count"] == len(catalogue["gifts"]) > 0
    assert any(g["id"] == FREE_GIFT and g["price_coins"] == 0 for g in catalogue["gifts"])


@pytest.mark.billing
def test_one_free_gift_per_utc_day(gift_pair):
    a, b, match_id = gift_pair
    first = _send_gift(a, match_id, FREE_GIFT, message_text="for you \U0001F339").ok()
    assert first["gift_send"]["price_coins"] == 0 and first["message"]["id"]
    second = _send_gift(a, match_id, "rose_pink_soft")
    assert second.status == 429 and second["error_code"] == "FREE_GIFT_DAILY_LIMIT_REACHED", second.text
    # The receiver sees the gift message in the chat.
    texts = [m["id"] for m in b.get(f"/chat/{match_id}/messages").ok()["messages"]]
    assert first["message"]["id"] in texts


@pytest.mark.billing
def test_paid_gift_needs_coins_and_wrong_receiver_is_refused(gift_pair):
    a, b, match_id = gift_pair
    paid = next(g for g in a.get("/chat/gifts").ok()["gifts"] if g["price_coins"] > 0 and g["is_active"])
    balance = b.get(f"/wallet/{b.user_id}/coins").ok()["wallet"]["coin_balance"]
    if balance >= paid["price_coins"]:
        pytest.skip("member unexpectedly has coins")
    broke = _send_gift(b, match_id, paid["id"])
    assert broke.status == 402 and broke["error_code"] == "INSUFFICIENT_COINS", broke.text
    wrong = _send_gift(b, match_id, FREE_GIFT, receiver_user_id=b.user_id)
    assert wrong.status in (400, 403), wrong.text
    stranger = _send_gift(b, match_id, FREE_GIFT, receiver_user_id=str(uuid.uuid4()))
    assert stranger.status == 403 and stranger["error_code"] == "GIFT_RECEIVER_MISMATCH", stranger.text
    unknown = _send_gift(b, match_id, "no_such_gift")
    assert unknown.status in (400, 404, 422), unknown.text


@pytest.mark.billing
@pytest.mark.concurrency
def test_double_tapped_free_gift_is_sent_once(make_member):
    a, b = make_member("gift_r1", "F", "M"), make_member("gift_r2", "M", "F")
    match_id = match(a, b)
    barrier = threading.Barrier(3)

    def send():
        barrier.wait()
        return _send_gift(a, match_id, FREE_GIFT)

    with ThreadPoolExecutor(3) as pool:
        results = list(pool.map(lambda _: send(), range(3)))
    assert all(r.status < 500 for r in results), [(r.status, r.text[:120]) for r in results]
    assert sum(r.status == 200 for r in results) == 1, [(r.status, r.text[:120]) for r in results]
    gifts = [m for m in b.get(f"/chat/{match_id}/messages").ok()["messages"]]
    assert len(gifts) == 1, gifts


@pytest.mark.billing
@pytest.mark.idempotency
def test_gift_idempotency_key_replays_and_rejects_a_different_gift(make_member):
    a, b = make_member("gift_i1", "F", "M"), make_member("gift_i2", "M", "F")
    match_id = match(a, b)
    headers = {"Idempotency-Key": f"e2e-{uuid.uuid4()}"}
    first = _send_gift(a, match_id, FREE_GIFT, headers=headers).ok()
    replay = _send_gift(a, match_id, FREE_GIFT, headers=headers).ok()
    assert replay["gift_send"]["id"] == first["gift_send"]["id"]
    other = _send_gift(a, match_id, "rose_pink_soft", headers=headers)
    assert other.status == 409, other.text
    assert other["error_code"] in ("IDEMPOTENCY_KEY_CONFLICT", "IDEMPOTENCY_KEY_REUSED")


@pytest.mark.billing
@pytest.mark.safety
def test_receiver_can_hide_and_report_a_gift(make_member):
    a, b = make_member("gift_h1", "F", "M"), make_member("gift_h2", "M", "F")
    match_id = match(a, b)
    sent = _send_gift(a, match_id, FREE_GIFT).ok()
    message_id = sent["message"]["id"]
    base = f"/chat/{match_id}/messages/{message_id}/gift"
    assert a.post(f"{base}/hide").status == 404, "the sender cannot hide the receiver's gift"
    assert b.post(f"{base}/report", {"reason": "because"}).status == 400
    assert b.post(f"{base}/report", {"reason": "other", "details": "d" * 501}).status == 400
    report = b.post(f"{base}/report", {"reason": "unwanted", "details": "e2e"})
    assert report.status == 201 and report["hidden"] is True, report.text
    again = b.post(f"{base}/report", {"reason": "unwanted"}).ok()
    assert again["report_id"] == report["report_id"]
    assert message_id not in [m["id"] for m in b.get(f"/chat/{match_id}/messages").ok()["messages"]]


# --- wallet and billing (sandbox provider) -------------------------------------------------

@pytest.mark.billing
def test_wallet_buy_is_card_checkout_only_and_audit_is_mine(make_member):
    a = make_member("wal_a", "F", "M")
    buy = a.post(f"/wallet/{a.user_id}/coins/buy", {"coins": 100, "package_id": "x"})
    assert buy.status in (403, 409), buy.text
    assert a.get(f"/wallet/{a.user_id}/coins").ok()["wallet"]["coin_balance"] == 0
    audit = a.get(f"/wallet/{a.user_id}/coins/audit").ok()
    assert audit["user_id"] == a.user_id


def _sandbox_pay(checkout_url: str, card: str) -> requests.Response:
    path = urlparse(checkout_url).path
    session_id = path.rstrip("/").rsplit("/", 1)[-1]
    return requests.post(f"{API_BASE}/billing/sandbox/checkout/{session_id}",
                         data={"card_number": card, "exp_month": "12", "exp_year": "2035",
                               "cvc": "123", "name": "E2E Sandbox"},
                         allow_redirects=False, timeout=20)


@pytest.mark.billing
def test_sandbox_coin_purchase_credits_wallet_and_pays_for_a_gift(make_member):
    a, b = make_member("bill_a", "F", "M"), make_member("bill_b", "M", "F")
    plans = Api().get("/billing/plans")
    assert plans.status == 200, "plans are public"
    packages = a.get("/billing/coin-packages").ok()
    if packages.get("mode") != "sandbox":
        pytest.skip("billing provider is not the sandbox; refusing to touch a real provider")
    package = min(packages["packages"], key=lambda p: p["total_coins"])
    assert a.post("/billing/checkout", {"kind": "coin_package", "package_id": str(uuid.uuid4())}).status == 404

    declined = a.post("/billing/checkout", {"kind": "coin_package", "package_id": package["id"]})
    assert declined.status == 201, declined.text
    paid = _sandbox_pay(declined["checkout"]["checkout_url"], "4000000000000002")
    assert paid.status_code in (200, 303)
    assert a.get(f"/wallet/{a.user_id}/coins").ok()["wallet"]["coin_balance"] == 0, "a declined card credited coins"

    checkout = a.post("/billing/checkout", {"kind": "coin_package", "package_id": package["id"]},
                      headers={"Idempotency-Key": f"e2e-{uuid.uuid4()}"})
    assert checkout.status == 201, checkout.text
    done = _sandbox_pay(checkout["checkout"]["checkout_url"], "4242424242424242")
    assert done.status_code == 303 and "status=success" in done.headers.get("Location", ""), done.text[:200]
    balance = a.get(f"/wallet/{a.user_id}/coins").ok()["wallet"]["coin_balance"]
    assert balance == package["total_coins"], balance
    # Paying the same session twice must not credit twice.
    _sandbox_pay(checkout["checkout"]["checkout_url"], "4242424242424242")
    assert a.get(f"/wallet/{a.user_id}/coins").ok()["wallet"]["coin_balance"] == balance

    match_id = match(a, b)
    gift = next(g for g in a.get("/chat/gifts").ok()["gifts"]
                if g["is_active"] and 0 < g["price_coins"] <= balance)
    sent = _send_gift(a, match_id, gift["id"]).ok()
    assert sent["wallet"]["coin_balance"] == balance - gift["price_coins"]
    audit = items(a.get(f"/wallet/{a.user_id}/coins/audit").ok().body, "audit")
    assert audit, "coin movements must be audited"
    payments = a.get(f"/billing/payments/{a.user_id}").ok()["payments"]
    assert payments, "the purchase must appear in payment history"


@pytest.mark.billing
def test_subscription_checkout_validation(make_member):
    a = make_member("bill_s", "F", "M")
    if a.get("/billing/coin-packages").ok().get("mode") != "sandbox":
        pytest.skip("billing provider is not the sandbox")
    assert a.post("/billing/checkout", {"plan_id": "free"}).status == 400
    assert a.post("/billing/checkout", {"plan_id": "no-such-plan"}).status in (400, 404)
    plans = a.get("/billing/plans").ok()
    paid = [p for p in plans.get("plans", []) if (p.get("id") or p.get("plan_id")) not in ("free", None)]
    if paid:
        plan_id = paid[0].get("id") or paid[0].get("plan_id")
        assert a.post("/billing/checkout", {"plan_id": plan_id, "billing_cycle": "weekly"}).status == 400
    assert a.post(f"/billing/subscription/{a.user_id}/cancel").status in (404, 409)
    assert a.post("/billing/subscribe", {"plan_id": "premium"}).status in (403, 409)
