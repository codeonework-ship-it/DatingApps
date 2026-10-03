"""Discovery -> like -> liked-me -> match -> quest unlock -> chat -> notifications."""

from __future__ import annotations

import pytest

from client import items, wait_for
from journeys import unlock_chat


pytestmark = pytest.mark.journey("discovery_match_chat")


@pytest.fixture(scope="module")
def state():
    return {}


def _candidate_ids(member, **params):
    body = member.get(f"/discovery/{member.user_id}", params=params or None).ok().body
    return [c.get("id") or c.get("user_id") for c in body.get("candidates", [])]


def test_new_members_see_each_other_in_discovery(pair):
    woman, man = pair
    assert man.user_id in _candidate_ids(woman, limit=300)
    assert woman.user_id in _candidate_ids(man, limit=300)


def test_discovery_respects_seeking_gender(pair, make_member):
    woman, _ = pair
    other_woman = make_member("disc_w2", "F", "M")
    # A woman seeking men must not be dealt another woman.
    assert other_woman.user_id not in _candidate_ids(woman, limit=300)


def test_like_appears_in_liked_me_then_mutual_like_creates_match(pair, state):
    woman, man = pair
    first = woman.post("/swipe", {"user_id": woman.user_id, "target_user_id": man.user_id,
                                  "is_like": True}).ok()
    assert first["accepted"] is True and first["mutual_match"] is False

    liked_me = man.get(f"/discovery/{man.user_id}/liked-me").ok()
    assert woman.user_id in [p.get("user_id") or p.get("id") for p in liked_me["profiles"]]

    second = man.post("/swipe", {"user_id": man.user_id, "target_user_id": woman.user_id,
                                 "is_like": True}).ok()
    assert second["mutual_match"] is True and second["match_id"]
    state["match_id"] = second["match_id"]

    # Matched members leave each other's discovery deck.
    assert man.user_id not in _candidate_ids(woman, limit=300)


def test_new_match_lists_friendly_preview_not_nil(pair, state):
    """Regression API-01: a match without messages previewed as '<nil>'."""
    woman, man = pair
    for member, other in ((woman, man), (man, woman)):
        matches = member.get(f"/matches/{member.user_id}").ok()["matches"]
        row = next(m for m in matches if m["id"] == state["match_id"])
        assert row["userId"] == other.user_id
        assert row["lastMessage"] not in ("", "<nil>", None)
        assert "<nil>" not in row["lastMessage"]


def test_new_match_can_chat_without_a_quest_by_default(pair, state):
    """DEFAULT_UNLOCK_POLICY_VARIANT=allow_without_template: a fresh match is open."""
    woman, _ = pair
    match_id = state["match_id"]
    unlock = woman.get(f"/matches/{match_id}/unlock-state").ok()
    assert unlock["chat_unlocked"] is True and unlock["has_requirement"] is False, unlock.text
    assert unlock["unlock_policy_variant"] == "allow_without_template"
    woman.post(f"/chat/{match_id}/messages", {"text": "Hi!", "sender_id": woman.user_id}).ok()


def test_quest_template_locks_chat_until_approved(pair, state):
    """A member may still ask for a quest: the template locks chat until approval."""
    woman, man = pair
    match_id = state["match_id"]
    woman.put(f"/matches/{match_id}/quest-template", {
        "creator_user_id": woman.user_id,
        "prompt_template": "What is your favourite weekend ritual and why?",
        "min_chars": 20, "max_chars": 400}).ok()
    locked = man.post(f"/chat/{match_id}/messages", {"text": "Hi!", "sender_id": man.user_id})
    assert locked.status == 423, locked.text
    assert locked["error_code"] == "CHAT_LOCKED_REQUIREMENT_PENDING"
    unlock_chat(match_id, creator=woman, responder=man)
    unlock = woman.get(f"/matches/{match_id}/unlock-state").ok()
    assert unlock["chat_unlocked"] is True


def test_quest_review_by_the_submitter_is_a_client_error(pair, state):
    """Regression API-02: business-rule violations are 403/409 with a reason, not 502."""
    _, man = pair
    response = man.post(f"/matches/{state['match_id']}/quest-workflow/review",
                        {"reviewer_user_id": man.user_id, "decision_status": "approved"})
    # The quest was already approved by unlock_chat, so this is "not pending" (409);
    # a self-review of a pending submission is 403.
    assert response.status in (403, 409), f"{response.status}: {response.text}"
    assert response["error_code"] in ("QUEST_NOT_PENDING", "QUEST_SELF_REVIEW"), response.text
    assert "temporarily unavailable" not in response.text


