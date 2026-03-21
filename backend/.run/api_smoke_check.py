import json
import sys
import urllib.error
import urllib.request

BASE = "http://localhost:8080/v1"
USER = "mock-user-001"

results = []


def call(method, path, payload=None, expected=(200,)):
    url = BASE + path
    data = None
    headers = {"Content-Type": "application/json"}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            status = resp.status
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as err:
        status = err.code
        body = err.read().decode("utf-8") if hasattr(err, "read") else ""
    except Exception as err:
        results.append((f"{method} {path}", False, f"EXCEPTION: {err}"))
        return None

    ok = status in expected
    results.append((f"{method} {path}", ok, f"status={status}"))
    if not ok:
        return None

    try:
        return json.loads(body) if body else {}
    except Exception:
        return {}


def main():
    ready_req = urllib.request.Request("http://localhost:8080/readyz", method="GET")
    try:
        with urllib.request.urlopen(ready_req, timeout=20) as resp:
            results.append(("GET /readyz", resp.status == 200, f"status={resp.status}"))
    except Exception as err:
        results.append(("GET /readyz", False, f"EXCEPTION: {err}"))

    call("GET", f"/users/{USER}/agreements/terms")
    call("PATCH", f"/users/{USER}/agreements/terms", {"accepted": True, "terms_version": "v2026-03-15"})
    agreement = call("GET", f"/users/{USER}/agreements/terms")
    if agreement:
        agreement_data = agreement.get("agreement", {})
        ok = bool(agreement_data.get("accepted")) and str(agreement_data.get("terms_version", "")).startswith("v2026-03-15")
        results.append(
            (
                "ASSERT terms persisted",
                ok,
                f"accepted={agreement_data.get('accepted')} version={agreement_data.get('terms_version')}",
            )
        )

    master = call("GET", "/master-data/preferences")
    if master:
        master_data = master.get("master_data", {})
        countries = master_data.get("countries") or []
        languages = master_data.get("languages") or []
        diets = master_data.get("diet_preferences") or []
        ok = ("India" in countries) and (len(languages) > 0) and (len(diets) > 0)
        results.append(("ASSERT master-data seeded", ok, f"countries={len(countries)} languages={len(languages)} diets={len(diets)}"))

    daily = call("GET", f"/engagement/daily-prompt/{USER}")
    prompt_id = None
    if daily:
        prompt_id = (((daily.get("daily_prompt") or {}).get("prompt") or {}).get("id"))
        ok = bool(prompt_id)
        results.append(("ASSERT daily prompt id present", ok, f"prompt_id={prompt_id}"))
    if prompt_id:
        call(
            "POST",
            f"/engagement/daily-prompt/{USER}/answer",
            {"prompt_id": prompt_id, "answer_text": "Smoke answer from automated check."},
        )
        responders = call("GET", f"/engagement/daily-prompt/{USER}/responders?limit=5&offset=0")
        ok = responders is not None and "pagination" in responders
        results.append(("ASSERT daily responders payload", ok, "pagination present" if ok else "missing pagination"))

    new_group = call(
        "POST",
        "/engagement/groups",
        {
            "owner_user_id": USER,
            "name": "Smoke Group 2026-03-15",
            "city": "Bengaluru",
            "topic": "fitness",
            "description": "Automated smoke test group",
            "visibility": "public",
            "invitee_user_ids": [],
        },
        expected=(200, 201),
    )
    if new_group:
        group = new_group.get("group", {})
        group_id = group.get("id")
        results.append(("ASSERT group created", bool(group_id), f"group_id={group_id}"))

    listed = call("GET", f"/engagement/groups?user_id={USER}&limit=10")
    if listed:
        groups = listed.get("groups", [])
        ok = isinstance(groups, list)
        results.append(("ASSERT groups list returned", ok, f"count={len(groups) if isinstance(groups, list) else -1}"))

    invites = call("GET", f"/engagement/group-invites?user_id={USER}&limit=10")
    if invites:
        ok = "invites" in invites
        results.append(("ASSERT group invites returned", ok, "invites key present" if ok else "missing invites key"))

    failed = [entry for entry in results if not entry[1]]
    print("\nSMOKE RESULTS")
    for name, ok, detail in results:
        print(f"{'PASS' if ok else 'FAIL'} | {name} | {detail}")

    if failed:
        print(f"\nFAILED_COUNT={len(failed)}")
        sys.exit(2)

    print("\nALL_SMOKE_CHECKS_PASSED")


if __name__ == "__main__":
    main()
