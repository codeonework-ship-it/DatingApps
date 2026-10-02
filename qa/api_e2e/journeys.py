"""Multi-step journeys shared by several test modules."""

from __future__ import annotations

from client import Member


def match(liker: Member, likee: Member) -> str:
    """Mutual like -> returns the match id."""
    first = liker.post("/swipe", {"user_id": liker.user_id, "target_user_id": likee.user_id,
                                  "is_like": True}).ok()
    assert first["accepted"] is True and first["mutual_match"] is False, first.text
    second = likee.post("/swipe", {"user_id": likee.user_id, "target_user_id": liker.user_id,
                                   "is_like": True}).ok()
    assert second["mutual_match"] is True and second["match_id"], second.text
    return second["match_id"]


def unlock_chat(match_id: str, creator: Member, responder: Member) -> None:
    """Quest unlock: creator writes a prompt, responder answers, creator approves."""
    creator.put(f"/matches/{match_id}/quest-template", {
        "creator_user_id": creator.user_id,
        "prompt_template": "What is your favourite weekend ritual and why?",
        "min_chars": 20, "max_chars": 400,
    }).ok()
    responder.post(f"/matches/{match_id}/quest-workflow/submit", {
        "submitter_user_id": responder.user_id,
        "response_text": "Slow coffee, a long walk by the sea and a good book.",
    }).ok()
    creator.post(f"/matches/{match_id}/quest-workflow/review", {
        "reviewer_user_id": creator.user_id, "decision_status": "approved",
        "review_reason": "Lovely answer",
    }).ok()


def befriend(requester: Member, accepter: Member, source: str = "search") -> None:
    sent = requester.post(f"/friends/{requester.user_id}",
                          {"friend_user_id": accepter.user_id, "source": source}).ok()
    assert sent["friend"]["status"] == "pending", sent.text
    accepter.post(f"/friends/{accepter.user_id}/{requester.user_id}/decision",
                  {"decision": "accept"}).ok()
