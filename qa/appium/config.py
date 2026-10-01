from __future__ import annotations

import os
import time
from dataclasses import dataclass
from urllib.parse import urlparse, urlunparse


def _api_host_base(default_api_base: str) -> str:
    explicit = os.getenv("QA_API_HOST_BASE_URL")
    if explicit:
        return explicit.rstrip("/")

    parsed = urlparse(default_api_base)
    path = parsed.path.rstrip("/")
    if path.endswith("/v1"):
        path = path[: -len("/v1")]
    return urlunparse(parsed._replace(path=path, params="", query="", fragment="")).rstrip("/")


@dataclass(frozen=True)
class AppiumConfig:
    server_url: str = os.getenv("APPIUM_SERVER_URL", "http://127.0.0.1:4723")
    platform_name: str = os.getenv("APPIUM_PLATFORM_NAME", "Android")
    automation_name: str = os.getenv("APPIUM_AUTOMATION_NAME", "UiAutomator2")
    device_name: str = os.getenv("ANDROID_DEVICE_NAME", "emulator-5554")
    app_package: str = os.getenv(
        "ANDROID_APP_PACKAGE", "com.verified_dating.verified_dating_app"
    )
    app_activity: str = os.getenv("ANDROID_APP_ACTIVITY", ".MainActivity")
    default_timeout: int = int(os.getenv("APPIUM_DEFAULT_TIMEOUT", "25"))
    long_timeout: int = int(os.getenv("APPIUM_LONG_TIMEOUT", "60"))
    new_command_timeout: int = int(os.getenv("APPIUM_NEW_COMMAND_TIMEOUT", "180"))
    no_reset: bool = os.getenv("APPIUM_NO_RESET", "false").lower() == "true"
    full_reset: bool = os.getenv("APPIUM_FULL_RESET", "false").lower() == "true"
    auto_grant_permissions: bool = True

    existing_username: str = os.getenv(
        "QA_EXISTING_USERNAME", "workflow_qa_20260803_final"
    )
    existing_password: str = os.getenv("QA_EXISTING_PASSWORD", "Password123!")
    signup_username: str = os.getenv(
        "QA_SIGNUP_USERNAME", f"appium_{int(time.time()) % 100000000:08d}"
    )
    signup_password: str = os.getenv("QA_SIGNUP_PASSWORD", "AppiumPass123")

    signup_name: str = os.getenv("QA_SIGNUP_NAME", "Appium QA User")
    signup_gender: str = os.getenv("QA_SIGNUP_GENDER", "Woman")
    signup_dob_day: str = os.getenv("QA_SIGNUP_DOB_DAY", "01")
    signup_dob_month: str = os.getenv("QA_SIGNUP_DOB_MONTH", "Jan")
    signup_dob_year: str = os.getenv("QA_SIGNUP_DOB_YEAR", "1998")

    filter_state: str = os.getenv("QA_FILTER_STATE", "Maharashtra")
    filter_city: str = os.getenv("QA_FILTER_CITY", "Thane")
    filter_smoking: str = os.getenv("QA_FILTER_SMOKING", "Never")
    filter_drinking: str = os.getenv("QA_FILTER_DRINKING", "Never")
    chat_message: str = os.getenv(
        "QA_CHAT_MESSAGE", f"Appium smoke message {int(time.time())}"
    )

    api_base_url: str = os.getenv("QA_API_BASE_URL", "http://127.0.0.1:18080/v1").rstrip("/")
    api_host_base_url: str = _api_host_base(api_base_url)
    bff_health_url: str = os.getenv("QA_BFF_HEALTH_URL", "http://127.0.0.1:18081/healthz")
    existing_user_id: str = os.getenv("QA_EXISTING_USER_ID", "")
    expected_min_discovery_candidates: int = int(os.getenv("QA_MIN_DISCOVERY_CANDIDATES", "1"))
    expected_min_matches: int = int(os.getenv("QA_MIN_MATCHES", "1"))
    enable_mutating_matrix: bool = os.getenv("QA_ENABLE_MUTATING_MATRIX", "false").lower() == "true"
    matrix_results_path: str = os.getenv(
        "QA_MATRIX_RESULTS_PATH",
        os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "qa",
            "reports",
            "appium",
            "matrix-results.json",
        ),
    )


CONFIG = AppiumConfig()
