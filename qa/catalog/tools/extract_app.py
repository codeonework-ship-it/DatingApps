"""Extract every interactive control in app/lib with label, key, callback and
resolved action (API calls, navigation, sheets, dialogs, pops)."""
import json, os, re, glob, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paths import build_path
from dartscan import *
from backend_scan import match_route

ARB = json.load(open(os.path.join(LIB, "l10n/app_en.arb")))

BUILTIN = {
    # name: (type, callback arg names)
    "IconButton": ("button", ["onPressed", "onLongPress"]),
    "IconButton.filled": ("button", ["onPressed"]),
    "IconButton.filledTonal": ("button", ["onPressed"]),
    "IconButton.outlined": ("button", ["onPressed"]),
    "FilledButton": ("button", ["onPressed", "onLongPress"]),
    "FilledButton.icon": ("button", ["onPressed"]),
    "FilledButton.tonal": ("button", ["onPressed"]),
    "FilledButton.tonalIcon": ("button", ["onPressed"]),
    "OutlinedButton": ("button", ["onPressed", "onLongPress"]),
    "OutlinedButton.icon": ("button", ["onPressed"]),
    "TextButton": ("button", ["onPressed", "onLongPress"]),
    "TextButton.icon": ("button", ["onPressed"]),
    "ElevatedButton": ("button", ["onPressed"]),
    "ElevatedButton.icon": ("button", ["onPressed"]),
    "FloatingActionButton": ("button", ["onPressed"]),
    "FloatingActionButton.extended": ("button", ["onPressed"]),
    "FloatingActionButton.small": ("button", ["onPressed"]),
    "BackButton": ("button", ["onPressed"]),
    "CloseButton": ("button", ["onPressed"]),
    "InkWell": ("button", ["onTap", "onLongPress", "onDoubleTap"]),
    "InkResponse": ("button", ["onTap", "onLongPress"]),
    "GestureDetector": ("gesture", ["onTap", "onLongPress", "onDoubleTap", "onHorizontalDragEnd", "onHorizontalDragUpdate",
                                    "onVerticalDragEnd", "onVerticalDragUpdate", "onPanEnd", "onPanUpdate", "onScaleEnd", "onScaleUpdate", "onTapUp", "onLongPressStart"]),
    "ListTile": ("button", ["onTap", "onLongPress"]),
    "ExpansionTile": ("toggle", ["onExpansionChanged"]),
    "Switch": ("toggle", ["onChanged"]),
    "Switch.adaptive": ("toggle", ["onChanged"]),
    "SwitchListTile": ("toggle", ["onChanged"]),
    "SwitchListTile.adaptive": ("toggle", ["onChanged"]),
    "Checkbox": ("toggle", ["onChanged"]),
    "CheckboxListTile": ("toggle", ["onChanged"]),
    "Radio": ("toggle", ["onChanged"]),
    "RadioListTile": ("toggle", ["onChanged"]),
    "RadioGroup": ("toggle", ["onChanged"]),
    "Slider": ("toggle", ["onChanged", "onChangeEnd"]),
    "RangeSlider": ("toggle", ["onChanged", "onChangeEnd"]),
    "SegmentedButton": ("toggle", ["onSelectionChanged"]),
    "ToggleButtons": ("toggle", ["onPressed"]),
    "TextField": ("field", ["onChanged", "onSubmitted", "onTap", "onEditingComplete"]),
    "TextFormField": ("field", ["onChanged", "onFieldSubmitted", "onTap", "onSaved", "validator"]),
    "DropdownButton": ("menu", ["onChanged"]),
    "DropdownButtonFormField": ("menu", ["onChanged"]),
    "DropdownMenu": ("menu", ["onSelected"]),
    "PopupMenuButton": ("menu", ["onSelected"]),
    "PopupMenuItem": ("menu", ["onTap"]),
    "MenuItemButton": ("menu", ["onPressed"]),
    "CheckedPopupMenuItem": ("menu", ["onTap"]),
    "ChoiceChip": ("toggle", ["onSelected"]),
    "FilterChip": ("toggle", ["onSelected"]),
    "ActionChip": ("button", ["onPressed"]),
    "InputChip": ("toggle", ["onSelected", "onPressed", "onDeleted"]),
    "Chip": ("button", ["onDeleted"]),
    "SnackBarAction": ("button", ["onPressed"]),
    "CupertinoButton": ("button", ["onPressed"]),
    "Dismissible": ("swipe", ["onDismissed", "confirmDismiss"]),
    "RefreshIndicator": ("gesture", ["onRefresh"]),
    "RefreshIndicator.adaptive": ("gesture", ["onRefresh"]),
    "PageView": ("swipe", ["onPageChanged"]),
    "PageView.builder": ("swipe", ["onPageChanged"]),
    "TabBar": ("menu", ["onTap"]),
    "NavigationBar": ("menu", ["onDestinationSelected"]),
    "BottomNavigationBar": ("menu", ["onTap"]),
    "NavigationRail": ("menu", ["onDestinationSelected"]),
    "Draggable": ("gesture", ["onDragEnd", "onDragCompleted"]),
    "LongPressDraggable": ("gesture", ["onDragEnd", "onDragCompleted"]),
    "DragTarget": ("gesture", ["onAcceptWithDetails", "onAccept"]),
    "ReorderableListView": ("gesture", ["onReorder"]),
    "ReorderableListView.builder": ("gesture", ["onReorder"]),
    "InteractiveViewer": ("gesture", ["onInteractionEnd"]),
    "SelectableText": ("field", ["onTap"]),
    "Stepper": ("menu", ["onStepTapped", "onStepContinue", "onStepCancel"]),
    "showModalBottomSheet": ("sheet", []),
    "showDialog": ("sheet", []),
    "showGeneralDialog": ("sheet", []),
    "showDatePicker": ("sheet", []),
    "showTimePicker": ("sheet", []),
    "showMenu": ("menu", []),
    "showCupertinoModalPopup": ("sheet", []),
    "showDateRangePicker": ("sheet", []),
}

