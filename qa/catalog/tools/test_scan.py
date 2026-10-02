"""Scan every test suite and extract, per test: the controls it ACTS on
(keys/texts/tooltips/icons), what it merely FINDS, whether an outcome is
asserted after the action, the classes it pumps and the API routes it hits."""
import json, os, re, glob, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paths import build_path
from dartscan import mask, match_close, ROOT, LIB
from backend_scan import match_route, go_tests

APP_TEST = os.path.join(ROOT, "app/test")
LIB_CLASSES = set()
for f in glob.glob(LIB + "/**/*.dart", recursive=True):
    LIB_CLASSES |= set(re.findall(r"^\s*(?:abstract\s+|final\s+)*class\s+(\w+)", open(f).read(), re.M))


def rel(f):
    return os.path.relpath(f, ROOT)


def strip_key(s):
    return re.sub(r"\$\{[^}]*\}|\$\w+", "*", s)


FINDER_PATTERNS = [
    ("key", re.compile(r"find\.byKey\(\s*(?:const\s+)?(?:ValueKey(?:<\w+>)?|Key)\(\s*'([^']*)'")),
    ("key", re.compile(r"find\.byKey\(\s*(?:const\s+)?(?:ValueKey(?:<\w+>)?|Key)\(\s*\"([^\"]*)\"")),
    ("text", re.compile(r"find\.(?:text|textContaining)\(\s*'((?:[^'\\]|\\.)*)'")),
    ("text", re.compile(r"find\.(?:text|textContaining)\(\s*\"((?:[^\"\\]|\\.)*)\"")),
    ("text", re.compile(r"find\.widgetWithText\(\s*\w+\s*,\s*'((?:[^'\\]|\\.)*)'")),
    ("text", re.compile(r"find\.bySemanticsLabel\(\s*(?:RegExp\()?\s*r?'((?:[^'\\]|\\.)*)'")),
    ("tooltip", re.compile(r"find\.byTooltip\(\s*'((?:[^'\\]|\\.)*)'")),
    ("icon", re.compile(r"find\.(?:byIcon|widgetWithIcon\(\s*\w+\s*,)\(?\s*Icons\.(\w+)")),
    ("type", re.compile(r"find\.byType\(\s*(\w+)")),
]
ACTION_RE = re.compile(r"\btester\s*\.\s*(tap|tapAt|longPress|drag|fling|timedDrag|enterText|dragUntilVisible|press|startGesture)\s*\(")
EXPECT_RE = re.compile(r"\b(expect|expectLater|verify|verifyNever)\s*\(")


def finders_in(text, var_finders):
    out = []
    for kind, rx in FINDER_PATTERNS:
        for mo in rx.finditer(text):
            v = mo.group(1)
            out.append((kind, strip_key(v) if kind == "key" else v))
    for var, fl in var_finders.items():
        if re.search(r"(?<![\w.])" + re.escape(var) + r"\b", text):
            out.extend(fl)
    # literal qa keys passed to helpers
    for mo in re.finditer(r"'(qa\.[^']+)'", text):
        out.append(("key", strip_key(mo.group(1))))
    return out


def var_finder_map(src):
    vm = {}
    for mo in re.finditer(r"(?:final|var|const|Finder)\s+(\w+)\s*=\s*([^;]*find\.[^;]*);", src, re.S):
        fl = []
        for kind, rx in FINDER_PATTERNS:
            for m2 in rx.finditer(mo.group(2)):
                fl.append((kind, strip_key(m2.group(1)) if kind == "key" else m2.group(1)))
        if fl:
            vm[mo.group(1)] = fl
    for mo in re.finditer(r"(?:const|final|var)\s+(\w+)\s*=\s*(?:const\s+)?(?:ValueKey(?:<\w+>)?|Key)\(\s*'([^']*)'\s*\)", src):
        vm[mo.group(1)] = [("key", strip_key(mo.group(2)))]
    # getters: Finder get love => find.byKey(...)
    for mo in re.finditer(r"Finder\s+(?:get\s+)?(\w+)(?:\([^)]*\))?\s*=>\s*([^;]*);", src, re.S):
        fl = []
        for kind, rx in FINDER_PATTERNS:
            for m2 in rx.finditer(mo.group(2)):
                fl.append((kind, strip_key(m2.group(1)) if kind == "key" else m2.group(1)))
        if fl:
            vm[mo.group(1)] = fl
    return vm


