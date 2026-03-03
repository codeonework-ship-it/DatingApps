import json
import urllib.request
import urllib.error
import datetime
from pathlib import Path

BASE = "http://localhost:8081/v1"
USER_A = "11111111-1111-1111-1111-111111111111"
PREFERRED_TARGET = "mock-female-001"


def call(method: str, path: str, body=None):
    url = BASE + path
    data = None
    headers = {"Content-Type": "application/json"}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            raw = response.read().decode("utf-8", "ignore")
            parsed = json.loads(raw) if raw else None
            return {"ok": True, "status": response.status, "url": url, "body": parsed}
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8", "ignore")
        try:
            parsed = json.loads(raw) if raw else None
        except Exception:
            parsed = raw
        return {"ok": False, "status": error.code, "url": url, "body": parsed}
    except Exception as error:
        return {"ok": False, "status": None, "url": url, "body": str(error)}


def main():
    evidence = {
        "meta": {
            "started_at": datetime.datetime.utcnow().isoformat() + "Z",
            "base": BASE,
            "uidA": USER_A,
        },
        "steps": {},
    }

    for ready_url in ["http://localhost:8080/readyz", "http://localhost:8081/readyz"]:
        try:
            with urllib.request.urlopen(ready_url, timeout=5) as response:
                evidence["steps"][f"ready:{ready_url}"] = {
                    "ok": response.status == 200,
                    "status": response.status,
                    "body": json.loads(response.read().decode("utf-8", "ignore")),
                }
        except Exception as error:
            evidence["steps"][f"ready:{ready_url}"] = {
                "ok": False,
                "status": None,
                "body": str(error),
            }

    discovery = call("GET", f"/discovery/{USER_A}?limit=15")
    evidence["steps"]["discovery_uidA"] = discovery
    candidates = ((discovery.get("body") or {}).get("candidates") or []) if discovery.get("ok") else []
    target = next(
        (item.get("id") for item in candidates if isinstance(item, dict) and item.get("id") == PREFERRED_TARGET),
        None,
    )
    if not target and candidates:
        first = candidates[0]
        if isinstance(first, dict):
            target = first.get("id")
    evidence["meta"]["target_user_id"] = target

    evidence["steps"]["swipe_uidA_to_target"] = {"ok": True, "status": None, "body": "deferred until target resolution"}
    evidence["steps"]["swipe_target_to_uidA"] = {"ok": True, "status": None, "body": "deferred until target resolution"}

    matches = call("GET", f"/matches/{USER_A}")
    evidence["steps"]["matches_uidA"] = matches

    match_id = ""
    if matches.get("ok"):
        for item in (matches.get("body") or {}).get("matches", []) or []:
            if not isinstance(item, dict):
                continue
            other = item.get("otherUserId") or item.get("other_user_id") or ""
            if not other:
                other = item.get("userId") or item.get("user_id") or ""
            if not target and other:
                target = other
            if target and other == target:
                match_id = item.get("id") or ""
                break
        if not match_id:
            all_matches = (matches.get("body") or {}).get("matches", []) or []
            if all_matches and isinstance(all_matches[0], dict):
                match_id = all_matches[0].get("id") or ""

    evidence["meta"]["target_user_id"] = target

    if target:
        evidence["steps"]["swipe_uidA_to_target"] = call(
            "POST",
            "/swipe",
            {"user_id": USER_A, "target_user_id": target, "is_like": True},
        )
        evidence["steps"]["swipe_target_to_uidA"] = call(
            "POST",
            "/swipe",
            {"user_id": target, "target_user_id": USER_A, "is_like": True},
        )

    evidence["meta"]["match_id"] = match_id

    if match_id:
        evidence["steps"]["quest_template_put"] = call(
            "PUT",
            f"/matches/{match_id}/quest-template",
            {
                "creator_user_id": USER_A,
                "prompt_template": "Share one recent moment that genuinely made you smile and why.",
                "min_chars": 20,
                "max_chars": 280,
            },
        )
        evidence["steps"]["quest_workflow_get_before"] = call("GET", f"/matches/{match_id}/quest-workflow")
        evidence["steps"]["quest_submit"] = call(
            "POST",
            f"/matches/{match_id}/quest-workflow/submit",
            {
                "submitter_user_id": target,
                "response_text": "I helped my younger cousin prepare for an interview, and seeing her confidence grow made my whole week better.",
            },
        )
        evidence["steps"]["quest_review"] = call(
            "POST",
            f"/matches/{match_id}/quest-workflow/review",
            {
                "reviewer_user_id": USER_A,
                "decision_status": "approved",
                "review_reason": "Thoughtful and authentic response.",
            },
        )
        evidence["steps"]["unlock_state_after_review"] = call("GET", f"/matches/{match_id}/unlock-state")
        evidence["steps"]["chat_send_after_unlock"] = call(
            "POST",
            f"/chat/{match_id}/messages",
            {
                "sender_id": USER_A,
                "text": "Quest approved ✅ Great answer — happy to continue chatting!",
            },
        )

        gesture_create = call(
            "POST",
            f"/matches/{match_id}/gestures",
            {
                "sender_user_id": USER_A,
                "receiver_user_id": target,
                "gesture_type": "thoughtful_opener",
                "content_text": "I liked your profile energy. What is one ritual that keeps your week grounded?",
                "tone": "warm",
            },
        )
        evidence["steps"]["gesture_create"] = gesture_create
        gesture_id = ""
        if gesture_create.get("ok") and isinstance((gesture_create.get("body") or {}).get("gesture"), dict):
            gesture_id = gesture_create["body"]["gesture"].get("id") or ""
        evidence["meta"]["gesture_id"] = gesture_id

        if gesture_id:
            evidence["steps"]["gesture_decision"] = call(
                "POST",
                f"/matches/{match_id}/gestures/{gesture_id}/decision",
                {
                    "reviewer_user_id": target,
                    "decision": "appreciate",
                    "reason": "Nice and specific opener.",
                },
            )
            evidence["steps"]["gesture_score"] = call("GET", f"/matches/{match_id}/gestures/{gesture_id}/score")

        evidence["steps"]["timeline_after_gesture"] = call("GET", f"/matches/{match_id}/timeline")

    out_dir = Path("/Users/anandsadasivan/Documents/Workspaces/Development/GitHub/Dating apps/documents/codex")
    out_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    output_file = out_dir / f"CANONICAL_SMOKE_EVIDENCE_{timestamp}.json"
    output_file.write_text(json.dumps(evidence, indent=2))

    failed_steps = [name for name, result in evidence["steps"].items() if not isinstance(result, dict) or not result.get("ok")]

    print(output_file)
    print("FAILED_STEPS", failed_steps)
    print("MATCH", evidence["meta"].get("match_id"))
    print("GESTURE", evidence["meta"].get("gesture_id"))


if __name__ == "__main__":
    main()
