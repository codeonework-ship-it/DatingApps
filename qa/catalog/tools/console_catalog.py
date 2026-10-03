"""Operator console (Django control panel) features for the catalog.

Everything is derived from the console's own source, so a new page, list,
report or live topic shows up without editing a hand-kept list:

* pages and actions: ``control_panel/urls.py`` (one control per named route,
  grouped into a feature per first path segment, ``moderation/<x>`` split).
  A route is an action (``.performs`` + ``.authz``) when its view is POST-only
  (``@require_POST`` / ``require_http_methods(["POST"])``) or its name says so;
  otherwise a page (``.renders``) or a download.
* list controls: every ``ListSpec`` in ``views*.py`` (search, each ``Filter``,
  sort, page size, Excel export) attached to the page whose view uses it, with
  ``<page>.filters`` and ``<page>.export`` cases.
* form controls: ``<form>`` fields in the templates a view renders. GET forms
  are page filters; POST form fields belong to the action route they post to
  (covered by its ``.performs`` case).
* reports: ``control_panel/reports/catalog.py`` - one feature per report with
  its parameters, group-by choices and Excel/CSV/PDF exports.
* the live socket: ``live.TOPICS`` from ``control_panel/live.py``.

Case ids follow ``console.<area>.<page>.<case>`` (the route name is the page).
Shared console behaviour that is not one page (the listing engine, the live
socket, the layout shell, the report server) has curated cases whose ids are
the ones the console tests already name.
"""
from __future__ import annotations

import ast
import collections
import glob
import importlib
import os
import re
import sys

CP = "control-panel"
APP = "control-panel/control_panel"
TPL = "control-panel/templates"

ACTION_RE = re.compile(r"(approve|reject|action|save|delete|toggle|suspend|unsuspend|ban|unban|verify|grant|adjust|control|update|claim|merge|reply|bulk|resolve|decision|cancel|stage|create|new|edit|activate|deactivate|rebuild|exclude|include|reverse|status|role|logout|login|review|preview)$")
DL_RE = re.compile(r"(export|csv|content|attachment|evidence|investor_pack)$")
AREAS = {"analytics": "Analytics", "business": "Business reports", "engagement": "Engagement admin", "moderation": "Moderation", "city-pilot": "City pilot",
         "support": "Support desk", "users": "Members", "billing": "Billing", "verifications": "Verification queue", "appeals": "Appeals",
         "safety": "Safety (SOS)", "account-recovery": "Account recovery", "catalog": "Gift catalog", "config": "Feature flags", "progression": "Progression",
         "client-errors": "Client errors", "growth": "Growth governance", "": "Dashboard", "login": "Auth", "logout": "Auth", "activities": "Activity feed",
         "audit": "Audit log", "events": "Domain events", "activity": "Member activity", "system": "Server activity", "reports": "Report server", "qa-lab": "QA Lab"}
SMOKE = {"suite": "django", "runner": "pytest qa/console_smoke (live console)", "file": "qa/console_smoke/test_console_smoke.py", "test": "test_nav_page_loads_cleanly"}


def slug(s, n=60):
    s = re.sub(r"[^a-z0-9]+", "_", (s or "").lower()).strip("_")
    return s[:n].strip("_") or "x"


def case(cid, title, ctype, steps, expected, auto, seed=None, status=None, notes=None, covers=None):
    c = {"id": cid, "title": title, "type": ctype, "steps": steps, "expected": expected, "seed_needs": seed or ["operator account"],
         "automated_by": auto, "status": status or ("automated" if auto else "not_automated")}
    if notes:
        c["notes"] = notes
    if covers:
        c["covers_controls"] = covers
    return c


def ctrl(cid, ctype, label, action, **extra):
    d = {"id": cid, "type": ctype, "label": label, "qa_key": None, "action": action, "api": None}
    d.update({k: v for k, v in extra.items() if v is not None})
    return d


# ---------------------------------------------------------------- source readers
def _read(root, rel):
    with open(os.path.join(root, rel), encoding="utf-8") as fh:
        return fh.read()


def _const(node):
    return node.value if isinstance(node, ast.Constant) else None


def routes(root):
    """[(path, module, func, name)] from urls.py, in file order."""
    tree = ast.parse(_read(root, f"{APP}/urls.py"))
    out = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and getattr(node.func, "id", None) == "path" and node.args:
            p = _const(node.args[0])
            name = next((_const(k.value) for k in node.keywords if k.arg == "name"), None)
            view = node.args[1] if len(node.args) > 1 else None
            if p is None or not name or view is None:
                continue
            if isinstance(view, ast.Attribute) and isinstance(view.value, ast.Name):
                out.append((p, view.value.id, view.attr, name, node.lineno))
    out.sort(key=lambda r: r[4])
    return [r[:4] for r in out]


