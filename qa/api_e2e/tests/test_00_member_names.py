"""Member names are unique across the suite.

Every module shares one run id, so ``make_member("cp_a")`` in two files signs
up the same username twice and the second test fails with 409 "username is
already taken" - but only in a full run (2026-10-03: test_15 and test_21 both
used cp_* and vo_*). Usernames are also cut to 30 characters, so names are
compared after the same cut.
"""
from __future__ import annotations

import collections
import re
from pathlib import Path

from client import RUN_ID

TESTS = Path(__file__).resolve().parent
ROLE = re.compile(r"""\b(?:make_member|create_member)\(\s*["']([A-Za-z0-9_]+)["']""")


def test_member_names_are_unique_across_modules():
    seen: dict[str, set[str]] = collections.defaultdict(set)
    for path in sorted(TESTS.glob("test_*.py")):
        if path.name == Path(__file__).name:
            continue
        for role in ROLE.findall(path.read_text()):
            seen[f"e2e_{RUN_ID}_{role}"[:30].lower()].add(path.name)
    shared = {name: sorted(files) for name, files in seen.items() if len(files) > 1}
    assert not shared, f"member names used by more than one module (rename one): {shared}"
