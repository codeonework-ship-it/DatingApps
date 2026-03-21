import json
import datetime
import urllib.request
import urllib.error
from pathlib import Path

BASE = "http://localhost:8080/v1"
SENDER = "11111111-1111-1111-1111-111111111111"
RECEIVER = "22222222-2222-2222-2222-222222222222"


def call(method, path, body=None):
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")

    req = urllib.request.Request(
        BASE + path,
        data=data,
        method=method,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            raw = response.read().decode("utf-8", "ignore")
            parsed = json.loads(raw) if raw else None
            return response.status, parsed
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8", "ignore")
        try:
            parsed = json.loads(raw) if raw else None
        except Exception:
            parsed = raw
        return error.code, parsed


def find_or_make_match_id():
    sender_swipe_status, _ = call(
        "POST",
        "/swipe",
        {"user_id": SENDER, "target_user_id": RECEIVER, "is_like": True},
    )
    receiver_swipe_status, receiver_swipe_body = call(
        "POST",
        "/swipe",
        {"user_id": RECEIVER, "target_user_id": SENDER, "is_like": True},
    )
    matches_status, matches_body = call("GET", f"/matches/{SENDER}")

    match_id = ""
    if isinstance(receiver_swipe_body, dict):
        match_id = (receiver_swipe_body.get("match_id") or "").strip()
        match = receiver_swipe_body.get("match")
        if not match_id and isinstance(match, dict):
            match_id = (match.get("id") or "").strip()

    if not match_id and isinstance(matches_body, dict):
        for item in matches_body.get("matches") or []:
            if not isinstance(item, dict):
                continue
            other = (
                item.get("otherUserId")
                or item.get("other_user_id")
                or item.get("userId")
                or item.get("user_id")
            )
            if other == RECEIVER:
                match_id = (item.get("id") or "").strip()
                break

    return {
        "swipe_sender_status": sender_swipe_status,
        "swipe_receiver_status": receiver_swipe_status,
        "list_matches_status": matches_status,
        "match_id": match_id,
    }


def ensure_chat_unlocked(match_id):
    call(
        "PUT",
        f"/matches/{match_id}/quest-template",
        {
            "creator_user_id": SENDER,
            "prompt_template": "Share one recent moment that genuinely made you smile and why.",
            "min_chars": 20,
            "max_chars": 280,
        },
    )
    call(
        "POST",
        f"/matches/{match_id}/quest-workflow/submit",
        {
            "submitter_user_id": RECEIVER,
            "response_text": "I helped my cousin prepare for an interview and that made my week.",
        },
    )
    call(
        "POST",
        f"/matches/{match_id}/quest-workflow/review",
        {
            "reviewer_user_id": SENDER,
            "decision_status": "approved",
            "review_reason": "Thoughtful answer",
        },
    )


def pick_message(messages_body, sender_id, text_hint):
    if not isinstance(messages_body, dict):
        return None
    for message in messages_body.get("messages") or []:
        if not isinstance(message, dict):
            continue
        sid = message.get("senderId") or message.get("sender_id")
        text = message.get("text") or ""
        if sid == sender_id and text_hint in text:
            return message
    return None


def run_proof():
    timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    proof = {
        "timestamp_utc": timestamp,
        "base": BASE,
        "participants": {"sender_user_id": SENDER, "receiver_user_id": RECEIVER},
        "steps": {},
    }

    bootstrap = find_or_make_match_id()
    proof["steps"]["match_bootstrap"] = bootstrap

    match_id = bootstrap["match_id"]
    if not match_id:
        raise RuntimeError("Unable to resolve match_id for sender/receiver pair")

    proof["match_id"] = match_id
    ensure_chat_unlocked(match_id)

    send_text = f"Receipt proof ping at {timestamp}"
    sent_status, sent_body = call(
        "POST",
        f"/chat/{match_id}/messages",
        {"sender_id": SENDER, "text": send_text},
    )
    proof["steps"]["sent"] = {
        "status": sent_status,
        "body": sent_body,
        "text": send_text,
    }

    sender_before_status, sender_before_body = call(
        "GET", f"/chat/{match_id}/messages?limit=50"
    )
    sender_before_msg = pick_message(sender_before_body, SENDER, send_text)
    proof["steps"]["sender_view_before_receiver_poll"] = {
        "status": sender_before_status,
        "message": sender_before_msg,
    }

    receiver_status, receiver_body = call("GET", f"/chat/{match_id}/messages?limit=50")
    receiver_seen = pick_message(receiver_body, SENDER, send_text)
    proof["steps"]["delivered_receiver_session"] = {
        "status": receiver_status,
        "receiver_seen_sender_message": receiver_seen is not None,
        "message": receiver_seen,
    }

    read_status, read_body = call(
        "POST", f"/matches/{match_id}/read", {"user_id": RECEIVER}
    )
    proof["steps"]["mark_read_by_receiver"] = {
        "status": read_status,
        "body": read_body,
    }

    sender_after_status, sender_after_body = call(
        "GET", f"/chat/{match_id}/messages?limit=50"
    )
    sender_after_msg = pick_message(sender_after_body, SENDER, send_text)
    proof["steps"]["sender_view_after_read"] = {
        "status": sender_after_status,
        "message": sender_after_msg,
    }

    proof["assertions"] = {
        "sent": bool(
            sent_status == 200
            and isinstance(sent_body, dict)
            and sent_body.get("accepted") is True
        ),
        "delivered": bool(receiver_status == 200 and receiver_seen is not None),
        "read": bool(
            read_status == 200
            and isinstance(read_body, dict)
            and read_body.get("success") is True
            and isinstance(sender_after_msg, dict)
            and bool(sender_after_msg.get("readAt"))
        ),
    }
    proof["result"] = "PASS" if all(proof["assertions"].values()) else "FAIL"

    out_dir = Path(__file__).resolve().parents[2] / "documents" / "codex"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f"RECEIPT_LIFECYCLE_PROOF_{timestamp}.json"
    out_file.write_text(json.dumps(proof, indent=2), encoding="utf-8")

    print(out_file)
    print(json.dumps({"result": proof["result"], "assertions": proof["assertions"]}, indent=2))


if __name__ == "__main__":
    run_proof()