GESTURE_TYPE = {"onLongPress": "gesture", "onDoubleTap": "gesture", "onHorizontalDragEnd": "swipe", "onHorizontalDragUpdate": "swipe",
                "onVerticalDragEnd": "swipe", "onVerticalDragUpdate": "swipe", "onPanEnd": "swipe", "onPanUpdate": "swipe",
                "onScaleEnd": "gesture", "onScaleUpdate": "gesture", "onLongPressStart": "gesture", "onReorder": "gesture"}

L10N_RE = re.compile(r"\b(?:l10n|l|t|s|loc|strings|copy|AppLocalizations\.of\([^()]*\)|context\.l10n|appL10n\([^()]*\)|_l10n)\.(\w+)")
STR_RE = re.compile(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"")
KEY_RE = re.compile(r"(?:ValueKey(?:<\w+>)?|Key)\(\s*(?:'([^']*)'|\"([^\"]*)\")")


def l10n_all(text):
    out = []
    for mo in L10N_RE.finditer(text):
        k = mo.group(1)
        if k in ARB and isinstance(ARB[k], str) and (ARB[k], k) not in out:
            out.append((ARB[k], k))
    return out


def l10n_label(text):
    al = l10n_all(text)
    if not al:
        return None, None
    if "?" in mask(text) and len(al) > 1:
        al = list(reversed(al))
    for v, k in al:
        if not v.rstrip().endswith(("…", "...")):
            return v, k
    return al[0]


def str_label(text):
    for mo in STR_RE.finditer(text):
        v = mo.group(1) if mo.group(1) is not None else mo.group(2)
        if v and not v.startswith("qa.") and not v.startswith("/") and not re.match(r"^[\w.]+$", v) or (v and " " in v):
            if v.startswith("assets/") or v.startswith("http"):
                continue
            return v
    return None


ICON_RE = re.compile(r"Icons\.(\w+)")


def label_from(args, src):
    """args list; returns (label, l10n_key, tooltip, icon)"""
    d = {}
    for name, val, _ in args:
        if name:
            d.setdefault(name, val)
    order = ["tooltip", "label", "semanticLabel", "semanticsLabel", "title", "text", "child", "content", "labelText",
             "hintText", "decoration", "message", "subtitle", "icon"]
    for k in order:
        if k in d:
            v = d[k]
            if k in ("semanticLabel", "semanticsLabel", "label") and re.match(r"\s*'qa\.", v):
                continue
            lab, key = l10n_label(v)
            if lab:
                return lab, key
            s = str_label(v)
            if s:
                return s, None
    # positional (e.g. Text child)
    for name, val, _ in args:
        lab, key = l10n_label(val)
        if lab:
            return lab, key
    for name, val, _ in args:
        mo = ICON_RE.search(val)
        if mo:
            return "icon:" + mo.group(1), None
    return None, None


def key_from(args):
    for name, val, _ in args:
        if name == "key":
            mo = KEY_RE.search(val)
            if mo:
                k = mo.group(1) if mo.group(1) is not None else mo.group(2)
                return re.sub(r"\$\{[^}]*\}|\$\w+", "*", k)
    for name, val, _ in args:
        if name in ("semanticLabel", "semanticsLabel", "identifier", "keyPrefix", "label"):
            mo = re.match(r"\s*'(qa\.[^']*)'", val)
            if mo:
                return re.sub(r"\$\{[^}]*\}|\$\w+", "*", mo.group(1))
    return None


QA_HOLDER_RE = re.compile(r"(?:ValueKey(?:<\w+>)?|Key)\(\s*'(qa\.[^']*)'\)|\b(?:label|identifier|semanticsLabel|semanticLabel|keyPrefix)\s*:\s*'(qa\.[^']*)'")

# ---------------------------------------------------------------- files
FILES = {}
for f in sorted(glob.glob(LIB + "/**/*.dart", recursive=True)):
    if "/l10n/" in f or f.endswith(".g.dart") or f.endswith(".freezed.dart"):
        continue
    s = open(f).read()
    m = mask(s)
    FILES[f] = {"src": s, "m": m, "classes": classes(s, m), "methods": methods(s, m), "imports": imports(f, s)}

CLASS_FILE = {}
for f, d in FILES.items():
    for c in d["classes"]:
        CLASS_FILE.setdefault(c["name"], f)


def rel(f):
    return os.path.relpath(f, ROOT)


def import_closure(f, depth=3):
    seen = {f}
    frontier = [f]
    for _ in range(depth):
        nxt = []
        for x in frontier:
            for i in FILES.get(x, {}).get("imports", []):
                if i in FILES and i not in seen:
                    seen.add(i)
                    nxt.append(i)
        frontier = nxt
    return seen


