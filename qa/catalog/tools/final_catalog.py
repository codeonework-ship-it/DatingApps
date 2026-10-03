import json, os, re, collections, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paths import build_path, CATALOG, MANUAL, EXTRA
from dartscan import ROOT, LIB
import extract_app as EA

HERE = os.path.dirname(__file__)
APP = json.load(open(build_path("app_features.json")))
OTHER = json.load(open(build_path("other_features.json")))
TESTS = json.load(open(build_path("tests.json")))
harness = open(os.path.join(ROOT, "app/test/features/responsive/screen_matrix_harness.dart")).read()
MATRIX = re.findall(r"^\s*'(\w+)':", harness[harness.find("buildScreenMatrix"):], re.M)
ROOTS = {"WelcomeScreen", "WebEntryScreen", "AuthScreen", "MainNavigationScreen", "HomeDiscoveryScreen", "MatchesListScreen",
         "EngagementHubScreen", "ProfileViewScreen", "SettingsScreen", "ProfileSetupEntryScreen"}
EXEMPT = {"UserAgreementScreen", "CheckoutWebViewScreen"}
from build_catalog_area import AREA

feat_by_screen = collections.defaultdict(list)
for f in APP:
    feat_by_screen[f["screen"]].append(f)

# ---- matrix screens without controls
for scr in MATRIX:
    if scr in feat_by_screen:
        continue
    fpath = EA.CLASS_FILE.get(scr)
    rel = os.path.relpath(fpath, ROOT) if fpath else None
    area_dir = rel.split("/")[3] if rel and "/features/" in rel else "core"
    fid = f"{area_dir}.{re.sub(r'(?<!^)(?=[A-Z])', '_', scr).lower().replace('_screen', '')}"
    feat = {"id": fid, "area": AREA.get(area_dir, area_dir), "screen": scr, "route": "see screen matrix", "source_files": [rel] if rel else [],
            "in_screen_matrix": True, "controls": [], "cases": [],
            "notes": "No interactive control detected in this file by static extraction (display-only, or controls live in shared child widgets listed under their own feature)."}
    APP.append(feat)
    feat_by_screen[scr].append(feat)
    feat["cases"].append({"id": f"{fid}.layout_matrix", "title": f"{scr} lays out on every device size/theme", "type": "layout", "steps": ["Pump at phone/tablet/desktop in every look"],
                          "expected": "No overflow", "automated_by": [{"suite": "flutter", "file": "app/test/features/responsive/screen_matrix_test.dart", "test": "$screenLabel lays out on $deviceLabel [$themeLabel]"}], "status": "automated"})
    feat["cases"].append({"id": f"{fid}.a11y_guidelines", "title": f"{scr} meets accessibility guidelines", "type": "a11y", "steps": ["Pump with semantics"],
                          "expected": "No guideline failures beyond allowlist", "automated_by": [{"suite": "flutter", "file": "app/test/features/responsive/screen_accessibility_test.dart", "test": "$label meets accessibility guidelines [$themeLabel]"}], "status": "automated"})

# ---- back affordance cases
for scr in MATRIX:
    if scr in ROOTS or scr in EXEMPT:
        continue
    for feat in feat_by_screen.get(scr, [])[:1]:
        feat["cases"].append({"id": f"{feat['id']}.back_affordance", "title": f"{scr} shows a visible way back when pushed", "type": "a11y",
                              "steps": [f"Push {scr} on a route stack", "Look for Back/Close control and use it"], "expected": "A visible back/close control pops to the opener",
                              "automated_by": [{"suite": "flutter", "file": "app/test/features/responsive/back_affordance_audit_test.dart", "test": "${entry.key} shows a way back when pushed"}],
                              "status": "automated", "notes": "audit checks the control exists; popping is asserted only for some screens"})

# ---- known-gap annotations (the model GAP)
PD_NOTE = ("GAP MODEL: at HEAD b96977f9d the dock popped ProfileDetailsAction.love/.message and the opener had to act; openers from Spotlight, Today, "
           "Liked-you, Liked and Passed lists ignored it, so the buttons did nothing. Tests at HEAD only asserted the dock exists "
           "(profile_details_cinematic_test 'dock' keys; appium test_05_profile_details/test_26_cinematic_profile wait_for_qa). "
           "Working tree (uncommitted, lead fixing) acts in place via ProfileActions and adds app/test/features/swipe/profile_actions_test.dart.")
