#!/usr/bin/env bash
set -eo pipefail

PYTEST_ARGS=()

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APPium_DIR="$ROOT_DIR/qa/appium"
BACKEND_DIR="$ROOT_DIR/backend"
REPORT_DIR="${QA_REPORT_DIR:-$ROOT_DIR/qa/reports/appium}"
mkdir -p "$REPORT_DIR"

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
export API_BASE_URL="${API_BASE_URL:-http://10.0.2.2:18080/v1}"
export QA_API_BASE_URL="${QA_API_BASE_URL:-http://127.0.0.1:18080/v1}"
export QA_GATEWAY_HEALTH_URL="${QA_GATEWAY_HEALTH_URL:-http://127.0.0.1:18080/healthz}"
export QA_BFF_HEALTH_URL="${QA_BFF_HEALTH_URL:-http://127.0.0.1:18081/healthz}"
export QA_EXISTING_USERNAME="${QA_EXISTING_USERNAME:-workflow_qa_20260803_final}"
export QA_EXISTING_PASSWORD="${QA_EXISTING_PASSWORD:-Password123!}"
export APPIUM_INSTALL_SCOPE="${APPIUM_INSTALL_SCOPE:-local}"
export APPIUM_AUTO_START="${APPIUM_AUTO_START:-true}"
export APPIUM_LOG_FILE="${APPIUM_LOG_FILE:-$REPORT_DIR/appium-server.log}"

PYTEST_ARGS=("$@")
PROFILE="${QA_APPIUM_PROFILE:-}"
if [[ -z "$PROFILE" && ${#PYTEST_ARGS[@]} -gt 0 ]]; then
  case "${PYTEST_ARGS[0]}" in
    smoke|release|preflight|nightly|discovery-full|chat-full|gifts-full|engagement-full|negative|contract)
      PROFILE="${PYTEST_ARGS[0]}"
      ;;
  esac
fi
PROFILE="${PROFILE:-smoke}"

PYTHON_BIN="${PYTHON_BIN:-$ROOT_DIR/.venv/bin/python}"
if [[ ! -x "$PYTHON_BIN" ]]; then
  PYTHON_BIN="$(command -v python3)"
fi

say() { printf '\n==> %s\n' "$*"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "$1 is required but was not found." >&2
    exit 1
  fi
}

appium_is_ready() {
  "$PYTHON_BIN" - <<'PY'
import json
import os
import sys
import urllib.request

base = os.environ.get("APPIUM_SERVER_URL", "http://127.0.0.1:4723").rstrip("/")
for path in ("/status", "/wd/hub/status"):
    try:
        with urllib.request.urlopen(base + path, timeout=2) as response:
            payload = json.loads(response.read().decode("utf-8"))
            if payload.get("value") is not None or payload.get("status") in (0, "0", None):
                sys.exit(0)
    except Exception:
        pass
sys.exit(1)
PY
}

start_appium_if_needed() {
  if appium_is_ready; then
    say "Appium server already running at $APPIUM_SERVER_URL"
    return
  fi
  if [[ "$APPIUM_AUTO_START" != "true" ]]; then
    echo "Appium is not running at $APPIUM_SERVER_URL and APPIUM_AUTO_START=false." >&2
    exit 1
  fi

  say "Starting Appium server"
  cd "$APPium_DIR"
  local server_port
  server_port="$("$PYTHON_BIN" -c 'import os; from urllib.parse import urlparse; print(urlparse(os.environ["APPIUM_SERVER_URL"]).port or 4723)')"
  if [[ "$APPIUM_INSTALL_SCOPE" == "global" ]]; then
    nohup appium --port "$server_port" --base-path / --allow-insecure=adb_shell >"$APPIUM_LOG_FILE" 2>&1 &
  else
    nohup npx appium --port "$server_port" --base-path / --allow-insecure=adb_shell >"$APPIUM_LOG_FILE" 2>&1 &
  fi
  local pid=$!
  echo "$pid" > "$REPORT_DIR/appium-server.pid"

  for _ in {1..30}; do
    if appium_is_ready; then
      say "Appium server ready (pid=$pid)"
      return
    fi
    sleep 1
  done
  echo "Appium failed to become ready. Last log lines:" >&2
  tail -80 "$APPIUM_LOG_FILE" >&2 || true
  exit 1
}

say "Checking prerequisites"
require_cmd adb
require_cmd flutter
require_cmd npm
if [[ "${QA_SKIP_DEPENDENCY_INSTALL:-false}" != "true" ]]; then
  "$PYTHON_BIN" -m pip install -q -r "$APPium_DIR/requirements.txt"
fi

say "Installing Appium tooling ($APPIUM_INSTALL_SCOPE)"
cd "$APPium_DIR"
if [[ "${QA_SKIP_DEPENDENCY_INSTALL:-false}" == "true" ]]; then
  say "Using existing Appium tooling"
elif [[ "$APPIUM_INSTALL_SCOPE" == "global" ]]; then
  if ! command -v appium >/dev/null 2>&1; then
    npm install -g appium
  fi
  appium driver install uiautomator2 || true
  appium driver list --installed
else
  npm install
  npx appium driver install uiautomator2 || true
  npx appium driver list --installed
fi

say "Checking Android emulator"
adb devices | sed -n '1,10p'
if ! adb -s "$ANDROID_DEVICE_NAME" get-state >/dev/null 2>&1; then
  echo "Android device $ANDROID_DEVICE_NAME is not available. Start the emulator first." >&2
  exit 1
fi

say "Checking backend health"
if ! curl -fsS "$QA_GATEWAY_HEALTH_URL" >/dev/null || ! curl -fsS "$QA_BFF_HEALTH_URL" >/dev/null; then
  echo "Native local-PostgreSQL backend is not healthy. Start it with the local PostgreSQL environment before running device QA." >&2
  exit 1
fi
curl -fsS "$QA_GATEWAY_HEALTH_URL" && echo
curl -fsS "$QA_BFF_HEALTH_URL" && echo

say "Running seed/API preflight before Appium launch"
cd "$APPium_DIR"
"$PYTHON_BIN" -m pytest tests/test_00_seed_preflight.py -m seed

if [[ "$PROFILE" == "preflight" ]]; then
  say "Preflight profile complete"
  echo "Seed summary: $REPORT_DIR/seed-preflight-summary.json"
  exit 0
fi

start_appium_if_needed

say "Running Android Appium suite (profile=$PROFILE)"
cd "$APPium_DIR"
if [[ ${#PYTEST_ARGS[@]} -gt 0 ]]; then
  QA_APPIUM_PROFILE="$PROFILE" "$APPium_DIR/run_android.sh" "${PYTEST_ARGS[@]}"
else
  QA_APPIUM_PROFILE="$PROFILE" "$APPium_DIR/run_android.sh"
fi

say "Appium automation complete"
echo "Report: $REPORT_DIR/android-smoke.html"
echo "Server log: $APPIUM_LOG_FILE"
