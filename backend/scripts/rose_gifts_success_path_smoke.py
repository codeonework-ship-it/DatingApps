import datetime
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

BASE = os.getenv("ROSE_GIFTS_SMOKE_BASE", "http://localhost:8080/v1").rstrip("/")
MATCH_ID = os.getenv("ROSE_GIFTS_SMOKE_MATCH_ID", "match-rose-smoke-001")
SENDER_USER_ID = os.getenv("ROSE_GIFTS_SMOKE_SENDER", "11111111-1111-1111-1111-111111111111")
RECEIVER_USER_ID = os.getenv("ROSE_GIFTS_SMOKE_RECEIVER", "mock-female-001")
TOPUP_AMOUNT = int(os.getenv("ROSE_GIFTS_SMOKE_TOPUP", "25"))


def call(method: str, path: str, body=None, headers=None):
    url = f"{BASE}{path}"
    payload = None
    req_headers = {"Content-Type": "application/json"}
    if headers:
        req_headers.update(headers)
    if body is not None:
        payload = json.dumps(body).encode("utf-8")

    req = urllib.request.Request(url, data=payload, method=method, headers=req_headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            raw = response.read().decode("utf-8", "ignore")
            parsed = json.loads(raw) if raw else None
            return {
                "ok": True,
                "status": response.status,
                "url": url,
                "headers": dict(response.headers.items()),
                "body": parsed,
            }
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8", "ignore")
        try:
            parsed = json.loads(raw) if raw else None
        except Exception:
            parsed = raw
        return {
            "ok": False,
            "status": error.code,
            "url": url,
            "headers": dict(error.headers.items()) if error.headers else {},
            "body": parsed,
        }
    except Exception as error:
        return {"ok": False, "status": None, "url": url, "headers": {}, "body": str(error)}


def normalize_steps(steps):
    summary = {}
    for key, result in steps.items():
        summary[key] = {
            "ok": bool(result.get("ok")),
            "status": result.get("status"),
        }
    return summary


def main():
    now = datetime.datetime.utcnow()
    evidence = {
        "meta": {
            "started_at": now.isoformat() + "Z",
            "base": BASE,
            "match_id": MATCH_ID,
            "sender_user_id": SENDER_USER_ID,
            "receiver_user_id": RECEIVER_USER_ID,
            "topup_amount": TOPUP_AMOUNT,
        },
        "steps": {},
    }

    gateway_ready_url = os.getenv("ROSE_GIFTS_SMOKE_READY_URL", "http://localhost:8080/readyz")
    try:
        with urllib.request.urlopen(gateway_ready_url, timeout=8) as response:
            raw = response.read().decode("utf-8", "ignore")
            parsed = json.loads(raw) if raw else None
            evidence["steps"]["ready_gateway"] = {
                "ok": response.status == 200,
                "status": response.status,
                "url": gateway_ready_url,
                "headers": dict(response.headers.items()),
                "body": parsed,
            }
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8", "ignore")
        try:
            parsed = json.loads(raw) if raw else None
        except Exception:
            parsed = raw
        evidence["steps"]["ready_gateway"] = {
            "ok": False,
            "status": error.code,
            "url": gateway_ready_url,
            "headers": dict(error.headers.items()) if error.headers else {},
            "body": parsed,
        }
    except Exception as error:
        evidence["steps"]["ready_gateway"] = {
            "ok": False,
            "status": None,
            "url": gateway_ready_url,
            "headers": {},
            "body": str(error),
        }

    evidence["steps"]["catalog_get"] = call("GET", "/chat/gifts")
    evidence["steps"]["wallet_before"] = call("GET", f"/wallet/{SENDER_USER_ID}/coins")

    evidence["steps"]["wallet_topup"] = call(
        "POST",
        f"/wallet/{SENDER_USER_ID}/coins/top-up",
        {"amount": TOPUP_AMOUNT, "reason": "qa_success_path_smoke", "requested_by": "qa-smoke-script"},
    )

    evidence["steps"]["gift_panel_event"] = call(
        "POST",
        f"/chat/{MATCH_ID}/gifts/events",
        {
            "event_name": "gift_panel_opened",
            "user_id": SENDER_USER_ID,
            "match_id": MATCH_ID,
            "wallet_coins": ((evidence["steps"]["wallet_before"].get("body") or {}).get("wallet") or {}).get("coin_balance", 0),
            "catalog_count": (evidence["steps"]["catalog_get"].get("body") or {}).get("count", 0),
        },
    )

    evidence["steps"]["gift_preview_event"] = call(
        "POST",
        f"/chat/{MATCH_ID}/gifts/events",
        {
            "event_name": "gift_preview_opened",
            "user_id": SENDER_USER_ID,
            "match_id": MATCH_ID,
            "gift_id": "rose_blue_rare",
            "tier": "premium_common",
            "price_coins": 1,
        },
    )

    evidence["steps"]["send_free"] = call(
        "POST",
        f"/chat/{MATCH_ID}/gifts/send",
        {"gift_id": "rose_red_single", "sender_user_id": SENDER_USER_ID, "receiver_user_id": RECEIVER_USER_ID},
        {"Idempotency-Key": "rose-smoke-free-001", "X-User-ID": SENDER_USER_ID},
    )

    evidence["steps"]["send_paid"] = call(
        "POST",
        f"/chat/{MATCH_ID}/gifts/send",
        {"gift_id": "rose_blue_rare", "sender_user_id": SENDER_USER_ID, "receiver_user_id": RECEIVER_USER_ID},
        {"Idempotency-Key": "rose-smoke-paid-001", "X-User-ID": SENDER_USER_ID},
    )

    evidence["steps"]["messages_after"] = call("GET", f"/chat/{MATCH_ID}/messages")
    evidence["steps"]["wallet_after"] = call("GET", f"/wallet/{SENDER_USER_ID}/coins")
    evidence["steps"]["wallet_audit"] = call("GET", f"/wallet/{SENDER_USER_ID}/coins/audit?limit=20")

    evidence["summary"] = {
        "steps": normalize_steps(evidence["steps"]),
        "expected_success_path": {
            "send_free_status": evidence["steps"]["send_free"].get("status"),
            "send_paid_status": evidence["steps"]["send_paid"].get("status"),
            "wallet_audit_status": evidence["steps"]["wallet_audit"].get("status"),
        },
    }

    if evidence["steps"]["send_free"].get("status") == 423 or evidence["steps"]["send_paid"].get("status") == 423:
        evidence["summary"]["blocker"] = {
            "reason": "chat lock still active for smoke identities",
            "next_action": "use unlock-capable test pair or run local with DEFAULT_UNLOCK_POLICY_VARIANT=allow_without_template",
        }

    repo_root = Path(__file__).resolve().parents[2]
    out_dir = repo_root / "documents" / "codex"
    out_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    out_file = out_dir / f"ROSE_GIFTS_SUCCESS_PATH_EVIDENCE_{ts}.json"
    out_file.write_text(json.dumps(evidence, indent=2))

    failed = [key for key, item in evidence["steps"].items() if not item.get("ok")]
    print(out_file)
    print("FAILED_STEPS", failed)


if __name__ == "__main__":
    main()