SP_NOTE = ("GAP MODEL: at HEAD the full Spotlight screen's Like/Pass/Message callbacks only advanced the local index / showed UI and never called POST /v1/swipe. "
           "Working tree routes them through _decide()/ProfileActions and adds 'Spotlight screen buttons reach the server' tests; Spotlight Message and Undo remain unasserted.")
for f in APP:
    for c in f["controls"]:
        k = c.get("qa_key") or ""
        if f["id"] == "swipe.profile_details" and k in ("qa.profile_detail.love_button", "qa.profile_detail.message_button"):
            c["history"] = PD_NOTE
        if f["id"] == "swipe.spotlight_profiles" and any(x in k for x in ("like_button", "pass_button", "message_button", "superlike_button")):
            c["history"] = SP_NOTE

# ---- curated cross-screen features
def find_tests(suites, rx, limit=8):
    out = []
    r = re.compile(rx, re.I)
    for s in suites:
        for t in TESTS[s]:
            if r.search(t["test"]):
                out.append({"suite": s, "file": t["file"], "test": t["test"]})
    return out[:limit]


def C(cid, title, ctype, steps, expected, auto, seed, status=None, notes=None):
    d = {"id": cid, "title": title, "type": ctype, "steps": steps, "expected": expected, "seed_needs": seed, "automated_by": auto,
         "status": status or ("automated" if auto else "not_automated")}
    if notes:
        d["notes"] = notes
    return d


pa = [t for t in TESTS["flutter"] if t["file"].endswith("profile_actions_test.dart")]
pa_any = [{"suite": "flutter", "file": t["file"], "test": t["test"]} for t in pa if "any entry point" in t["test"]]
pa_spot = [{"suite": "flutter", "file": t["file"], "test": t["test"]} for t in pa if "Spotlight" in t["test"]]
entry = {"id": "discover.profile_entry_points", "area": "Discover", "screen": "ProfileDetailsScreen (opened from every entry point)",
         "route": "Discover card View more / Spotlight rail / Spotlight screen / Today rail / Liked you / Liked / Passed / Matches",
         "source_files": ["app/lib/features/swipe/screens/profile_details_screen.dart", "app/lib/features/swipe/profile_actions.dart",
                          "app/lib/features/swipe/screens/home_discovery_screen.dart", "app/lib/features/swipe/screens/spotlight_profiles_screen.dart",
                          "app/lib/features/swipe/screens/liked_me_screen.dart", "app/lib/features/swipe/screens/liked_profiles_screen.dart",
                          "app/lib/features/swipe/screens/passed_profiles_screen.dart"],
         "controls": [], "cases": []}
openers = [("discover_view_more", "Discover deck card 'View more'"), ("spotlight_rail", "Discover Spotlight rail avatar"), ("spotlight_screen", "Full Spotlight screen 'View more'"),
           ("today_rail", "Today rail card"), ("liked_you", "Liked you list (own Love rule = like back)"), ("liked_list", "Liked profiles list"), ("passed_list", "Passed profiles list"),
           ("web_likes", "Web #/likes")]
for oid, oname in openers:
    for act, exp in (("love", "POST /v1/swipe is_like=true for THIS member exactly once (double-tap safe); on mutual match the match screen opens; otherwise snackbar and the profile closes; opener list refreshes"),
                     ("message", "existing match → ChatScreen opens with no new like; no match → like is sent, explainer shown, profile stays; daily-limit → 'See plans' sheet")):
        entry["cases"].append(C(f"discover.profile_entry_points.{oid}.{act}", f"{act.capitalize()} works when the profile is opened from {oname}", "happy",
                                [f"Open {oname}", "Open a member's profile", f"Tap {act.capitalize()} (qa.profile_detail.{act}_button)", "Inspect network log and screen"],
                                exp, pa_any if oid in ("discover_view_more",) else [], ["member with deck, spotlight, Today set, >=1 liker, >=1 liked and >=1 passed profile", "one candidate already matched (for Message)"],
                                status="partial" if (pa_any and oid == "discover_view_more") else "not_automated",
                                notes="profile_actions_test pumps ProfileDetailsScreen behind a generic launcher ('any entry point'); no test opens it from each real opener. This was the shipped bug."))
