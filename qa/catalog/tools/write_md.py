import json, os, re, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paths import ROOT, CATALOG, INVENTORY_MD
D = json.load(open(CATALOG))
F = D["features"]
S = D["stats"]

AREA_W = {"Payments & Membership": 5, "Auth & Onboarding": 5, "Safety": 5, "Chat (dating)": 4, "Discover": 4, "Matches": 4,
          "Profile": 3, "Verification": 3, "Friends & Introducer": 3, "Groups": 3, "Date Plans": 3, "Social Chat (friends/rooms/groups)": 3,
          "Navigation & Settings": 3, "Today / Intentional Dating": 3, "Help & Support": 3}


def esc(s):
    return (s or "").replace("|", "\\|").replace("\n", " ")


def tref(t):
    return f"{t['suite']}: `{os.path.basename(t['file'])}` › {esc(t['test'])[:70]}"


def action_case(f, c):
    for k in f["cases"]:
        if k["id"] == c["id"] + ".action":
            return k
    return None


rows = []
for f in F:
    for c in f["controls"]:
        ac = action_case(f, c)
        rows.append((f, c, ac))


def score(f, c, ac):
    if not ac or ac["status"] == "automated":
        return -1
    s = AREA_W.get(f["area"], 2)
    api = c.get("api") or ""
    if re.search(r"\b(POST|PUT|PATCH|DELETE)\b", api):
        s += 3
    elif api:
        s += 1
    if c.get("navigates_to"):
        s += 1
    if ac["status"] == "presence_only":
        s += 3
    else:
        s += 2
    risks = " ".join(c.get("risks", []))
    if "NO-OP" in risks:
        s += 5
    if "pops a result" in risks:
        s += 1
    if c.get("history"):
        s += 4
    if c["type"] == "sheet":
        s -= 2
    if (c.get("label") or "").lower() in ("retry", "close", "cancel", "not now", "back"):
        s -= 2
    if "Operator console" == f["area"]:
        s -= 1
    return s


gaps = sorted([(score(f, c, ac), f, c, ac) for f, c, ac in rows if score(f, c, ac) >= 0], key=lambda x: -x[0])

L = []
w = L.append
w("# Connect — Feature, Control & Test Inventory (2026-10-02)")
w("")
w("Machine-readable twin: [`qa/catalog/feature_catalog.json`](../../qa/catalog/feature_catalog.json) (same ids; drives the QA runner).")
w("")
w("**How this was built.** Every Dart file under `app/lib` was scanned for interactive widgets (buttons, `InkWell`/`GestureDetector`, switches, chips, sliders, fields, menus, `Dismissible`, `RefreshIndicator`, `PageView`, `showModalBottomSheet`/`showDialog`, long-press/drag handlers) including private wrapper widgets and helper methods that forward a callback, with each callback followed through local methods → Riverpod notifiers → Dio calls and matched against the Go BFF route table (`backend/internal/bff/mobile/server.go`). Tests were scanned in all suites (Flutter `app/test`, Playwright `website/tests`, Appium `qa/appium/tests`, API e2e `qa/api_e2e/tests`, Go `backend/**/_test.go`, Django `control-panel/control_panel/tests`, console smoke) for the controls they **act on** and whether an **outcome is asserted after the action**. Website pages and operator-console routes are inventoried at page/route level.")
w("")
w("**Snapshot.** Working tree on 2026-10-02, which includes the lead's *uncommitted* fix for the profile Message/Love and Spotlight buttons (`profile_actions.dart`, `app/test/features/swipe/profile_actions_test.dart`). Where HEAD (`b96977f9d`) differs it is called out.")
w("")
w("**Status legend.** `automated` = a test performs the action and asserts its effect · `manual` = cannot be automated locally; a person checks it in QA Lab · `presence-only` = tests find the control (or tap it) but never assert what it does — the pattern that hid the profile-dock bug · `partial` = covered indirectly · **GAP** = nothing. *API* is inferred statically; rows marked *unclassified* need a human look.")
w("")
w("## 1. Coverage summary")
w("")
cs = S["case_status"]
cas = S["control_action_status"]
tot_a = sum(cas.values())
w("| Metric | Value |")
w("|---|---|")
w(f"| Features (screens, sheets, shared widgets, web pages, console areas) | {S['features']} |")
w(f"| Screens in the Flutter screen matrix | {S['screens_in_matrix']} |")
w(f"| Interactive controls (all surfaces) | {S['controls']} |")
app_ctrl = sum(len(f['controls']) for f in F if not f['id'].startswith(('site.', 'console.')))
w(f"| … in the Flutter app | {app_ctrl} |")
w(f"| … website (public pages) | {sum(len(f['controls']) for f in F if f['id'].startswith('site.'))} |")
w(f"| … operator console routes | {sum(len(f['controls']) for f in F if f['id'].startswith('console.'))} |")
w(f"| Test cases | {S['cases']} |")
w(f"| Cases automated / partial / presence-only / manual / not automated | {cs.get('automated',0)} / {cs.get('partial',0)} / {cs.get('presence_only',0)} / {cs.get('manual',0)} / {cs.get('not_automated',0)} |")
mb = S.get("mapped_by", {})
w(f"| Automated cases proven by a `[case:…]` tag / by heuristic match | {mb.get('tag',0)} / {sum(1 for f in F for c in f['cases'] if c['status']=='automated' and c.get('mapped_by')=='heuristic')} |")
ti = S.get("tag_issues", {})
if ti.get("unknown_case_ids"):
    w(f"| Tags naming unknown case ids (fix the test or the catalog) | {len(ti['unknown_case_ids'])} |")
