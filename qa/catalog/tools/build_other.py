"""Website (static public pages) and operator console (Django) features."""
import json, os, re, collections
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paths import ROOT, build_path
TESTS = json.load(open(build_path("tests.json")))
PW = {(t["file"].split("/")[-1], t["test"]): t for t in TESTS["playwright"]}


def pw(spec, prefix):
    out = []
    for (f, n), t in PW.items():
        if f == spec and n.startswith(prefix):
            out.append({"suite": "playwright", "file": t["file"], "test": n})
    return out


def case(cid, title, ctype, steps, expected, auto, seed=None, status=None, notes=None, covers=None):
    c = {"id": cid, "title": title, "type": ctype, "steps": steps, "expected": expected, "seed_needs": seed or ["none (public page)"],
         "automated_by": auto, "status": status or ("automated" if auto else "not_automated")}
    if notes:
        c["notes"] = notes
    if covers:
        c["covers_controls"] = covers
    return c


W = []
# ---------------------------------------------------------------- shared header/footer
hdr = {"id": "site.site_header", "area": "Website (public)", "screen": "Shared header/footer (all public pages)", "route": "/ , /features, /safety, /contact, /membership, /guidelines, /privacy (+ /{de,en-gb,es,fr,it,nl,pl,pt,ru}/...)",
       "source_files": ["website/public/site.js", "website/generate_pages.py", "website/locales/"],
       "controls": [
           {"id": "site.site_header.language_switch", "type": "menu", "label": "Language (select[data-lang-switch])", "qa_key": None, "action": "navigates to the same page in the chosen locale (site.js change handler sets location.href)", "api": None},
           {"id": "site.site_header.menu_toggle", "type": "button", "label": "Open menu (.menu-toggle)", "qa_key": None, "action": "toggles aria-expanded and the mobile nav (<=1000px)", "api": None},
           {"id": "site.site_header.nav_links", "type": "link", "label": "Features / How it works / Safety / Sign in / Join", "qa_key": None, "action": "navigates to page or /app/#/signin, /app/#/signup; closes mobile menu", "api": None},
           {"id": "site.site_header.skip_link", "type": "link", "label": "Skip to content", "qa_key": None, "action": "moves focus to #main", "api": None},
           {"id": "site.site_header.footer_links", "type": "link", "label": "Footer: Contact, Privacy, Guidelines, Safety, Membership", "qa_key": None, "action": "navigates to the localized page", "api": None},
       ], "cases": []}
hdr["cases"] += [
    case("site.site_header.language_switch.moves_locale", "Language switcher moves between every locale on the same page", "l10n", ["Open /features", "Pick each language in the switcher"], "URL becomes /{locale}/features and copy is translated; html[lang] matches", pw("public-pages.spec.js", "locale switcher"), covers=['site.site_header.language_switch']),
    case("site.site_header.menu_toggle.mobile", "Menu button drives the nav up to 1000px, inline nav above", "layout", ["Resize to 390/768/1000/1001px", "Click Open menu"], "Menu opens/closes, aria-expanded toggles, menu stays in viewport", pw("responsive.spec.js", "WEB-04: menu button") + pw("responsive.spec.js", "open phone menu") + pw("website.spec.js", "mobile navigation"), covers=['site.site_header.menu_toggle']),
    case("site.site_header.nav_links.every_locale", "Header navigation, skip link and mobile menu work in every locale", "happy", ["For each locale open /", "Use skip link, open menu, click each nav link"], "Each link lands on the right localized page", pw("public-pages.spec.js", "header navigation"), covers=['site.site_header.nav_links', 'site.site_header.skip_link']),
    case("site.site_header.links_resolve", "Every internal link, asset and app deep link resolves", "happy", ["Crawl all generated pages"], "No 404s; anchors land on elements", pw("links.spec.js", "") + pw("website.spec.js", "all public links"), covers=['site.site_header.footer_links', 'site.site_header.nav_links', 'site.story.cta', 'site.chapter.cta', 'site.index.cta_join', 'site.index.cta_signin', 'site.membership.plan_cta', 'site.safety.links', 'site.guidelines.links', 'site.privacy.links', 'site.features.feature_links']),
    case("site.site_header.a11y", "Public pages pass axe smoke, heading order and visible focus", "a11y", ["Run axe on each page in each locale"], "No serious violations; headings never skip; focus visible", pw("a11y-smoke.spec.js", "")),
    case("site.site_header.security_headers", "Every browser-facing response carries security headers (CSP etc.)", "negative", ["Fetch each page"], "CSP, HSTS, X-Content-Type-Options, Referrer-Policy present; untrusted hosts rejected", pw("website.spec.js", "every browser-facing") + pw("website.spec.js", "website rejects")),
]
W.append(hdr)

