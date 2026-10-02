"""Idempotency-Key semantics and racing requests.

Idempotency: a replay with the same key returns the stored response (marked
X-Idempotent-Replay) without running the command again; the same key with a
different body is a 409 conflict; keys are namespaced by member and route.

Concurrency: requests fired together from threads must never produce a 5xx, a
duplicate relationship or a double spend.
"""

from __future__ import annotations

import threading
import uuid
from concurrent.futures import ThreadPoolExecutor

import pytest

from client import Api, items, login
from journeys import befriend, match


pytestmark = pytest.mark.journey("idempotency_concurrency")


def _key() -> dict:
    return {"Idempotency-Key": f"e2e-{uuid.uuid4()}"}


def _race(*calls):
    """Run the callables at the same moment; return their results in order."""
    barrier = threading.Barrier(len(calls))

    def run(fn):
        barrier.wait()
        return fn()

    with ThreadPoolExecutor(max_workers=len(calls)) as pool:
        return list(pool.map(run, calls))


def _no_server_errors(responses):
    for r in responses:
        assert r.status < 500, f"{r.method} {r.url} -> {r.status} {r.text[:300]}"


# --- Idempotency-Key ----------------------------------------------------------

@pytest.mark.idempotency
def test_replay_with_same_key_returns_the_stored_response(make_member):
    member = make_member("idem_a", "F", "M")
    headers = _key()
    path = f"/settings/{member.user_id}"
    first = member.patch(path, {"theme": "light:snow"}, headers=headers).ok()
    # Change the state in between: a replay must not re-run the command.
    member.patch(path, {"theme": "dark:gothic"}).ok()
    replay = member.patch(path, {"theme": "light:snow"}, headers=headers)
    assert replay.status == first.status, replay.text
    assert replay.headers.get("X-Idempotent-Replay") == "true", dict(replay.headers)
    assert member.get(path).ok()["settings"]["theme"] == "dark:gothic"


@pytest.mark.idempotency
def test_same_key_with_a_different_body_is_a_conflict(make_member):
    member = make_member("idem_b", "F", "M")
    headers = _key()
    path = f"/settings/{member.user_id}"
    member.patch(path, {"theme": "light:snow"}, headers=headers).ok()
    conflict = member.patch(path, {"theme": "dark:gothic"}, headers=headers)
    assert conflict.status == 409, conflict.text
    assert conflict["error_code"] == "IDEMPOTENCY_KEY_CONFLICT", conflict.text
    assert member.get(path).ok()["settings"]["theme"] == "light:snow"


@pytest.mark.idempotency
def test_keys_are_namespaced_per_member_and_route(make_member):
    a, b = make_member("idem_c", "F", "M"), make_member("idem_d", "M", "F")
    headers = _key()
    a.patch(f"/settings/{a.user_id}", {"theme": "light:snow"}, headers=headers).ok()
    other_member = b.patch(f"/settings/{b.user_id}", {"theme": "dark:gothic"}, headers=headers)
    assert other_member.status == 200 and other_member.headers.get("X-Idempotent-Replay") != "true"
    assert b.get(f"/settings/{b.user_id}").ok()["settings"]["theme"] == "dark:gothic"
    other_route = a.patch(f"/notifications/{a.user_id}/preferences", {"notify_likes": False},
                          headers=headers)
    assert other_route.status == 200 and other_route.headers.get("X-Idempotent-Replay") != "true"
    a.patch(f"/notifications/{a.user_id}/preferences", {"notify_likes": True}).ok()


@pytest.mark.idempotency
def test_replayed_chat_send_stores_one_message(make_member):
    a, b = make_member("idem_e", "F", "M"), make_member("idem_f", "M", "F")
    match_id = match(a, b)
    headers = _key()
    body = {"text": "exactly once please", "sender_id": a.user_id}
    first = a.post(f"/chat/{match_id}/messages", body, headers=headers).ok()
    again = a.post(f"/chat/{match_id}/messages", body, headers=headers).ok()
    assert again["message_id"] == first["message_id"]
    texts = [m["text"] for m in b.get(f"/chat/{match_id}/messages", params={"limit": 50}).ok()["messages"]]
    assert texts.count("exactly once please") == 1, texts


@pytest.mark.idempotency
def test_concurrent_requests_with_one_key_run_once(make_member):
    a, b = make_member("idem_g", "F", "M"), make_member("idem_h", "M", "F")
    match_id = match(a, b)
    headers = _key()
    body = {"text": "raced with one key", "sender_id": a.user_id}
    results = _race(*[lambda: a.post(f"/chat/{match_id}/messages", body, headers=headers)] * 4)
    _no_server_errors(results)
    ok = [r for r in results if r.status == 200]
    assert ok and len({r["message_id"] for r in ok}) == 1, [r.text[:200] for r in results]
    texts = [m["text"] for m in b.get(f"/chat/{match_id}/messages", params={"limit": 50}).ok()["messages"]]
    assert texts.count("raced with one key") == 1, texts


# --- races ----------------------------------------------------------------------

@pytest.mark.concurrency
def test_simultaneous_mutual_likes_create_exactly_one_match(make_member):
    a, b = make_member("race_a", "F", "M"), make_member("race_b", "M", "F")
    results = _race(
        lambda: a.post("/swipe", {"user_id": a.user_id, "target_user_id": b.user_id, "is_like": True}),
        lambda: b.post("/swipe", {"user_id": b.user_id, "target_user_id": a.user_id, "is_like": True}),
    )
    _no_server_errors(results)
    for member, other in ((a, b), (b, a)):
        rows = [m for m in member.get(f"/matches/{member.user_id}").ok()["matches"]
                if m["userId"] == other.user_id]
        assert len(rows) == 1, f"expected one match, got {rows}"
    assert a.get(f"/matches/{a.user_id}").ok()["matches"][0]["id"] == \
        b.get(f"/matches/{b.user_id}").ok()["matches"][0]["id"]