# global: method name -> [(file, start, end)]
GLOBAL_METHODS = {}
for f, d in FILES.items():
    for name, spans in d["methods"].items():
        for sp in spans:
            GLOBAL_METHODS.setdefault(name, []).append((f, sp[0], sp[1]))


def resolve_var_path(f, src, pos, var):
    """resolve '<path>' style API path by looking back for `var = ...`"""
    win = src[max(0, pos - 2500):pos]
    mos = list(re.finditer(r"\b" + re.escape(var.split(".")[-1].split("(")[0]) + r"\s*=\s*([^;]*);", win, re.S))
    if not mos:
        # maybe a function
        fn = var.split("(")[0]
        for (ff, a, b) in GLOBAL_METHODS.get(fn, []):
            if ff == f:
                body = FILES[ff]["src"][a:b]
                lits = [x[0] or x[1] for x in re.findall(r"'(/[^']*)'|\"(/[^\"]*)\"", body)]
                return lits
        return []
    expr = mos[-1].group(1)
    return [x[0] or x[1] for x in re.findall(r"'(/[^']*)'|\"(/[^\"]*)\"", expr)] + \
           [x for x in re.findall(r"'(\$\{_\w+\([^']*)'", expr)]


def expand_helper_prefix(f, path):
    mo = re.match(r"\$\{(_?\w+)\([^)]*\)\}(.*)", path)
    if not mo:
        return path
    fn = mo.group(1)
    for (ff, a, b) in GLOBAL_METHODS.get(fn, []):
        if ff == f:
            body = FILES[ff]["src"][a:b]
            lits = re.findall(r"'(/[^']*)'", body)
            if lits:
                return lits[0] + mo.group(2)
    return path


def api_in_span(f, a, b):
    d = FILES[f]
    out = []
    # helper(path-literal, ...) where helper does api.<verb>(path)
    for mo in re.finditer(r"\b(_?[a-z]\w*)\(\s*'(/[a-z][^']*)'", d["src"][a:b]):
        for (ha, hb) in d["methods"].get(mo.group(1), [])[:1]:
            for c in api_calls(d["src"], d["m"], ha, hb):
                if c["path"].startswith("<"):
                    np_ = norm_app_path(mo.group(2))
                    r = match_route(c["method"], np_) if np_ else None
                    out.append({"method": c["method"], "path": r["path"] if r else np_, "matched": bool(r),
                                "handler": r["handler"] if r else None, "via": rel(f) + ":" + str(line_of(d["src"], a + mo.start()))})
    for c in api_calls(d["src"], d["m"], a, b):
        paths = []
        p = c["path"]
        if p.startswith("<"):
            paths = resolve_var_path(f, d["src"], c["pos"], p[1:-1])
        else:
            paths = [p]
        for p in paths:
            p = expand_helper_prefix(f, p)
            if p.startswith("$base"):
                p = p[5:]
            np_ = norm_app_path(p)
            r = match_route(c["method"] if c["method"] != "UPLOADATTACHMENT" else "POST", np_) if np_ else None
            out.append({"method": c["method"], "path": r["path"] if r else (np_ or p), "matched": bool(r),
                        "handler": r["handler"] if r else None, "via": rel(f) + ":" + str(line_of(d["src"], c["pos"]))})
    return out


CALL_RE = re.compile(r"\b(_?[a-zA-Z]\w*)\s*(?:<[^>()]*>)?\s*\(")
TEAROFF_RE = re.compile(r"(?:^|[\s(,:=>?])(?:widget\.|this\.)?(_?[a-z]\w*)\s*(?=[,)\s;]|$)")
SKIP_NAMES = {"setState", "if", "for", "while", "switch", "return", "print", "debugPrint", "unawaited", "Text", "Icon", "mounted",
              "context", "of", "read", "watch", "notifier", "pop", "push", "then", "catchError", "whenComplete", "toString",
              "map", "where", "toList", "contains", "add", "remove", "isEmpty", "isNotEmpty", "trim", "copyWith", "maybeOf",
              "showSnackBar", "hideCurrentSnackBar", "SnackBar", "length", "call", "invalidate", "refresh", "listen", "build",
              "addPostFrameCallback", "dispose", "clear", "first", "last", "join", "split", "format", "parse", "tryParse"}


def enclosing_class(f, pos):
    best = None
    for c in FILES[f]["classes"]:
        if c["start"] <= pos <= c["end"]:
            if best is None or c["start"] > best["start"]:
                best = c
    return best


def class_fields(f, cls):
    if not cls:
        return set()
    body = FILES[f]["src"][cls["start"]:cls["end"]]
    return set(re.findall(r"final\s+[\w<>?,\s()]+?\s+(\w+)\s*;", body))


def state_widget_class(f, cls):
    """for _FooState extends State<Foo> return Foo class dict."""
    if not cls:
        return None
    mo = re.match(r"(?:ConsumerState|State)<(\w+)>", cls["extends"] or "")
    if not mo:
        return None
    wf = CLASS_FILE.get(mo.group(1))
    if not wf:
        return None
    for c in FILES[wf]["classes"]:
        if c["name"] == mo.group(1):
            return (wf, c)
    return None