entry["cases"].append(C("discover.profile_entry_points.spotlight_screen.buttons_reach_server", "Full Spotlight screen Like/Pass/Super like call POST /v1/swipe", "happy",
                        ["Open Spotlight screen", "Tap Like / Pass / Super like"], "One /v1/swipe per tap with the right is_like / super flag; deck advances; match screen on mutual like",
                        pa_spot, ["member with >=3 spotlight profiles"], notes="tests exist only in uncommitted working tree"))
entry["cases"].append(C("discover.profile_entry_points.spotlight_screen.message", "Full Spotlight screen Message opens chat or likes+explains", "happy",
                        ["Open Spotlight screen", "Tap Message on a matched and an unmatched member"], "Same rules as profile Message", [], ["matched + unmatched spotlight members"]))
entry["cases"].append(C("discover.profile_entry_points.liked_you.own_rule", "Liked-you profile Love uses like-back endpoint (override) and returns love", "edge",
                        ["Open Liked you", "Open a liker's profile", "Tap Love"], "Like-back call made, not a plain swipe; liker leaves the list",
                        [{"suite": "flutter", "file": t["file"], "test": t["test"]} for t in pa if "own rule" in t["test"]], ["member with >=1 liker"]))
APP.append(entry)

journ = {"id": "journeys.e2e", "area": "End-to-end journeys", "screen": "Multi-screen journeys", "route": "mobile (Appium) / web (Playwright) / API (api_e2e)",
         "source_files": ["qa/appium/tests", "qa/api_e2e/tests", "website/tests"], "controls": [], "cases": []}
J = [
    ("signup_to_discover", "Sign up → terms → profile setup (photos, about, preferences, preview) → Discover", r"signup|profile_setup|setup_flow|onboarding|photo-upload", ["fresh device", "test photo fixture"]),
    ("signin_existing", "Sign in with existing credentials lands on Discover; wrong password shows error", r"(^|_)(signin|login)(_|$)|signin_credentials|auth_session|browser login", ["existing member"]),
    ("like_to_match_to_chat", "Like → mutual like → match screen → unlock chat → send first message → other member receives", r"match_creation|core_dating|discovery_match_chat|mutual|first message|creates_match|like_back", ["two compatible members"]),
    ("gifts", "Send a gift in chat: free daily gift, coin gift, insufficient coins → wallet top-up", r"gift", ["match with chat", "wallet coins", "gift catalog"]),
    ("payments", "Upgrade plan via checkout (sandbox/Stripe test), auto-renew off, wallet coin purchase", r"billing|payment|checkout|wallet|(^|_)subscription|upgrade|plan_change|coin_package|entitlement", ["sandbox provider", "free member"]),
    ("safety_report_block", "Report and block a member; blocked member disappears everywhere; appeal flow", r"(^|_)(report|block|unblock|appeal|sos)(_|$)|report_submit|blocked_users", ["two members", "moderator queue"]),
    ("friends_social_chat", "Add friend → accept → open friend chat → send message", r"friend", ["two members"]),
    ("rooms_groups", "Join a room / create a group → invite → group chat", r"room|group", ["member with friend"]),
    ("date_plan", "Propose date plan → partner accepts → friend fan-out → debrief after the date", r"date_plan|debrief|propose_plan|plan_state", ["match", "friend"]),
    ("account_lifecycle", "Download data, pause discovery, delete account", r"account_lifecycle|delete|lifecycle|export", ["disposable member"]),
    ("verification", "Upload ID + selfie → pending → approved by operator", r"verif", ["unverified member", "operator"]),
    ("theme_language", "Change look and language in Settings; persists after restart", r"theme|(^|_)language|locale|settings_theme", ["member"]),
    ("back_navigation", "Back from every pushed screen returns to the opener (Android back + on-screen back)", r"(^|_)back(_|$)|back_navigation|Back arrow|goes back", ["member"]),
]
for jid, title, rx, seed in J:
    auto = find_tests(["appium", "playwright", "api_e2e"], rx, 10)
    journ["cases"].append(C(f"journeys.e2e.{jid}", title, "happy", [title], "Journey completes; every step's API returns 2xx; UI shows the result", auto, seed,
                            status="automated" if auto else "not_automated", notes="matched by test name/file keyword; verify depth of assertions per test"))
APP.append(journ)

features = APP + OTHER