def _decorator_methods(fn):
    """'POST' / 'GET' / None from require_POST, require_GET, require_http_methods([...])."""
    for d in fn.decorator_list:
        name = d.id if isinstance(d, ast.Name) else (d.attr if isinstance(d, ast.Attribute) else None)
        if isinstance(d, ast.Call):
            fname = getattr(d.func, "id", None) or getattr(d.func, "attr", None)
            if fname == "require_http_methods" and d.args and isinstance(d.args[0], (ast.List, ast.Tuple)):
                methods = {(_const(e) or "").upper() for e in d.args[0].elts}
                if methods == {"POST"}:
                    return "POST"
                if "POST" in methods:
                    return "GET+POST"
                return "GET"
        if name == "require_POST":
            return "POST"
        if name in ("require_GET", "require_safe"):
            return "GET"
    return None


def _filter_spec(call):
    """listing.Filter(name, label, choices?, kind=...) -> dict."""
    args = [a for a in call.args]
    name = _const(args[0]) if args else None
    label = _const(args[1]) if len(args) > 1 else None
    kw = {k.arg: k.value for k in call.keywords}
    kind = _const(kw["kind"]) if "kind" in kw else ("choice" if (len(args) > 2 or "choices" in kw) else "choice")
    return {"name": name, "label": label or name, "kind": kind or "choice"}


def list_specs(root):
    """{module: {VAR: spec}} for every ListSpec assignment in views*.py."""
    out = collections.defaultdict(dict)
    for f in sorted(glob.glob(os.path.join(root, APP, "views*.py"))):
        mod = os.path.basename(f)[:-3]
        tree = ast.parse(open(f, encoding="utf-8").read())
        for node in tree.body:
            if not (isinstance(node, ast.Assign) and isinstance(node.value, ast.Call)):
                continue
            fn = node.value.func
            fname = getattr(fn, "attr", None) or getattr(fn, "id", None)
            if fname != "ListSpec":
                continue
            kw = {k.arg: k.value for k in node.value.keywords}
            filters = []
            if isinstance(kw.get("filters"), (ast.Tuple, ast.List)):
                for e in kw["filters"].elts:
                    if isinstance(e, ast.Call) and (getattr(e.func, "attr", None) or getattr(e.func, "id", None)) == "Filter":
                        filters.append(_filter_spec(e))
            sorts = []
            if isinstance(kw.get("sorts"), (ast.Tuple, ast.List)):
                for e in kw["sorts"].elts:
                    if isinstance(e, (ast.Tuple, ast.List)) and e.elts:
                        sorts.append(_const(e.elts[0]))
            searchable = _const(kw["searchable"]) if "searchable" in kw else True
            columns = isinstance(kw.get("columns"), (ast.Tuple, ast.List)) and bool(kw["columns"].elts) or \
                (isinstance(kw.get("columns"), ast.Name))
            spec = {"name": _const(kw.get("name")) if kw.get("name") is not None else None, "filters": filters, "sorts": sorts,
                    "searchable": searchable is not False, "search_label": _const(kw["search_label"]) if "search_label" in kw else "Search",
                    "export": bool(columns)}
            for t in node.targets:
                if isinstance(t, ast.Name):
                    out[mod][t.id] = spec
    return out


def view_info(root, specs):
    """{(module, func): {method, templates, specs}} from views*.py."""
    info = {}
    for f in sorted(glob.glob(os.path.join(root, APP, "views*.py"))):
        mod = os.path.basename(f)[:-3]
        src = open(f, encoding="utf-8").read()
        tree = ast.parse(src)
        helpers = {}
        for node in tree.body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                names = {n.id for n in ast.walk(node) if isinstance(n, ast.Name)}
                tpls = sorted({n.value for n in ast.walk(node) if isinstance(n, ast.Constant) and isinstance(n.value, str)
                               and n.value.startswith("control_panel/") and n.value.endswith(".html")})
                calls = {getattr(n.func, "id", None) for n in ast.walk(node) if isinstance(n, ast.Call)}
                posts = any(isinstance(n, ast.Compare) and isinstance(n.left, ast.Attribute) and n.left.attr == "method"
                            for n in ast.walk(node))
                helpers[node.name] = {"names": names, "templates": tpls, "calls": calls - {None},
                                      "method": _decorator_methods(node), "branches_on_method": posts}
        for name, h in helpers.items():
            used = [s for s in specs.get(mod, {}) if s in h["names"]]
            tpls = list(h["templates"])
            # one level of local helpers (e.g. a shared render function)
            for c in h["calls"]:
                if c in helpers and c != name:
                    tpls += [t for t in helpers[c]["templates"] if t not in tpls]
                    used += [s for s in specs.get(mod, {}) if s in helpers[c]["names"] and s not in used]
            info[(mod, name)] = {"method": h["method"], "branches_on_method": h["branches_on_method"], "templates": tpls,
                                 "specs": [specs[mod][s] for s in used]}
    return info