def instantiation_args(cls_name, field, home_file):
    """Find `ClassName(... field: value ...)` occurrences; returns list of (file, value_text, value_pos)."""
    out = []
    files = [home_file] if cls_name.startswith("_") else list(FILES.keys())
    pat = re.compile(r"(?<![\w.])" + re.escape(cls_name) + r"\s*\(")
    for f in files:
        d = FILES[f]
        if cls_name not in d["src"]:
            continue
        for mo in pat.finditer(d["m"]):
            pre = d["m"][max(0, mo.start() - 12):mo.start()]
            if re.search(r"(class|extends|const)\s*$", pre) and "const" not in pre:
                continue
            if re.search(r"\bclass\s+$", pre):
                continue
            o = mo.end() - 1
            c = match_close(d["m"], o)
            for name, val, vpos in top_level_args(d["src"], d["m"], o, c):
                if name == field:
                    out.append((f, val, vpos))
    return out


PROVIDER_CLASS = {}
_GEN = {g: {"src": open(g).read()} for g in glob.glob(LIB + "/**/*.g.dart", recursive=True)}
for _f, _d in list(FILES.items()) + list(_GEN.items()):
    for _mo in re.finditer(r"final\s+(\w+)\s*=\s*\w*Provider(?:\.\w+)*\s*<\s*(\w+)", _d["src"]):
        PROVIDER_CLASS[_mo.group(1)] = _mo.group(2)
    for _mo in re.finditer(r"final\s+(\w+)\s*=\s*\w*Provider(?:\.\w+)*(?:<[^(]*>)?\(\s*(\w+)\.new", _d["src"]):
        PROVIDER_CLASS[_mo.group(1)] = _mo.group(2)


def class_methods(cname, mname):
    f = CLASS_FILE.get(cname)
    if not f:
        return []
    cls = next((c for c in FILES[f]["classes"] if c["name"] == cname), None)
    if not cls:
        return []
    spans = [(f, a, b) for (a, b) in FILES[f]["methods"].get(mname, []) if cls["start"] <= a <= cls["end"]]
    if not spans and cls.get("extends"):
        base = re.match(r"(\w+)", cls["extends"])
        if base and base.group(1) != cname and base.group(1) in CLASS_FILE:
            return class_methods(base.group(1), mname)
    return spans


def qualified_targets(f, text, pos):
    """resolve X.m( / ref.read(p.notifier).m( / alias.m( to method spans."""
    out = []
    mt = mask(text)
    for mo in re.finditer(r"\b([A-Z]\w+)\.(_?[a-z]\w*)\b", mt):
        out += class_methods(mo.group(1), mo.group(2))
    for mo in re.finditer(r"ref\s*\.\s*(?:read|watch)\(\s*(\w+)(?:\([^()]*\))?(?:\.notifier)?\s*\)\s*\.\s*(_?[a-z]\w*)", mt):
        c = PROVIDER_CLASS.get(mo.group(1))
        if c:
            out += class_methods(c, mo.group(2))
    # aliases defined in file: v = ref.read(p.notifier)
    aliases = {}
    for mo in re.finditer(r"(\w+)\s*=\s*ref\s*\.\s*(?:read|watch)\(\s*(\w+)(?:\([^()]*\))?(?:\.notifier)?\s*\)\s*;", FILES[f]["m"]):
        c = PROVIDER_CLASS.get(mo.group(2))
        if c:
            aliases[mo.group(1)] = c
    for mo in re.finditer(r"\b([A-Z]\w*(?:Notifier|Repository|Service|Api|Store|Controller|Actions|Client))\??\s+(\w+)\s*[,)=;]", FILES[f]["m"]):
        if mo.group(1) in CLASS_FILE:
            aliases.setdefault(mo.group(2), mo.group(1))
    for mo in re.finditer(r"\b(\w+)\s*\.\s*(_?[a-z]\w*)\b", mt):
        if mo.group(1) in aliases:
            out += class_methods(aliases[mo.group(1)], mo.group(2))
    # methods of own class (incl. notifier internals) referenced bare: handled elsewhere
    return out


GENERIC_NAMES = {"start", "stop", "play", "pause", "resume", "load", "reload", "init", "open", "close", "show", "hide", "save", "send", "submit",
                 "cancel", "reset", "update", "toggle", "select", "fetch", "run", "apply", "retry", "next", "previous", "back", "register",
                 "sync", "attach", "detach", "connect", "disconnect", "set", "get", "remove", "delete", "create", "edit", "complete", "finish"}


