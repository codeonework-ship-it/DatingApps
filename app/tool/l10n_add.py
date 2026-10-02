#!/usr/bin/env python3
"""Add translated strings to every ARB file safely, then regenerate.

Usage (from anywhere):
    python3 app/tool/l10n_add.py path/to/new_strings.json [--no-gen]

The JSON maps each new key to its metadata and one value per locale:

    {
      "friendsEmptyTitle": {
        "description": "Friends screen: title when the list is empty.",
        "placeholders": {"name": {"type": "String", "example": "Priya"}},
        "en": "No friends yet", "en_GB": "No friends yet",
        "de": "...", "fr": "...", "ru": "...", "es": "...",
        "it": "...", "pt": "...", "nl": "...", "pl": "..."
      }
    }

Every locale is required. A key that already exists with the same English
text is skipped; with different English text it is an error (pick another
key). Several sessions can run this at once: the files are edited under an
exclusive lock and `flutter gen-l10n` runs under the same lock. New lines are
appended in the files' one-line-per-key style without reformatting.
"""

import fcntl
import json
import os
import subprocess
import sys

APP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARB_DIR = os.path.join(APP, "lib", "l10n")
LOCALES = ["en", "en_GB", "de", "fr", "ru", "es", "it", "pt", "nl", "pl"]


def arb_path(locale):
    return os.path.join(ARB_DIR, f"app_{locale}.arb")


def append_lines(path, lines):
    if not lines:
        return
    with open(path, encoding="utf-8") as fh:
        text = fh.read().rstrip()
    if not text.endswith("}"):
        raise SystemExit(f"{path}: does not end with '}}'")
    body = text[:-1].rstrip()
    if not body.endswith(","):
        body += ","
    new = body + "\n" + ",\n".join(lines) + "\n}\n"
    json.loads(new)  # never write a broken file
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(new)


def update_values(entries):
    """--update: correct translations of existing keys.

    The JSON maps each existing key to {locale: new value} for only the
    locales being corrected (not "en": English is the source of truth and
    tests match on it). Lines are rewritten in place, keeping the format.
    """
    import re

    for key, values in entries.items():
        bad = [loc for loc in values if loc not in LOCALES or loc == "en"]
        if bad:
            raise SystemExit(f"{key}: cannot update locales {bad}")
    lock_path = os.path.join(ARB_DIR, ".l10n_add.lock")
    with open(lock_path, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        changed = 0
        for loc in LOCALES:
            path = arb_path(loc)
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
            for key, values in entries.items():
                if loc not in values:
                    continue
                pattern = re.compile(r'^(  ' + re.escape(json.dumps(key)) + r': )(".*?")(,?)$', re.M)
                if len(pattern.findall(text)) != 1:
                    raise SystemExit(f"{loc}:{key}: expected exactly one existing line")
                value = json.dumps(values[loc], ensure_ascii=False)
                text = pattern.sub(lambda m: m.group(1) + value + m.group(3), text)
                changed += 1
            json.loads(text)
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(text)
        print(f"updated {changed} values")
        result = subprocess.run(["flutter", "gen-l10n"], cwd=APP, capture_output=True, text=True)
        if result.returncode != 0:
            sys.stderr.write(result.stdout + result.stderr)
            raise SystemExit("flutter gen-l10n failed")
        print("regenerated app_localizations*.dart")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        raise SystemExit(__doc__)
    with open(args[0], encoding="utf-8") as fh:
        entries = json.load(fh)
    if "--update" in sys.argv:
        update_values(entries)
        return
    for key, entry in entries.items():
        if not key[0].islower() or not key.replace("_", "").isalnum():
            raise SystemExit(f"{key}: keys must be lowerCamelCase identifiers")
        missing = [loc for loc in LOCALES if not str(entry.get(loc, "")).strip()]
        if missing:
            raise SystemExit(f"{key}: missing locales {missing}")
        if not str(entry.get("description", "")).strip():
            raise SystemExit(f"{key}: description is required")
        # gen-l10n rejects non-string placeholder examples (e.g. 17 for an
        # int); store them as strings so a batch can never break generation.
        for name, spec in (entry.get("placeholders") or {}).items():
            if "example" in spec and not isinstance(spec["example"], str):
                spec["example"] = str(spec["example"])
            if "example" in spec and not spec["example"].strip():
                raise SystemExit(f"{key}: placeholder {name} has an empty example")

    lock_path = os.path.join(ARB_DIR, ".l10n_add.lock")
    with open(lock_path, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        existing = {}
        for loc in LOCALES:
            with open(arb_path(loc), encoding="utf-8") as fh:
                existing[loc] = json.load(fh)
        added, skipped = [], []
        for key, entry in entries.items():
            if key in existing["en"]:
                if existing["en"][key] != entry["en"]:
                    raise SystemExit(
                        f"{key}: already exists with different English text "
                        f"({existing['en'][key]!r}); choose another key"
                    )
                skipped.append(key)
                continue
            added.append(key)
        for loc in LOCALES:
            lines = []
            for key in added:
                entry = entries[key]
                lines.append(f"  {json.dumps(key)}: {json.dumps(entry[loc], ensure_ascii=False)}")
                if loc == "en":
                    meta = {"description": entry["description"]}
                    if entry.get("placeholders"):
                        meta["placeholders"] = entry["placeholders"]
                    lines.append(f"  {json.dumps('@' + key)}: {json.dumps(meta, ensure_ascii=False)}")
            append_lines(arb_path(loc), lines)
        print(f"added {len(added)}, skipped {len(skipped)} existing")
        if added and "--no-gen" not in sys.argv:
            result = subprocess.run(["flutter", "gen-l10n"], cwd=APP, capture_output=True, text=True)
            if result.returncode != 0:
                sys.stderr.write(result.stdout + result.stderr)
                raise SystemExit("flutter gen-l10n failed")
            print("regenerated app_localizations*.dart")


if __name__ == "__main__":
    main()