def dart_helpers(src, m):
    """top-level/local helper functions whose body performs tester actions."""
    helpers = {}
    for mo in re.finditer(r"(?:Future<\w+>|void|Future)\s+(_?[a-z]\w*)\s*\(", m):
        o = mo.end() - 1
        c = match_close(m, o)
        rest = m[c + 1:c + 20]
        mm = re.match(r"\s*(async\s*)?(\{|=>)", rest)
        if not mm:
            continue
        b = c + 1 + mm.end() - 1
        e = match_close(m, b) if mm.group(2) == "{" else m.find(";", b)
        body = src[o:e + 1]
        if ACTION_RE.search(m[o:e + 1]):
            helpers[mo.group(1)] = body
    return helpers


def flutter_tests():
    out = []
    for f in sorted(glob.glob(APP_TEST + "/**/*.dart", recursive=True)):
        src = open(f).read()
        m = mask(src)
        vm = var_finder_map(src)
        helpers = dart_helpers(src, m)
        file_classes = set(re.findall(r"\b([A-Z]\w+)\s*[(.]", m)) & LIB_CLASSES
        # also classes in strings? no
        heads = list(re.finditer(r"\b(testWidgets|test|patrolTest)\s*\(\s*", m))
        groups = [(g.start(), match_close(m, g.end() - 1), src[g.end():g.end() + 200]) for g in re.finditer(r"\bgroup\s*\(\s*", m)]
        for h in heads:
            o = h.end() - 1
            c = match_close(m, o)
            nm = re.match(r"\s*(?:'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\")", src[h.end():h.end() + 400], re.S)
            name = (nm.group(1) or nm.group(2)) if nm else "?"
            gname = ""
            for (gs, ge, gtxt) in groups:
                if gs < h.start() < ge:
                    gm = re.match(r"\s*'((?:[^'\\]|\\.)*)'", gtxt)
                    if gm:
                        gname = gm.group(1) + " > "
            body = src[o:c + 1]
            bm = m[o:c + 1]
            actions = []
            for am in ACTION_RE.finditer(bm):
                ao = am.end() - 1
                ac = match_close(bm, ao)
                arg = body[ao:ac + 1]
                fl = finders_in(arg, vm)
                if re.search(r"Key\(\s*[a-z]\w*\s*\)", arg):
                    pre = src[max(0, h.start() - 900):h.start()] + body
                    fl += [("key", strip_key(x)) for x in re.findall(r"'(qa\.[^']+)'", pre)]
                kind = am.group(1)
                actions.append({"pos": am.start(), "verb": kind, "finders": fl, "end": ac})
            # helper calls
            for hn, hb in helpers.items():
                for hm in re.finditer(r"(?<![\w.])" + re.escape(hn) + r"\s*\(", bm):
                    ho = hm.end() - 1
                    hc = match_close(bm, ho)
                    arg = body[ho:hc + 1]
                    fl = finders_in(arg, vm)
                    # helper's own finders (fixed taps inside helper)
                    fl += finders_in(hb, vm)
                    verbs = set(a.group(1) for a in ACTION_RE.finditer(mask(hb)))
                    actions.append({"pos": hm.start(), "verb": "/".join(sorted(verbs)), "finders": fl, "end": hc, "helper": hn})
            expects = []
            for em in EXPECT_RE.finditer(bm):
                eo = em.end() - 1
                ec = match_close(bm, eo)
                expects.append({"pos": em.start(), "text": body[eo:ec + 1]})
            actions.sort(key=lambda a: a["pos"])
            acted = []
            for a in actions:
                later = [e for e in expects if e["pos"] > a["pos"]]
                own = set(v for _, v in a["finders"])
                outcome = False
                for e in later:
                    efs = finders_in(e["text"], vm)
                    evals = set(v for _, v in efs)
                    if re.search(r"findsNothing", e["text"]) and evals & own:
                        outcome = True  # control disappeared / sheet closed
                        break
                    if not evals or not (evals <= own):
                        outcome = True
                        break
                for kind, v in a["finders"]:
                    if kind == "type":
                        continue
                    acted.append({"kind": kind, "value": v, "verb": a["verb"], "outcome": outcome})
            found = []
            for e in expects:
                for kind, v in finders_in(e["text"], vm):
                    if kind != "type":
                        found.append({"kind": kind, "value": v})
            types = set(re.findall(r"find\.byType\(\s*(\w+)", body))
            api = set(re.findall(r"'(/[a-z][\w/{}$.-]*)'", body)) | set(re.findall(r"\"(/[a-z][\w/{}$.-]*)\"", body))
            out.append({"suite": "flutter", "file": rel(f), "test": (gname + name).strip(), "acted": acted, "found": found,
                        "classes": sorted((set(re.findall(r"\b([A-Z]\w+)\s*[(.]", bm)) & LIB_CLASSES) | file_classes),
                        "types_asserted": sorted(types), "paths": sorted(api), "n_expect": len(expects)})
    return out