def analyse_action(f, text, pos, depth=0, seen=None, ctx_cls=None):
    """Return dict(api=[...], nav=set, sheets=set, effects=set, delegated=[...])"""
    if seen is None:
        seen = set()
    res = {"api": [], "nav": set(), "sheets": set(), "effects": set(), "delegated": set(), "pop_result": False}
    if depth > 5:
        return res
    d = FILES[f]
    # navigation / effects in text itself
    for mo in re.finditer(r"\b([A-Z]\w*(?:Screen|Page))\s*\(", text):
        res["nav"].add(mo.group(1))
    for mo in re.finditer(r"(?:MaterialPageRoute|PageRouteBuilder|CupertinoPageRoute)\s*(?:<[^>]*>)?\s*\([^;]*?builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?([A-Z]\w+)\s*\(", text, re.S):
        res["nav"].add(mo.group(1))
    for mo in re.finditer(r"\b(show\w*(?:Sheet|Dialog|Picker|Menu|Popup)\w*)\s*(?:<[^>()]*>)?\(", text):
        res["sheets"].add(mo.group(1))
    res["has_modal"] = bool(re.search(r"show\w*(?:Sheet|Dialog|Picker)|AlertDialog|BottomSheet", text))
    if re.search(r"Navigator\.(?:of\([^)]*\)\.)?(?:maybeP|p)op\(|\.pop\(|context\.pop\(", text):
        res["effects"].add("closes screen/sheet")
        if re.search(r"Navigator\.(?:maybeP|p)op(?:<[^>]*>)?\(\s*\w+\s*,\s*[^)\s]|\.of\([^()]*\)\s*\.\s*(?:maybeP|p)op(?:<[^>]*>)?\(\s*[^)\s]|\bcontext\.pop\(\s*[^)\s]", text):
            if not re.search(r"pop(?:<[^>]*>)?\(\s*\w*(?:dialog|Dialog|sheet|Sheet)", text):
                res["pop_result"] = True
            res["effects"].add("pops a result to caller")
    if "launchUrl" in text or "openExternal" in text or "launchUrlString" in text:
        res["effects"].add("opens external link")
    if "showSnackBar" in text or "SnackBar(" in text or "showAppSnackBar" in text or "showConnectSnackBar" in text or "Snack" in text:
        res["effects"].add("shows snackbar")
    if "Clipboard.setData" in text:
        res["effects"].add("copies to clipboard")
    if re.search(r"\bShare\.|share\(", text):
        res["effects"].add("opens share sheet")
    if "setState" in text:
        res["effects"].add("updates local state")
    if "ref.invalidate" in text or ".refresh(" in text:
        res["effects"].add("refreshes data")
    if "pickImage" in text or "ImagePicker" in text or "pickFiles" in text:
        res["effects"].add("opens photo/file picker")
    if "HapticFeedback" in text:
        res["effects"].add("haptic")
    if re.search(r"_go\(\s*'(/[^']*)'", text):
        for mo in re.finditer(r"_go\(\s*'(/[^']*)'", text):
            res["nav"].add("web:" + mo.group(1))
    # direct api calls in text
    for c in api_calls(text, mask(text)):
        np_ = norm_app_path(c["path"]) if not c["path"].startswith("<") else None
        r = match_route(c["method"], np_) if np_ else None
        if r or np_:
            res["api"].append({"method": c["method"], "path": r["path"] if r else np_, "matched": bool(r),
                               "handler": r["handler"] if r else None, "via": rel(f)})

    def merge(sub):
        res["api"].extend(sub["api"])
        res["nav"] |= sub["nav"]
        res["sheets"] |= sub["sheets"]
        res["effects"] |= sub["effects"]
        res["delegated"] |= sub["delegated"]
        res["pop_result"] = res["pop_result"] or (sub["pop_result"] and not sub.get("has_modal"))

    cls = ctx_cls if ctx_cls is not None else enclosing_class(f, pos)
    fields = class_fields(f, cls)
    sw = state_widget_class(f, cls)
    if sw:
        fields |= class_fields(sw[0], sw[1])
    names = [mo.group(1) for mo in CALL_RE.finditer(mask(text))]
    tear = [mo.group(1) for mo in TEAROFF_RE.finditer(mask(text))]
    tear += [mo.group(1) for mo in re.finditer(r"\.(_?[a-z]\w*)\b(?!\s*[(<])", mask(text))]
    closure = import_closure(f, 2)
    for (ff, a, b) in qualified_targets(f, text, pos)[:8]:
        if (ff, a) in seen:
            continue
        seen.add((ff, a))
        res["api"].extend(api_in_span(ff, a, b))
        merge(analyse_action(ff, FILES[ff]["src"][a:b], a, depth + 1, seen))
    for name in list(dict.fromkeys(names + tear)):
        if name in SKIP_NAMES or (f, name) in seen:
            continue
        seen.add((f, name))
        # delegated field?
        local_method = name in d["methods"]
        if name in fields and not local_method:
            owner_file, owner = (sw if sw and name in class_fields(sw[0], sw[1]) else (f, cls))
            if owner:
                res["delegated"].add(owner["name"] + "." + name)
                for (ff, val, vpos) in instantiation_args(owner["name"], name, owner_file)[:6]:
                    if (ff, val) in seen:
                        continue
                    seen.add((ff, val))
                    merge(analyse_action(ff, val, vpos, depth + 1, seen))
            continue
        # getter `get onTap => widget.onTap`
        gm = re.search(r"\bget\s+" + re.escape(name) + r"\s*=>\s*(?:widget\.)?(\w+)\s*;", d["src"])
        if gm and gm.group(1) != name and gm.group(1) in fields:
            merge(analyse_action(f, gm.group(1), pos, depth + 1, seen, ctx_cls=cls))
            continue
        spans = []
        if local_method:
            spans = [(f, a, b) for (a, b) in d["methods"][name]]
        elif name in GLOBAL_METHODS and depth < 4 and not name.startswith("_") and name not in GENERIC_NAMES:
            allsp = GLOBAL_METHODS[name]
            spans = [x for x in allsp if x[0] in closure and x[0] != f]
            if not (len(spans) == 1 or (len(spans) == 2 and len(name) >= 8)):
                spans = []
            elif len(name) <= 4 and len(allsp) > 1:
                spans = []
        for (ff, a, b) in spans[:3]:
            body = FILES[ff]["src"][a:b]
            res["api"].extend(api_in_span(ff, a, b))
            sub = analyse_action(ff, body, a, depth + 1, seen)
            merge(sub)
    return res


