#!/usr/bin/env python3
"""Bounded local reliability gate for the native-PostgreSQL API path.

This is an engineering regression gate, not evidence of ten-million-user
capacity. Production burst/soak tests must run from distributed load generators
against a production-shaped environment.
"""

from __future__ import annotations

import argparse
import json
import os
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
    "smoke": {"duration": 8, "concurrency": 16, "target_rps": 80},
    "burst": {"duration": 30, "concurrency": 48, "target_rps": 110},
    "soak": {"duration": 600, "concurrency": 32, "target_rps": 100},
}


@dataclass
class Results:
    latencies_ms: list[float] = field(default_factory=list)
    statuses: Counter = field(default_factory=Counter)
    timeout_tiers: Counter = field(default_factory=Counter)
    transport_errors: Counter = field(default_factory=Counter)
    lock: threading.Lock = field(default_factory=threading.Lock)

    def add(self, latency_ms: float, status: int, tier: str, error: str = "") -> None:
        with self.lock:
            self.latencies_ms.append(latency_ms)
            self.statuses[str(status)] += 1
            if tier:
                self.timeout_tiers[tier] += 1
            if error:
                self.transport_errors[error] += 1


def request_json(url: str, *, token: str = "", timeout: float = 12) -> tuple[int, dict, dict]:
    headers = {
        "Accept": "application/json",
        "X-Client-Platform": "native-postgres-reliability-gate",
        "X-Correlation-ID": f"reliability-{uuid.uuid4()}",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = Request(url, headers=headers, method="GET")
    try:
        with urlopen(request, timeout=timeout) as response:  # noqa: S310 - local QA endpoint
            raw = response.read()
            return response.status, json.loads(raw or b"{}"), dict(response.headers.items())
    except HTTPError as exc:
        raw = exc.read()
        try:
            body = json.loads(raw or b"{}")
        except json.JSONDecodeError:
            body = {"raw": raw.decode("utf-8", errors="replace")}
        return exc.code, body, dict(exc.headers.items())


def authenticate(base_url: str, username: str, password: str) -> tuple[str, str]:
    payload = json.dumps({"username": username, "password": password}).encode()
    request = Request(
        f"{base_url}/auth/login",
        data=payload,
        headers={"Accept": "application/json", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=15) as response:  # noqa: S310 - local QA endpoint
            body = json.load(response)
    except HTTPError as exc:
        raise SystemExit(f"login failed with HTTP {exc.code}: {exc.read().decode(errors='replace')}") from exc
    token = str(body.get("access_token") or "").strip()
    user_id = str(body.get("user_id") or "").strip()
    if response.status != 200 or not token or not user_id:
        raise SystemExit(f"login did not return a usable session: {body}")
    return token, user_id


def percentile(values: list[float], value: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = min(len(ordered) - 1, max(0, int(round((len(ordered) - 1) * value))))
    return ordered[index]


def worker(deadline: float, interval: float, base_url: str, token: str, user_id: str, results: Results) -> None:
    routes = (
        f"/discovery/{user_id}?limit=20&mode=all",
        f"/matches/{user_id}",
        f"/notifications/{user_id}/unread-count",
        f"/profile/{user_id}/summary",
        "/master-data/preferences",
    )
    iteration = 0
    while time.monotonic() < deadline:
        iteration_started = time.monotonic()
        route = routes[iteration % len(routes)]
        iteration += 1
        started = time.perf_counter()
        try:
            status, _, headers = request_json(f"{base_url}{route}", token=token)
            elapsed = (time.perf_counter() - started) * 1000
            tier = str(headers.get("X-Timeout-Tier") or headers.get("X-timeout-tier") or "")
            results.add(elapsed, status, tier)
        except (URLError, TimeoutError, OSError) as exc:
            elapsed = (time.perf_counter() - started) * 1000
            results.add(elapsed, 0, "", type(exc).__name__)
        remaining = interval - (time.monotonic() - iteration_started)
        if remaining > 0:
            time.sleep(remaining)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", choices=PROFILES, default="smoke")
    parser.add_argument("--base-url", default=os.getenv("QA_API_BASE_URL", "http://127.0.0.1:18080/v1"))
    parser.add_argument("--username", default=os.getenv("QA_EXISTING_USERNAME", "workflow_qa_20260803_final"))
    parser.add_argument("--password", default=os.getenv("QA_EXISTING_PASSWORD", "Password123!"))
    parser.add_argument("--duration", type=int)
    parser.add_argument("--concurrency", type=int)
    parser.add_argument("--target-rps", type=int)
    parser.add_argument("--max-p99-ms", type=float, default=float(os.getenv("QA_RELIABILITY_MAX_P99_MS", "2500")))
    parser.add_argument("--max-error-rate", type=float, default=float(os.getenv("QA_RELIABILITY_MAX_ERROR_RATE", "0.01")))
    parser.add_argument("--report", default=os.getenv("QA_RELIABILITY_REPORT", ""))
    args = parser.parse_args()

    parsed = urlparse(args.base_url)
    if parsed.hostname not in {"127.0.0.1", "localhost"}:
        raise SystemExit("This gate only accepts a loopback API URL; use a dedicated distributed tool for remote load.")
    settings = PROFILES[args.profile]
    duration = args.duration or settings["duration"]
    concurrency = args.concurrency or settings["concurrency"]
    target_rps = args.target_rps or settings["target_rps"]
    if duration < 1 or concurrency < 1 or concurrency > 256 or target_rps < 1:
        raise SystemExit("duration/target-rps must be positive and concurrency must be between 1 and 256")

    token, user_id = authenticate(args.base_url.rstrip("/"), args.username, args.password)
    results = Results()
    started = time.monotonic()
    deadline = started + duration
    worker_interval = concurrency / target_rps
    with ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [executor.submit(worker, deadline, worker_interval, args.base_url.rstrip("/"), token, user_id, results) for _ in range(concurrency)]
        for future in futures:
            future.result()
    elapsed = max(time.monotonic() - started, 0.001)

    total = sum(results.statuses.values())
    failures = sum(count for status, count in results.statuses.items() if status == "0" or int(status) >= 400)
    error_rate = failures / total if total else 1.0
    report = {
        "capacity_claim": False,
        "scope": "bounded local native-PostgreSQL regression",
        "profile": args.profile,
        "duration_seconds": round(elapsed, 3),
        "concurrency": concurrency,
        "target_requests_per_second": target_rps,
        "requests": total,
        "requests_per_second": round(total / elapsed, 2),
        "latency_ms": {
            "mean": round(statistics.fmean(results.latencies_ms), 2) if results.latencies_ms else 0,
            "p50": round(percentile(results.latencies_ms, 0.50), 2),
            "p95": round(percentile(results.latencies_ms, 0.95), 2),
            "p99": round(percentile(results.latencies_ms, 0.99), 2),
            "max": round(max(results.latencies_ms), 2) if results.latencies_ms else 0,
        },
        "statuses": dict(sorted(results.statuses.items())),
        "timeout_tiers": dict(sorted(results.timeout_tiers.items())),
        "transport_errors": dict(results.transport_errors),
        "error_rate": round(error_rate, 6),
        "thresholds": {"max_p99_ms": args.max_p99_ms, "max_error_rate": args.max_error_rate},
    }
    output = json.dumps(report, indent=2, sort_keys=True)
    print(output)
    if args.report:
        report_path = os.path.abspath(args.report)
        os.makedirs(os.path.dirname(report_path), exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as handle:
            handle.write(output + "\n")

    passed = (
        total > 0
        and report["latency_ms"]["p99"] <= args.max_p99_ms
        and error_rate <= args.max_error_rate
        and results.timeout_tiers["normal_read"] > 0
    )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
