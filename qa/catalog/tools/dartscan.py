"""Light Dart source scanner: masks strings/comments, matches parens, finds
methods, classes, imports, API calls and interactive controls."""
import json, os, re, glob

from paths import ROOT
LIB = os.path.join(ROOT, "app/lib")


def mask(src):
    """Return text with string contents and comments replaced by spaces
    (quotes kept) so paren/brace matching is safe. Positions preserved."""
    out = list(src)
    i, n = 0, len(src)
    # stack of modes: ('code', depth) or ('str', quote, raw)
    stack = [("code", 0)]
    while i < n:
        mode = stack[-1]
        c = src[i]
        if mode[0] == "code":
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
            raw = False
            if c == "r" and i + 1 < n and src[i + 1] in "'\"" and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == "_")):
                raw = True
                i += 1
                c = src[i]
            if c in "'\"":
                q = src[i:i + 3] if src[i:i + 3] in ("'''", '"""') else c
                stack.append(("str", q, raw))
                i += len(q)
                continue
            if c == "{":
                stack[-1] = ("code", mode[1] + 1)
            elif c == "}":
                if mode[1] == 0 and len(stack) > 1:
                    # end of interpolation
                    out[i] = " "
                    stack.pop()
                    i += 1
                    continue
                stack[-1] = ("code", mode[1] - 1)
            i += 1
            continue
        # string mode
        _, q, raw = mode
        if not raw and c == "\\":
            out[i] = " "
            if i + 1 < n and src[i + 1] != "\n":
                out[i + 1] = " "
            i += 2
            continue
        if src.startswith(q, i):
            stack.pop()
            i += len(q)
            continue
        if not raw and src.startswith("${", i):
            out[i] = " "
            out[i + 1] = " "
            stack.append(("code", 0))
            i += 2
            continue
        if c != "\n":
            out[i] = " "
        i += 1
    return "".join(out)


def match_close(m, start):
    """m = masked text, start = index of an opening ( [ or {. Returns index of
    matching close."""
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


def top_level_args(src, m, open_idx, close_idx):
    """Split a call's args at depth 1. Returns list of (name|None, value_text, value_start)."""
    args = []
    depth = 0
    seg_start = open_idx + 1
    pairs = "([{"
    closers = ")]}"
    for i in range(open_idx + 1, close_idx + 1):
        ch = m[i]
        if ch in pairs:
            depth += 1
        elif ch in closers:
            if depth == 0 or i == close_idx:
                pass
            depth -= 1
        if (ch == "," and depth == 0) or i == close_idx:
            seg = src[seg_start:i]
            mseg = m[seg_start:i]
            mm = re.match(r"\s*([A-Za-z_]\w*)\s*:(?!:)", mseg)
            if mm:
                args.append((mm.group(1), seg[mm.end():].strip(), seg_start + mm.end()))
            elif seg.strip():
                args.append((None, seg.strip(), seg_start))
            seg_start = i + 1
    return args


def line_of(src, idx):
    return src.count("\n", 0, idx) + 1


CLASS_RE = re.compile(r"^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*class\s+(\w+)(?:<[^>{]*>)?\s*(?:extends\s+([\w$<>, ?]+?))?(?:\s+with\s+[\w$<>, ?]+?)?(?:\s+implements\s+[\w$<>, ?]+?)?\s*\{", re.M)
METHOD_RE = re.compile(r"(?:^|\n)\s*(?:static\s+|@override\s+)*(?:Future<[^>]*>+\??\s+|void\s+|Widget\s+|bool\s+|String\??\s+|int\s+|[A-Z]\w*(?:<[^>]*>+)?\??\s+)?(_?[a-z]\w*)\s*(?:<[^>]*>)?\s*\(", re.M)


def classes(src, m):
    out = []
    for mo in CLASS_RE.finditer(m):
        b = m.find("{", mo.end() - 1)
        e = match_close(m, b)
        out.append({"name": mo.group(1), "extends": (mo.group(2) or "").strip(), "start": mo.start(), "end": e})
    return out