pages = [
    ("index", "Home", "/", [("cta_join", "link", "Create account / Join", "opens /app/#/signup"), ("cta_signin", "link", "Sign in", "opens /app/#/signin"),
                            ("faq", "toggle", "FAQ <details> items", "expand/collapse answers")]),
    ("features", "Features", "/features", [("search", "field", "Find a feature (#feature-search)", "filters feature cards live; announces result count politely"),
                                           ("feature_links", "link", "Feature card deep links (/app/#/discover, /matches, /preferences, ...)", "opens the web app route")]),
    ("safety", "Safety", "/safety", [("links", "link", "Safety resources / Contact links", "navigates")]),
    ("membership", "Membership", "/membership", [("plan_cta", "link", "Plan call-to-action", "opens /app/#/membership (sign-in gated)")]),
    ("guidelines", "Community guidelines", "/guidelines", [("links", "link", "Links", "navigates")]),
    ("privacy", "Privacy", "/privacy", [("links", "link", "Links", "navigates")]),
]
for stem, title, route, ctrls in pages:
    f = {"id": f"site.{stem}", "area": "Website (public)", "screen": f"{title} page", "route": route + " (+9 locale prefixes)",
         "source_files": [f"website/public/{stem}.html", "website/generate_pages.py"], "controls": [], "cases": []}
    for cid, t, lab, act in ctrls:
        f["controls"].append({"id": f"site.{stem}.{cid}", "type": t, "label": lab, "qa_key": None, "action": act, "api": None})
    f["cases"].append(case(f"site.{stem}.renders_all_locales", f"{title} renders in every locale with one h1 and fits phone/tablet/desktop", "layout",
                           [f"Open {route} and each /{{locale}}{route}"], "Localized copy, lang attribute, no horizontal overflow",
                           pw("public-pages.spec.js", "${url}") + pw("responsive.spec.js", "${locale.hreflang}") + pw("website.spec.js", "${path} has working")))
    if stem == "features":
        f["cases"].append(case("site.features.search.filters", "Feature search filters cards, shows empty state and recovers", "happy",
                               ["Open /features", "Type 'chat'", "Type nonsense", "Clear"], "Matching cards only; empty-state message; all cards back after clearing; live region announces count",
                               pw("public-forms.spec.js", "feature search") + pw("website.spec.js", "feature search") + pw("public-pages.spec.js", "features page lists"), covers=['site.features.search']))
        f["cases"].append(case("site.features.feature_links.deep_links", "Every feature card deep link opens the right app route", "happy", ["Click each feature card link"], "Lands on /app/#/<route> (sign-in gate if signed out)", pw("links.spec.js", "every internal link"), status=None))
    if stem == "index":
        f["cases"].append(case("site.index.faq.keyboard", "FAQ operates with keyboard and touch targets >= 44px", "a11y", ["Tab to FAQ items, press Enter"], "Items expand/collapse", pw("website.spec.js", "mobile navigation and FAQ"), covers=['site.index.faq']))
    W.append(f)

contact = {"id": "site.contact", "area": "Website (public)", "screen": "Contact page", "route": "/contact (+locales)", "source_files": ["website/public/contact.html", "website/public/contact.js"],
           "controls": [
               {"id": "site.contact.email", "type": "field", "label": "Email (#contact-email)", "qa_key": None, "action": "required, validated email", "api": None},
               {"id": "site.contact.name", "type": "field", "label": "Name (#contact-name, optional)", "qa_key": None, "action": "optional; omitted from payload when empty", "api": None},
               {"id": "site.contact.category", "type": "menu", "label": "Category (#contact-category)", "qa_key": None, "action": "required select", "api": None},
               {"id": "site.contact.subject", "type": "field", "label": "Subject (#contact-subject)", "qa_key": None, "action": "4-120 chars", "api": None},
               {"id": "site.contact.description", "type": "field", "label": "Description (#contact-description) + live counter", "qa_key": None, "action": "required, max 5000", "api": None},
               {"id": "site.contact.honeypot", "type": "field", "label": "Hidden website honeypot (#contact-website)", "qa_key": None, "action": "bots filling it are dropped", "api": None},
               {"id": "site.contact.submit", "type": "button", "label": "Send (#contact-submit)", "qa_key": None, "action": "client-validates, then POST /v1/support/contact with locale; shows reference number", "api": "POST /v1/support/contact"},
               {"id": "site.contact.again", "type": "button", "label": "Send another message (#contact-again)", "qa_key": None, "action": "resets the form for a new message", "api": None},
               {"id": "site.contact.error_summary_links", "type": "link", "label": "Error summary links", "qa_key": None, "action": "focus the invalid field", "api": None},
           ], "cases": []}
