"""Static scanner for the QA Lab test -> catalog case contract.

Every automated test names the catalog case(s) it proves:

* Flutter (``app/test``) and Playwright (``website/tests``): ``[case:<id>]`` in
  the test name (or in an enclosing ``group``/``test.describe`` name, which the
  runtime name includes). Several tags are allowed; ``[case:a, b]`` is accepted
  as shorthand for ``[case:a] [case:b]``.
* pytest (``qa/api_e2e``, ``qa/appium``): ``@pytest.mark.case("<id>", ...)`` on
  the test, on its class, or in a module-level ``pytestmark``.
* Go (``backend/**/_test.go``): ``// case: <id>`` comment line(s) directly above
  ``func TestX(t *testing.T)`` (``// cases:``, several ids per line separated by
  commas/spaces, and ``// [case:<id>]`` in the doc comment are accepted).
* Django (``control-panel``): ``[case:<id>]`` in the test method docstring (the
  repo convention), or ``# case: <id>`` comment line(s) directly above
  ``def test_x`` (or above its decorators).

pytest marks are read by evaluating the module's top-level statements with a
recording ``pytest`` stub (other imports are inert stand-ins, nothing runs a
test), so ``@pytest.mark.case(*CONSTANT)``, ``pytest.param(..., marks=...)``
inside ``parametrize`` lists/comprehensions and helper functions that build
params are all seen. If a module cannot be evaluated the literal AST reader is
used instead.

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
_INTERP_RE = re.compile(r"\$\{[^{}]*\}|\$[A-Za-z_]\w*")
COMMENT_CASE_RE = re.compile(r"^\s*(?://|#)\s*cases?:\s*(.+?)\s*$")


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
    text = _INTERP_RE.sub("\x00", name or "")  # interpolated ids are patterns (patterns_in_name), not ids
    for mo in TAG_RE.finditer(text):
        for part in re.split(r"[\s,]+", mo.group(1).strip()):
            if "\x00" in part:
                continue
            for cid in split_ids(part):
                if cid not in out:
                    out.append(cid)
    return out



def patterns_in_name(name: str) -> list[str]:
    """Interpolated tag ids (``[case:a.$name.action]``, ``[case:site.${p}.x]``):
    the source name of a parameterised test. Each ``$x`` / ``${...}`` becomes
    ``{}``; final_catalog expands a pattern only to catalog ids whose
    interpolated part is a string literal of the same file."""
    out: list[str] = []
    text = _INTERP_RE.sub("\x00", name or "")
    for mo in TAG_RE.finditer(text):
        for part in re.split(r"[\s,]+", mo.group(1).strip()):
            part = part.strip("'\"`")
            if "\x00" in part and re.fullmatch(r"[A-Za-z0-9_.\-\x00]+", part):
                pat = part.replace("\x00", "{}")
                if pat not in out:
                    out.append(pat)
    return out


def file_literals(src: str) -> list[str]:
    """String literal values of a test file (and their slash-stripped forms),
    the candidate values of interpolated tag ids."""
    vals = set()
    for a, b, c in re.findall(r"'((?:[^'\\\n]|\\.)*)'|\"((?:[^\"\\\n]|\\.)*)\"|`((?:[^`\\]|\\.)*)`", src):
        v = a or b or c
        if v and len(v) <= 120 and re.fullmatch(r"[A-Za-z0-9_./\-]+", v):
            vals.add(v)
            vals.add(v.strip("/"))
            vals.add(re.sub(r"\.(html|js|json|dart)$", "", v.strip("/")))
    return sorted(x for x in vals if x)


def expand_pattern(pattern: str, literals, known_ids) -> list[str]:
    """Catalog ids matching ``pattern`` whose every ``{}`` part is a literal."""
    lits = set(literals)
    parts = pattern.split("{}")
    rx = re.compile("^" + "(.+?)".join(re.escape(p) for p in parts) + "$")
    out = []
    for cid in known_ids:
        mo = rx.match(cid)
        if mo and all(g in lits for g in mo.groups()):
            out.append(cid)
    return sorted(out)


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
        pats = []
        for g in enclosing:
            pats += patterns_in_name(g["name"])
        pats += patterns_in_name(t["name"])
        full = sep.join([g["name"] for g in enclosing] + [t["name"]])
        rec = {"test": full, "name": t["name"], "cases": _dedupe(cases), "line": src.count("\n", 0, t["start"]) + 1}
        if pats:
            rec["case_patterns"] = _dedupe(pats)
        out.append(rec)
    return out


def _mask_c_like(src: str, backtick: bool) -> str:
    """Blank string contents and comments (positions preserved). Interpolations
    (``${...}`` in Dart strings and JS template literals, which may hold nested
    strings) are blanked too, which is fine for locating call boundaries."""
    out = list(src)
    n = len(src)
    quotes = "'\"`" if backtick else "'\""

    def blank(a, b):
        for k in range(a, min(b, n)):
            if out[k] != "\n":
                out[k] = " "

    def skip_string(i):
        """i at an opening quote; returns the index just past the closing quote."""
        triple = src[i:i + 3] if src[i:i + 3] in ("\'\'\'", '"""') else None
        q = triple or src[i]
        raw = i > 0 and src[i - 1] in "rR" and not backtick
        interp = (q != "`" and not backtick) or q == "`"
        j = i + len(q)
        while j < n and not src.startswith(q, j):
            if src[j] == "\\" and not raw:
                j += 2
                continue
            if interp and not raw and src.startswith("${", j):
                j = skip_braces(j + 1)
                continue
            if not triple and q != "`" and src[j] == "\n":
                break
            j += 1
        return min(j + len(q), n)

    def skip_braces(i):
        """i at '{'; returns the index just past the matching '}'."""
        depth = 0
        j = i
        while j < n:
            c = src[j]
            if c in quotes:
                j = skip_string(j)
                continue
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return j + 1
            j += 1
        return n

    i = 0
    while i < n:
        if src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            blank(i, j)
            i = j
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            blank(i, j)
            i = j
            continue
        c = src[i]
        if c in quotes:
            j = skip_string(i)
            q = 3 if src[i:i + 3] in ("\'\'\'", '"""') else 1
            blank(i + q, j - q)
            i = j
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


