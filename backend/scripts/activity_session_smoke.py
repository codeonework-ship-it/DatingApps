import datetime
import json
import urllib.error
import urllib.request
from pathlib import Path

BASE = "http://localhost:8081/v1"


def call(method: str, path: str, body=None):
    url = BASE + path
    data = None
    headers = {"Content-Type": "application/json"}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
    request = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
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


def main():
    artifact = {
        "meta": {
            "started_at": datetime.datetime.utcnow().isoformat() + "Z",
            "base": BASE,
        },
        "steps": {},
    }

    start = call(
        "POST",
        "/activities/sessions/start",
        {
            "match_id": "match-activity-smoke-001",
            "initiator_user_id": "11111111-1111-1111-1111-111111111111",
            "participant_user_id": "22222222-2222-2222-2222-222222222222",
            "activity_type": "value_match_round",
            "metadata": {"source": "story-4.1-smoke"},
        },
    )
    artifact["steps"]["start_session"] = start

    session_id = ""
    if start.get("ok"):
        session_id = ((start.get("body") or {}).get("session") or {}).get("id", "")
    artifact["meta"]["session_id"] = session_id

    if session_id:
        artifact["steps"]["submit_user_a"] = call(
            "POST",
            f"/activities/sessions/{session_id}/submit",
            {
                "user_id": "11111111-1111-1111-1111-111111111111",
                "responses": ["family", "consistency", "communication"],
            },
        )
        artifact["steps"]["submit_user_b"] = call(
            "POST",
            f"/activities/sessions/{session_id}/submit",
            {
                "user_id": "22222222-2222-2222-2222-222222222222",
                "responses": ["honesty", "kindness", "shared goals"],
            },
        )
        artifact["steps"]["summary"] = call(
            "GET",
            f"/activities/sessions/{session_id}/summary",
        )

    out_dir = Path("/Users/anandsadasivan/Documents/Workspaces/Development/GitHub/Dating apps/documents/codex")
    out_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    out_file = out_dir / f"ACTIVITY_SESSION_SMOKE_{timestamp}.json"
    out_file.write_text(json.dumps(artifact, indent=2))

    failed_steps = [step for step, result in artifact["steps"].items() if not result.get("ok")]
    print(out_file)
    print("FAILED_STEPS", failed_steps)


if __name__ == "__main__":
    main()