# ---- qa/catalog/extra_cases.json: what static extraction cannot see, each with a reason
EXTRA_ISSUES = []
if os.path.exists(EXTRA):
    _x = json.load(open(EXTRA))
    _fby = {f["id"]: f for f in features}
    for nf in _x.get("features", []):
        nf = dict(nf)
        nf.setdefault("controls", [])
        for c in nf.get("cases", []):
            c.setdefault("automated_by", [])
            c.setdefault("status", "not_automated")
            c["declared_in"] = "qa/catalog/extra_cases.json"
        if nf["id"] in _fby:
            _fby[nf["id"]]["cases"] += nf.get("cases", [])
            _fby[nf["id"]]["controls"] += nf.get("controls", [])
        else:
            nf["declared_in"] = "qa/catalog/extra_cases.json"
            features.append(nf)
            _fby[nf["id"]] = nf
    _ctl_owner = {c["id"]: f for f in features for c in f["controls"]}
    for xc in _x.get("controls", []):
        f = _fby.get(xc["feature"])
        if not f:
            EXTRA_ISSUES.append({"id": xc["id"], "reason": f"feature {xc['feature']} not in the catalog"})
            continue
        if xc["id"] in _ctl_owner:
            EXTRA_ISSUES.append({"id": xc["id"], "reason": "control now extracted; remove it from extra_cases.json"})
            continue
        ctl = {k: v for k, v in xc.items() if k != "feature"}
        ctl.setdefault("qa_key", None)
        ctl.setdefault("api", None)
        ctl.setdefault("action", ctl.get("why", ""))
        ctl["declared_in"] = "qa/catalog/extra_cases.json"
        f["controls"].append(ctl)
        _ctl_owner[ctl["id"]] = f
    _case_ids = {c["id"] for f in features for c in f["cases"]}
    for xc in _x.get("cases", []):
        on = xc["on"]
        f = _ctl_owner.get(on) or _fby.get(on)
        if not f:
            EXTRA_ISSUES.append({"id": xc["id"], "reason": f"target {on} not in the catalog"})
            continue
        if xc["id"] in _case_ids:
            EXTRA_ISSUES.append({"id": xc["id"], "reason": "case now generated; remove it from extra_cases.json"})
            continue
        case = {"id": xc["id"], "title": xc["title"], "type": xc["type"], "steps": xc.get("steps") or [xc["title"]],
                "expected": xc.get("expected") or xc["title"], "automated_by": [], "status": "not_automated",
                "why_declared": xc.get("why", ""), "declared_in": "qa/catalog/extra_cases.json"}
        if on in _ctl_owner:
            case["covers_controls"] = [on]
        f["cases"].append(case)
        _case_ids.add(xc["id"])

_seen = set()
for f in features:
    for c in f["cases"]:
        base = c["id"]
        i = 2
        while c["id"] in _seen:
            c["id"] = f"{base}_{i}"
            i += 1
        _seen.add(c["id"])
# ---- QA Lab contract: explicit [case:...] tags win; manual_cases.json next; heuristic last
import case_tags as CT_
TAG_SCAN = CT_.scan_all(ROOT)
TAG_INDEX = CT_.index(TAG_SCAN, known_ids=sorted({c["id"] for f in features for c in f["cases"]}))
MANUAL_CASES = {}
if os.path.exists(MANUAL):
    _m = json.load(open(MANUAL))
    MANUAL_CASES = {k: (v if isinstance(v, str) else (v or {}).get("reason", "")) for k, v in _m.items() if not k.startswith("_")}
_all_ids = {c["id"] for f in features for c in f["cases"]}
tag_issues = {"unknown_case_ids": sorted({cid for cid in TAG_INDEX if cid not in _all_ids}),
              "manual_unknown_case_ids": sorted(k for k in MANUAL_CASES if k not in _all_ids),
              "manual_but_tagged": sorted(k for k in MANUAL_CASES if k in TAG_INDEX),
              "unmatched_patterns": sorted({f"{t['file']}: {p}" for ts in TAG_SCAN.values() for t in ts
                                            for p in (t.get("case_patterns") or [])
                                            if not any(CT_.expand_pattern(p, t.get("pattern_values") or (), _all_ids))}),
              "extra_cases_issues": EXTRA_ISSUES}
