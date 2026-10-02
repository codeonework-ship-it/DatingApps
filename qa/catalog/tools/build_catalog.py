import json, os, re, glob, sys, fnmatch, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paths import build_path
from dartscan import ROOT, LIB
import extract_app as EA

HERE = os.path.dirname(__file__)
CTRL = json.load(open(build_path("app_controls.json")))["controls"]
TESTS = json.load(open(build_path("tests.json")))

AREA = {
    "auth": "Auth & Onboarding", "admin": "Admin (in-app)", "blog": "Blog / Chapters", "calls": "Calls", "celebrations": "Celebrations & Rewards",
    "city_pilot": "City Pilot", "clubs": "Clubs & Lists", "common": "Navigation & Settings", "engagement": "Engagement Hub",
    "first_chapter": "First Chapter Studio", "friends": "Friends & Introducer", "graduation": "Graduation", "groups": "Groups",
    "intentional_dating": "Today / Intentional Dating", "matching": "Matches", "messaging": "Chat (dating)", "notifications": "Notifications",
    "payment": "Payments & Membership", "photo_themes": "Photo Themes", "plans": "Date Plans", "profile": "Profile",
    "safety": "Safety", "social_chat": "Social Chat (friends/rooms/groups)", "support": "Help & Support", "swipe": "Discover",
    "verification": "Verification", "walls": "Today Wall", "web": "Web Workspace", "core": "Shared components",
}

ICON_WORDS = {"favorite": "Like", "favorite_rounded": "Love", "close": "Pass", "close_rounded": "Close", "star": "Super like", "message": "Message",
              "undo": "Undo", "arrow_back_rounded": "Back", "arrow_back": "Back", "arrow_back_ios_new_rounded": "Back", "more_vert": "More",
              "more_horiz_rounded": "More", "delete_outline": "Delete", "send_rounded": "Send", "send": "Send", "refresh": "Refresh",
              "chat_bubble_outline_rounded": "Message", "flag_outlined": "Report", "visibility_off_outlined": "Hide", "edit": "Edit",
              "edit_outlined": "Edit", "share": "Share", "add": "Add", "search": "Search", "person": "Open profile",
              "notifications_none_rounded": "Notifications", "notifications_rounded": "Notifications", "settings": "Settings",
              "shield_outlined": "Submit report", "verified": "Open card", "visibility_outlined": "Who liked me", "call_end_rounded": "End call"}

# ---------------------------------------------------------------- screens
harness = open(os.path.join(ROOT, "app/test/features/responsive/screen_matrix_harness.dart")).read()
MATRIX = re.findall(r"^\s*'(\w+)':", harness[harness.find("buildScreenMatrix"):], re.M)
ws = open(os.path.join(LIB, "features/web/web_member_workspace.dart")).read()
WEB_ROUTES = {}
for mo in re.finditer(r"'(/[a-z][\w/-]*)'[^']{0,240}?\(\)\s*=>\s*(?:const\s+)?(\w+Screen)\(", ws, re.S):
    WEB_ROUTES.setdefault(mo.group(2), "#" + mo.group(1))
TABS = {"HomeDiscoveryScreen": ("#/discover", "Discover tab"), "MatchesListScreen": ("#/matches", "Matches tab"),
        "EngagementHubScreen": ("#/engagement", "Engage tab"), "ProfileViewScreen": ("#/profile", "Profile tab"),
        "SettingsScreen": ("#/settings", "Settings tab")}


def callers_of(cls):
    out = set()
    pat = re.compile(r"(?<![\w])" + re.escape(cls) + r"\s*\(")
    for f, d in EA.FILES.items():
        if cls in d["src"] and pat.search(d["m"]):
            if EA.CLASS_FILE.get(cls) == f:
                continue
            for c in d["classes"]:
                pass
            out.add(os.path.basename(f).replace(".dart", ""))
    return sorted(out)