def own_controls(f):
    d = FILES[f]
    src, m = d["src"], d["m"]
    out = []
    names = sorted(BUILTIN.keys(), key=len, reverse=True)
    pat = re.compile(r"(?<![\w.])(" + "|".join(re.escape(n) for n in names) + r")\s*(?:<[^>()]*>)?\s*\(")
    for mo in pat.finditer(m):
        name = mo.group(1)
        pre = m[max(0, mo.start() - 30):mo.start()]
        if re.search(r"(class|extends|implements|with|is|as)\s+$", pre):
            continue
        o = mo.end() - 1
        c = match_close(m, o)
        args = top_level_args(src, m, o, c)
        ctype, cbs = BUILTIN[name]
        argd = {a[0]: (a[1], a[2]) for a in args if a[0]}
        out.append({"ctor": name, "type": ctype, "start": mo.start(), "end": c, "args": args, "argd": argd, "cbs": cbs})
    return out



def qa_holders(f):
    d = FILES[f]
    out = []
    for mo in QA_HOLDER_RE.finditer(d["src"]):
        key = mo.group(1) or mo.group(2)
        m = d["m"]
        depth = 0
        i = mo.start()
        o = None
        while i > 0:
            i -= 1
            ch = m[i]
            if ch in ")]}":
                depth += 1
            elif ch in "([{":
                if depth == 0:
                    o = i
                    break
                depth -= 1
        if o is None or m[o] != "(":
            continue
        c = match_close(m, o)
        out.append({"key": re.sub(r"\$\{[^}]*\}|\$\w+", "*", key), "start": o, "end": c})
    return out

# ------------------------------------------------------- delegators
FN_FIELD_RE = re.compile(r"final\s+(?:VoidCallback|AsyncCallback|GestureTapCallback|ValueChanged<[^;]*?>|ValueSetter<[^;]*?>|Future<[^;]*?>\s+Function\([^;]*?\)|void\s+Function\([^;]*?\)|FutureOr<[^;]*?>\s+Function\([^;]*?\)|\w+Callback|[\w<>]+\s+Function\([^;]*?\))\??\s+(\w+)\s*;")
FN_PARAM_RE = re.compile(r"(?:VoidCallback|AsyncCallback|ValueChanged<[^,)]*?>|ValueSetter<[^,)]*?>|Future<[^,)]*?>\s+Function\([^)]*\)|void\s+Function\([^)]*\)|\w+Callback|[\w<>]+\s+Function\([^)]*\))\??\s+(\w+)\s*[,)}=]")


def fn_fields(f, cls):
    if not cls:
        return set()
    body = FILES[f]["src"][cls["start"]:cls["end"]]
    return set(FN_FIELD_RE.findall(body)) | {x for x in re.findall(r"final\s+[\w<>?,\s()]+?\s+(on[A-Z]\w*)\s*;", body)}


def owner_of(f, pos):
    """returns ('class', file, cls) for widget class owning pos (State -> widget) or None"""
    cls = enclosing_class(f, pos)
    if not cls:
        return None, None
    sw = state_widget_class(f, cls)
    return (sw if sw else (f, cls)), cls


def enclosing_method(f, pos):
    best = None
    for name, spans in FILES[f]["methods"].items():
        for a, b in spans:
            if a <= pos <= b and (best is None or a > best[1]):
                best = (name, a, b)
    return best


TRIVIAL = SKIP_NAMES | {"HapticFeedback", "selectionClick", "lightImpact", "mediumImpact", "forward", "reverse", "stop", "Future", "delayed",
                        "unfocus", "FocusScope", "requestFocus", "Duration", "Offset", "isLoading", "widget", "null", "true", "false", "return",
                        "final", "if", "await", "async", "const", "var", "else", "try", "finally", "onPressed", "details", "value", "mounted"}


SUBSTANTIVE_RE = re.compile(r"\bref\.|Navigator|showModalBottomSheet|showDialog|\b(?!HapticFeedback|Future|Duration|Theme|MediaQuery|math|Offset|Colors|Icons|Curves|DateTime|Tween|Timer|SystemSound|SemanticsService|Scrollable)[A-Z]\w+\.\w+\(|\.(?:get|post|put|patch|delete)\s*(?:<[^>]*>)?\(")


def _expand_local(f, text, depth, acc):
    mt = mask(text)
    acc.append(mt)
    if depth >= 2:
        return
    for name in set(re.findall(r"\b(_?[a-z]\w*)\b", mt)):
        if name in FILES[f]["methods"] and name != "build":
            for a, b in FILES[f]["methods"][name][:1]:
                if b - a < 2500:
                    _expand_local(f, FILES[f]["src"][a:b], depth + 1, acc)


def refs_in_callback(f, text, pos, fields=None):
    """identifiers referenced in a callback. Local helper methods are followed
    only when they are thin forwarders (no provider/navigation/API work)."""
    mt = mask(text)
    ids = set(re.findall(r"(?:widget\.)?\b([a-zA-Z_]\w*)\b", mt))
    if fields is not None and ids & fields:
        return ids
    acc = []
    _expand_local(f, text, 0, acc)
    joined = "\n".join(acc)
    if SUBSTANTIVE_RE.search(joined):
        return ids
    return set(re.findall(r"(?:widget\.)?\b([a-zA-Z_]\w*)\b", joined))