FORM_RE = re.compile(r"<form\b([^>]*)>(.*?)</form>", re.S | re.I)
FIELD_RE = re.compile(r"<(input|select|textarea)\b([^>]*)>", re.I)
ATTR_RE = re.compile(r'([\w:-]+)\s*=\s*"([^"]*)"')
URL_RE = re.compile(r"\{%\s*url\s+'([\w:]+)'")


def _attrs(s):
    return {k.lower(): v for k, v in ATTR_RE.findall(s)}


def template_forms(root, tpl, seen=None):
    """Forms in a template (one level of {% include %} / {% extends %} is not followed for base.html)."""
    seen = seen or set()
    path = os.path.join(root, TPL, tpl)
    if tpl in seen or not os.path.exists(path):
        return []
    seen.add(tpl)
    src = open(path, encoding="utf-8").read()
    out = []
    for mo in FORM_RE.finditer(src):
        a = _attrs(mo.group(1))
        method = (a.get("method") or "get").lower()
        action = URL_RE.search(mo.group(1))
        fields = []
        for fm in FIELD_RE.finditer(mo.group(2)):
            fa = _attrs(fm.group(2))
            nm = fa.get("name")
            if not nm or nm == "csrfmiddlewaretoken" or "{" in nm:
                continue
            typ = (fa.get("type") or ("select" if fm.group(1).lower() == "select" else fm.group(1).lower())).lower()
            if typ in ("hidden", "submit", "button"):
                continue
            label = fa.get("aria-label") or fa.get("placeholder") or nm.replace("_", " ")
            if not any(f["name"] == nm for f in fields):
                fields.append({"name": nm, "type": typ, "label": label})
        out.append({"method": method, "action": action.group(1) if action else None, "fields": fields, "template": tpl})
    for mo in re.finditer(r"\{%\s*include\s+(?:\"([^\"]+)\"|'([^']+)')([^%]*)%\}", src):
        t = mo.group(1) or mo.group(2)
        if "partials/_list" in t:  # the shared list toolbar is modelled from ListSpec
            continue
        # A page that includes a shared header with show_filters=False shows
        # none of that header's filter form (analytics data page).
        if re.search(r"\bshow_filters\s*=\s*False\b", mo.group(3) or ""):
            continue
        out += template_forms(root, t, seen)
    return out


def load_reports(root):
    """REPORTS, CATEGORIES from control_panel/reports/catalog.py (pure Python, no Django)."""
    sys.path.insert(0, os.path.join(root, CP))
    try:
        mod = importlib.import_module("control_panel.reports.catalog")
        return list(mod.REPORTS), list(mod.CATEGORIES)
    except Exception as e:  # noqa: BLE001
        print("console_catalog: report catalog not importable:", e, file=sys.stderr)
        return [], []
    finally:
        sys.path.pop(0)


def live_topics(root):
    src = _read(root, f"{APP}/live.py")
    mo = re.search(r"TOPICS\s*=\s*frozenset\(\{([^}]*)\}\)", src)
    topics = re.findall(r'"(\w+)"', mo.group(1)) if mo else []
    doc = {}
    for t in topics:
        dm = re.search(r"``" + t + r"``\s+(.*?)(?=\n\s*``|\n\"\"\")", src, re.S)
        doc[t] = " ".join(dm.group(1).split()) if dm else t
    return topics, doc


# ---------------------------------------------------------------- features
def _feature_key(p):
    seg = p.split("/")[0]
    if seg == "moderation" and len(p.split("/")) > 1:
        seg2 = p.split("/")[1]
        return f"moderation/{seg2}", "Moderation: " + seg2.replace("-", " ")
    return seg, AREAS.get(seg, seg)