w(f"| Cases automated (%) | {100*cs.get('automated',0)/S['cases']:.1f}% (incl. partial {100*(cs.get('automated',0)+cs.get('partial',0))/S['cases']:.1f}%) |")
w(f"| App controls whose **action** is asserted by a UI test | {cas.get('automated',0)} of {tot_a} ({100*cas.get('automated',0)/tot_a:.1f}%) |")
w(f"| App controls tested for presence only | {cas.get('presence_only',0)} ({100*cas.get('presence_only',0)/tot_a:.1f}%) |")
w(f"| App controls with no UI test at all | {cas.get('not_automated',0)} ({100*cas.get('not_automated',0)/tot_a:.1f}%) |")
w("")
w("**Controls by type**")
w("")
tc = collections.Counter(c["type"] for f in F for c in f["controls"])
w("| " + " | ".join(tc.keys()) + " |")
w("|" + "---|" * len(tc))
w("| " + " | ".join(str(v) for v in tc.values()) + " |")
w("")
w("**Cases by type and status**")
w("")
tt = collections.defaultdict(collections.Counter)
for f in F:
    for c in f["cases"]:
        tt[c["type"]][c["status"]] += 1
w("| Type | automated | partial | presence-only | manual | not automated |")
w("|---|---|---|---|---|---|")
for k, v in sorted(tt.items()):
    w(f"| {k} | {v.get('automated',0)} | {v.get('partial',0)} | {v.get('presence_only',0)} | {v.get('manual',0)} | {v.get('not_automated',0)} |")
w("")
w("**Cases automated, by suite** (a case can be covered by several suites) and tests scanned")
w("")
w("| Suite | Cases covered | Tests scanned |")
w("|---|---|---|")
ts = S["tests_scanned"]
for k, v in sorted(S["cases_by_suite"].items(), key=lambda x: -x[1]):
    w(f"| {k} | {v} | {ts.get(k, ts.get('django') if 'django' in k else '—')} |")
w("")
w("**By area (app + web + console)**")
w("")
w("| Area | Features | Controls | Action asserted | Presence-only | GAP |")
w("|---|---|---|---|---|---|")
ar = collections.OrderedDict()
for f, c, ac in rows:
    a = ar.setdefault(f["area"], {"f": set(), "c": 0, "ok": 0, "po": 0, "gap": 0})
    a["f"].add(f["id"])
    a["c"] += 1
    st = ac["status"] if ac else None
    if st == "automated":
        a["ok"] += 1
    elif st == "presence_only":
        a["po"] += 1
    elif st == "not_automated":
        a["gap"] += 1