def primary_class(f):
    d = EA.FILES[f]
    names = [c["name"] for c in d["classes"]]
    pub = [n for n in names if not n.startswith("_")]
    for suf in ("Screen", "Page", "Sheet", "Dialog", "Workspace"):
        for n in pub:
            if n.endswith(suf):
                return n
    if pub:
        return pub[0]
    stem = os.path.basename(f).replace(".dart", "")
    fn = re.findall(r"\b(show\w+)\s*(?:<[^>]*>)?\(", d["src"])
    return "".join(w.capitalize() for w in stem.split("_"))


def route_for(cls, f):
    if cls in TABS:
        r, t = TABS[cls]
        return f"{r} (web) / bottom nav: {t} (mobile)"
    if cls in WEB_ROUTES:
        return f"{WEB_ROUTES[cls]} (web) / pushed screen (mobile)"
    if cls == "MainNavigationScreen":
        return "app shell (signed-in)"
    cs = callers_of(cls)
    if cs:
        return "opened from: " + ", ".join(cs[:6]) + (" …" if len(cs) > 6 else "")
    return "embedded / not directly routed"


# ---------------------------------------------------------------- test index
def norm(s):
    return re.sub(r"\s+", " ", (s or "").strip().lower().replace("’", "'").replace("…", "..."))


def label_rx(label):
    if not label:
        return None
    parts = re.split(r"\{[^}]*\}", label)
    rx = ".*".join(re.escape(norm(p)) for p in parts)
    return re.compile("^" + rx + "$")


def key_match(ckey, tval):
    if not ckey or not tval:
        return False
    if ckey == tval:
        return True
    a = ckey.replace("*", "\u0000")
    if "*" in ckey and fnmatch.fnmatchcase(tval, ckey):
        return True
    if "*" in tval and fnmatch.fnmatchcase(ckey, tval):
        return True
    if tval.endswith(".") and ckey.startswith(tval):
        return True
    return False


def _one_text_match(lab, tval):
    if not lab or not tval or lab.startswith("icon:"):
        return False
    t = norm(tval)
    prefix = t.startswith("^")
    t = t.lstrip("^")
    for alt in t.split("|"):
        alt = alt.strip()
        if not alt:
            continue
        if norm(lab) == alt or (prefix and norm(lab).startswith(alt)):
            return True
        rx = label_rx(lab)
        if rx and "{" in lab and rx.match(alt):
            return True
    return False


def text_match(c, tval):
    if _one_text_match(c.get("label") or "", tval):
        return True
    return any(_one_text_match(a, tval) for a in c.get("alt_labels") or [])


def _defines_screen(f):
    return any(re.search(r"(Screen|Page|Workspace)$", c["name"]) and not c["name"].startswith("_") for c in EA.FILES[f]["classes"])


def ctx_files(test):
    files = set()
    for cls in test.get("classes", []):
        f = EA.CLASS_FILE.get(cls)
        if f:
            files.add(f)
            if "/features/" in f and re.search(r"(Screen|Page|Sheet|Dialog|Workspace)$", cls):
                for i in EA.FILES[f]["imports"]:
                    if ("/features/" in i or "/core/widgets" in i) and i in EA.FILES and not _defines_screen(i):
                        files.add(i)
    return {os.path.relpath(f, ROOT) for f in files}


KEY_OWNERS = collections.defaultdict(set)
for _c in CTRL:
    if _c.get("key"):
        KEY_OWNERS[_c["key"]].add(_c["file"])


def _stem_tokens(f):
    st = os.path.basename(f).replace(".dart", "").replace("_screen", "")
    return [t for t in st.split("_") if len(t) > 3 and t not in ("profiles", "profile", "screen", "widgets")] or [st]


CALLER_COUNT = {}


def shared_key_ok(c, test):
    """A key used by controls in several files: a non-flutter test is credited
    to this control only if the test names this control's screen, or (when it
    names none) this file is the most-used owner."""
    owners = KEY_OWNERS.get(c.get("key"), set())
    if len(owners) <= 1:
        return True
    hay = (test["file"] + " " + test["test"]).lower()
    named = [o for o in owners if any(t in hay for t in _stem_tokens(o))]
    if named:
        return c["file"] in named
    def cc(o):
        if o not in CALLER_COUNT:
            CALLER_COUNT[o] = sum(1 for g in EA.FILES.values() if os.path.basename(o) in g["src"])
        return CALLER_COUNT[o]
    best = max(sorted(owners), key=cc)
    return c["file"] == best


