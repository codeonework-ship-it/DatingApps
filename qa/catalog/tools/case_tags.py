"""Static scanner for the QA Lab test -> catalog case contract.

Every automated test names the catalog case(s) it proves:

* Flutter (``app/test``) and Playwright (``website/tests``): ``[case:<id>]`` in
  the test name (or in an enclosing ``group``/``test.describe`` name, which the
  runtime name includes). Several tags are allowed; ``[case:a, b]`` is accepted
  as shorthand for ``[case:a] [case:b]``.
* pytest (``qa/api_e2e``, ``qa/appium``): ``@pytest.mark.case("<id>", ...)`` on
  the test, on its class, or in a module-level ``pytestmark``.
* Go (``backend/**/_test.go``): ``// case: <id>`` comment line(s) directly above
  ``func TestX(t *testing.T)``.
* Django (``control-panel``): ``# case: <id>`` comment line(s) directly above
  ``def test_x`` (or above its decorators).

``scan_all(root)`` returns ``{suite: [{"suite", "file", "test", "cases", ...}]}``
with repo-relative files. ``index(scan)`` inverts it to ``case_id -> [test]``.
The runtime twin of this grammar lives in website/qa-lab/mapper.mjs; both are
unit-tested (qa/lab/tests/test_case_tags.py, website/qa-lab/mapper.test.mjs).
"""
from __future__ import annotations

import ast
import glob
import os
import re

TAG_RE = re.compile(r"\[case:\s*([^\]]+?)\s*\]")
ID_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9_.\-]*$")
COMMENT_CASE_RE = re.compile(r"^\s*(?://|#)\s*case:\s*(.+?)\s*$")


def split_ids(text: str) -> list[str]:
    """'a, b c' -> ['a', 'b', 'c'] keeping only well-formed ids."""
    out = []
    for part in re.split(r"[\s,]+", text.strip()):
        part = part.strip().strip("'\"`")
        if part and ID_RE.match(part):
            out.append(part)
    return out


def tags_in_name(name: str) -> list[str]:
    """Case ids named by ``[case:...]`` tags in a test (or group) name."""
    out: list[str] = []
    for mo in TAG_RE.finditer(name or ""):
        for cid in split_ids(mo.group(1)):
            if cid not in out:
                out.append(cid)
    return out


def _dedupe(seq):
    out = []
    for x in seq:
        if x not in out:
            out.append(x)
    return out


# ------------------------------------------------------------------ Dart / JS
def _match_close(m: str, start: int) -> int:
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack = []
    for i in range(start, len(m)):
        ch = m[i]
        if ch in pairs:
            stack.append(pairs[ch])
        elif ch in ")]}":
            if stack and stack[-1] == ch:
                stack.pop()
                if not stack:
                    return i
            else:
                return i
    return len(m) - 1


def _first_arg_end(m: str, open_idx: int, close_idx: int) -> int:
    depth = 0
    for i in range(open_idx + 1, close_idx):
        ch = m[i]
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            return i
    return close_idx


def _string_literals(src: str) -> str:
    """Concatenate the string literal contents in a Dart/JS name expression."""
    parts = re.findall(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"|`((?:[^`\\]|\\.)*)`", src, re.S)
    return "".join(a or b or c for a, b, c in parts)


def _named_calls(src: str, masked: str, head_re: re.Pattern) -> list[dict]:
    calls = []
    for h in head_re.finditer(masked):
        o = h.end() - 1
        c = _match_close(masked, o)
        a = _first_arg_end(masked, o, c)
        calls.append({"kind": h.group(1), "start": h.start(), "end": c, "name": _string_literals(src[o + 1:a])})
    return calls


def _scan_named(src: str, masked: str, test_re: re.Pattern, group_re: re.Pattern, sep: str) -> list[dict]:
    tests = _named_calls(src, masked, test_re)
    groups = _named_calls(src, masked, group_re)
    out = []
    for t in tests:
        enclosing = [g for g in groups if g["start"] < t["start"] <= g["end"]]
        enclosing.sort(key=lambda g: g["start"])
        cases = []
        for g in enclosing:
            cases += tags_in_name(g["name"])
        cases += tags_in_name(t["name"])
        full = sep.join([g["name"] for g in enclosing] + [t["name"]])
        out.append({"test": full, "name": t["name"], "cases": _dedupe(cases), "line": src.count("\n", 0, t["start"]) + 1})
    return out