# pytest, evaluated: module top level run against a recording pytest stub
_SAFE_IMPORTS = {"__future__", "dataclasses", "typing", "os", "os.path", "re", "json", "uuid", "datetime", "time",
                 "pathlib", "collections", "functools", "itertools", "enum", "base64", "struct", "binascii", "zlib",
                 "io", "secrets", "string", "random", "math", "decimal", "fractions", "textwrap", "hashlib", "copy",
                 "operator", "types", "abc", "contextlib", "urllib", "urllib.parse"}


class _Inert:
    """Stand-in for anything imported from outside the stdlib: every attribute,
    call, index and iteration yields another inert value (iteration is empty)."""

    def __getattr__(self, name):
        if name.startswith("__") and name.endswith("__"):
            raise AttributeError(name)
        return _Inert()

    def __call__(self, *a, **k):
        if len(a) == 1 and not k and callable(a[0]) and not isinstance(a[0], _Inert):
            return a[0]  # used as a decorator
        return _Inert()

    def __getitem__(self, k):
        return _Inert()

    def __iter__(self):
        return iter(())

    def __len__(self):
        return 0

    def __bool__(self):
        return False

    def __mro_entries__(self, bases):
        return (object,)


class _Mark:
    def __init__(self, name, args, kwargs):
        self.name, self.args, self.kwargs = name, args, kwargs

    def __call__(self, *a, **k):
        import inspect
        if len(a) == 1 and not k and (inspect.isfunction(a[0]) or inspect.isclass(a[0])):
            target = a[0]
            marks = list(getattr(target, "_qalab_marks", []))
            target._qalab_marks = [self] + marks
            return target
        return _Mark(self.name, self.args + a, {**self.kwargs, **k})


class _MarkGen:
    def __getattr__(self, name):
        if name.startswith("__"):
            raise AttributeError(name)
        return _Mark(name, (), {})


class _Param:
    def __init__(self, values, marks, pid):
        self.values, self.marks, self.id = values, marks, pid


def _pytest_stub():
    import types
    mod = types.ModuleType("pytest")
    mod.mark = _MarkGen()

    def param(*values, marks=(), id=None):  # noqa: A002
        if isinstance(marks, _Mark):
            marks = [marks]
        return _Param(values, list(marks or ()), id)

    def fixture(*a, **k):
        if len(a) == 1 and callable(a[0]) and not k:
            return a[0]
        return lambda f: f

    mod.param = param
    mod.fixture = fixture
    mod.__getattr__ = lambda name: _Inert()
    return mod