UI_TESTS = TESTS["flutter"] + TESTS["playwright"] + TESTS["appium"]
for t in TESTS["flutter"]:
    t["_ctx"] = ctx_files(t)

# label frequency for global (no-context) matching
LABEL_FREQ = collections.Counter(norm(c["label"]) for c in CTRL if c.get("label"))


def tests_for_control(c):
    acted_ok, acted_weak, found = [], [], []
    for t in UI_TESTS:
        suite = t["suite"]
        ctx = t.get("_ctx")
        for a in t.get("acted", []):
            hit = False
            how = None
            if a["kind"] == "text" and a["value"].lstrip("^").startswith("qa."):
                a = dict(a, kind="key", value=a["value"].lstrip("^").split("|")[0])
            if a["kind"] == "key" and "{" in a["value"]:
                a = dict(a, value=re.sub(r"\{[^}]*\}", "*", a["value"]))
            if a["kind"] == "key" and key_match(c.get("key"), a["value"]):
                if suite == "flutter":
                    hit = c["file"] in ctx or len(KEY_OWNERS.get(c.get("key"), ())) <= 1
                else:
                    hit = shared_key_ok(c, t)
                how = "key"
            elif a["kind"] in ("text", "tooltip"):
                if text_match(c, a["value"]):
                    if suite == "flutter":
                        hit = c["file"] in ctx
                    else:
                        hit = LABEL_FREQ[norm(c["label"])] <= 2
                    how = "label"
            elif a["kind"] == "icon" and (c.get("label") or "") == "icon:" + a["value"] and suite == "flutter" and c["file"] in ctx:
                hit, how = True, "icon"
            if hit:
                ref = {"suite": suite if not (suite == "appium" and a.get("indirect")) else "appium", "file": t["file"], "test": t["test"],
                       "matched_by": how, "verb": a["verb"]}
                (acted_ok if a["outcome"] else acted_weak).append(ref)
        for fd in t.get("found", []):
            if fd["kind"] == "key" and key_match(c.get("key"), fd["value"]) and (suite == "flutter" and (c["file"] in (ctx or set()) or len(KEY_OWNERS.get(c.get("key"), ())) <= 1) or suite != "flutter" and shared_key_ok(c, t)):
                found.append({"suite": suite, "file": t["file"], "test": t["test"]})
            elif fd["kind"] in ("text", "tooltip") and text_match(c, fd["value"]) and suite == "flutter" and c["file"] in (ctx or set()):
                found.append({"suite": suite, "file": t["file"], "test": t["test"]})
    def dd(lst):
        seen, out = set(), []
        for r in lst:
            k = (r["file"], r["test"])
            if k not in seen:
                seen.add(k)
                out.append(r)
        return out
    ok = dd(acted_ok)
    okk = {(r["file"], r["test"]) for r in ok}
    weak = [r for r in dd(acted_weak) if (r["file"], r["test"]) not in okk]
    fnd = [r for r in dd(found) if (r["file"], r["test"]) not in okk and (r["file"], r["test"]) not in {(x["file"], x["test"]) for x in weak}]
    return ok, weak, fnd


ROUTE_TESTS = collections.defaultdict(list)
for suite in ("api_e2e", "go", "appium"):
    for t in TESTS[suite]:
        if not t.get("asserts", True):
            continue
        for r in t.get("routes", []):
            ROUTE_TESTS[r].append({"suite": "api_e2e" if suite == "api_e2e" else ("go" if suite == "go" else "appium"), "file": t["file"], "test": t["test"]})


# ---------------------------------------------------------------- helpers
def slug(s, n=40):
    s = re.sub(r"[^a-z0-9]+", "_", (s or "").lower()).strip("_")
    return s[:n].strip("_") or "x"