def _mask_c_like(src: str, backtick: bool) -> str:
    """Blank string contents and comments (positions preserved). Interpolations
    are blanked too, which is fine for locating call boundaries."""
    out = list(src)
    i, n = 0, len(src)
    quotes = "'\"`" if backtick else "'\""
    while i < n:
        if src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                out[k] = " "
            i = j
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            for k in range(i, j):
                if out[k] != "\n":
                    out[k] = " "
            i = j
            continue
        c = src[i]
        if c in quotes:
            triple = src[i:i + 3] if src[i:i + 3] in ("'''", '"""') else None
            q = triple or c
            j = i + len(q)
            while j < n and not src.startswith(q, j):
                if src[j] == "\\":
                    j += 1
                elif not triple and q != "`" and src[j] == "\n":
                    break
                j += 1
            for k in range(i + len(q), min(j, n)):
                if out[k] != "\n":
                    out[k] = " "
            i = j + len(q)
            continue
        i += 1
    return "".join(out)


DART_TEST_RE = re.compile(r"(?<![\w.])(testWidgets|test|patrolTest|testGoldens)\s*\(")
DART_GROUP_RE = re.compile(r"(?<![\w.])(group)\s*\(")
JS_TEST_RE = re.compile(r"(?<![\w.])(test(?:\.only|\.skip|\.fixme|\.fail|\.slow)?)\s*\(")
JS_GROUP_RE = re.compile(r"(?<![\w.])(test\.describe(?:\.serial|\.parallel|\.only|\.skip|\.configure)?|describe)\s*\(")


def dart_tags(src: str) -> list[dict]:
    return _scan_named(src, _mask_c_like(src, backtick=False), DART_TEST_RE, DART_GROUP_RE, " ")


def js_tags(src: str) -> list[dict]:
    return _scan_named(src, _mask_c_like(src, backtick=True), JS_TEST_RE, JS_GROUP_RE, " > ")


# ------------------------------------------------------------------ pytest
def _mark_case_ids(node: ast.AST) -> list[str]:
    """ids from pytest.mark.case(...) expressions (call or list of calls)."""
    out: list[str] = []
    if isinstance(node, (ast.List, ast.Tuple)):
        for elt in node.elts:
            out += _mark_case_ids(elt)
        return out
    if isinstance(node, ast.Call):
        f = node.func
        if isinstance(f, ast.Attribute) and f.attr == "case":
            v = f.value
            if (isinstance(v, ast.Attribute) and v.attr == "mark") or (isinstance(v, ast.Name) and v.id == "mark"):
                for a in node.args:
                    if isinstance(a, ast.Constant) and isinstance(a.value, str):
                        out += split_ids(a.value)
    return out