# ------------------------------------------------------------- playwright
JS_ACTION_RE = re.compile(r"\.(click|dblclick|fill|check|uncheck|selectOption|press|tap|dragTo|setInputFiles|hover|type|pressSequentially)\s*\(")


def js_locators(text):
    out = []
    for mo in re.finditer(r"getByRole\(\s*'(\w+)'\s*,\s*\{\s*name:\s*(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\"|/((?:[^/\\]|\\.)*)/\w*)", text):
        out.append(("text", (mo.group(2) or mo.group(3) or mo.group(4) or "").replace("\\", "")))
    for mo in re.finditer(r"getBy(?:Text|Label|Placeholder|Title|AltText)\(\s*(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\"|/((?:[^/\\]|\\.)*)/\w*)", text):
        out.append(("text", (mo.group(1) or mo.group(2) or mo.group(3) or "").replace("\\", "")))
    for mo in re.finditer(r"(qa\.[\w.*-]+)", text):
        out.append(("key", mo.group(1)))
    for mo in re.finditer(r"locator\(\s*['\"`]([^'\"`]+)['\"`]", text):
        out.append(("css", mo.group(1)))
    return out


def js_blocks(src):
    m = src  # JS: approximate, no masking of template strings
    out = []
    for h in re.finditer(r"\btest(?:\.only|\.skip)?\(\s*(['\"`])(.*?)\1\s*,", src):
        # find body start: first '{' after '=>'
        arrow = src.find("=>", h.end())
        if arrow < 0:
            continue
        b = src.find("{", arrow)
        e = match_close(mask_js(src), b)
        out.append((h.group(2), src[b:e + 1], h.start()))
    return out


def mask_js(src):
    # replace string contents for paren matching (simple)
    out = list(src)
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
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
        if c in "'\"`":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 1
                j += 1
            for k in range(i + 1, min(j, n)):
                if out[k] != "\n":
                    out[k] = " "
            i = j + 1
            continue
        if c == "/" and i > 0 and re.match(r"[(,=:\s!&|]", src[i - 1]) and not src.startswith("//", i):
            # regex literal
            j = i + 1
            while j < n and src[j] != "/" and src[j] != "\n":
                if src[j] == "\\":
                    j += 1
                j += 1
            if j < n and src[j] == "/":
                for k in range(i + 1, j):
                    out[k] = " "
                i = j + 1
                continue
        i += 1
    return "".join(out)