def build(root, tests):
    dj = tests["django"]
    by_name = collections.defaultdict(list)
    for t in dj:
        for n in t["url_names"]:
            by_name[n].append({"suite": "django", "file": t["file"], "test": t["test"]})
    base = _read(root, f"{TPL}/control_panel/base.html")
    rts = routes(root)
    sidebar = set(re.findall(r'href="(/[^"]*)"', base))
    sidebar |= {"/" + p for p, _, _, n in rts if n in set(re.findall(r"\{% url '([a-z_]+)'", base))}
    specs = list_specs(root)
    views = view_info(root, specs)

    # POST forms anywhere -> fields of their action route
    action_fields = collections.defaultdict(list)
    for tpl in sorted(glob.glob(os.path.join(root, TPL, "control_panel", "**", "*.html"), recursive=True)):
        rel = os.path.relpath(tpl, os.path.join(root, TPL))
        for fm in template_forms(root, rel):
            if fm["method"] == "post" and fm["action"]:
                for fld in fm["fields"]:
                    if not any(x["name"] == fld["name"] for x in action_fields[fm["action"]]):
                        action_fields[fm["action"]].append(dict(fld, template=rel))

    groups = collections.OrderedDict()
    for p, mod, func, name in rts:
        key, title = _feature_key(p)
        groups.setdefault(key, {"title": title, "routes": []})["routes"].append((p, mod, func, name))

    features = []
    feat_by_route = {}
    for key, g in groups.items():
        fid = "console." + re.sub(r"[^a-z0-9]+", "_", key.lower()).strip("_") if key else "console.dashboard"
        feat = {"id": fid, "area": "Operator console", "screen": g["title"], "route": "control-panel /" + key + "/",
                "source_files": sorted({f"{APP}/{m}.py" for _, m, _, _ in g["routes"]} | {f"{APP}/urls.py"}), "controls": [], "cases": []}
        for p, mod, func, name in g["routes"]:
            feat_by_route[name] = feat
            vi = views.get((mod, func), {})
            is_post_only = vi.get("method") == "POST"
            kind = "button" if (ACTION_RE.search(name) or is_post_only) else "link"
            is_dl = kind == "link" and bool(DL_RE.search(name))
            is_page = kind == "link" and not is_dl
            cid = f"{fid}.{name}"
            view_ref = f"{mod}.{func}"
            feat["controls"].append(ctrl(cid, kind, name.replace("_", " "),
                                         ("POST form → " if kind == "button" else ("download/stream → " if is_dl else "page → ")) + "/" + p + f" ({view_ref})",
                                         method=vi.get("method"), templates=vi.get("templates") or None))
            tests_for = by_name.get(name, [])
            if is_page and ("/" + p) in sidebar:
                tests_for = tests_for + [SMOKE]
            if kind == "button":
                fields = action_fields.get(name, [])
                covers = [cid]
                for fld in fields:
                    fcid = f"{cid}.field_{slug(fld['name'], 40)}"
                    ftype = "menu" if fld["type"] in ("select", "radio") else ("toggle" if fld["type"] == "checkbox" else "field")
                    feat["controls"].append(ctrl(fcid, ftype, f"{fld['label']} ({name.replace('_', ' ')} form)",
                                                 f"form field '{fld['name']}' posted to /{p}", template=fld["template"]))
                    covers.append(fcid)
                feat["cases"].append(case(f"{cid}.performs", f"Operator '{name.replace('_', ' ')}' performs its change and writes an audit entry", "happy",
                                          ["Log in as operator", f"Submit the {name} form (POST /{p})"], "Change persisted via BFF admin API; success message; audit log row; CSRF required",
                                          tests_for, seed=["operator account", "records for the target (user/ticket/report)"], covers=covers))
                feat["cases"].append(case(f"{cid}.authz", f"'{name.replace('_', ' ')}' refuses anonymous / non-operator / GET", "negative",
                                          [f"POST /{p} without session", "GET the action URL"], "Redirect to login / 405; nothing changes",
                                          [t for t in tests_for if re.search(r"anon|login|permission|forbid|csrf|get_|method|refus|denied|requires|authz|role", t["test"], re.I)],
                                          seed=["operator account"], covers=[cid]))
            else:
                feat["cases"].append(case(f"{cid}.renders", f"'{name.replace('_', ' ')}' renders with data and handles missing records (404 not 500)", "happy",
                                          ["Log in as operator", f"GET /{p}"], "200 with expected sections; 404 for unknown ids; a BFF failure shows a banner, not a 500",
                                          tests_for, seed=["operator account", "seeded BFF data"], covers=[cid]))
            if not is_page:
                continue
            # ---- list controls (ListSpec) and GET-form filters on this page
            filt_controls, export_control = [], None
            for spec in vi.get("specs") or []:
                if spec["searchable"]:
                    filt_controls.append(ctrl(f"{cid}.search", "field", f"{spec['search_label']} ({name.replace('_', ' ')})",
                                              "free-text search sent to Go as q (escaped in page links)", list_spec=spec["name"]))
                for flt in spec["filters"]:
                    ftype = "field" if flt["kind"] in ("text", "date") else "menu"
                    filt_controls.append(ctrl(f"{cid}.filter_{slug(flt['name'], 40)}", ftype, f"{flt['label']} filter ({name.replace('_', ' ')})",
                                              f"{flt['kind']} filter '{flt['name']}' sent to Go only when allowed by the ListSpec", list_spec=spec["name"]))
                if spec["sorts"]:
                    filt_controls.append(ctrl(f"{cid}.sort", "menu", f"Sort ({', '.join(s for s in spec['sorts'] if s)})",
                                              "sort + direction sent to Go as sort/order", list_spec=spec["name"]))
                filt_controls.append(ctrl(f"{cid}.paging", "link", "Page size and pager", "page/page_size reach Go as limit/offset; past-the-end clamps", list_spec=spec["name"]))
                if spec["export"] and not export_control:
                    export_control = ctrl(f"{cid}.export_xlsx", "button", f"Export Excel ({name.replace('_', ' ')})",
                                          "?export=xlsx pages through Go with the same filters and returns a workbook", list_spec=spec["name"])
            have = {c["id"] for c in filt_controls}
            for tpl in vi.get("templates") or []:
                for fm in template_forms(root, tpl.replace("control_panel/", "control_panel/", 1)):
                    if fm["method"] != "get":
                        continue
                    for fld in fm["fields"]:
                        fcid = f"{cid}.filter_{slug(fld['name'], 40)}" if fld["name"] != "q" else f"{cid}.search"
                        if fcid in have:
                            continue
                        have.add(fcid)
                        ftype = "menu" if fld["type"] in ("select", "radio") else ("toggle" if fld["type"] == "checkbox" else "field")
                        filt_controls.append(ctrl(fcid, ftype, f"{fld['label']} ({name.replace('_', ' ')})", f"GET filter '{fld['name']}'", template=fm["template"]))
            if filt_controls:
                feat["controls"] += filt_controls
                feat["cases"].append(case(f"{cid}.filters", f"'{name.replace('_', ' ')}' search, filters, sort and paging reach Go", "happy",
                                          ["Log in as operator", f"GET /{p} with each filter, a search, a sort and page 2"],
                                          "Only allowed values are forwarded to Go with the documented names; links keep the filters; the total is Go's",
                                          [t for t in tests_for if t is not SMOKE and re.search(r"filter|search|sort|page|paging|forward|reach", t["test"], re.I)],
                                          seed=["operator account", "seeded BFF data"], covers=[c["id"] for c in filt_controls]))
            if export_control:
                feat["controls"].append(export_control)
                feat["cases"].append(case(f"{cid}.export", f"'{name.replace('_', ' ')}' Excel export holds every filtered row", "happy",
                                          ["Log in as operator", f"GET /{p}?export=xlsx with filters"], "An .xlsx with every row matching the filters (paged through Go), typed cells, no formulas",
                                          [t for t in tests_for if re.search(r"export|excel|xlsx|workbook", t["test"], re.I)],
                                          seed=["operator account", "seeded BFF data"], covers=[export_control["id"]]))
        features.append(feat)

    # ---- member page sections and live tail on the activity feature
    act = next((f for f in features if f["id"] == "console.activity"), None)
    if act:
        act["controls"].append(ctrl("console.activity.member.panel", "link", "Member page: latest actions + link to the full log",
                                    "user_detail renders the member's latest actions (Go member_activity) and links to /activity/?member=", page="user_detail"))
        act["cases"] += [
            case("console.activity.member.section", "A member's page shows a summary and their latest actions with a link to the full log", "happy",
                 ["Open /users/<id>/"], "Latest actions, devices and IP counts, link to /activity/?member=<id>", [], covers=["console.activity.member.panel"]),
            case("console.activity.member.denied", "A role without activity access sees a note on the member page, not an error", "negative",
                 ["Open /users/<id>/ as a role Go refuses"], "'not available to your role' note; rest of the page renders", [], covers=["console.activity.member.panel"]),
        ]

    server, per_report = report_features(root)
    rep = next((f for f in features if f["id"] == "console.reports"), None)
    if rep is not None:
        rep["controls"] += server["controls"]
        rep["cases"] += server["cases"]
        rep["source_files"] = sorted(set(rep["source_files"]) | set(server["source_files"]))
    else:
        features.append(server)
    features += per_report
    features += live_features(root)
    features += shared_features()
    return features