for f in features:
    for c in f["cases"]:
        tagged = TAG_INDEX.get(c["id"], [])
        heur = [dict(a, via=a.get("via", "heuristic")) for a in c.get("automated_by", [])]
        if tagged:
            if c.get("status") != "automated":
                c["heuristic_status"] = c.get("status")
            seen = {(t["suite"], t["file"], t["test"]) for t in tagged}
            c["automated_by"] = tagged + [a for a in heur if (a["suite"], a["file"], a["test"]) not in seen]
            c["status"] = "automated"
            c["mapped_by"] = "tag"
        elif c["id"] in MANUAL_CASES:
            if c.get("status") not in (None, "not_automated"):
                c["heuristic_status"] = c.get("status")
            c["automated_by"] = heur
            c["status"] = "manual"
            c["manual_reason"] = MANUAL_CASES[c["id"]]
            c["mapped_by"] = "manual"
        else:
            c["automated_by"] = heur
            c["mapped_by"] = "heuristic" if heur else None
# ---- normalise / validate
CT = {"button", "swipe", "toggle", "field", "menu", "link", "gesture", "sheet"}
KT = {"happy", "edge", "negative", "a11y", "l10n", "layout"}
SU = {"flutter", "playwright", "appium", "api_e2e", "go", "django"}
KS = {"automated", "partial", "presence_only", "not_automated", "manual"}
for f in features:
    for k in ("id", "area", "screen", "route", "source_files", "controls", "cases"):
        assert k in f, (f.get("id"), k)
    for c in f["controls"]:
        assert c["type"] in CT, c
        c.setdefault("qa_key", None)
        c.setdefault("api", None)
    for c in f["cases"]:
        assert c["type"] in KT, c
        c.setdefault("seed_needs", ["signed-in member with completed profile"] if not f["id"].startswith(("site.", "console.")) else ["none"])
        if c["seed_needs"] is None:
            c["seed_needs"] = ["signed-in member with completed profile"]
        assert c["status"] in KS, c
        for a in c.get("automated_by", []):
            assert a["suite"] in SU, a
# ---- stats
ctrl_total = sum(len(f["controls"]) for f in features)
cases = [c for f in features for c in f["cases"]]
st = collections.Counter(c["status"] for c in cases)
suite_cases = collections.Counter()
for c in cases:
    for s in {a["suite"] for a in c.get("automated_by", [])}:
        suite_cases[s] += 1
action_cases = [c for c in cases if c["id"].endswith(".action")]
ctrl_status = collections.Counter(c["status"] for c in action_cases)
stats = {"features": len(features), "screens_in_matrix": len(MATRIX), "controls": ctrl_total, "cases": len(cases), "case_status": dict(st),
         "control_action_status": dict(ctrl_status), "cases_by_suite": dict(suite_cases),
         "tests_scanned": {k: len(v) for k, v in TESTS.items()},
         "mapped_by": dict(collections.Counter(c.get("mapped_by") or "none" for c in cases)),
         "tagged_tests": {k: sum(1 for t in v if t.get("cases") or t.get("expanded_cases")) for k, v in TAG_SCAN.items()},
         "tag_issues": tag_issues}
out = {"generated": os.environ.get("QA_CATALOG_DATE") or __import__("datetime").date.today().isoformat(),
       "generator": "python3 qa/catalog/tools/regenerate.py (static extraction of app/lib + test suites; [case:...] tags and qa/catalog/manual_cases.json applied)",
       "conventions": {"status": "automated = a test performs the action AND asserts an outcome (mapped_by=tag: the test names the case; mapped_by=heuristic: static key/label match); presence_only = tests find/tap the control without asserting its effect; partial = covered indirectly; manual = cannot be automated locally (manual_reason; checked by a person in QA Lab); not_automated = no test",
                       "case_tags": "Flutter/Playwright: [case:<id>] in the test name (interpolated ids are expanded only to string literals of the file); pytest: @pytest.mark.case(\"<id>\") incl. pytest.param marks; Go: // case: <id> above func TestX; Django: [case:<id>] in the test method docstring (or # case: <id> above def test_x)",
                       "extra_cases": "qa/catalog/extra_cases.json declares controls/cases/features static extraction cannot see; each has a reason (why_declared)",
                       "api": "statically inferred from callback → provider → Dio call; verify where action says 'unclassified'",
                       "qa_key": "ValueKey('qa.*') or Semantics label/identifier 'qa.*' (Appium content-desc); '*' = interpolated id"},
       "stats": stats, "features": features}
os.makedirs(os.path.dirname(CATALOG), exist_ok=True)
_tmp = CATALOG + ".tmp"
with open(_tmp, "w") as _fh:  # atomic replace: QA Lab may be reading the catalog
    json.dump(out, _fh, indent=1, ensure_ascii=False)
os.replace(_tmp, CATALOG)
json.dump(stats, sys.stdout, indent=1)
