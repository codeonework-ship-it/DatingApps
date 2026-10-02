from __future__ import annotations

import json
import os
import re
import subprocess
import time
from pathlib import Path

import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options

from api_client import ApiClient
from config import CONFIG
from helpers import DatingApp


_MATRIX_RESULTS: list[dict[str, object]] = []


@pytest.fixture(scope="session")
def appium_config():
    return CONFIG


@pytest.fixture(scope="function")
def api_client(appium_config):
    client = ApiClient(appium_config.api_base_url)
    client.authenticate(
        appium_config.existing_username,
        appium_config.existing_password,
    )
    return client


@pytest.fixture(scope="function")
def qa_user_id(api_client, appium_config) -> str:
    authenticated_id = api_client.authenticated_user_id or ""
    configured_id = appium_config.existing_user_id.strip()
    if configured_id and configured_id != authenticated_id:
        raise AssertionError(
            "QA_EXISTING_USER_ID does not match the user returned by credential login: "
            f"configured={configured_id}, authenticated={authenticated_id}"
        )
    if not authenticated_id:
        raise AssertionError("Credential login did not provide a QA user id")
    return authenticated_id


@pytest.fixture(scope="function")
def driver(request, appium_config):
    capabilities = {
        "platformName": appium_config.platform_name,
        "appium:automationName": appium_config.automation_name,
        "appium:deviceName": appium_config.device_name,
        "appium:udid": appium_config.device_name,
        "appium:appPackage": appium_config.app_package,
        "appium:appActivity": appium_config.app_activity,
        "appium:autoGrantPermissions": appium_config.auto_grant_permissions,
        "appium:newCommandTimeout": appium_config.new_command_timeout,
        "appium:adbExecTimeout": 60000,
        "appium:appWaitDuration": 60000,
        # Flutter animations can keep Android's accessibility tree active.
        # Explicit element waits handle readiness without a 10s idle wait
        # for every selector lookup.
        "appium:settings[waitForIdleTimeout]": 500,
        "appium:systemPort": int(os.getenv("APPIUM_SYSTEM_PORT", "8200")),
        "appium:noReset": appium_config.no_reset,
        "appium:fullReset": appium_config.full_reset,
    }
    app_path = os.getenv("ANDROID_APP_PATH")
    if app_path:
        capabilities["appium:app"] = str(Path(app_path).expanduser().resolve())

    if not appium_config.no_reset and not appium_config.full_reset:
        _clear_app_data_before_session(appium_config)

    options = UiAutomator2Options().load_capabilities(capabilities)
    driver = webdriver.Remote(appium_config.server_url, options=options)
    driver.implicitly_wait(0)
    _ensure_app_foreground(driver, appium_config)
    yield driver
    if getattr(request.node, "rep_call", None) and request.node.rep_call.failed:
        _capture_failure_artifacts(driver, request.node.name)
    try:
        driver.quit()
    except Exception:  # noqa: BLE001 - session may already be gone after app/AVD failure
        pass


@pytest.fixture(scope="function")
def app(driver, appium_config):
    return DatingApp(driver, appium_config)


@pytest.fixture(scope="function")
def device_member(appium_config):
    """The member the device is signed in as (QA_EXISTING_USERNAME), via the API."""
    from seed_members import Member

    client = ApiClient(appium_config.api_base_url)
    client.authenticate(appium_config.existing_username, appium_config.existing_password)
    return Member(
        username=appium_config.existing_username,
        user_id=client.authenticated_user_id or "",
        name="",
        api=client,
    )


@pytest.fixture(scope="function")
def counterpart_factory():
    """Creates synthetic counterpart members; runs registered cleanups afterwards."""
    from seed_members import create_member

    cleanups: list = []

    def make(role: str, display_name: str | None = None):
        return create_member(role, display_name)

    make.cleanups = cleanups  # type: ignore[attr-defined]
    yield make
    for cleanup in reversed(cleanups):
        try:
            cleanup()
        except Exception as exc:  # noqa: BLE001 - cleanup must not mask the test result
            print(f"[counterpart cleanup failed] {exc!r}")


