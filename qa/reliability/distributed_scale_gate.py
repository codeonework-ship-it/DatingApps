#!/usr/bin/env python3
"""Cross-instance duplicate/reconnect/burst/soak proof harness.

The production-soak profile refuses to run for less than 24 hours. Local runs
are explicitly labelled as non-capacity evidence in the JSON report.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import socket
import ssl
import statistics
import threading
import time
import uuid
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen


PROFILES = {
    "local": {"duration": 15, "concurrency": 24, "duplicate": 32, "reconnect": 40},
    "distributed-burst": {"duration": 300, "concurrency": 200, "duplicate": 500, "reconnect": 1000},
    "production-soak": {"duration": 86400, "concurrency": 100, "duplicate": 1000, "reconnect": 5000},
}


@dataclass
class Results:
    latencies: list[float] = field(default_factory=list)
    statuses: Counter = field(default_factory=Counter)
    errors: Counter = field(default_factory=Counter)
    lock: threading.Lock = field(default_factory=threading.Lock)

    def add(self, elapsed: float, status: int, error: str = "") -> None:
        with self.lock:
            self.latencies.append(elapsed)
            self.statuses[str(status)] += 1
            if error:
                self.errors[error] += 1


def http_json(url: str, method: str = "GET", token: str = "", payload: dict | None = None,
              idem: str = "", timeout: float = 15) -> tuple[int, bytes, dict]:
    data = None if payload is None else json.dumps(payload, sort_keys=True).encode()
    headers = {"Accept": "application/json", "X-Correlation-ID": f"scale-{uuid.uuid4()}"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if idem:
        headers["Idempotency-Key"] = idem
    request = Request(url, data=data, headers=headers, method=method)
    try:
        with urlopen(request, timeout=timeout) as response:  # noqa: S310 - operator-selected target
            return response.status, response.read(), dict(response.headers.items())
    except HTTPError as exc:
        return exc.code, exc.read(), dict(exc.headers.items())


def authenticate(base: str, username: str, password: str) -> tuple[str, str]:
    status, raw, _ = http_json(f"{base}/auth/login", "POST", payload={"username": username, "password": password})
    body = json.loads(raw or b"{}")
    if status != 200 or not body.get("access_token") or not body.get("user_id"):
        raise RuntimeError(f"login failed against {base}: HTTP {status} {body}")
    return str(body["access_token"]), str(body["user_id"])


def websocket_probe(base: str, token: str, user_id: str, timeout: float = 8) -> None:
    parsed = urlparse(base)
    secure = parsed.scheme == "https"
    port = parsed.port or (443 if secure else 80)
    connection = socket.create_connection((parsed.hostname or "", port), timeout=timeout)
    if secure:
        connection = ssl.create_default_context().wrap_socket(connection, server_hostname=parsed.hostname)
    key = base64.b64encode(os.urandom(16)).decode()
    path = f"{parsed.path.rstrip('/')}/realtime/notifications?user_id={user_id}&after=0"
    request = (
        f"GET {path} HTTP/1.1\r\nHost: {parsed.hostname}:{port}\r\nUpgrade: websocket\r\n"
        f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n"
        f"Authorization: Bearer {token}\r\n\r\n"
    )
    connection.sendall(request.encode())
    response = b""
    while b"\r\n\r\n" not in response and len(response) < 16384:
        chunk = connection.recv(4096)
        if not chunk:
            break
        response += chunk
    connection.close()
    first_line = response.split(b"\r\n", 1)[0]
    if b" 101 " not in first_line:
        raise RuntimeError(first_line.decode(errors="replace") or "empty websocket response")
    expected = base64.b64encode(hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest()).decode()  # noqa: S324
    if expected.lower().encode() not in response.lower():
        raise RuntimeError("websocket accept key mismatch")


def percentile(values: list[float], ratio: float) -> float:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, int((len(ordered) - 1) * ratio))] if ordered else 0.0


def find_unlocked_match(base: str, token: str, user_id: str) -> str:
    status, raw, _ = http_json(f"{base}/matches/{user_id}", token=token)
    if status != 200:
        return ""
    body = json.loads(raw or b"{}")
    for match in body.get("matches") or body.get("items") or []:
        match_id = str(match.get("id") or match.get("match_id") or "")
        if not match_id:
            continue
        s, r, _ = http_json(f"{base}/matches/{match_id}/unlock-state", token=token)
        state = json.loads(r or b"{}") if s == 200 else {}
        if state.get("chat_unlocked", state.get("unlocked")):
            return match_id
    return ""


def wallet_balance(base: str, token: str, user_id: str) -> int | None:
    status, raw, _ = http_json(f"{base}/wallet/{user_id}/coins", token=token)
    if status != 200:
        return None
    return int((json.loads(raw or b"{}").get("wallet") or {}).get("coin_balance", -1))


def money_storm(bases: list[str], token: str, user_id: str, attempts: int, match_id: str,
                gift_id: str, price: int) -> dict:
    """Duplicate a paid gift send across instances and check its effects.

    Status codes alone cannot prove money correctness, so this reads the
    durable effects: exactly one gift send may exist for the key and the
    wallet must move by exactly one price. Any other outcome is a lost or
    duplicated money write.
    """
    match_id = match_id or find_unlocked_match(bases[0], token, user_id)
    if not match_id:
        return {"ran": False, "passed": False, "reason": "no unlocked match for the test member"}
    before = wallet_balance(bases[0], token, user_id)
    idem = f"scale-money-{uuid.uuid4()}"
    payload = {"gift_id": gift_id, "sender_user_id": user_id, "message_text": "scale gate"}

    def send(index: int) -> tuple[int, bytes, dict]:
        return http_json(f"{bases[index % len(bases)]}/chat/{match_id}/gifts/send", "POST", token, payload, idem)

    with ThreadPoolExecutor(max_workers=min(attempts, 128)) as pool:
        results = list(pool.map(send, range(attempts)))
    statuses = Counter(str(item[0]) for item in results)
    send_ids = set()
    for status, raw, _ in results:
        if status == 200:
            try:
                send_ids.add(str((json.loads(raw or b"{}").get("gift_send") or {}).get("id", "")))
            except ValueError:
                send_ids.add("unparseable")
    after = wallet_balance(bases[0], token, user_id)
    delta = None if before is None or after is None else before - after
    ok_statuses = set(statuses) <= {"200"}
    passed = ok_statuses and len(send_ids) == 1 and delta == price
    return {
        "ran": True, "passed": bool(passed), "attempts": attempts, "statuses": statuses,
        "distinct_gift_sends": len(send_ids), "wallet_before": before, "wallet_after": after,
        "wallet_delta": delta, "expected_delta": price, "match_id": match_id, "gift_id": gift_id,
        "note": "requires gifts enabled in the target (RELEASE_EXCLUDED_FLAGS must not exclude gifts_enabled)",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", choices=PROFILES, default="local")
    parser.add_argument("--base-urls", default=os.getenv("SCALE_API_BASE_URLS", "http://127.0.0.1:18080/v1"))
    parser.add_argument("--username", default=os.getenv("QA_EXISTING_USERNAME", "workflow_qa_20260803_final"))
    parser.add_argument("--password", default=os.getenv("QA_EXISTING_PASSWORD", "Password123!"))
    parser.add_argument("--duration", type=int)
    parser.add_argument("--report", default=os.getenv("SCALE_DISTRIBUTED_REPORT", ""))
    parser.add_argument("--money-storm", action="store_true",
                        default=os.getenv("SCALE_MONEY_STORM", "").lower() == "true",
                        help="also duplicate a paid gift send and verify one debit and one send")
    parser.add_argument("--gift-match-id", default=os.getenv("SCALE_GIFT_MATCH_ID", ""))
    parser.add_argument("--gift-id", default=os.getenv("SCALE_GIFT_ID", "rose_blue_rare"))
    parser.add_argument("--gift-price", type=int, default=int(os.getenv("SCALE_GIFT_PRICE", "1")))
    args = parser.parse_args()

    bases = [item.strip().rstrip("/") for item in args.base_urls.split(",") if item.strip()]
    if not bases:
        raise SystemExit("at least one API base URL is required")
    settings = dict(PROFILES[args.profile])
    if args.duration is not None:
        settings["duration"] = args.duration
    if args.profile == "production-soak" and settings["duration"] < 86400:
        raise SystemExit("production-soak cannot be shortened below 86400 seconds")
    local = all(urlparse(base).hostname in {"127.0.0.1", "localhost"} for base in bases)
    if args.profile != "local" and local:
        raise SystemExit("distributed profiles require non-loopback load-balanced targets")

    token, user_id = authenticate(bases[0], args.username, args.password)
    idem_key = f"scale-duplicate-{uuid.uuid4()}"
    payload = {"notifications_enabled": True}

    def duplicate(index: int) -> tuple[int, bytes, dict]:
        return http_json(f"{bases[index % len(bases)]}/settings/{user_id}", "PATCH", token, payload, idem_key)

    with ThreadPoolExecutor(max_workers=min(settings["duplicate"], 256)) as pool:
        duplicate_results = list(pool.map(duplicate, range(settings["duplicate"])))
    duplicate_statuses = Counter(str(item[0]) for item in duplicate_results)
    duplicate_bodies = {item[1] for item in duplicate_results}
    replay_count = sum(1 for _, _, headers in duplicate_results if str(headers.get("X-Idempotent-Replay", "")).lower() == "true")
    conflict_status, _, _ = http_json(
        f"{bases[0]}/settings/{user_id}", "PATCH", token,
        {"notifications_enabled": False}, idem_key,
    )

    money = {"ran": False, "passed": True, "reason": "not requested"}
    if args.money_storm:
        money = money_storm(bases, token, user_id, min(settings["duplicate"], 64),
                            args.gift_match_id, args.gift_id, args.gift_price)

    reconnect_errors: Counter = Counter()
    def reconnect(index: int) -> None:
        try:
            websocket_probe(bases[index % len(bases)], token, user_id)
        except (OSError, RuntimeError) as exc:
            reconnect_errors[type(exc).__name__ + ":" + str(exc)] += 1
    with ThreadPoolExecutor(max_workers=min(settings["reconnect"], 128)) as pool:
        list(pool.map(reconnect, range(settings["reconnect"])))

    sustained = Results()
    deadline = time.monotonic() + settings["duration"]
    def reader(index: int) -> None:
        route = (f"/profile/{user_id}/summary", f"/notifications/{user_id}/unread-count", f"/matches/{user_id}")[index % 3]
        while time.monotonic() < deadline:
            started = time.perf_counter()
            try:
                status, _, _ = http_json(bases[index % len(bases)] + route, token=token)
                sustained.add((time.perf_counter() - started) * 1000, status)
            except (URLError, TimeoutError, OSError) as exc:
                sustained.add((time.perf_counter() - started) * 1000, 0, type(exc).__name__)
    with ThreadPoolExecutor(max_workers=settings["concurrency"]) as pool:
        list(pool.map(reader, range(settings["concurrency"])))

    total = sum(sustained.statuses.values())
    failures = sum(count for status, count in sustained.statuses.items() if status == "0" or int(status) >= 400)
    report = {
        "capacity_claim": args.profile == "production-soak" and not local and len(bases) > 1,
        "profile": args.profile, "base_url_count": len(bases), "duration_seconds": settings["duration"],
        "duplicate_storm": {"attempts": settings["duplicate"], "statuses": duplicate_statuses,
                            "distinct_bodies": len(duplicate_bodies), "replays": replay_count,
                            "payload_conflict_status": conflict_status},
        "reconnect_storm": {"attempts": settings["reconnect"], "errors": reconnect_errors},
        "money_storm": money,
        "sustained": {"requests": total, "statuses": sustained.statuses, "errors": sustained.errors,
                      "error_rate": failures / total if total else 1.0,
                      "p95_ms": round(percentile(sustained.latencies, .95), 2),
                      "p99_ms": round(percentile(sustained.latencies, .99), 2),
                      "mean_ms": round(statistics.fmean(sustained.latencies), 2) if sustained.latencies else 0},
    }
    output = json.dumps(report, indent=2, sort_keys=True)
    print(output)
    if args.report:
        os.makedirs(os.path.dirname(os.path.abspath(args.report)), exist_ok=True)
        with open(args.report, "w", encoding="utf-8") as handle:
            handle.write(output + "\n")
    passed = (duplicate_statuses == {"200": settings["duplicate"]} and len(duplicate_bodies) == 1
              and replay_count >= settings["duplicate"] - len(bases) and conflict_status == 409
              and not reconnect_errors and total > 0 and failures / total <= .01
              and money["passed"])
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