def pytest_tags(src: str) -> list[dict]:
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return []
    module_ids: list[str] = []
    for stmt in tree.body:
        if isinstance(stmt, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "pytestmark" for t in stmt.targets):
            module_ids += _mark_case_ids(stmt.value)
    out = []

    def fn(f, prefix, inherited):
        if not f.name.startswith("test"):
            return
        ids = list(inherited)
        for d in f.decorator_list:
            ids += _mark_case_ids(d)
        out.append({"test": f.name, "nodeid_suffix": prefix + f.name, "cases": _dedupe(ids), "line": f.lineno})

    for stmt in tree.body:
        if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef)):
            fn(stmt, "", module_ids)
        elif isinstance(stmt, ast.ClassDef) and stmt.name.startswith("Test"):
            cls_ids = list(module_ids)
            for d in stmt.decorator_list:
                cls_ids += _mark_case_ids(d)
            for f in stmt.body:
                if isinstance(f, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    fn(f, stmt.name + "::", cls_ids)
    return out


# ------------------------------------------------------------------ Go / Django comments
GO_FUNC_RE = re.compile(r"^func (Test\w+)\(\s*\w+\s+\*testing\.T\s*\)")


def go_tags(src: str) -> list[dict]:
    lines = src.split("\n")
    out = []
    for i, line in enumerate(lines):
        mo = GO_FUNC_RE.match(line)
        if not mo:
            continue
        ids: list[str] = []
        j = i - 1
        while j >= 0 and lines[j].lstrip().startswith("//"):
            cm = COMMENT_CASE_RE.match(lines[j])
            if cm:
                ids = split_ids(cm.group(1)) + ids
            j -= 1
        out.append({"test": mo.group(1), "cases": _dedupe(ids), "line": i + 1})
    return out


PY_DEF_RE = re.compile(r"^(\s*)(?:async\s+)?def (test\w*)\s*\(")
PY_CLASS_RE = re.compile(r"^(\s*)class (\w+)\s*[(:]")


def django_tags(src: str) -> list[dict]:
    """Comment-tagged unittest/Django tests -> [{test: Class.method, cases}]."""
    lines = src.split("\n")
    out = []
    classes: list[tuple[int, str]] = []  # (indent, name)
    for i, line in enumerate(lines):
        cm = PY_CLASS_RE.match(line)
        if cm:
            ind = len(cm.group(1))
            classes = [c for c in classes if c[0] < ind] + [(ind, cm.group(2))]
            continue
        mo = PY_DEF_RE.match(line)
        if not mo:
            continue
        ind = len(mo.group(1))
        owner = [c for c in classes if c[0] < ind]
        ids: list[str] = []
        j = i - 1
        while j >= 0 and (lines[j].lstrip().startswith("#") or lines[j].lstrip().startswith("@")):
            cc = COMMENT_CASE_RE.match(lines[j])
            if cc:
                ids = split_ids(cc.group(1)) + ids
            j -= 1
        name = (owner[-1][1] + "." if owner else "") + mo.group(2)
        out.append({"test": name, "cases": _dedupe(ids), "line": i + 1})
    return out


# ------------------------------------------------------------------ repo scan
def _rel(root, f):
    return os.path.relpath(f, root)


def _read(f):
    with open(f, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def _skip(f):
    return any(p in f for p in ("/node_modules/", "/.venv/", "/venv/", "/site-packages/", "/.dart_tool/", "/build/"))


def scan_all(root: str) -> dict[str, list[dict]]:
    res: dict[str, list[dict]] = {k: [] for k in ("flutter", "playwright", "api_e2e", "appium", "go", "django")}
    for f in sorted(glob.glob(os.path.join(root, "app/test/**/*.dart"), recursive=True)):
        for t in dart_tags(_read(f)):
            res["flutter"].append({"suite": "flutter", "file": _rel(root, f), **t})
    for f in sorted(glob.glob(os.path.join(root, "website/tests/**/*.spec.js"), recursive=True)):
        if _skip(f):
            continue
        for t in js_tags(_read(f)):
            res["playwright"].append({"suite": "playwright", "file": _rel(root, f), **t})
    for suite, d in (("api_e2e", "qa/api_e2e"), ("appium", "qa/appium")):
        for f in sorted(glob.glob(os.path.join(root, d, "tests/**/*.py"), recursive=True)):
            for t in pytest_tags(_read(f)):
                rel = _rel(root, f)
                t["nodeid"] = os.path.relpath(f, os.path.join(root, d)) + "::" + t.pop("nodeid_suffix")
                res[suite].append({"suite": suite, "file": rel, **t})
    for f in sorted(glob.glob(os.path.join(root, "backend/**/*_test.go"), recursive=True)):
        if _skip(f):
            continue
        for t in go_tags(_read(f)):
            res["go"].append({"suite": "go", "file": _rel(root, f), "package": os.path.dirname(_rel(root, f)), **t})
    cp = os.path.join(root, "control-panel")
    files = set(glob.glob(cp + "/**/tests/**/*.py", recursive=True)) | set(glob.glob(cp + "/**/test_*.py", recursive=True))
    for f in sorted(files):
        if _skip(f):
            continue
        for t in django_tags(_read(f)):
            res["django"].append({"suite": "django", "file": _rel(root, f), **t})
    return res


def index(scan: dict[str, list[dict]]) -> dict[str, list[dict]]:
    """case_id -> [{suite, file, test}] for tagged tests only."""
    idx: dict[str, list[dict]] = {}
    for suite, tests in scan.items():
        for t in tests:
            for cid in t.get("cases") or []:
                ref = {"suite": suite, "file": t["file"], "test": t["test"], "via": "tag"}
                if t.get("nodeid"):
                    ref["nodeid"] = t["nodeid"]
                idx.setdefault(cid, []).append(ref)
    return idx


if __name__ == "__main__":
    import json
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from paths import ROOT
    s = scan_all(ROOT)
    idx = index(s)
    print(json.dumps({k: sum(1 for t in v if t["cases"]) for k, v in s.items()}), len(idx), "cases tagged")