DELEGATORS = {}  # name -> {file, kind: class|method, fields: {field: {type,label,key}}}


def base_controls(f):
    return own_controls(f)


def delegation_targets(f, ct, cbtext, pos):
    """which function-typed fields/params of the owner does this callback forward to?"""
    (own, cls) = owner_of(f, ct["start"])
    out = []
    if own and own[1]:
        flds = fn_fields(own[0], own[1]) | fn_fields(f, cls)
        ids = refs_in_callback(f, cbtext, pos, flds)
        hit = [x for x in ids if x in flds]
        if hit:
            out.append(("class", own[1]["name"], own[0], hit))
    em = enclosing_method(f, ct["start"])
    if em and em[0] not in ("build",):
        sig = FILES[f]["src"][em[1]:min(em[2], em[1] + 900)]
        sig = sig[:sig.find(")") + 1] if ")" in sig else sig
        # use full param list (balanced)
        mm = FILES[f]["m"]
        o = mm.find("(", em[1])
        c = match_close(mm, o)
        params = set(FN_PARAM_RE.findall(FILES[f]["src"][o:c + 1] + ","))
        params |= set(re.findall(r"\b(on[A-Z]\w*)\b", FILES[f]["src"][o:c + 1]))
        ids = refs_in_callback(f, cbtext, pos, params)
        hit = [x for x in ids if x in params]
        if hit:
            out.append(("method", em[0], f, hit))
    return out


def build_delegators():
    changed = True
    rounds = 0
    while changed and rounds < 6:
        changed = False
        rounds += 1
        for f in FILES:
            for ct in all_raw_controls(f):
                for cb in ct["cbs"]:
                    if cb not in ct["argd"]:
                        continue
                    txt, pos = ct["argd"][cb]
                    for kind, name, home, hit in delegation_targets(f, ct, txt, pos):
                        if name.endswith("Screen") or name.endswith("State") and kind == "class":
                            pass
                        d = DELEGATORS.setdefault(name, {"file": home, "kind": kind, "fields": {}})
                        lab, lk = label_from(ct["args"], FILES[f]["src"])
                        inner = ct.get("inner_fields", {})
                        for h in hit:
                            if h not in d["fields"]:
                                itype = ct["type"]
                                if ct["ctor"] in ("GestureDetector", "InkWell", "InkResponse"):
                                    itype = GESTURE_TYPE.get(cb, "button" if cb in ("onTap", "onTapUp") else "gesture")
                                info = {"type": itype, "label": lab, "l10n_key": lk, "key": key_from(ct["args"])}
                                # inherit from inner delegator
                                if ct["ctor"] in DELEGATORS and cb in DELEGATORS[ct["ctor"]]["fields"]:
                                    ii = DELEGATORS[ct["ctor"]]["fields"][cb]
                                    info = dict(ii)
                                    if lab and len(DELEGATORS[ct["ctor"]]["fields"]) == 1:
                                        info["label"], info["l10n_key"] = lab, lk
                                    info["key"] = key_from(ct["args"]) or ii.get("key")
                                d["fields"][h] = info
                                changed = True


_RAW_CACHE = {}


def all_raw_controls(f):
    """built-in controls + delegator call sites (classes and helper methods)."""
    out = list(own_controls(f))
    if DELEGATORS:
        d = FILES[f]
        src, m = d["src"], d["m"]
        names = [n for n in DELEGATORS if (not n.startswith("_") or DELEGATORS[n]["file"] == f)]
        if names:
            pat = re.compile(r"(?<![\w])(" + "|".join(re.escape(n) for n in sorted(names, key=len, reverse=True)) + r")\s*(?:<[^>()]*>)?\s*\(")
            for mo in pat.finditer(m):
                name = mo.group(1)
                pre = m[max(0, mo.start() - 40):mo.start()]
                if re.search(r"(class|extends|implements|with|is|as|new)\s+$", pre):
                    continue
                o = mo.end() - 1
                if re.match(r"\(\s*\{\s*(super\.key|this\.|required)", m[o:o + 80]) or re.match(r"\(\s*(this\.|super\.)", m[o:o + 30]):
                    continue
                if mo.start() > 0 and m[mo.start() - 1] == ".":
                    # method call on other object: only allow this./self
                    if not pre.endswith("this."):
                        continue
                c = match_close(m, o)
                # method declaration?  `Widget _tile(` followed by { or =>
                rest = m[c + 1:c + 20]
                if re.match(r"\s*(async\s*)?(\{|=>)", rest) and re.search(r"(Widget|void|Future<[^>]*>)\s+$", pre):
                    continue
                args = top_level_args(src, m, o, c)
                argd = {a[0]: (a[1], a[2]) for a in args if a[0]}
                cbs = sorted(DELEGATORS[name]["fields"].keys())
                if not any(cb in argd for cb in cbs):
                    continue
                out.append({"ctor": name, "type": "delegate", "start": mo.start(), "end": c, "args": args, "argd": argd, "cbs": cbs})
    return out