def human_label(c):
    lab = c.get("label")
    if lab and lab.startswith("icon:"):
        ic = lab[5:]
        w = ICON_WORDS.get(ic) or ICON_WORDS.get(re.sub(r"_(rounded|outlined|outline|sharp)$", "", ic))
        if c.get("key"):
            k = c["key"].split(".")[-1].replace("_button", "").replace("_", " ").replace("*", "").strip()
            if k:
                w = w or k.capitalize()
        return (w or ic.replace("_", " ")) + f" (icon {ic})"
    if lab and not re.search(r"[A-Za-z]", lab):
        lab = None
    if not lab and c.get("key"):
        parts = [p for p in c["key"].split(".") if p not in ("*", "qa")]
        base = (parts[-1] if parts else c["key"]).replace("_", " ")
        verb = {"onLongPress": "Long-press ", "onDoubleTap": "Double-tap "}.get(c["callback"], "")
        return verb + base
    if not lab:
        return f"{c['ctor']} {c['callback']}"
    return lab


NOOP_RE = re.compile(r"^\(?[\w, ]*\)?\s*(?:\{\s*\}|=>\s*\{\s*\}|=>\s*null)$")

CTYPE = {"button", "swipe", "toggle", "field", "menu", "link", "gesture", "sheet"}


def control_type(c):
    t = c["type"]
    if "opens external link" in c["effects"]:
        return "link"
    if t == "delegate":
        return "button"
    return t if t in CTYPE else "button"


def describe(c):
    parts = []
    if c["api"]:
        parts.append("calls " + ", ".join(f"{a['method'].replace('UPLOADATTACHMENT', 'POST(upload)')} {a['path']}" for a in c["api"][:4]))
    nav = [n for n in c["nav"] if not n.startswith("web:")]
    web = [n[4:] for n in c["nav"] if n.startswith("web:")]
    if nav:
        parts.append("may open " + ", ".join(nav[:4]))
    if web:
        parts.append("routes to " + ", ".join(web))
    sh = [s for s in c["sheets"] if s not in ("showModalBottomSheet", "showDialog")] if c["callback"] != "open" else []
    if c["callback"] == "open":
        parts.append(f"presents a {'bottom sheet' if 'Sheet' in c['ctor'] else 'dialog/picker'}")
    elif c["sheets"]:
        parts.append("opens " + ", ".join(c["sheets"][:3]))
    eff = [e for e in c["effects"] if e not in ("haptic",)]
    if eff:
        parts.append(", ".join(eff))
    if not parts:
        if NOOP_RE.match(c["callback_src"].strip()):
            return "NO-OP: callback body is empty"
        parts.append("local/unclassified action — callback: " + c["callback_src"][:90])
    return "; ".join(parts)


def verb_for(c):
    t = control_type(c)
    return {"button": "Tap", "link": "Tap", "toggle": "Toggle/select", "field": "Type into", "menu": "Choose from", "swipe": "Swipe",
            "gesture": {"onRefresh": "Pull to refresh", "onLongPress": "Long-press", "onDoubleTap": "Double-tap"}.get(c["callback"], "Gesture on"),
            "sheet": "Trigger"}[t]


# result-ignored detection for screens that pop a value
def push_sites(cls):
    sites = []
    pat = re.compile(r"(?<![\w])" + re.escape(cls) + r"\s*\(")
    for f, d in EA.FILES.items():
        if cls not in d["src"] or EA.CLASS_FILE.get(cls) == f:
            continue
        for mo in pat.finditer(d["m"]):
            win = d["m"][max(0, mo.start() - 400):mo.start()]
            stmt_start = max(win.rfind(";"), win.rfind("{"))
            stmt = win[stmt_start + 1:]
            after = d["m"][mo.start():mo.start() + 600]
            awaited = "await" in stmt or ".then(" in after[:after.find(";") if ";" in after else 600]
            sites.append({"file": os.path.relpath(f, ROOT), "line": d["src"].count("\n", 0, mo.start()) + 1, "awaited": awaited,
                          "uses_result": bool(re.search(r"(final|var)\s+\w+\s*=\s*await|=\s*await|\.then\(", stmt + after[:300]))})
    return sites