@pytest.mark.concurrency
def test_double_tapped_like_is_counted_once(make_member):
    a, b = make_member("race_c", "F", "M"), make_member("race_d", "M", "F")
    before = a.get(f"/billing/entitlements/{a.user_id}").ok()["likes"]["used"]
    body = {"user_id": a.user_id, "target_user_id": b.user_id, "is_like": True}
    results = _race(*[lambda: a.post("/swipe", body)] * 3)
    _no_server_errors(results)
    liked_me = b.get(f"/discovery/{b.user_id}/liked-me").ok()["profiles"]
    assert [p.get("user_id") or p.get("id") for p in liked_me].count(a.user_id) == 1
    used = a.get(f"/billing/entitlements/{a.user_id}").ok()["likes"]["used"]
    assert used - before <= 1, f"one like consumed {used - before} of the daily quota"


@pytest.mark.concurrency
# Regression guard: API-09 (fixed, verified live 2026-10-02)
def test_crossing_friend_requests_end_as_one_friendship(make_member):
    a, b = make_member("race_e", "F", "M"), make_member("race_f", "M", "F")
    results = _race(
        lambda: a.post(f"/friends/{a.user_id}", {"friend_user_id": b.user_id, "source": "search"}),
        lambda: b.post(f"/friends/{b.user_id}", {"friend_user_id": a.user_id, "source": "search"}),
    )
    _no_server_errors(results)
    for me, other in ((a, b), (b, a)):
        rows = [f for f in me.get(f"/friends/{me.user_id}").ok()["friends"]
                if f["friend_user_id"] == other.user_id]
        assert len(rows) == 1, rows
    # Crossing requests are mutual intent: both sides agree on one state.
    status_a = next(f for f in a.get(f"/friends/{a.user_id}").ok()["friends"]
                    if f["friend_user_id"] == b.user_id)["status"]
    status_b = next(f for f in b.get(f"/friends/{b.user_id}").ok()["friends"]
                    if f["friend_user_id"] == a.user_id)["status"]
    assert status_a == status_b, (status_a, status_b)


@pytest.mark.concurrency
def test_simultaneous_accepts_are_safe(make_member):
    a, b = make_member("race_g", "F", "M"), make_member("race_h", "M", "F")
    a.post(f"/friends/{a.user_id}", {"friend_user_id": b.user_id, "source": "search"}).ok()
    results = _race(*[lambda: b.post(f"/friends/{b.user_id}/{a.user_id}/decision",
                                     {"decision": "accept"})] * 3)
    _no_server_errors(results)
    assert any(r.status == 200 for r in results)
    rows = [f for f in a.get(f"/friends/{a.user_id}").ok()["friends"] if f["friend_user_id"] == b.user_id]
    assert len(rows) == 1 and rows[0]["status"] == "accepted", rows


@pytest.mark.concurrency
@pytest.mark.security
def test_parallel_refresh_with_one_token_issues_one_session(make_member):
    member = make_member("race_i", "F", "M")
    session = login(member.username).ok()
    token = session["refresh_token"]
    results = _race(*[lambda: Api().post("/auth/refresh", {"refresh_token": token})] * 3)
    _no_server_errors(results)
    winners = [r for r in results if r.status == 200]
    assert len(winners) == 1, [(r.status, r.text[:120]) for r in results]
    assert all(r.status == 401 for r in results if r.status != 200)


@pytest.mark.concurrency
def test_parallel_friend_chat_sends_with_one_client_id(make_member):
    a, b = make_member("race_j", "F", "M"), make_member("race_k", "M", "F")
    befriend(a, b)
    cid = a.post(f"/social/friends/{b.user_id}/channel").ok()["channel"]["id"]
    client_id = str(uuid.uuid4())
    body = {"client_message_id": client_id, "body": "sent from four threads"}
    results = _race(*[lambda: a.post(f"/social/channels/{cid}/messages", body)] * 4)
    _no_server_errors(results)
    bodies = [m["body"] for m in b.get(f"/social/channels/{cid}/messages").ok()["messages"]]
    assert bodies.count("sent from four threads") == 1, bodies


@pytest.mark.concurrency
def test_parallel_community_group_joins(make_member):
    owner = make_member("race_o", "F", "M")
    joiners = [make_member(f"race_j{n}", "M" if n % 2 else "F", "F") for n in range(3)]
    category = owner.get("/engagement/group-categories").ok()["categories"][0]["slug"]
    created = owner.post("/engagement/groups", {
        "kind": "community", "category_slug": category,
        "name": f"E2E Race Club {uuid.uuid4().hex[:4]}", "description": "concurrency check"})
    assert created.status == 201, created.text
    gid = created["group"]["id"]
    try:
        calls = [lambda m=m: m.post(f"/engagement/groups/{gid}/join") for m in joiners]
        calls += [lambda m=joiners[0]: m.post(f"/engagement/groups/{gid}/join")]
        results = _race(*calls)
        _no_server_errors(results)
        members = items(owner.get(f"/engagement/groups/{gid}/members").ok().body, "members")
        ids = [m["user_id"] for m in members]
        assert len(ids) == len(set(ids)) == 4, ids
        assert owner.get(f"/engagement/groups/{gid}").ok()["group"]["member_count"] == 4
    finally:
        owner.delete(f"/engagement/groups/{gid}")
