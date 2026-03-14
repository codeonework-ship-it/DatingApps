#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "== Backend compliance check =="

echo "[1/4] Checking runtime hardcoded local URLs in non-test Go files..."
RUNTIME_HARDCODED="$(grep -RInE 'http://localhost|10\.0\.2\.2' --include='*.go' --exclude='*_test.go' internal cmd | grep -v 'internal/platform/config/config.go' || true)"
if [[ -n "$RUNTIME_HARDCODED" ]]; then
  echo "FAIL: Found runtime hardcoded local URLs (review with author):"
  echo "$RUNTIME_HARDCODED"
  exit 1
fi

echo "[2/4] Checking correlation ID middleware registration..."
if ! grep -q 'CorrelationIDMiddleware' internal/gateway/http/server.go; then
  echo "FAIL: CorrelationIDMiddleware missing in gateway"
  exit 1
fi
if ! grep -q 'CorrelationIDMiddleware' internal/bff/mobile/server.go; then
  echo "FAIL: CorrelationIDMiddleware missing in mobile-bff"
  exit 1
fi

echo "[3/4] Checking structured logger bootstrap in service entrypoints..."
MISSING_LOGGER=0
while IFS= read -r file; do
  if ! grep -q 'observability.NewLogger' "$file"; then
    echo "FAIL: structured logger bootstrap missing in $file"
    MISSING_LOGGER=1
  fi
done < <(find cmd -mindepth 2 -maxdepth 2 -name main.go | sort)
if [[ "$MISSING_LOGGER" -ne 0 ]]; then
  exit 1
fi

echo "[4/4] Checking module layering directories..."
for module in auth profile matching chat admin billing verification safety calls; do
  if [[ ! -d "internal/modules/$module/application" || ! -d "internal/modules/$module/infrastructure" ]]; then
    echo "FAIL: module layering missing application/infrastructure for $module"
    exit 1
  fi
done

echo "PASS: Backend compliance checks succeeded."