def report_features(root):
    reports, cats = load_reports(root)
    out = []
    server = {"id": "console.reports", "area": "Operator console", "screen": "Report server (catalog, viewer, exports)",
              "route": "control-panel /reports/ and /reports/<id>/",
              "source_files": [f"{APP}/views_reports.py", f"{APP}/reports/engine.py", f"{APP}/reports/exporters.py", f"{APP}/reports/catalog.py",
                               f"{TPL}/control_panel/reports/catalog.html", f"{TPL}/control_panel/reports/view.html"],
              "controls": [ctrl("console.reports.catalog.search_box", "field", "Find a report (q)", "filters the catalog by title, description, category and keywords"),
                           ctrl("console.reports.view.group_by_select", "menu", "Group by (per table)", "group_<dataset>=field regroups a table or shows it flat"),
                           ctrl("console.reports.view.drill_link", "link", "Drill-through links", "a drill field links to another report with its parameters"),
                           ctrl("console.reports.export.xlsx_button", "button", "Export Excel", "?export=xlsx"),
                           ctrl("console.reports.export.csv_button", "button", "Export CSV (per table)", "?export=csv&dataset=<key>"),
                           ctrl("console.reports.export.pdf_button", "button", "Export PDF", "?export=pdf")],
              "cases": [
                  case("console.reports.catalog.search", "The catalog lists every report by category and finds them by keyword", "happy", ["Open /reports/", "Search a keyword"],
                       "Sections Members/Operations/Business/Product/Server; search narrows the list", [], covers=["console.reports.catalog.search_box"]),
                  case("console.reports.catalog.role_scoped", "The catalog hides reports the operator's role cannot read", "negative", ["Open /reports/ as support"],
                       "Finance reports are absent", []),
                  case("console.reports.params.validated", "Only listed parameter values reach Go; defaults fill the rest", "negative",
                       ["Open a report with unknown/invalid parameters"], "Invalid values dropped; defaults used", []),
                  case("console.reports.view.groups_totals", "Grouped rows get subtotals; money is never added across currencies", "happy",
                       ["Open a grouped report"], "Subtotal rows; per-currency totals", []),
                  case("console.reports.view.group_by", "Operators regroup a table or show it flat", "happy", ["Change Group by"], "Table regrouped; flat when cleared", [],
                       covers=["console.reports.view.group_by_select"]),
                  case("console.reports.view.drill_through", "A drill field links to the target report with its parameters", "happy", ["Click a city"],
                       "Opens the liquidity report for that city", [], covers=["console.reports.view.drill_link"]),
                  case("console.reports.view.denied", "Go's 403 renders as 'not available to your role' (403), not a crash", "negative", ["Open a report Go refuses"], "403 page with the note", []),
                  case("console.reports.view.unknown", "An unknown report id is a 404", "negative", ["Open /reports/nope/"], "404", []),
                  case("console.reports.view.analytics_tables", "Product reports take their tables and units from Go's column metadata", "happy",
                       ["Open a Product report"], "Tables and units as Go describes them", []),
                  case("console.reports.export.xlsx", "Excel export: one typed sheet per table, subtotal rows and an About sheet", "happy", ["Export Excel"],
                       "Typed .xlsx with parameters on the About sheet", [], covers=["console.reports.export.xlsx_button"]),
                  case("console.reports.export.csv", "CSV exports one table, UTF-8 with BOM", "happy", ["Export CSV of a table"], "One table as CSV", [],
                       covers=["console.reports.export.csv_button"]),
                  case("console.reports.export.pdf", "PDF export renders the whole report", "happy", ["Export PDF"], "A PDF of every table", [],
                       covers=["console.reports.export.pdf_button"]),
              ]}
    for r in reports:
        rid = slug(r.id)
        fid = f"console.reports.{rid}"
        feat = {"id": fid, "area": "Operator console", "screen": f"Report: {r.title} ({r.category})", "route": f"control-panel /reports/{r.id}/",
                "source_files": [f"{APP}/reports/catalog.py", f"{APP}/views_reports.py"], "report": {"id": r.id, "category": r.category,
                                                                                                  "source": f"/v1/admin/{r.admin_path}"},
                "controls": [], "cases": []}
        pcs = []
        for p in r.params:
            ptype = "menu" if p.kind == "choice" else "field"
            c = ctrl(f"{fid}.param_{slug(p.name, 30)}", ptype, f"{p.label} parameter", f"{p.kind} parameter '{p.name}'" + (" (required)" if p.required else ""))
            feat["controls"].append(c)
            pcs.append(c["id"])
        groupable = []
        for ds in r.datasets:
            if tuple(ds.groupable) or tuple(ds.group_by):
                groupable.append(ds.key)
        if groupable:
            feat["controls"].append(ctrl(f"{fid}.group_by", "menu", "Group by (" + ", ".join(groupable) + ")", "regroups the table(s)"))
        for ext, label in (("xlsx", "Excel"), ("csv", "CSV (per table)"), ("pdf", "PDF")):
            feat["controls"].append(ctrl(f"{fid}.export_{ext}", "button", f"Export {label}", f"/reports/{r.id}/?export={ext}"))
        n_ds = len(r.datasets)
        feat["cases"].append(case(f"{fid}.renders", f"'{r.title}' report reads {r.admin_path} and renders " + (f"its {n_ds} table(s)" if n_ds else "Go's tables"), "happy",
                                  ["Log in as an operator whose role may read it", f"Open /reports/{r.id}/"],
                                  "Each table/section renders from Go's rows; a failing source is reported without breaking the page", [],
                                  seed=["operator account", "seeded BFF data"], covers=[f"{fid}.group_by"] if groupable else None))
        if pcs:
            feat["cases"].append(case(f"{fid}.filters", f"'{r.title}' parameters are validated and reach Go", "happy",
                                      [f"Open /reports/{r.id}/ with each parameter set"], "Go is called with exactly the chosen parameters; invalid values fall back to defaults", [],
                                      covers=pcs))
        for ext, label in (("xlsx", "Excel"), ("csv", "CSV"), ("pdf", "PDF")):
            feat["cases"].append(case(f"{fid}.export_{ext}", f"'{r.title}' exports to {label}", "happy", [f"Open /reports/{r.id}/?export={ext}"],
                                      f"A {label} file with the same rows and parameters as the page", [], covers=[f"{fid}.export_{ext}"]))
        if any(p.kind == "member" for p in r.params):
            feat["cases"].append(case(f"{fid}.requires_member", f"'{r.title}' asks for a member before reading Go", "negative", [f"Open /reports/{r.id}/ without a member"],
                                      "A prompt for a member; no Go calls", [], covers=pcs))
            feat["cases"].append(case(f"{fid}.unknown_member", f"'{r.title}' explains an unknown @username", "negative", [f"Open /reports/{r.id}/?member=@nobody"],
                                      "A clear 'no such member' message", [], covers=pcs))
        out.append(feat)
    return server, out