SEED = {
    "auth": ["fresh device (no session)", "existing member credentials from qa seed", "member with recovery code"],
    "swipe": ["member with complete profile", ">=3 undecided discovery candidates", ">=1 spotlight profile", ">=1 member who liked the seeded member", ">=1 passed profile"],
    "matching": ["member with >=2 matches (one with messages, one new)", "match eligible for call/plan/graduation"],
    "messaging": ["match with unlocked chat and message history", "wallet with coins", "gift catalog active", "daily message limit state"],
    "social_chat": ["friend pair / room / group membership with messages"],
    "friends": ["member with 1 friend, 1 pending incoming and 1 outgoing request", "introducer account"],
    "groups": ["member owning one group and member of another", "pending invite"],
    "payment": ["sandbox/Stripe test provider", "member on free plan", "wallet with coins", "coin packages active"],
    "profile": ["member with 3+ photos, prompts, chapters and wall photos (public + opted-in)"],
    "verification": ["unverified member", "member with pending verification", "test ID photo fixture"],
    "plans": ["match with an accepted date plan", "plan past its time (for debrief)", ">=1 friend for fan-out"],
    "blog": [">=2 published chapters, 1 draft, 1 writer to follow"],
    "photo_themes": ["active theme with entries and comments"],
    "clubs": ["club with posts", "titles in lists"],
    "support": ["member with 1 open and 1 resolved ticket"],
    "safety": ["emergency contacts", "a blocked member", "a reportable member"],
    "intentional_dating": ["curated Today set", "today wall posts", "introductions", "stories"],
    "engagement": ["active daily prompt, challenges, coffee polls, rooms, nudges"],
    "notifications": ["unread notifications of each category"],
    "common": ["member with settings defaults", "blocked user", "appeal"],
    "graduation": ["match that both members graduated"],
    "first_chapter": ["match with first-chapter studio unlocked"],
    "calls": ["match with call history", "call permissions granted"],
    "city_pilot": ["city pilot with experiences"],
}

# ---------------------------------------------------------------- build app features
by_file = collections.defaultdict(list)
for c in CTRL:
    by_file[c["file"]].append(c)

features = []
all_case_ids = set()
stats_presence = []


def add_case(lst, case):
    cid = case["id"]
    i = 2
    while cid in all_case_ids:
        cid = f"{case['id']}_{i}"
        i += 1
    case["id"] = cid
    all_case_ids.add(cid)
    lst.append(case)


