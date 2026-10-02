import re, glob, os, json
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paths import ROOT
BE = os.path.join(ROOT, "backend")

ROUTE_RE = re.compile(r'\b(v1|r|api|admin|g)\.(Get|Post|Put|Patch|Delete|Handle|HandleFunc)\("(/[^"]*)",\s*([\w.]+)')


def routes():
    out = []
    for f in glob.glob(BE + "/internal/bff/mobile/*.go"):
        if f.endswith("_test.go"):
            continue
        s = open(f).read()
        for mo in ROUTE_RE.finditer(s):
            if mo.group(1) != "v1":
                continue
            method = mo.group(2).upper()
            path = "/v1" + mo.group(3)
            handler = mo.group(4).split(".")[-1]
            rx = "^" + re.sub(r"\\\{[^}]*\\\}", r"[^/]+", re.escape(path)) + "/?$"
            out.append({"method": method, "path": path, "handler": handler, "rx": re.compile(rx),
                        "file": os.path.relpath(f, ROOT)})
    return out


ROUTES = routes()


def match_route(method, path):
    """path may contain {} placeholders; returns route dict or None."""
    if path is None:
        return None
    p = path.split("?")[0]
    p = p.replace("{}", "X")
    if not p.startswith("/v1"):
        p = "/v1" + p
    cands = [r for r in ROUTES if r["rx"].match(p)]
    if method:
        mc = [r for r in cands if r["method"] == method]
        if mc:
            cands = mc
    if not cands:
        return None
    # prefer most literal segments
    cands.sort(key=lambda r: -len(re.sub(r"\{[^}]*\}", "", r["path"])))
    return cands[0]


GO_TEST_RE = re.compile(r"^func (Test\w+)\(t \*testing\.T\)\s*\{", re.M)
METHOD_MAP = {"MethodGet": "GET", "MethodPost": "POST", "MethodPut": "PUT", "MethodPatch": "PATCH", "MethodDelete": "DELETE"}


def go_tests():
    """list of {file, test, routes:set(key), handlers:set}"""
    out = []
    handler_names = {r["handler"] for r in ROUTES}
    for f in glob.glob(BE + "/**/*_test.go", recursive=True):
        s = open(f).read()
        heads = list(GO_TEST_RE.finditer(s))
        # helper funcs in file (non-test) that build requests: include their paths into file-level pool
        for i, h in enumerate(heads):
            start = h.start()
            end = heads[i + 1].start() if i + 1 < len(heads) else len(s)
            body = s[start:end]
            keys = set()
            # httptest.NewRequest(http.MethodX, "/v1/..." + id + "/x", ...)
            for mo in re.finditer(r'(?:NewRequest|NewRequestWithContext|newRequest|doRequest|do|request|serve|call|perform)\w*\(\s*(?:ctx,\s*)?(?:http\.(Method\w+)|"(GET|POST|PUT|PATCH|DELETE)")\s*,\s*((?:"[^"]*"|[\w.()]+|\s*\+\s*)+)', body):
                method = METHOD_MAP.get(mo.group(1)) or mo.group(2)
                expr = mo.group(3)
                parts = re.findall(r'"([^"]*)"|([\w.()]+)', expr)
                path = ""
                for lit, var in parts:
                    if lit or lit == "":
                        if lit:
                            path += lit
                        elif var:
                            path += "{}"
                    else:
                        path += "{}"
                path = re.sub(r"%[sdv]", "{}", path)
                r = match_route(method, path)
                if r:
                    keys.add(r["method"] + " " + r["path"])
            for mo in re.finditer(r'fmt\.Sprintf\("(/v1/[^"]*)"', body):
                r = match_route(None, re.sub(r"%[sdv]", "{}", mo.group(1)))
                if r:
                    keys.add(r["method"] + " " + r["path"])
            for mo in re.finditer(r'"(/v1/[^"?]*)', body):
                r = match_route(None, mo.group(1) + ("{}" if mo.group(1).endswith("/") else ""))
                if r:
                    keys.add(r["method"] + " " + r["path"])
            hs = set(mo.group(1) for mo in re.finditer(r"\.(\w+)\(", body) if mo.group(1) in handler_names)
            for r in ROUTES:
                if r["handler"] in hs:
                    keys.add(r["method"] + " " + r["path"])
            asserts = bool(re.search(r"t\.(Fatal|Fatalf|Error|Errorf)|require\.|assert\.", body))
            out.append({"suite": "go", "file": os.path.relpath(f, ROOT), "test": h.group(1), "routes": sorted(keys), "asserts": asserts})
    return out


if __name__ == "__main__":
    print(len(ROUTES))
    gt = go_tests()
    print(len(gt), sum(1 for t in gt if t["routes"]))
    covered = set(k for t in gt for k in t["routes"])
    print("routes covered by go", len(covered))