contact["cases"] += [
    case("site.contact.submit.valid_posts_json", "Valid submission posts JSON and shows the reference", "happy", ["Open /contact", "Fill all fields", "Send"], "POST /v1/support/contact with JSON body; confirmation with reference", pw("contact.spec.js", "valid submission") + pw("contact.spec.js", "success without"), covers=['site.contact.email', 'site.contact.name', 'site.contact.category', 'site.contact.subject', 'site.contact.description', 'site.contact.submit']),
    case("site.contact.submit.client_validation", "Client validation lists errors, focuses the summary and sends nothing", "negative", ["Submit empty / invalid email / short subject"], "Error summary focused; links focus fields; no request", pw("contact.spec.js", "client validation"), covers=['site.contact.email', 'site.contact.subject', 'site.contact.description', 'site.contact.category', 'site.contact.error_summary_links', 'site.contact.submit']),
    case("site.contact.submit.server_errors", "Server validation, rate-limit, disabled feature and outage messages", "negative", ["Stub 400/429/403/503"], "Readable message; form kept", pw("contact.spec.js", "server validation") + pw("contact.spec.js", "rate limit")),
    case("site.contact.honeypot", "Honeypot hidden from people and skipped by keyboard", "a11y", ["Tab through form"], "Honeypot unreachable and invisible", pw("contact.spec.js", "honeypot"), covers=['site.contact.honeypot']),
    case("site.contact.locale", "Localized contact page sends its locale and shows translated copy", "l10n", ["Open /de/contact", "Submit"], "Payload carries locale=de; German copy", pw("contact.spec.js", "localised contact")),
    case("site.contact.again.resets", "Send another message resets the form", "happy", ["Submit successfully", "Click Send another message"], "Empty form, focus on first field", [], notes="clicked inside 'valid submission' flow? not asserted separately", covers=['site.contact.again']),
    case("site.contact.api_contract", "POST /v1/support/contact validates and stores the message", "happy", ["POST valid and invalid bodies"], "201 with reference; 400 for invalid", [{"suite": "api_e2e", "file": t["file"], "test": t["test"]} for t in TESTS["api_e2e"] if any("support/contact" in r for r in t.get("routes", []))]
         + [{"suite": "go", "file": t["file"], "test": t["test"]} for t in TESTS["go"] if any("support/contact" in r for r in t.get("routes", []))][:6]),
]
W.append(contact)