def methods(src, m):
    """name -> list of (start, end) of body (including signature)."""
    res = {}
    for mo in re.finditer(r"(_?[a-zA-Z]\w*)\s*(?:<[^>()]*>)?\s*\(", m):
        name = mo.group(1)
        if name in ("if", "for", "while", "switch", "catch", "return", "super", "this", "assert", "build"):
            if name != "build":
                continue
        p = mo.end() - 1
        q = match_close(m, p)
        rest = m[q + 1:q + 40]
        mm = re.match(r"\s*(async\*?|sync\*)?\s*(\{|=>)", rest)
        if not mm:
            continue
        # must look like a declaration: previous token is a type, newline or 'void' etc.
        before = m[max(0, mo.start() - 60):mo.start()]
        if not re.search(r"(\n\s*|[>\w?]\s+)$", before):
            continue
        if re.search(r"(=|\(|,|:|return)\s*$", before):
            continue
        if re.search(r"\b(new|const|await|return|throw)\s+$", before):
            continue
        if name[0].isupper():
            continue
        if mm.group(2) == "{":
            b = q + 1 + mm.end() - 1
            e = match_close(m, b)
        else:
            b = q + 1 + mm.end()
            e = m.find(";", b)
            # arrow body may contain nested ; inside closures; approximate
            depth = 0
            for k in range(b, len(m)):
                ch = m[k]
                if ch in "([{":
                    depth += 1
                elif ch in ")]}":
                    depth -= 1
                    if depth < 0:
                        e = k
                        break
                elif ch == ";" and depth == 0:
                    e = k
                    break
        res.setdefault(name, []).append((mo.start(), e))
    return res


IMPORT_RE = re.compile(r"^import\s+'([^']+)'", re.M)


def imports(path, src):
    out = []
    for mo in IMPORT_RE.finditer(src):
        imp = mo.group(1)
        if imp.startswith("package:"):
            if imp.startswith("package:verified_dating_app/"):
                out.append(os.path.normpath(os.path.join(LIB, imp.split("/", 1)[1])))
            continue
        if imp.startswith("dart:"):
            continue
        out.append(os.path.normpath(os.path.join(os.path.dirname(path), imp)))
    return out


API_RE = re.compile(r"\.(get|post|put|patch|delete|uploadAttachment)\s*(?:<(?:[^<>()]|<(?:[^<>()]|<[^<>()]*>)*>)*>)?\(\s*")


def api_calls(src, m, start=0, end=None):
    end = len(src) if end is None else end
    out = []
    for mo in API_RE.finditer(m, start, end):
        p = mo.end()
        seg = src[p:p + 160]
        # path literal (possibly interpolated) or expression
        sm = re.match(r"(['\"])(.*?)\1", seg, re.S)
        if sm:
            path = sm.group(2)
        else:
            em = re.match(r"([\w.$]+(?:\([^)]*\))?)", seg)
            if not em:
                continue
            path = "<" + em.group(1) + ">"
            # skip map gets like json.get / prefs.get
            pre = src[max(0, mo.start() - 40):mo.start()]
            if not re.search(r"(api|Api|client|Client|dio|Dio|_http|apiClientProvider\)|http)\s*\n?\s*$", pre):
                continue
        if sm:
            pre = src[max(0, mo.start() - 60):mo.start()]
            if not path.startswith("/") and not path.startswith("$") and not path.startswith("${"):
                continue
            if not re.search(r"(api|Api|client|Client|dio|Dio|_http|apiClientProvider\)|\)|http|_api|\w)\s*$", pre.strip() + ""):
                pass
        out.append({"method": mo.group(1).upper(), "path": path, "pos": mo.start()})
    return out


def norm_app_path(p):
    p = re.sub(r"\?.*$", "", p)
    p = re.sub(r"\$\{[^}]*\}|\$\w+", "{}", p)
    if not p.startswith("/"):
        return None
    return "/v1" + p if not p.startswith("/v1") else p