@pytest.fixture(scope="function")
def ensure_deck(api_client, qa_user_id):
    """Make sure the Explore deck has candidates for the device member.

    Every run passes, likes and matches through the shared account's small
    pool (it seeks men; there are few synthetic men), so on a busy QA day
    GET /discovery/{id} returns nothing and deck specs could only skip.
    Seed completed male candidates through the API when the pool is low.
    """
    from api_client import extract_items
    from seed_members import create_deck_candidate

    body = api_client.get(f"/discovery/{qa_user_id}", query={"limit": 10, "mode": "all"}).require_status(200).body
    have = len(extract_items(body, "candidates", "profiles", "items"))
    for index in range(max(0, 3 - have)):
        create_deck_candidate(f"Deck Dev {int(time.time()) % 10000}{index}")
    return have


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()
    setattr(item, f"rep_{report.when}", report)
    if report.when != "call":
        return
    if report.failed and os.getenv("QA_ARTIFACT_DIR"):
        artifact_dir = Path(os.environ["QA_ARTIFACT_DIR"])
        artifact_dir.mkdir(parents=True, exist_ok=True)
        safe_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", item.name)
        (artifact_dir / f"{safe_name}.failure.txt").write_text(
            report.longreprtext, encoding="utf-8"
        )
    marker_names = sorted(marker.name for marker in item.iter_markers())
    matrix_markers = {
        "contract",
        "discovery_matrix",
        "profile_detail",
        "swipe_matrix",
        "match_matrix",
        "chat_matrix",
        "gift_matrix",
        "unlock_matrix",
        "resilience",
        "negative",
    }
    if matrix_markers.intersection(marker_names):
        _MATRIX_RESULTS.append(
            {
                "nodeid": item.nodeid,
                "outcome": report.outcome,
                "duration_seconds": round(float(report.duration), 3),
                "markers": marker_names,
                "longrepr": "" if report.passed else str(report.longrepr)[:4000],
            }
        )


def pytest_sessionfinish(session, exitstatus):
    path = Path(CONFIG.matrix_results_path).expanduser().resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "exitstatus": exitstatus,
        "generated_at_epoch": int(time.time()),
        "summary": {
            "total": len(_MATRIX_RESULTS),
            "passed": sum(1 for item in _MATRIX_RESULTS if item["outcome"] == "passed"),
            "failed": sum(1 for item in _MATRIX_RESULTS if item["outcome"] == "failed"),
            "skipped": sum(1 for item in _MATRIX_RESULTS if item["outcome"] == "skipped"),
        },
        "results": _MATRIX_RESULTS,
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def _ensure_app_foreground(driver, appium_config) -> None:
    deadline = time.time() + 20
    while time.time() < deadline:
        if _current_package(driver) == appium_config.app_package:
            time.sleep(3)
            return
        try:
            driver.activate_app(appium_config.app_package)
        except Exception:  # noqa: BLE001 - fall back to shell launch below
            pass
        try:
            activity = appium_config.app_activity
            component = f"{appium_config.app_package}/{activity}"
            driver.execute_script(
                "mobile: shell",
                {
                    "command": "am",
                    "args": [
                        "start",
                        "-W",
                        "-n",
                        component,
                        "-a",
                        "android.intent.action.MAIN",
                        "-c",
                        "android.intent.category.LAUNCHER",
                    ],
                    "timeout": 20000,
                },
            )
        except Exception:  # noqa: BLE001 - retry until deadline
            pass
        time.sleep(1)
    raise RuntimeError(
        f"App did not foreground: expected {appium_config.app_package}, got {_current_package(driver)}"
    )


def _clear_app_data(driver, appium_config) -> None:
    try:
        driver.terminate_app(appium_config.app_package)
    except Exception:  # noqa: BLE001 - app may not be running yet
        pass
    try:
        driver.execute_script(
            "mobile: shell",
            {
                "command": "pm",
                "args": ["clear", appium_config.app_package],
                "timeout": 20000,
            },
        )
    except Exception:  # noqa: BLE001 - Appium reset capability may already have cleared state
        pass