def _case_args(mark) -> list[str]:
    out: list[str] = []
    for a in getattr(mark, "args", ()):
        if isinstance(a, str):
            out += split_ids(a)
    return out


def _marks_cases(marks) -> list[str]:
    out: list[str] = []
    for m in marks or ():
        if isinstance(m, _Mark) and m.name == "case":
            out += _case_args(m)
    return out


def _eval_module(src: str, label: str) -> dict | None:
    """Run top-level statements one by one; returns the namespace (None if the
    source does not parse). Statements that fail are skipped."""
    import builtins
    import sys
    import types
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return None
    modname = "_qalab_scan_" + re.sub(r"\W", "_", label)
    module = types.ModuleType(modname)
    ns = module.__dict__
    ns["__name__"] = modname
    ns["__file__"] = label
    stub = _pytest_stub()
    real_import = builtins.__import__

    def guarded_import(name, globals=None, locals=None, fromlist=(), level=0):  # noqa: A002
        if level == 0 and name == "pytest":
            return stub
        if level == 0 and (name in _SAFE_IMPORTS or name.split(".")[0] in _SAFE_IMPORTS):
            return real_import(name, globals, locals, fromlist, level)
        return _Inert()

    env_builtins = dict(vars(builtins))
    env_builtins["__import__"] = guarded_import
    env_builtins["open"] = lambda *a, **k: (_ for _ in ()).throw(OSError("scan"))
    ns["__builtins__"] = env_builtins
    sys.modules[modname] = module
    try:
        for stmt in tree.body:
            code = compile(ast.Module(body=[stmt], type_ignores=[]), label, "exec",
                           flags=__import__("__future__").annotations.compiler_flag, dont_inherit=True)
            try:
                exec(code, ns)  # noqa: S102 - repo-owned test modules, imports stubbed, no test is run
            except Exception:  # noqa: BLE001
                continue
    finally:
        sys.modules.pop(modname, None)
    return ns


def pytest_tags_eval(src: str, label: str = "test_module.py") -> list[dict] | None:
    ns = _eval_module(src, label)
    if ns is None:
        return None
    module_ids = []
    pm = ns.get("pytestmark")
    module_ids += _marks_cases(pm if isinstance(pm, (list, tuple)) else [pm])
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return None
    out = []

    def collect(fn_obj, name, prefix, inherited, line):
        marks = list(getattr(fn_obj, "_qalab_marks", []))
        ids = list(inherited) + _marks_cases(marks)
        params: list[tuple[str, list[str]]] = []
        for m in marks:
            if m.name != "parametrize":
                continue
            argvalues = m.args[1] if len(m.args) > 1 else m.kwargs.get("argvalues", ())
            try:
                argvalues = list(argvalues)
            except TypeError:
                continue
            for i, v in enumerate(argvalues):
                if isinstance(v, _Param):
                    pc = _marks_cases(v.marks)
                    if pc:
                        params.append((str(v.id) if v.id is not None else str(i), pc))
        out.append({"test": name, "nodeid_suffix": prefix + name, "cases": _dedupe(ids + [c for _, pc in params for c in pc]),
                    "line": line, **({"param_cases": {pid: _dedupe(pc) for pid, pc in params}} if params else {})})

    for stmt in tree.body:
        if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef)) and stmt.name.startswith("test"):
            collect(ns.get(stmt.name), stmt.name, "", module_ids, stmt.lineno)
        elif isinstance(stmt, ast.ClassDef) and stmt.name.startswith("Test"):
            cls = ns.get(stmt.name)
            cls_ids = list(module_ids) + _marks_cases(getattr(cls, "_qalab_marks", []))
            for f in stmt.body:
                if isinstance(f, (ast.FunctionDef, ast.AsyncFunctionDef)) and f.name.startswith("test"):
                    collect(getattr(cls, f.name, None) if cls is not None else None, f.name, stmt.name + "::", cls_ids, f.lineno)
    return out


# ------------------------------------------------------------------ Go / Django comments
GO_FUNC_RE = re.compile(r"^func\s+(Test\w*)\s*\(\s*\w+\s+\*testing\.T\s*\)")


def _comment_ids(line: str) -> list[str]:
    """ids on one ``// case: a, b`` / ``# cases: a b`` / ``// ... [case:a]`` line."""
    cm = COMMENT_CASE_RE.match(line)
    if cm:
        return split_ids(cm.group(1))
    return tags_in_name(line)


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
            ids = _comment_ids(lines[j]) + ids
            j -= 1
        out.append({"test": mo.group(1), "cases": _dedupe(ids), "line": i + 1})
    return out


