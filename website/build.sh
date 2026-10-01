#!/usr/bin/env bash
set -euo pipefail
website_dir="$(cd "$(dirname "$0")" && pwd)"
flutter_bin="${FLUTTER_BIN:-/Users/anandsadasivan/flutter/bin/flutter}"
cd "$website_dir/../app"
"$flutter_bin" build web --release --base-href=/app/ --no-web-resources-cdn
# Publish a separate copy. Flutter may remove previous target outputs when
# switching to an Android build; the served website must not be one of them.
# Strip mobile environment configuration before any assets become public.
python3 - "$website_dir" <<'PY'
from pathlib import Path
import shutil
import sys
import tempfile

website = Path(sys.argv[1]).resolve()
source = website.parent / 'app' / 'build' / 'web'
target = website / '.build' / 'app'
target.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='publish-', dir=target.parent) as work:
    stage = Path(work) / 'app'
    shutil.copytree(source, stage)
    for name in ('.env.local', '.env'):
        (stage / 'assets' / name).unlink(missing_ok=True)
    if not (stage / 'assets' / 'FontManifest.json').is_file():
        raise SystemExit('Web build is missing the font manifest; publication refused.')
    backup = Path(work) / 'previous'
    if target.exists():
        target.rename(backup)
    try:
        stage.rename(target)
    except Exception:
        if backup.exists():
            backup.rename(target)
        raise
print('Published isolated web assets without mobile environment files.')
PY
