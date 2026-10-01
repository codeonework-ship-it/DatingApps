#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to install the local Appium CLI." >&2
  exit 1
fi

npm install
npx appium driver install uiautomator2 || true
npx appium driver list --installed