def test_chat_messages_are_delivered_and_previewed(pair, state):
    woman, man = pair
    match_id = state["match_id"]
    woman.post(f"/chat/{match_id}/messages", {"text": "Hello from the e2e suite",
                                              "sender_id": woman.user_id}).ok()
    man.post(f"/chat/{match_id}/messages", {"text": "Hi back!", "sender_id": man.user_id}).ok()
    messages = man.get(f"/chat/{match_id}/messages", params={"limit": 50}).ok()["messages"]
    texts = [m["text"] for m in messages]
    assert "Hello from the e2e suite" in texts and "Hi back!" in texts
    preview = next(m for m in woman.get(f"/matches/{woman.user_id}").ok()["matches"]
                   if m["id"] == match_id)
    assert preview["lastMessage"] == "Hi back!"


def test_member_cannot_post_as_someone_else(pair, state):
    woman, man = pair
    spoof = man.post(f"/chat/{state['match_id']}/messages",
                     {"text": "spoof", "sender_id": woman.user_id})
    assert spoof.status == 403, spoof.text


def test_like_match_and_message_notifications(make_member):
    # Its own pair, so the test also runs alone (QA Lab re-runs single cases).
    woman, man = make_member("dn_w", "F", "M"), make_member("dn_m", "M", "F")
    woman.post("/swipe", {"user_id": woman.user_id, "target_user_id": man.user_id, "is_like": True}).ok()
    assert man.post("/swipe", {"user_id": man.user_id, "target_user_id": woman.user_id,
                               "is_like": True}).ok()["mutual_match"] is True

    def events():
        body = man.get(f"/notifications/{man.user_id}", params={"limit": 50}).ok().body
        return {n["event_type"] for n in body.get("notifications", [])}

    got = wait_for(lambda: {"like.received", "match.created"} <= events() and events())
    assert {"like.received", "match.created"} <= (got or set()), got
    unread = man.get(f"/notifications/{man.user_id}/unread-count").ok()["unread_count"]
    assert unread >= 2
    before = {n["id"] for n in man.get(f"/notifications/{man.user_id}", params={"limit": 50})
              .ok()["notifications"]}
    man.post(f"/notifications/{man.user_id}/read-all").ok()
    # Chat-message notifications are produced asynchronously and may land after
    # read-all; every notification that existed before it must now be read.
    after = man.get(f"/notifications/{man.user_id}", params={"limit": 50}).ok()["notifications"]
    still_unread = [n for n in after if n["id"] in before and not n["is_read"]]
    assert still_unread == [], still_unread
    # The count is exactly the late arrivals. A late one can land between the
    # list and the count, so compare a fresh list with the count until stable.

    def count_matches_late():
        listed = man.get(f"/notifications/{man.user_id}", params={"limit": 50}).ok()["notifications"]
        late = [n for n in listed if n["id"] not in before and not n["is_read"]]
        count = man.get(f"/notifications/{man.user_id}/unread-count").ok()["unread_count"]
        return (count, len(late)) if count == len(late) else None

    assert wait_for(count_matches_late), "unread count never matched the late notifications"


def test_mark_match_read_clears_unread(pair, state):
    woman, _ = pair
    woman.post(f"/matches/{state['match_id']}/read", {"user_id": woman.user_id}).ok()
    row = next(m for m in woman.get(f"/matches/{woman.user_id}").ok()["matches"]
               if m["id"] == state["match_id"])
    assert row["unreadCount"] == 0


def test_block_hides_member_and_unblock_restores(make_member):
    blocker = make_member("blk_w", "F", "M")
    blocked = make_member("blk_m", "M", "F")
    assert blocked.user_id in _candidate_ids(blocker, limit=300)
    blocker.post("/safety/block", {"user_id": blocker.user_id,
                                   "blocked_user_id": blocked.user_id}).ok()
    assert blocked.user_id not in _candidate_ids(blocker, limit=300)
    # Neither side can find the other in friend search after a block.
    found = blocked.get(f"/friends/{blocked.user_id}/search", params={"q": blocker.username}).ok()
    assert blocker.user_id not in [r["user_id"] for r in found["results"]]
    listed = items(blocker.get(f"/blocked-users/{blocker.user_id}").ok().body,
                   "blocked_users", "items", "users")
    assert any(blocked.user_id in str(row) for row in listed)
    blocker.post("/safety/unblock", {"user_id": blocker.user_id,
                                     "blocked_user_id": blocked.user_id}).ok()
    assert blocked.user_id in _candidate_ids(blocker, limit=300)


def test_unmatch_removes_the_match(make_member):
    from journeys import match

    woman = make_member("unm_w", "F", "M")
    man = make_member("unm_m", "M", "F")
    match_id = match(woman, man)
    woman.delete(f"/matches/{match_id}", params={"user_id": woman.user_id}).ok()
    for member in (woman, man):
        ids = [m["id"] for m in member.get(f"/matches/{member.user_id}").ok()["matches"]]
        assert match_id not in ids