def playwright_tests():
    out = []
    for f in sorted(glob.glob(os.path.join(ROOT, "website/tests/*.spec.js"))):
        src = open(f).read()
        # locator variables
        varmap = {}
        for mo in re.finditer(r"(?:const|let|var)\s+(\w+)\s*=\s*([^;]*?(?:getBy\w+|locator)\([^;]*);", src, re.S):
            ls = js_locators(mo.group(2))
            if ls:
                varmap[mo.group(1)] = ls
        for name, body, pos in js_blocks(src):
            acted = []
            stmts = re.split(r";\s*\n|\n\s*\n", body)
            spos = 0
            exp_positions = [mo.start() for mo in re.finditer(r"\bexpect(?:\.poll)?\(|waitForRequest|waitForResponse|toHaveURL", body)]
            for mo in JS_ACTION_RE.finditer(body):
                # statement start
                st = max(body.rfind("\n", 0, mo.start()), body.rfind(";", 0, mo.start()))
                stmt = body[st + 1:mo.end()]
                # also chained multi-line: include previous 3 lines if starts with '.'
                k = st
                while stmt.strip().startswith(".") and k > 0:
                    k2 = body.rfind("\n", 0, k)
                    stmt = body[k2 + 1:mo.end()]
                    k = k2
                ls = js_locators(stmt)
                for v, vl in varmap.items():
                    if re.search(r"\b" + re.escape(v) + r"\b", stmt):
                        ls += vl
                lm = re.findall(r"\b(\w+)\s*\.\s*(?:click|fill|check|tap)\(", stmt)
                later = [p for p in exp_positions if p > mo.start()]
                outcome = bool(later)
                for kind, v in ls:
                    acted.append({"kind": kind, "value": v, "verb": mo.group(1), "outcome": outcome})
            found = [{"kind": k, "value": v} for k, v in js_locators(" ".join(re.findall(r"expect\([^;]*", body)))]
            gotos = re.findall(r"goto\(\s*[`'\"]([^`'\"]+)", body)
            out.append({"suite": "playwright", "file": rel(f), "test": name, "acted": acted, "found": found, "gotos": gotos,
                        "routes": sorted(set(re.findall(r"#/([\w/-]+)", body))), "paths": sorted(set(re.findall(r"/v1(/[\w/{}-]+)", body))),
                        "n_expect": len(exp_positions)})
    return out


# ------------------------------------------------------------- python (appium/api)
def py_blocks(src):
    out = []
    lines = src.split("\n")
    heads = [(i, re.match(r"^(\s*)def (test_\w+)\(", l)) for i, l in enumerate(lines)]
    heads = [(i, mo) for i, mo in heads if mo]
    for idx, (i, mo) in enumerate(heads):
        ind = len(mo.group(1))
        j = i + 1
        while j < len(lines):
            l = lines[j]
            if l.strip() and (len(l) - len(l.lstrip())) <= ind and not l.lstrip().startswith(("#", ")", "]", "}")):
                break
            j += 1
        out.append((mo.group(2), "\n".join(lines[i:j]), i + 1))
    return out


PY_ACT_RE = re.compile(r"\.(tap_qa|tap_qa_coordinate|maybe_tap_qa|tap_text|tap_text_contains|tap_scroll_text|tap_scroll_text_contains|tap_accessibility_id|type_into_qa|tap_first_visible_text|long_press\w*|swipe\w*|scroll_sheet_to_text\w*|select\w*|toggle\w*|tap_\w+)\(\s*(?:f?['\"]([^'\"]+)['\"]|\[([^\]]*)\])?")
PY_HTTP_RE = re.compile(r"\.(get|post|put|patch|delete|request)\(\s*(?:\"(GET|POST|PUT|PATCH|DELETE)\"\s*,\s*)?f?['\"](/[^'\"]*)['\"]")


def py_helper_actions(path):
    """helpers.py: function -> list of (verb, value) of qa taps it performs."""
    src = open(path).read()
    out = {}
    for mo in re.finditer(r"^\s*def (\w+)\(", src, re.M):
        start = mo.end()
        nxt = re.search(r"^\s*def \w+\(", src[start:], re.M)
        body = src[start:start + nxt.start()] if nxt else src[start:]
        acts = [(a.group(1), a.group(2)) for a in PY_ACT_RE.finditer(body) if a.group(2)]
        if acts:
            out[mo.group(1)] = acts
    return out