for f in F:
    ar.setdefault(f["area"], {"f": set(), "c": 0, "ok": 0, "po": 0, "gap": 0})["f"].add(f["id"])
for k, v in sorted(ar.items(), key=lambda x: -x[1]["c"]):
    w(f"| {k} | {len(v['f'])} | {v['c']} | {v['ok']} | {v['po']} | {v['gap']} |")
w("")
w("_Operator-console and website controls carry their own cases (`.performs`, `.renders`, `.authz`, page cases) instead of `.action`; their coverage is in the case totals above._")
w("")

# ---------------------------------------------------------------- gaps
w("## 2. Biggest gaps, prioritised")
w("")
w("Score = area risk (money/auth/safety highest) + mutating API + navigation + (presence-only tests ⇒ false confidence) + risk flags (no-op, result popped to opener, known regression). The top of this list is where a bug like the profile dock can ship unnoticed.")
w("")
w("### 2.1 Top 40 controls whose action is never asserted")
w("")
w("| # | Area | Screen | Control | qa key | What it should do | Tests today |")
w("|---|---|---|---|---|---|---|")
for i, (sc, f, c, ac) in enumerate(gaps[:40], 1):
    tests = ac.get("presence_only_tests", []) + ac.get("acts_without_outcome_assert", [])
    tdesc = "presence-only: " + "; ".join(tref(t) for t in tests[:2]) if tests else "**none**"
    w(f"| {i} | {esc(f['area'])} | {esc(f['screen'])} | {esc(c['label'])[:45]} | `{c.get('qa_key') or '—'}` | {esc(c['action'])[:120]} | {tdesc} |")
w("")
w("### 2.2 Structural findings")
w("")
noop = [(f, c) for f in F for c in f["controls"] if any("NO-OP" in r for r in c.get("risks", []))]
w(f"* **No-op controls ({len(noop)})** — callbacks with an empty body; they look tappable and do nothing:")
for f, c in noop:
    w(f"  * {esc(f['screen'])} › **{esc(c['label'])}** (`{c['source']}`)")
pops = [f for f in F if any(k["id"].endswith("openers_handle_result") for k in f["cases"])]
for f in pops:
    k = next(k for k in f["cases"] if k["id"].endswith("openers_handle_result"))
    if "do not read" not in k.get("notes", ""):
        continue
    w(f"* **Result popped to opener — {esc(f['screen'])}**: {esc(k.get('notes',''))}. Same shape as the shipped profile-dock bug (heuristic — confirm each: the result may be optional or the control hidden).")
keyowners = collections.defaultdict(set)
for f in F:
    for c in f["controls"]:
        if c.get("qa_key"):
            keyowners[c["qa_key"]].add(f["screen"])
shared = {k: v for k, v in keyowners.items() if len(v) > 1}
w(f"* **qa keys shared by different screens ({len(shared)})** — an Appium/Playwright step that finds the key cannot tell which screen it is on, so a pass on Discover can mask a broken Spotlight. Examples: " +
  "; ".join(f"`{k}` ({', '.join(sorted(v))})" for k, v in list(shared.items())[:8]))