for f in sorted(by_file):
    absf = os.path.join(ROOT, f)
    parts = f.split("/")
    if "features" in parts:
        area_dir = parts[parts.index("features") + 1]
    else:
        area_dir = "core"
    area = AREA.get(area_dir, area_dir)
    cls = primary_class(absf)
    stem = os.path.basename(f).replace(".dart", "").replace("_screen", "")
    fid = f"{slug(area_dir, 20)}.{slug(stem, 40)}"
    route = route_for(cls, absf)
    in_matrix = cls in MATRIX
    feat = {"id": fid, "area": area, "screen": cls, "route": route, "source_files": [f], "in_screen_matrix": in_matrix,
            "controls": [], "cases": []}
    # contributing component files
    extra = set()
    used_ids = set()
    pop_screen = False
    for c in sorted(by_file[f], key=lambda x: x["line"]):
        base = c.get("key") or ""
        if base.startswith("qa."):
            base = base[3:]
        cslug = slug(base.replace("*", "x").replace(".", "_"), 50) if base else slug(human_label(c), 32)
        if c["callback"] not in ("onTap", "onPressed", "open", "onChanged", "onSelected") and not base:
            cslug += "_" + slug(c["callback"], 20)
        elif c["callback"] not in ("onTap", "onPressed", "open", "onChanged", "onSelected") and base:
            cslug += "_" + slug(c["callback"].replace("on", "", 1), 20)
        cid = f"{fid}.{cslug}"
        k = 2
        while cid in used_ids:
            cid = f"{fid}.{cslug}_{k}"
            k += 1
        used_ids.add(cid)
        ctype = control_type(c)
        action = describe(c)
        api = ", ".join(f"{a['method']} {a['path']}" for a in c["api"][:4]) or None
        risks = []
        if NOOP_RE.match(c["callback_src"].strip()):
            risks.append("NO-OP callback: control does nothing when used")
        if c["pop_result"] and not c.get("in_sheet"):
            pop_screen = True
            risks.append("pops a result to its opener — verify every opener handles it")
        if ctype in ("button", "gesture", "swipe") and not (c["api"] or c["nav"] or c["sheets"] or c["effects"]) and not risks:
            risks.append("action not statically resolved — verify manually")
        ctrl = {"id": cid, "type": ctype, "label": human_label(c), "qa_key": c.get("key") if (c.get("key") or "").startswith("qa.") else None,
                "key": c.get("key") if c.get("key") and not c["key"].startswith("qa.") else None,
                "action": action, "api": api, "widget": c["ctor"], "callback": c["callback"], "source": f"{c['file']}:{c['line']}",
                "l10n_key": c.get("l10n_key"), "navigates_to": [n for n in c["nav"]] or None}
        if c.get("alt_labels"):
            ctrl["alt_labels"] = c["alt_labels"]
        if risks:
            ctrl["risks"] = risks
        feat["controls"].append(ctrl)
        # ---- cases
        ok, weak, fnd = tests_for_control(c)
        steps = [f"Sign in as the seeded member and open {cls} ({route.split(' / ')[0] if route else ''})",
                 f"{verb_for(c)} '{human_label(c)}'" + (f" [key {c['key']}]" if c.get("key") else "")]
        expected = action[0].upper() + action[1:] if action else ""
        if c["api"]:
            expected += ". Network log shows the request(s) with 2xx and the UI reflects the result (no silent failure)."
        status = "automated" if ok else ("presence_only" if (weak or fnd) else "not_automated")
        case = {"id": f"{cid}.action", "title": f"{verb_for(c)} {human_label(c)} on {cls} performs its action", "type": "happy",
                "steps": steps, "expected": expected, "seed_needs": SEED.get(area_dir, ["signed-in member with completed profile"]),
                "automated_by": ok, "status": status}
        if weak:
            case["acts_without_outcome_assert"] = weak
        if fnd:
            case["presence_only_tests"] = fnd
        add_case(feat["cases"], case)
        if c["api"]:
            rts = []
            for a in c["api"]:
                rk = f"{a['method']} {a['path']}"
                rts.extend(ROUTE_TESTS.get(rk, []))
            seen = set()
            rts2 = []
            for r in rts:
                kk = (r["file"], r["test"])
                if kk not in seen:
                    seen.add(kk)
                    rts2.append(r)
            add_case(feat["cases"], {"id": f"{cid}.api_contract", "title": f"API behind '{human_label(c)}' ({api}) accepts a valid request and rejects bad input/authz",
                                     "type": "happy", "steps": [f"Call {api} as the seeded member with a valid body", "Repeat with another member's id / missing fields"],
                                     "expected": "2xx with the documented body for the valid call; 4xx (400/403/404/409) for invalid or foreign ids; no 5xx.",
                                     "automated_by": rts2[:12], "automated_by_total": len(rts2), "status": "automated" if rts2 else "not_automated", "level": "api"})
            if ctype in ("button", "toggle", "swipe", "gesture", "menu"):
                neg = [r for r in ok if re.search(r"error|fail|offline|retry|409|500|reject|denied|limit|quota|unavailable|roll", r["test"], re.I)]
                add_case(feat["cases"], {"id": f"{cid}.api_failure", "title": f"'{human_label(c)}' surfaces an API failure and does not lose state",
                                         "type": "negative", "steps": steps[:1] + [f"Make {api} return 500 / time out (proxy or stub)", steps[1]],
                                         "expected": "A readable error (snackbar/inline) appears, the control re-enables, local state rolls back; no crash, no duplicate request on retry.",
                                         "automated_by": neg, "status": "automated" if neg else "not_automated"})
        if risks and any(r.startswith("NO-OP") for r in risks):
            add_case(feat["cases"], {"id": f"{cid}.not_noop", "title": f"'{human_label(c)}' must do something (currently an empty callback)", "type": "negative",
                                     "steps": steps, "expected": "The control performs a visible action or is removed/disabled. BUG today: empty callback.",
                                     "automated_by": [], "status": "not_automated", "bug": True})
        if ctype == "field":
            add_case(feat["cases"], {"id": f"{cid}.validation", "title": f"'{human_label(c)}' validates input (empty, max length, emoji/RTL, whitespace)",
                                     "type": "edge", "steps": steps[:1] + [f"Enter empty, whitespace-only, max+1 length and emoji/RTL text into '{human_label(c)}'", "Submit"],
                                     "expected": "Invalid input is blocked with a localized message; valid unicode is preserved end-to-end.",
                                     "automated_by": [r for r in ok if r["verb"] in ("enterText", "fill", "type_into_qa")],
                                     "status": "automated" if any(r["verb"] in ("enterText", "fill", "type_into_qa") for r in ok) else "not_automated"})
    # pop-result consumers
    if pop_screen and cls.endswith("Screen"):
        sites = push_sites(cls)
        ignored = [s for s in sites if not s["uses_result"]]
        feat["opened_by"] = sites
        add_case(feat["cases"], {"id": f"{fid}.openers_handle_result", "title": f"Every opener of {cls} handles the popped result (Love/Message from every entry point)",
                                 "type": "edge", "steps": [f"Open {cls} from each opener: " + ", ".join(sorted({os.path.basename(s['file']) for s in sites})), "Use each result-returning control"],
                                 "expected": "The action takes effect regardless of entry point (API call made, list updated, chat opened).",
                                 "automated_by": [], "status": "not_automated",
                                 "notes": (f"{len(ignored)} opener call site(s) do not read the result: " + ", ".join(f"{s['file']}:{s['line']}" for s in ignored)) if ignored else "all openers await the result"})
    # screen-level cases
    if in_matrix:
        add_case(feat["cases"], {"id": f"{fid}.layout_matrix", "title": f"{cls} lays out without overflow on every device size/theme", "type": "layout",
                                 "steps": ["Pump the screen at phone/tablet/desktop sizes in every look"], "expected": "No overflow/exception; golden matches",
                                 "automated_by": [{"suite": "flutter", "file": "app/test/features/responsive/screen_matrix_test.dart", "test": "$screenLabel lays out on $deviceLabel [$themeLabel]"}],
                                 "status": "automated"})
        add_case(feat["cases"], {"id": f"{fid}.a11y_guidelines", "title": f"{cls} meets tap-target/contrast/label guidelines", "type": "a11y",
                                 "steps": ["Pump with semantics on", "Run androidTapTargetGuideline, textContrastGuideline, labeledTapTargetGuideline"],
                                 "expected": "No guideline failures beyond the ratchet allowlist",
                                 "automated_by": [{"suite": "flutter", "file": "app/test/features/responsive/screen_accessibility_test.dart", "test": "$label meets accessibility guidelines [$themeLabel]"}],
                                 "status": "automated"})
    add_case(feat["cases"], {"id": f"{fid}.l10n", "title": f"{cls} has no hard-coded user-facing strings and renders in all 10 locales", "type": "l10n",
                             "steps": ["Switch language in Settings > Language to each locale", f"Open {cls}"],
                             "expected": "Every label is translated; no truncation; no English fallbacks",
                             "automated_by": [{"suite": "flutter", "file": "app/test/l10n/hardcoded_strings_guard_test.dart", "test": "no new hard-coded user-facing strings"}],
                             "status": "partial", "notes": "guard test is a static ratchet over source; rendering per locale is not automated"})
    features.append(feat)

json.dump(features, open(build_path("app_features.json"), "w"), indent=1)
print(len(features), "features", sum(len(f["controls"]) for f in features), "controls", sum(len(f["cases"]) for f in features), "cases")