def py_tests(suite_dir, suite_name):
    out = []
    helper_files = [p for p in glob.glob(os.path.join(ROOT, suite_dir, "*.py"))]
    hmap = {}
    for p in helper_files:
        hmap.update(py_helper_actions(p))
    for f in sorted(glob.glob(os.path.join(ROOT, suite_dir, "tests/*.py"))):
        src = open(f).read()
        local_h = py_helper_actions(f)
        allh = dict(hmap)
        allh.update(local_h)
        for name, body, line in py_blocks(src):
            acted = []
            assert_pos = [mo.start() for mo in re.finditer(r"\bassert\b|wait_for\w*\(|\.ok\(\)|expect_\w+\(|assert_\w+\(|pytest\.raises", body)]
            for mo in PY_ACT_RE.finditer(body):
                vals = []
                if mo.group(2):
                    vals = [mo.group(2)]
                elif mo.group(3):
                    vals = re.findall(r"['\"]([^'\"]+)['\"]", mo.group(3))
                later = [p for p in assert_pos if p > mo.end()]
                for v in vals:
                    acted.append({"kind": "key" if v.startswith("qa.") else "text", "value": strip_key(v), "verb": mo.group(1), "outcome": bool(later)})
            for hn, acts in allh.items():
                for hm in re.finditer(r"\b" + re.escape(hn) + r"\(", body):
                    later = [p for p in assert_pos if p > hm.end()]
                    for verb, v in acts:
                        acted.append({"kind": "key" if v.startswith("qa.") else "text", "value": v, "verb": verb + " via " + hn, "outcome": bool(later), "indirect": True})
            found = [{"kind": "key" if v.startswith("qa.") else "text", "value": strip_key(v)}
                     for v in re.findall(r"\.(?:wait_for_qa|wait_for_text|wait_for_accessibility_id|assert_\w+|find_\w+|is_\w+visible)\(\s*f?['\"]([^'\"]+)['\"]", body)]
            routes = set()
            for mo in PY_HTTP_RE.finditer(body):
                method = (mo.group(2) or mo.group(1)).upper()
                if method == "REQUEST":
                    continue
                p = re.sub(r"\{[^}]*\}", "{}", mo.group(3))
                r = match_route(method, p)
                if r:
                    routes.add(r["method"] + " " + r["path"])
            out.append({"suite": suite_name, "file": rel(f), "test": name, "line": line, "acted": acted, "found": found,
                        "routes": sorted(routes), "asserts": bool(assert_pos)})
    return out


def django_tests():
    out = []
    base = os.path.join(ROOT, "control-panel")
    for f in sorted(glob.glob(base + "/**/tests/**/*.py", recursive=True) + glob.glob(base + "/**/test_*.py", recursive=True)):
        if "/site-packages/" in f or "/.venv/" in f or "/venv/" in f:
            continue
        src = open(f).read()
        for name, body, line in py_blocks(src):
            urls = set(re.findall(r"reverse\(\s*['\"]([\w:.-]+)['\"]", body))
            paths = set(re.findall(r"client\.(?:get|post|put|patch|delete)\(\s*f?['\"](/[^'\"]*)['\"]", body))
            out.append({"suite": "django", "file": rel(f), "test": name, "line": line, "url_names": sorted(urls), "paths": sorted(paths),
                        "asserts": bool(re.search(r"assert|self\.assert", body))})
    return list({(t["file"], t["test"]): t for t in out}.values())


if __name__ == "__main__":
    res = {
        "flutter": flutter_tests(),
        "playwright": playwright_tests(),
        "appium": py_tests("qa/appium", "appium"),
        "api_e2e": py_tests("qa/api_e2e", "api_e2e"),
        "go": go_tests(),
        "django": django_tests(),
    }
    json.dump(res, open(build_path("tests.json"), "w"), indent=1)
    for k, v in res.items():
        print(k, len(v), "tests;", sum(1 for t in v if t.get("acted")), "with UI actions;", sum(1 for t in v if t.get("routes")), "with routes")