story = {"id": "site.story", "area": "Website (public)", "screen": "Shared story page", "route": "/story.html?id=<publication>", "source_files": ["website/public/story.html", "website/public/story.js"],
         "controls": [
             {"id": "site.story.share", "type": "button", "label": "Share (#share)", "qa_key": None, "action": "navigator.share or copy fallback", "api": None},
             {"id": "site.story.copy", "type": "button", "label": "Copy link (#copy)", "qa_key": None, "action": "copies share URL to clipboard", "api": None},
             {"id": "site.story.retry", "type": "button", "label": "Retry (#retry)", "qa_key": None, "action": "re-fetches the publication", "api": "GET /v1/blog/public/{id}"},
             {"id": "site.story.report_reason", "type": "menu", "label": "Report reason (#reason)", "qa_key": None, "action": "required", "api": None},
             {"id": "site.story.report_description", "type": "field", "label": "Report description (#description)", "qa_key": None, "action": "max 1000", "api": None},
             {"id": "site.story.report_submit", "type": "button", "label": "Send report (#report-submit)", "qa_key": None, "action": "POST {endpoint}/report without credentials", "api": "POST /v1/blog/public/{id}/report"},
             {"id": "site.story.cta", "type": "link", "label": "Start your own chapter / Join", "qa_key": None, "action": "opens /chapter.html or /app/#/signup", "api": None},
         ], "cases": [
             case("site.story.renders_safely", "Approved story renders safe DOM at phone/desktop widths", "happy", ["Open /story.html?id=<approved>"], "Excerpt rendered with formatting, no script execution", pw("blog-public.spec.js", "approved story") + pw("blog-public.spec.js", "formatted excerpt") + pw("blog-public.spec.js", "chapters without")),
             case("site.story.withdrawn", "Withdrawn/invalid links clear content and never fetch a bad source", "negative", ["Open withdrawn id / malformed id"], "Calm unavailable state", pw("blog-public.spec.js", "withdrawn") + pw("blog-public.spec.js", "incomplete links")),
             case("site.story.report_submit.retry", "Report retry preserves text and sends no member credentials", "negative", ["Fill report", "Server fails", "Retry"], "Text kept; request has credentials:'omit'", pw("blog-public.spec.js", "report retry"), covers=['site.story.report_reason', 'site.story.report_description', 'site.story.report_submit', 'site.story.retry']),
             case("site.story.copy_share", "Copy and Share produce the canonical share URL", "happy", ["Click Copy", "Click Share"], "Clipboard has /story.html?id=...; share sheet or copy fallback", [], covers=['site.story.copy', 'site.story.share']),
         ]}
W.append(story)
chapter = {"id": "site.chapter", "area": "Website (public)", "screen": "Pass the Chapter (public studio)", "route": "/chapter.html[?scene=&beginning=&surprise=|?share=]", "source_files": ["website/public/chapter.html", "website/public/chapter.js"],
           "controls": [
               {"id": "site.chapter.choice_buttons", "type": "toggle", "label": "Beginning / surprise choice buttons (aria-pressed)", "qa_key": None, "action": "select options; updates remix URL", "api": None},
               {"id": "site.chapter.copy", "type": "button", "label": "Copy remix link (#copy)", "qa_key": None, "action": "copies remix URL", "api": None},
               {"id": "site.chapter.share", "type": "button", "label": "Share (#share)", "qa_key": None, "action": "navigator.share or copy", "api": None},
               {"id": "site.chapter.reset", "type": "button", "label": "Start again (#reset)", "qa_key": None, "action": "clears choices", "api": None},
               {"id": "site.chapter.cta", "type": "link", "label": "Join Connect", "qa_key": None, "action": "opens /app/#/signup", "api": None},
           ], "cases": [
               case("site.chapter.flow", "Choose, copy a remix link, reopen it and reset", "happy", ["Open /chapter.html", "Choose options", "Copy", "Open copied URL", "Reset"], "Choices restored from URL; reset clears", pw("public-forms.spec.js", "Pass the Chapter: choose"), covers=['site.chapter.choice_buttons', 'site.chapter.copy', 'site.chapter.reset']),
               case("site.chapter.tampered", "Tampered remix links degrade safely (no XSS)", "negative", ["Open URL with <img onerror> scene"], "No script runs; defaults shown", pw("public-forms.spec.js", "Pass the Chapter: tampered")),
               case("site.chapter.missing_share", "Missing shared card shows a calm error", "negative", ["Open ?share=<unknown uuid>"], "Error, no studio", pw("public-forms.spec.js", "Pass the Chapter: a missing")),
           ]}
W.append(chapter)

# ---------------------------------------------------------------- control panel
cp = open(os.path.join(ROOT, "control-panel/control_panel/urls.py")).read()
routes = re.findall(r'path\(\s*"([^"]*)",\s*([\w.]+),\s*name="([^"]+)"', cp)
DJ = TESTS["django"]
by_name = collections.defaultdict(list)
for t in DJ:
    for n in t["url_names"]:
        by_name[n].append({"suite": "django", "file": t["file"], "test": t["test"]})
