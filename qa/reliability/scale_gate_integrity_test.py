#!/usr/bin/env python3
"""Assert the distributed scale gate cannot be talked into a false capacity claim.

`distributed_scale_gate.py` is the only thing standing between a local laptop
run and a signed production capacity claim. It carries three guards:

  * `production-soak` refuses any duration below 86400 seconds,
  * distributed profiles refuse loopback targets,
  * `capacity_claim` is emitted true only for a non-loopback, multi-target soak.

Nothing tested those guards. Deleting any one of them leaves a harness that
still runs, still writes a report, and still prints "passed" — while the report
now blesses a 60-second run against 127.0.0.1 as production evidence. That is
precisely the failure this repository has already been bitten by elsewhere: a
gate whose green result means nothing.

Run directly (`python3 scale_gate_integrity_test.py`); it is also invoked by
`run_local_reliability_gate.sh` so the guards are re-checked on every gate run.
It performs no load and needs no services.
"""

from __future__ import annotations

import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
GATE = HERE / "distributed_scale_gate.py"
CHAOS_GATE = HERE / "run_production_chaos_gate.sh"
REMOTE_TARGETS = "https://alpha.example.invalid,https://beta.example.invalid"


def _run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(GATE), *args],
        capture_output=True,
        text=True,
        timeout=60,
    )


def _run_chaos(env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    merged = {**os.environ, **env}
    merged.pop("SCALE_CHAOS_REPORT", None)
    # If a guard under test has been deleted the script proceeds to its
    # injection phase, whose default hold is 60s. Collapse the hold so the
    # assertion below reports the missing guard instead of the harness dying
    # on a timeout — a timeout is a much weaker signal, and it is slow enough
    # that the check would likely be disabled rather than fixed.
    merged["SCALE_CHAOS_HOLD_SECONDS"] = "1"
    return subprocess.run(
        ["bash", str(CHAOS_GATE)],
        capture_output=True,
        text=True,
        timeout=120,
        env=merged,
    )


def _assert_rejected(label: str, args: list[str], expected: str) -> None:
    result = _run(*args)
    combined = f"{result.stdout}{result.stderr}"
    assert result.returncode != 0, (
        f"{label}: the gate accepted an invalid configuration "
        f"(exit 0). A capacity claim could be produced from it.\n{combined}"
    )
    assert expected in combined, (
        f"{label}: rejected, but not for the expected reason. "
        f"Wanted {expected!r} in output.\n{combined}"
    )
    print(f"  ok  {label}")


def test_production_soak_cannot_be_shortened() -> None:
    _assert_rejected(
        "production-soak refuses a shortened duration",
        ["--profile", "production-soak", "--duration", "60",
         "--base-urls", REMOTE_TARGETS],
        "cannot be shortened below 86400 seconds",
    )


def test_production_soak_rejects_one_second_under() -> None:
    # The boundary matters: a `<` that became `<=`, or 86399 slipping through,
    # would still be a sub-24-hour run wearing a 24-hour label.
    _assert_rejected(
        "production-soak refuses 86399 seconds",
        ["--profile", "production-soak", "--duration", "86399",
         "--base-urls", REMOTE_TARGETS],
        "cannot be shortened below 86400 seconds",
    )


def test_distributed_profiles_reject_loopback() -> None:
    for target in ("http://127.0.0.1:18080/v1", "http://localhost:18080/v1"):
        _assert_rejected(
            f"distributed-burst refuses {target}",
            ["--profile", "distributed-burst", "--base-urls", target],
            "require non-loopback load-balanced targets",
        )


def test_soak_rejects_loopback_even_at_full_duration() -> None:
    _assert_rejected(
        "production-soak refuses loopback at full duration",
        ["--profile", "production-soak", "--duration", "86400",
         "--base-urls", "http://127.0.0.1:18080/v1"],
        "require non-loopback load-balanced targets",
    )


def test_capacity_claim_is_gated_in_source() -> None:
    """The claim must require soak *and* non-local *and* more than one target.

    Asserted against the source because producing a true claim for real would
    mean standing up multiple non-loopback hosts and running for 24 hours.
    """
    source = GATE.read_text()
    assert '"capacity_claim": args.profile == "production-soak" and not local and len(bases) > 1' in source, (
        "the capacity_claim condition changed. It must stay conjunctive: a "
        "production-soak profile, non-loopback targets, and more than one base "
        "URL. Weakening any term lets a lesser run be reported as capacity "
        "evidence."
    )
    print("  ok  capacity_claim stays conjunctive")


def _assert_chaos_rejected(label: str, env: dict[str, str], expected: str) -> None:
    result = _run_chaos(env)
    combined = f"{result.stdout}{result.stderr}"
    assert result.returncode != 0, (
        f"{label}: the chaos gate accepted the configuration and would have "
        f"started injecting failures.\n{combined}"
    )
    assert expected in combined, (
        f"{label}: rejected, but not for the expected reason. "
        f"Wanted {expected!r} in output.\n{combined}"
    )
    print(f"  ok  {label}")


def test_chaos_gate_refuses_without_explicit_opt_in() -> None:
    """Chaos must never start from ambient configuration alone.

    These guards are what keep a failure-injection run from being pointed at
    the wrong environment. Losing any of them is not a failing test somewhere
    later — it is a drill that starts killing processes it should not touch.
    """
    with tempfile.TemporaryDirectory() as tmp:
        hook = Path(tmp) / "hook.sh"
        hook.write_text("#!/bin/sh\nexit 0\n")
        hook.chmod(hook.stat().st_mode | stat.S_IXUSR)
        not_executable = Path(tmp) / "plain.sh"
        not_executable.write_text("#!/bin/sh\nexit 0\n")
        not_executable.chmod(0o644)

        base = {
            "SCALE_API_BASE_URLS": REMOTE_TARGETS,
            "SCALE_CHAOS_HOOK": str(hook),
            "SCALE_RECOVERY_HOOK": str(hook),
        }

        _assert_chaos_rejected(
            "chaos refuses without SCALE_ALLOW_CHAOS=true",
            base,
            "Set SCALE_ALLOW_CHAOS=true only inside the approved test environment.",
        )
        _assert_chaos_rejected(
            "chaos refuses SCALE_ALLOW_CHAOS=1 (only literal true opts in)",
            {**base, "SCALE_ALLOW_CHAOS": "1"},
            "Set SCALE_ALLOW_CHAOS=true only inside the approved test environment.",
        )
        for target in ("http://127.0.0.1:18080/v1", "http://localhost:18080/v1"):
            _assert_chaos_rejected(
                f"chaos refuses loopback target {target}",
                {**base, "SCALE_ALLOW_CHAOS": "true", "SCALE_API_BASE_URLS": target},
                "Production chaos gate refuses loopback targets.",
            )
        _assert_chaos_rejected(
            "chaos refuses a non-executable hook",
            {**base, "SCALE_ALLOW_CHAOS": "true",
             "SCALE_CHAOS_HOOK": str(not_executable)},
            "Hook is not an absolute executable",
        )
        _assert_chaos_rejected(
            "chaos refuses a relative hook path",
            {**base, "SCALE_ALLOW_CHAOS": "true", "SCALE_CHAOS_HOOK": "hook.sh"},
            "Hook is not an absolute executable",
        )


def main() -> int:
    tests = [value for name, value in sorted(globals().items()) if name.startswith("test_")]
    print(f"scale gate integrity: {len(tests)} checks")
    for test in tests:
        test()
    print("scale gate integrity checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