PY_DEF_RE = re.compile(r"^(\s*)(?:async\s+)?def (test\w*)\s*\(")
PY_CLASS_RE = re.compile(r"^(\s*)class (\w+)\s*[(:]")


def _docstring_tags(src: str) -> dict[tuple[str, int], list[str]]:
    """(Class.method, def line) -> [case:...] ids in each test method's docstring."""
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return {}
    out: dict[tuple[str, int], list[str]] = {}

    def visit(body, owner):
        for node in body:
            if isinstance(node, ast.ClassDef):
                visit(node.body, node.name)
            elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name.startswith("test"):
                doc = ast.get_docstring(node, clean=False) or ""
                ids = tags_in_name(" ".join(doc.split()))
                if ids:
                    out[((owner + "." if owner else "") + node.name, node.lineno)] = ids

    visit(tree.body, "")
    return out


def django_tags(src: str) -> list[dict]:
    """Django/unittest tests -> [{test: Class.method, cases}]: ``[case:...]`` in
    the method docstring plus ``# case:`` comment lines above the def."""
    lines = src.split("\n")
    docs = _docstring_tags(src)
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
        ids += docs.get((name, i + 1), [])
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
        src = _read(f)
        lits = None
        for t in dart_tags(src):
            if t.get("case_patterns"):
                lits = lits if lits is not None else file_literals(src)
                t["pattern_values"] = lits
            res["flutter"].append({"suite": "flutter", "file": _rel(root, f), **t})
    for f in sorted(glob.glob(os.path.join(root, "website/tests/**/*.spec.js"), recursive=True)):
        if _skip(f):
            continue
        src = _read(f)
        lits = None
        for t in js_tags(src):
            if t.get("case_patterns"):
                lits = lits if lits is not None else file_literals(src)
                t["pattern_values"] = lits
            res["playwright"].append({"suite": "playwright", "file": _rel(root, f), **t})
    for suite, d in (("api_e2e", "qa/api_e2e"), ("appium", "qa/appium")):
        for f in sorted(glob.glob(os.path.join(root, d, "tests/**/*.py"), recursive=True)):
            src = _read(f)
            evaluated = pytest_tags_eval(src, _rel(root, f))
            literal = {t["nodeid_suffix"]: t for t in pytest_tags(src)}
            tests = evaluated if evaluated is not None else list(literal.values())
            for t in tests:
                lit = literal.get(t["nodeid_suffix"])
                if lit:  # the literal reader never sees less than the source says
                    t["cases"] = _dedupe(lit["cases"] + t["cases"])
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


def index(scan: dict[str, list[dict]], known_ids=None) -> dict[str, list[dict]]:
    """case_id -> [{suite, file, test}] for tagged tests only. A case that only a
    ``pytest.param(..., marks=pytest.mark.case(...))`` names points at that
    parametrized instance (``test[param-id]``). With ``known_ids``, interpolated
    tags (``case_patterns``) are expanded against them (see expand_pattern)."""
    idx: dict[str, list[dict]] = {}
    for suite, tests in scan.items():
        for t in tests:
            if known_ids is not None and t.get("case_patterns"):
                extra = []
                for pat in t["case_patterns"]:
                    extra += expand_pattern(pat, t.get("pattern_values") or (), known_ids)
                t["expanded_cases"] = _dedupe(extra)
                for cid in t["expanded_cases"]:
                    if cid not in (t.get("cases") or []):
                        ref = {"suite": suite, "file": t["file"], "test": t["test"], "via": "tag", "pattern": True}
                        idx.setdefault(cid, []).append(ref)
            param_cases = t.get("param_cases") or {}
            from_params = {cid for pc in param_cases.values() for cid in pc}
            for cid in t.get("cases") or []:
                if cid in from_params:
                    continue
                ref = {"suite": suite, "file": t["file"], "test": t["test"], "via": "tag"}
                if t.get("nodeid"):
                    ref["nodeid"] = t["nodeid"]
                idx.setdefault(cid, []).append(ref)
            for pid, pc in param_cases.items():
                for cid in pc:
                    ref = {"suite": suite, "file": t["file"], "test": f"{t['test']}[{pid}]", "via": "tag"}
                    if t.get("nodeid"):
                        ref["nodeid"] = f"{t['nodeid']}[{pid}]"
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