def extract_file(f):
    d = FILES[f]
    src, m = d["src"], d["m"]
    ctrls = all_raw_controls(f)
    holders = qa_holders(f)
    res = []
    for ct in ctrls:
        present = [cb for cb in ct["cbs"] if cb in ct["argd"] and ct["argd"][cb][0].strip() not in ("null",)]
        is_sheet = BUILTIN.get(ct["ctor"], ("",))[0] == "sheet"
        if not is_sheet and ct["type"] != "field" and ct["ctor"] not in ("TabBar", "PageView", "PageView.builder") and not present:
            continue
        cls = enclosing_class(f, ct["start"])
        # key
        key = key_from(ct["args"])
        if not key:
            best = None
            for h in holders:
                if h["start"] <= ct["start"] and ct["end"] <= h["end"] and h["start"] >= ct["start"] - 900:
                    inner = [x for x in ctrls if h["start"] <= x["start"] and x["end"] <= h["end"]]
                    if len(inner) <= 1 or all(x["start"] >= ct["start"] and x["end"] <= ct["end"] for x in inner):
                        if best is None or h["start"] > best["start"]:
                            best = h
            if best:
                key = best["key"]
        label, lkey = label_from(ct["args"], src)
        if not label:
            win = src[max(0, ct["start"] - 400):ct["start"]]
            for x in reversed(list(re.finditer(r"(?:tooltip|message|label|semanticsLabel)\s*:\s*([^,\n]+)", win))):
                lab, lk = l10n_label(x.group(1))
                if lab:
                    label, lkey = lab, lk
                    break
        entries = []
        if is_sheet:
            entries.append(("open", src[ct["start"]:ct["end"] + 1], ct["start"]))
        elif ct["ctor"] in ("TabBar", "PageView", "PageView.builder") and not present:
            entries.append(("onSwipe", "", ct["start"]))
        else:
            for cb in present:
                entries.append((cb, ct["argd"][cb][0], ct["argd"][cb][1]))
            if ct["type"] == "field" and not [e for e in entries if e[0] in ("onChanged", "onSubmitted", "onFieldSubmitted")]:
                entries.insert(0, ("input", "", ct["start"]))
        for cb, text, vpos in entries:
            if cb in ("validator", "onSaved"):
                continue
            # skip if this callback just forwards to the owner's own callback field/param
            if cb not in ("open", "input") and delegation_targets(f, ct, text, vpos):
                continue
            ctype = ct["type"]
            clabel, ckey, cl10n = label, key, lkey
            if ct["type"] == "delegate":
                info = DELEGATORS[ct["ctor"]]["fields"].get(cb, {})
                ctype = info.get("type", "button")
                nf = len(DELEGATORS[ct["ctor"]]["fields"])
                if nf > 1 or not clabel:
                    if info.get("label"):
                        clabel, cl10n = info["label"], info.get("l10n_key")
                if info.get("key") and (nf > 1 or not key_from(ct["args"])):
                    ckey = info.get("key")
            if ct["ctor"] == "GestureDetector" or ct["type"] == "gesture":
                ctype = GESTURE_TYPE.get(cb, "button" if cb in ("onTap", "onTapUp") else ct["type"])
            elif cb in GESTURE_TYPE:
                ctype = GESTURE_TYPE[cb]
            if cb in ("onLongPress", "onDoubleTap", "onRefresh"):
                ctype = "gesture"
            if cb in ("open", "input"):
                act = {"api": [], "nav": set(), "sheets": {ct["ctor"]}, "effects": set(), "delegated": set(), "pop_result": False}
            else:
                act = analyse_action(f, text, vpos)
            em = enclosing_method(f, ct["start"])
            in_sheet = bool(cls and re.search(r"(Sheet|Dialog|Picker|Menu)", cls["name"])) or bool(em and re.match(r"_?show", em[0])) or any(
                BUILTIN.get(x["ctor"], ("",))[0] == "sheet" and x["start"] < ct["start"] < x["end"] for x in ctrls)
            if ckey and not re.search(r"[A-Za-z]{2}", ckey):
                ckey = None
            res.append({
                "in_sheet": in_sheet,
                "file": rel(f), "line": line_of(src, ct["start"]), "ctor": ct["ctor"], "type": ctype, "callback": cb,
                "label": clabel, "l10n_key": cl10n, "key": ckey, "class": cls["name"] if cls else None,
                "alt_labels": [v for v, _ in l10n_all(src[ct["start"]:ct["end"] + 1]) if v != clabel][:6],
                "callback_src": re.sub(r"\s+", " ", text)[:220],
                "api": dedupe_api(act["api"]), "nav": sorted(act["nav"]), "sheets": sorted(act["sheets"]),
                "effects": sorted(act["effects"]), "delegated": sorted(act["delegated"]), "pop_result": act["pop_result"],
            })
    return res


def dedupe_api(lst):
    seen = set()
    out = []
    for a in lst:
        k = (a["method"], a["path"])
        if k in seen:
            continue
        seen.add(k)
        out.append(a)
    return out


build_delegators()

if __name__ == "__main__":
    allc = []
    for f in FILES:
        if "/features/" not in f and "/core/widgets" not in f and "/core/rich_text" not in f:
            continue
        allc.extend(extract_file(f))
    json.dump({"controls": allc, "delegators": {k: {"file": rel(v["file"]), "kind": v["kind"], "fields": v["fields"]} for k, v in DELEGATORS.items()}},
              open(build_path("app_controls.json"), "w"), indent=1)
    print(len(allc), "controls;", len(DELEGATORS), "delegators")