def _clear_app_data_before_session(appium_config) -> None:
    commands = [
        ["adb", "-s", appium_config.device_name, "shell", "am", "force-stop", appium_config.app_package],
        ["adb", "-s", appium_config.device_name, "shell", "pm", "clear", appium_config.app_package],
    ]
    for command in commands:
        try:
            subprocess.run(command, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:  # noqa: BLE001 - Appium reset can still provide isolation
            pass


def _current_package(driver) -> str:
    try:
        return driver.current_package or ""
    except Exception:  # noqa: BLE001
        return ""


def _capture_failure_artifacts(driver, test_name: str) -> None:
    safe_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", test_name)
    artifact_dir = Path(os.getenv(
        "QA_ARTIFACT_DIR",
        str(Path(__file__).resolve().parents[1] / "reports" / "appium" / "artifacts"),
    ))
    artifact_dir.mkdir(parents=True, exist_ok=True)
    try:
        driver.save_screenshot(str(artifact_dir / f"{safe_name}.png"))
    except Exception:  # noqa: BLE001
        pass
    try:
        (artifact_dir / f"{safe_name}.xml").write_text(driver.page_source, encoding="utf-8")
    except Exception:  # noqa: BLE001
        pass
    try:
        details = [
            f"captured_at_epoch={int(time.time())}",
            f"package={_current_package(driver)}",
            f"activity={getattr(driver, 'current_activity', '')}",
        ]
        try:
            details.append(f"window_size={driver.get_window_size()}")
            details.append(f"orientation={driver.orientation}")
        except Exception:  # noqa: BLE001
            pass
        details.extend(_device_network_details(driver))
        (artifact_dir / f"{safe_name}.txt").write_text("\n".join(details), encoding="utf-8")
    except Exception:  # noqa: BLE001
        pass
    workspace = Path(__file__).resolve().parents[2]
    _copy_tail_to_artifact(os.getenv("APPIUM_LOG_FILE"), artifact_dir / f"{safe_name}.appium.log")
    _copy_tail_to_artifact(
        str(workspace / "backend" / ".run" / "gateway.log"),
        artifact_dir / f"{safe_name}.gateway.log",
    )
    _copy_tail_to_artifact(
        str(workspace / "backend" / ".run" / "mobile-bff.log"),
        artifact_dir / f"{safe_name}.mobile-bff.log",
    )

    seed_summary = workspace / "qa" / "reports" / "appium" / "seed-preflight-summary.json"
    if seed_summary.exists():
        _copy_tail_to_artifact(str(seed_summary), artifact_dir / f"{safe_name}.seed-preflight-summary.json", max_lines=500)

    matrix_results = workspace / "qa" / "reports" / "appium" / "matrix-results.json"
    if matrix_results.exists():
        _copy_tail_to_artifact(str(matrix_results), artifact_dir / f"{safe_name}.matrix-results.json", max_lines=500)


def _device_network_details(driver) -> list[str]:
    details: list[str] = []
    for command, args, label in (
        ("svc", ["wifi"], "wifi"),
        ("svc", ["data"], "data"),
    ):
        try:
            result = driver.execute_script(
                "mobile: shell",
                {"command": command, "args": args, "timeout": 10000},
            )
            details.append(f"network_{label}={str(result).strip()}")
        except Exception:  # noqa: BLE001 - shell diagnostics are best effort
            pass
    try:
        result = driver.execute_script(
            "mobile: shell",
            {
                "command": "dumpsys",
                "args": ["connectivity"],
                "timeout": 10000,
            },
        )
        lines = [line.strip() for line in str(result).splitlines() if "NetworkAgentInfo" in line or "state:" in line]
        if lines:
            details.append("connectivity=" + " | ".join(lines[:8]))
    except Exception:  # noqa: BLE001 - shell diagnostics are best effort
        pass
    return details


def _copy_tail_to_artifact(source: str | None, target: Path, max_lines: int = 300) -> None:
    if not source:
        return
    path = Path(source).expanduser()
    if not path.exists() or not path.is_file():
        return
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        target.write_text("\n".join(lines[-max_lines:]), encoding="utf-8")
    except Exception:  # noqa: BLE001
        pass