def live_features(root):
    topics, doc = live_topics(root)
    feat = {"id": "console.live", "area": "Operator console", "screen": "Live socket (/ws/live/)", "route": "control-panel ws /ws/live/",
            "source_files": [f"{APP}/consumers.py", f"{APP}/live.py", "control-panel/control_panel_project/asgi.py"],
            "controls": [ctrl(f"console.live.{t}", "link", f"Live topic '{t}'", doc.get(t, t)) for t in topics], "cases": [
                case("console.live.socket.requires_session", "Signed-out visitors cannot open the live socket", "negative", ["Open /ws/live/ without a session"], "Refused", []),
                case("console.live.socket.same_origin_only", "A page on another origin cannot open the socket", "negative", ["Open /ws/live/ with a foreign Origin"], "Refused", []),
                case("console.live.socket.pauses_when_hidden", "A hidden tab makes no BFF reads", "edge", ["Pause the socket"], "No reads while paused", []),
                case("console.live.socket.closed_on_sign_out", "Signing out ends the live socket in every tab of the session", "happy", ["Sign out in one tab"], "Every socket gets signed_out", []),
                case("console.live.socket.go_session_ended", "Go refusing the token refresh ends the socket", "negative", ["Expire the Go session"], "signed_out pushed", []),
                case("console.live.socket.saves_rotated_tokens", "Tokens Go rotates during a live read are saved to the session", "edge", ["Rotate tokens"], "Session holds the new tokens", []),
            ]}
    curated = {"nav": [("counts", "The sidebar topic counts open queue items and the BFF state", "happy"),
                       ("role_scoped", "The nav topic reads only the queues the operator's role may see", "negative")],
               "dashboard": [("pushes_region", "The command center's live region is pushed as rendered HTML", "happy")],
               "activity": [("tail", "The activity live tail pushes only actions newer than the page, with its filters", "happy")]}
    for t in topics:
        for suffix, title, ctype in curated.get(t, [("pushes", f"The '{t}' topic is pushed when its payload changes", "happy")]):
            feat["cases"].append(case(f"console.live.{t}.{suffix}", title, ctype, [f"Subscribe to '{t}'"], doc.get(t, t), [], covers=[f"console.live.{t}"]))
    return [feat]