SIDEBAR = set(re.findall(r'href="(/[^"]*)"', open(os.path.join(ROOT, "control-panel/templates/control_panel/base.html")).read()))
SIDEBAR |= {"/" + p for p, v, n in routes if n in set(re.findall(r"\{% url '([a-z_]+)'", open(os.path.join(ROOT, "control-panel/templates/control_panel/base.html")).read()))}
ACTION_RE = re.compile(r"(approve|reject|action|save|delete|toggle|suspend|unsuspend|ban|unban|verify|grant|adjust|control|update|claim|merge|reply|bulk|resolve|decision|cancel|stage|create|new|edit|activate|deactivate|rebuild|exclude|include|reverse|status|role|logout|login|review|preview)$")
DL_RE = re.compile(r"(export|csv|content|attachment|evidence|investor_pack)$")
AREAS = {"analytics": "Analytics", "business": "Business reports", "engagement": "Engagement admin", "moderation": "Moderation", "city-pilot": "City pilot",
         "support": "Support desk", "users": "Members", "billing": "Billing", "verifications": "Verification queue", "appeals": "Appeals",
         "safety": "Safety (SOS)", "account-recovery": "Account recovery", "catalog": "Gift catalog", "config": "Feature flags", "progression": "Progression",
         "client-errors": "Client errors", "growth": "Growth governance", "": "Dashboard", "login": "Auth", "logout": "Auth", "activities": "Activity feed",
         "audit": "Audit log", "events": "Domain events"}
groups = collections.OrderedDict()
for p, view, name in routes:
    seg = p.split("/")[0]
    if seg == "moderation" and len(p.split("/")) > 1:
        seg2 = p.split("/")[1]
        key = f"moderation/{seg2}"
        area_title = "Moderation: " + seg2.replace("-", " ")
    else:
        key = seg
        area_title = AREAS.get(seg, seg)
    groups.setdefault(key, {"title": area_title, "routes": []})["routes"].append((p, view, name))
smoke = {"suite": "django", "runner": "pytest qa/console_smoke (live console)", "file": "qa/console_smoke/test_console_smoke.py", "test": "test_nav_page_loads_cleanly"}
for key, g in groups.items():
    fid = "console." + re.sub(r"[^a-z0-9]+", "_", key.lower()).strip("_") if key else "console.dashboard"
    feat = {"id": fid, "area": "Operator console", "screen": g["title"], "route": "control-panel /" + key + "/", "source_files": sorted({"control-panel/control_panel/" + v.split(".")[0].replace("views", "views") + ".py" if "." in v else "control-panel/control_panel/views.py" for _, v, _ in g["routes"]}),
            "controls": [], "cases": []}
    for p, view, name in g["routes"]:
        kind = "button" if ACTION_RE.search(name) else ("link" if DL_RE.search(name) else "link")
        is_page = kind == "link" and not DL_RE.search(name)
        cid = f"{fid}.{name}"
        feat["controls"].append({"id": cid, "type": kind, "label": name.replace("_", " "), "qa_key": None,
                                 "action": ("POST form → " if kind == "button" else ("download/stream → " if DL_RE.search(name) else "page → ")) + "/" + p + f" ({view})", "api": None})
        tests = by_name.get(name, [])
        if is_page and ("/" + p) in SIDEBAR:
            tests = tests + [smoke]
        if kind == "button":
            feat["cases"].append(case(f"{cid}.performs", f"Operator '{name.replace('_', ' ')}' performs its change and writes an audit entry", "happy",
                                      ["Log in as operator", f"Submit the {name} form (POST /{p})"], "Change persisted via BFF admin API; success message; audit log row; CSRF required",
                                      tests, seed=["operator account", "records for the target (user/ticket/report)"]))
            feat["cases"].append(case(f"{cid}.authz", f"'{name.replace('_', ' ')}' refuses anonymous / non-operator / GET", "negative",
                                      [f"POST /{p} without session", "GET the action URL"], "Redirect to login / 405; nothing changes",
                                      [t for t in tests if re.search(r"anon|login|permission|forbid|csrf|get_|method|refus|denied|requires", t["test"], re.I)], seed=["operator account"]))
        else:
            feat["cases"].append(case(f"{cid}.renders", f"'{name.replace('_', ' ')}' renders with data and handles missing records (404 not 500)", "happy",
                                      ["Log in as operator", f"GET /{p}"], "200 with expected sections; 404 for unknown ids", tests, seed=["operator account", "seeded BFF data"]))
    W.append(feat)

json.dump(W, open(build_path("other_features.json"), "w"), indent=1)
print(len(W), "features", sum(len(f["controls"]) for f in W), "controls", sum(len(f["cases"]) for f in W), "cases")
