#!/usr/bin/env bash
set -eo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$ROOT_DIR/app"
REPORT_DIR="${QA_REPORT_DIR:-$ROOT_DIR/qa/reports/appium}"
mkdir -p "$REPORT_DIR"
PYTHON_BIN="${PYTHON_BIN:-$ROOT_DIR/.venv/bin/python}"
if [[ ! -x "$PYTHON_BIN" ]]; then
  PYTHON_BIN="$(command -v python3)"
fi

# Appium's uiautomator2 driver shells out to the Android SDK and reads only
# ANDROID_HOME/ANDROID_SDK_ROOT. The server inherits this environment, so an
# unset value fails every test at session creation with a driver error that
# looks like a product fault rather than a missing tool.
#
# Derive it from whichever adb is on PATH so the suite runs on a machine that
# has a working SDK without requiring a global export.
if [[ -z "${ANDROID_HOME:-}" && -n "${ANDROID_SDK_ROOT:-}" ]]; then
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
fi
if [[ -z "${ANDROID_HOME:-}" ]]; then
  if adb_path="$(command -v adb 2>/dev/null)"; then
    # <sdk>/platform-tools/adb -> <sdk>
    ANDROID_HOME="$(cd "$(dirname "$adb_path")/.." && pwd)"
    export ANDROID_HOME
  fi
fi
if [[ -z "${ANDROID_HOME:-}" || ! -d "$ANDROID_HOME" ]]; then
  echo "ANDROID_HOME could not be resolved. Install the Android SDK or export" >&2
  echo "ANDROID_HOME=/path/to/sdk before running this suite." >&2
  exit 1
fi
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"

export APPIUM_SERVER_URL="${APPIUM_SERVER_URL:-http://127.0.0.1:4723}"
export ANDROID_DEVICE_NAME="${ANDROID_DEVICE_NAME:-emulator-5554}"
export ANDROID_APP_PACKAGE="${ANDROID_APP_PACKAGE:-com.verified_dating.verified_dating_app}"
export ANDROID_APP_ACTIVITY="${ANDROID_APP_ACTIVITY:-.MainActivity}"
export QA_EXISTING_USERNAME="${QA_EXISTING_USERNAME:-workflow_qa_20260803_final}"
export QA_EXISTING_PASSWORD="${QA_EXISTING_PASSWORD:-Password123!}"
export QA_API_BASE_URL="${QA_API_BASE_URL:-http://127.0.0.1:18080/v1}"

PYTEST_ARGS=("$@")
PROFILE="${QA_APPIUM_PROFILE:-}"

has_marker_arg() {
  local arg
  for arg in "${PYTEST_ARGS[@]}"; do
    if [[ "$arg" == "-m" ]]; then
      return 0
    fi
  done
  return 1
}

if [[ ${#PYTEST_ARGS[@]} -gt 0 ]]; then
  case "${PYTEST_ARGS[0]}" in
    smoke|release|preflight|nightly|discovery-full|chat-full|gifts-full|engagement-full|negative|contract)
      PROFILE="${PROFILE:-${PYTEST_ARGS[0]}}"
      PYTEST_ARGS=("${PYTEST_ARGS[@]:1}")
      ;;
  esac
fi

PROFILE="${PROFILE:-smoke}"
if ! has_marker_arg; then
  case "$PROFILE" in
    smoke)
      PYTEST_ARGS=(-m "smoke" "${PYTEST_ARGS[@]}")
      ;;
    release)
      PYTEST_ARGS=(-m "auth_contract or core_journey or signup_workflow or security_negative" "${PYTEST_ARGS[@]}")
      ;;
    preflight)
      PYTEST_ARGS=(tests/test_00_seed_preflight.py -m "seed" "${PYTEST_ARGS[@]}")
      ;;
    discovery-full)
      PYTEST_ARGS=(-m "seed or discovery_matrix or filters" "${PYTEST_ARGS[@]}")
      ;;
    chat-full)
      PYTEST_ARGS=(-m "seed or match_matrix or chat_matrix" "${PYTEST_ARGS[@]}")
      ;;
    gifts-full)
      PYTEST_ARGS=(-m "seed or gift_matrix" "${PYTEST_ARGS[@]}")
      ;;
    engagement-full)
      PYTEST_ARGS=(-m "engagement_ui or unlock_matrix" "${PYTEST_ARGS[@]}")
      ;;
    negative)
      PYTEST_ARGS=(-m "negative" "${PYTEST_ARGS[@]}")
      ;;
    contract)
      PYTEST_ARGS=(-m "contract and not requires_appium" "${PYTEST_ARGS[@]}")
      ;;
    nightly)
      ;;
    *)
      echo "Unknown QA_APPIUM_PROFILE/profile: $PROFILE" >&2
      echo "Supported profiles: smoke, release, preflight, nightly, discovery-full, chat-full, gifts-full, engagement-full, negative, contract" >&2
      exit 2
      ;;
  esac
fi

if [[ "${QA_SKIP_APK_BUILD:-false}" != "true" ]]; then
  cd "$APP_DIR"
  flutter build apk --debug --split-per-abi \
    --dart-define=API_BASE_URL="${API_BASE_URL:-http://10.0.2.2:18080/v1}" \
    --dart-define=QA_FORCED_USER_ID="${QA_FORCED_USER_ID:-}" \
    --dart-define=ENABLE_QA_AUTOMATION=true
fi

if [[ "${QA_SKIP_APK_INSTALL:-false}" != "true" ]]; then
  DEVICE_ABI="${ANDROID_DEVICE_ABI:-$(adb -s "$ANDROID_DEVICE_NAME" shell getprop ro.product.cpu.abi | tr -d '\r')}"
  case "$DEVICE_ABI" in
    arm64-v8a|armeabi-v7a|x86_64) APK_ABI="$DEVICE_ABI" ;;
    *)
      echo "Unsupported Android device ABI: $DEVICE_ABI" >&2
      exit 2
      ;;
  esac
  APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-$APK_ABI-debug.apk"
  if [[ ! -f "$APK_PATH" ]]; then
    echo "Expected split APK was not built: $APK_PATH" >&2
    exit 1
  fi
  adb -s "$ANDROID_DEVICE_NAME" shell pm clear "$ANDROID_APP_PACKAGE" >/dev/null 2>&1 || true
  adb -s "$ANDROID_DEVICE_NAME" install -r -d "$APK_PATH" >/dev/null
fi

cd "$ROOT_DIR/qa/appium"
"$PYTHON_BIN" -m pytest tests \
  --html="$REPORT_DIR/android-smoke.html" \
  --self-contained-html \
  "${PYTEST_ARGS[@]}"