def shared_features():
    lists = {"id": "console.lists", "area": "Operator console", "screen": "Server-side lists (shared paging, search, filters, Excel export)",
             "route": "every list page (listing.ListSpec)", "source_files": [f"{APP}/listing.py", f"{TPL}/control_panel/partials/_list_toolbar.html",
                                                                            f"{TPL}/control_panel/partials/_list_controls.html", f"{TPL}/control_panel/partials/_pagination.html"],
             "controls": [ctrl("console.lists.toolbar", "field", "List toolbar: search, filters, sort, page size", "shared list controls"),
                          ctrl("console.lists.pager", "link", "Pagination links", "page links keep every parameter"),
                          ctrl("console.lists.export", "button", "Export Excel", "?export=xlsx")],
             "cases": [
                 case("console.lists.paging.server_side", "Paging is server side: page and page size reach Go as limit and offset", "happy", ["Open page 2 with page_size 10"], "Go called with limit/offset", [], covers=["console.lists.pager"]),
                 case("console.lists.paging.clamps", "A page past the end lands on the last page", "edge", ["Filter down while on page 9"], "Last page shown", [], covers=["console.lists.pager"]),
                 case("console.lists.params.allow_list", "Filters, sizes and pages outside the allow-list never reach Go", "negative", ["Send unknown values"], "Dropped", [], covers=["console.lists.toolbar"]),
                 case("console.lists.search.escaped", "A search with & or quotes keeps its meaning in every link", "edge", ["Search 'a&b \"c\"'"], "Links keep the text", [], covers=["console.lists.toolbar"]),
                 case("console.lists.export.xlsx", "Export Excel holds every filtered row, not just one page", "happy", ["Export a filtered list"], "All matching rows", [], covers=["console.lists.export"]),
                 case("console.lists.export.no_formulas", "Member text starting with = is written as text (no Excel injection)", "negative", ["Export a row with '=cmd'"], "Text cell", [], covers=["console.lists.export"]),
                 case("console.lists.export.failure", "Go failing the first export read gives a 502 with the reason", "negative", ["Make Go fail", "Export"], "502 with reason", [], covers=["console.lists.export"]),
                 case("console.lists.contract.billing", "Billing lists pass q and the date range to Go; Excel uses the same filters", "happy", ["Filter a billing list", "Export"], "Same filters in Go calls and export", []),
             ]}
    layout = {"id": "console.layout", "area": "Operator console", "screen": "Console shell (sidebar, phone menu, dialogs, styles)",
              "route": "every console page (base.html)", "source_files": [f"{TPL}/control_panel/base.html", "control-panel/static"],
              "controls": [ctrl("console.layout.sidebar_toggle", "button", "Fold sidebar into an icon rail (desktop)", "toggles the icon rail"),
                           ctrl("console.layout.menu_toggle", "button", "Phone menu", "opens/closes the sidebar on phones"),
                           ctrl("console.layout.confirm", "button", "Confirm dialog for destructive actions", "Bootstrap dialog instead of window.confirm"),
                           ctrl("console.layout.report_dialog", "button", "Report action modal", "centred opaque Bootstrap modal")],
              "cases": [
                  case("console.layout.sidebar_rail", "The desktop menu folds the sidebar into an icon rail, never hiding it", "layout", ["Toggle the sidebar on desktop"], "Icon rail stays visible", [], covers=["console.layout.sidebar_toggle"]),
                  case("console.layout.mobile_menu", "The phone menu opens and closes", "layout", ["Open the console at phone width", "Toggle the menu"], "Menu opens and closes", [], covers=["console.layout.menu_toggle"]),
                  case("console.layout.confirm_dialog", "Destructive actions confirm in the Bootstrap dialog, not window.confirm", "happy", ["Click a destructive action"], "Dialog shown; cancel keeps the record", [], covers=["console.layout.confirm"]),
                  case("console.layout.report_modal", "Report actions open in a centred, opaque modal", "layout", ["Open a report action"], "Modal centred and opaque", [], covers=["console.layout.report_dialog"]),
                  *[case(f"console.layout.{label}", f"Every console page fits and aligns at {label} width ({w}px)", "layout", [f"Open every sidebar page at {w}px"],
                         "No horizontal overflow; form labels and controls aligned", []) for label, w in (("phone", 390), ("tablet", 768), ("desktop", 1440))],
                  case("console.layout.no_inline_styles", "Templates carry no inline styles (CSP)", "edge", ["Scan templates"], "No style= attributes", []),
              ]}
    return [lists, layout]
