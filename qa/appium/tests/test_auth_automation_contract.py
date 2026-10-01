from __future__ import annotations

from pathlib import Path

import pytest


@pytest.mark.auth_contract
def test_runnable_mobile_automation_has_no_retired_auth_assumptions():
    appium_dir = Path(__file__).resolve().parents[1]
    scanned = [
        appium_dir / "config.py",
        appium_dir / "conftest.py",
        appium_dir / "helpers.py",
        appium_dir / "run_android.sh",
        appium_dir / "run_full_android_automation.sh",
        appium_dir / "pytest.ini",
        appium_dir / "fixtures" / "users.json",
    ]
    scanned.extend(sorted((appium_dir / "tests").glob("test_*.py")))
    scanned = [path for path in scanned if path.name != Path(__file__).name]

    retired_terms = (
        "BYPASS_" + "OTP_VALIDATION",
        "QA_" + "OTP_CODE",
        "QA_EXISTING_" + "PHONE",
        "QA_SIGNUP_" + "PHONE",
        "generated_" + "phone",
        "/auth/send-" + "otp",
        "/auth/verify-" + "otp",
        "qa.signup." + "otp_input",
        "qa.signin." + "otp_input",
        "otp_" + "verify",
    )
    violations = []
    for path in scanned:
        content = path.read_text(encoding="utf-8").lower()
        for term in retired_terms:
            if term.lower() in content:
                violations.append(f"{path.relative_to(appium_dir)}: {term}")

    retired_filename_fragment = "_" + "otp" + "_"
    for path in (appium_dir / "tests").glob("test_*.py"):
        if retired_filename_fragment in path.name.lower():
            violations.append(f"{path.relative_to(appium_dir)}: retired auth filename")

    assert not violations, "Retired mobile authentication automation returned:\n" + "\n".join(violations)