app_rows = [(f, c) for f in F if not f["id"].startswith(("site.", "console.")) for c in f["controls"]]
nokey = [1 for f, c in app_rows if not c.get("qa_key") and c["type"] != "sheet"]
w(f"* **Automation readiness** — {len(nokey)} of {len([1 for f, c in app_rows if c['type'] != 'sheet'])} app controls have **no `qa.*` key/semantics id**; device suites must fall back to visible text, which changes per locale (10 locales) and look.")
unres = [1 for f, c in app_rows if c["action"].startswith("local/unclassified")]
w(f"* **Unclassified actions** — {len(unres)} controls whose effect could not be resolved statically (focus moves, local filters, callbacks into generic helpers). Each is listed per screen below; the runner should at least assert a visible state change.")
api_only = [(f, c) for f, c, ac in rows if ac and ac["status"] != "automated" and c.get("api") and any(k["id"] == c["id"] + ".api_contract" and k["status"] == "automated" for k in f["cases"])]
w(f"* **API tested, UI wiring not** — {len(api_only)} controls call an endpoint that has Go/api_e2e coverage, but no UI test proves the control actually calls it. This is the Spotlight failure mode (endpoint fine, button never called it).")
fail_cases = [k for f in F for k in f["cases"] if k["id"].endswith(".api_failure")]
w(f"* **Error paths** — {sum(1 for k in fail_cases if k['status']=='automated')} of {len(fail_cases)} API-backed controls have a UI test for the failure path (500/timeout → readable error, state rolled back, no double submit).")
w("* **Gestures** — the Discover deck has **no drag-to-swipe gesture**: Like/Pass/Super like/Undo are buttons (`SwipeButtons`). Real swipe/drag gestures are: Today wall `PageView`, profile photo reels (`PageView`), setup preview pager, notification inbox swipe-to-dismiss (`Dismissible`), reward burst dismiss, photo reorder drag (setup photos), long-press on chat/social-chat bubbles, and ~29 pull-to-refresh lists. Only a handful of `tester.drag/fling` calls exist in the Flutter suite.")
w("* **Locale rendering** — the hard-coded-strings guard is a static ratchet; no test renders app screens in each of the 10 locales (only the website does).")
w("")

# ---------------------------------------------------------------- per area
w("## 3. Inventory by area")
w("")
w("Each table lists every control: type, `qa` key, what it does (API + visible result), the tests that **perform it and assert the outcome**, and status. Non-action cases (API contract, failure path, validation, layout, a11y, l10n, back affordance) are in the JSON under each feature's `cases`.")
w("")
areas = collections.OrderedDict()
order = ["Auth & Onboarding", "Discover", "Today / Intentional Dating", "Today Wall", "Matches", "Chat (dating)", "Profile", "Verification", "Payments & Membership",
         "Friends & Introducer", "Social Chat (friends/rooms/groups)", "Groups", "Engagement Hub", "Date Plans", "Graduation", "First Chapter Studio", "Calls",
         "Blog / Chapters", "Photo Themes", "Clubs & Lists", "City Pilot", "Notifications", "Celebrations & Rewards", "Safety", "Help & Support",
         "Navigation & Settings", "Web Workspace", "Admin (in-app)", "Shared components", "End-to-end journeys", "Website (public)", "Operator console"]
for f in F:
    areas.setdefault(f["area"], []).append(f)
keys = [a for a in order if a in areas] + [a for a in areas if a not in order]
for a in keys:
    fs = areas[a]
    w(f"### {a}")
    w("")
    for f in fs:
        w(f"#### {esc(f['screen'])} — `{f['id']}`")
        w("")
        w(f"Route: {esc(f.get('route'))} · Source: {', '.join('`'+s+'`' for s in f.get('source_files', [])[:3])}" + (" · in screen matrix" if f.get("in_screen_matrix") else ""))
        if f.get("notes"):
            w(f"\n_{esc(f['notes'])}_")
        w("")
        if f["controls"]:
            w("| Control | Type | qa key | What it does | Automated by (acts + asserts) | Status |")
            w("|---|---|---|---|---|---|")
            for c in f["controls"]:
                ac = action_case(f, c)
                if ac:
                    st = {"automated": "automated", "presence_only": "presence-only", "not_automated": "**GAP**", "partial": "partial", "manual": "manual"}.get(ac["status"], ac["status"])
                    tests = ac["automated_by"]
                    tdesc = "<br>".join(tref(t) for t in tests[:2]) + (f"<br>+{len(tests)-2} more" if len(tests) > 2 else "")
                    if not tests and ac.get("presence_only_tests"):
                        tdesc = "only checks presence: " + tref(ac["presence_only_tests"][0])
                else:
                    rel = [k for k in f["cases"] if k["id"].startswith(c["id"] + ".") or c["id"] in k.get("covers_controls", [])]
                    if not rel and f["id"].startswith("site."):
                        rel = [k for F2 in F if F2["id"].startswith("site.") for k in F2["cases"] if c["id"] in k.get("covers_controls", [])]
                    oks = [t for k in rel for t in k["automated_by"]]
                    st = "automated" if rel and all(k["status"] == "automated" for k in rel) else ("partial" if oks else "**GAP**")
                    tdesc = "<br>".join(tref(t) for t in oks[:2]) + (f"<br>+{len(oks)-2} more" if len(oks) > 2 else "")
                flags = ""
                if c.get("risks"):
                    flags = " ⚠ " + "; ".join(r for r in c["risks"] if not r.startswith("action not statically"))
                if c.get("history"):
                    flags += " ⚠ see history in JSON (profile/Spotlight dock regression)"
                w(f"| {esc(c['label'])[:60]} | {c['type']} | {('`'+c['qa_key']+'`') if c.get('qa_key') else '—'} | {esc(c['action'])[:160]}{esc(flags)} | {tdesc or '—'} | {st} |")
            w("")
        extra = [k for k in f["cases"] if not any(k["id"].startswith(c["id"] + ".") for c in f["controls"])]
        if extra and (not f["controls"] or f["id"].startswith(("discover.", "journeys.", "site."))):
            w("| Case | Type | Automated by | Status |")
            w("|---|---|---|---|")
            for k in extra:
                tests = k["automated_by"]
                w(f"| {esc(k['title'])[:110]} | {k['type']} | {'<br>'.join(tref(t) for t in tests[:2]) or '—'}{'<br>+'+str(len(tests)-2)+' more' if len(tests)>2 else ''} | {k['status'] if k['status']!='not_automated' else '**GAP**'} |")
            w("")
w("## 4. Using the catalog in the QA runner")
w("")
w("* Iterate `features[].cases[]`; `steps`/`expected` are written to be executed against seeded data (`seed_needs`). Prefer `qa_key` locators; fall back to `label` (English) or `alt_labels`.")
w("* Treat `status: presence_only` as **failing coverage**: the runner must perform the action and assert `expected` (network call + visible result), not just locate the control.")
w("* `*.api_contract` cases are API-level and already backed by Go/api_e2e tests where listed; `*.api_failure` cases need a fault-injecting proxy or stubbed BFF.")
w("* Regenerate after UI or test changes: `python3 qa/catalog/tools/regenerate.py` (deterministic; rewrites `feature_catalog.json` and this file). New controls appear with status GAP.")
w("* Test → case contract (QA Lab): Flutter/Playwright put `[case:<id>]` in the test name; pytest uses `@pytest.mark.case(\"<id>\")`; Go puts `// case: <id>` directly above `func TestX`; Django puts `[case:<id>]` in the test method docstring (or `# case: <id>` above `def test_x`); interpolated ids (`[case:a.$name.action]`) count only for values that are string literals of the same file; `qa/catalog/extra_cases.json` declares, with a reason, controls/cases the static extraction cannot see. Tagged cases become `automated` (`mapped_by: tag`); cases listed in `qa/catalog/manual_cases.json` become `manual`. Run them from QA Lab (`documents/qa/QA_LAB_2026-10-02.md`).")
w("")
w("## 5. Method limits")
w("")
w("* Static inference: API calls reached only through dynamic dispatch or generic helpers may be missing (rows marked *unclassified*), and a callback that can take several branches lists all endpoints it can reach.")
w("* Test matching is by `qa` key, then English label within the screens a test pumps; Appium/Playwright label matches are accepted only when the label is near-unique. Parameterised tests (`$key`) are credited to every key they iterate.")
w("* Operator console is inventoried per URL route (each POST route = one control); template-level buttons are not enumerated individually.")
open(INVENTORY_MD, "w").write("\n".join(L) + "\n")
print(len(L), "lines")
print("TOP25")
for i, (sc, f, c, ac) in enumerate(gaps[:25], 1):
    print(i, sc, f["area"], "|", f["screen"], "|", c["label"][:40], "|", c.get("qa_key"), "|", (c.get("api") or "")[:60], "|", ac["status"])
