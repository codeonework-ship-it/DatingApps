import json
import re
import subprocess
import time
from pathlib import Path
import datetime
import xml.etree.ElementTree as ET

ROOT = Path("/Users/anandsadasivan/Documents/Workspaces/Development/GitHub/Dating apps")
ARTIFACT_DIR = ROOT / "documents" / "codex" / "artifacts" / "ui_smoke_20260301"
ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

REPORT_JSON = ROOT / "documents" / "codex" / f"UI_SMOKE_CHECKLIST_{datetime.datetime.now(datetime.UTC).strftime('%Y%m%dT%H%M%SZ')}.json"
REPORT_MD = ROOT / "documents" / "codex" / f"UI_SMOKE_CHECKLIST_{datetime.datetime.now(datetime.UTC).strftime('%Y%m%dT%H%M%SZ')}.md"

BOUNDS_RE = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")


def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)


def adb(cmd):
    full = f"adb -s emulator-5554 {cmd}"
    result = run(full)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def wait_for_device():
    for _ in range(30):
        code, out, _ = adb("get-state")
        if code == 0 and "device" in out:
            return True
        time.sleep(1)
    return False


def dump_ui_xml(path: Path):
    adb("shell uiautomator dump /sdcard/window_dump.xml")
    adb(f"pull /sdcard/window_dump.xml '{path}'")


def parse_bounds(bounds: str):
    match = BOUNDS_RE.fullmatch(bounds.strip())
    if not match:
        return None
    x1, y1, x2, y2 = map(int, match.groups())
    return x1, y1, x2, y2


def center(bounds: str):
    parsed = parse_bounds(bounds)
    if not parsed:
        return None
    x1, y1, x2, y2 = parsed
    return (x1 + x2) // 2, (y1 + y2) // 2


def find_node_by_text_or_desc(root, candidates):
    lc = {item.lower() for item in candidates}
    for node in root.iter("node"):
        text = (node.attrib.get("text") or "").strip().lower()
        desc = (node.attrib.get("content-desc") or "").strip().lower()
        if text in lc or desc in lc:
            return node
    for node in root.iter("node"):
        text = (node.attrib.get("text") or "").strip().lower()
        desc = (node.attrib.get("content-desc") or "").strip().lower()
        for item in lc:
            if item and (item in text or item in desc):
                return node
    return None


def has_any_label(root, labels):
    return find_node_by_text_or_desc(root, labels) is not None


def get_first_edit_text(root):
    for node in root.iter("node"):
        if (node.attrib.get("class") or "") == "android.widget.EditText":
            return node
    return None


def tap_node(node):
    b = node.attrib.get("bounds", "")
    point = center(b)
    if point is None:
        return False, "invalid_bounds"
    x, y = point
    return tap_absolute(x, y)


def tap_by_labels(labels):
    xml_path = ARTIFACT_DIR / "tmp_ui.xml"
    dump_ui_xml(xml_path)
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        node = find_node_by_text_or_desc(root, labels)
        if node is None:
            return False, "node_not_found"
        b = node.attrib.get("bounds", "")
        point = center(b)
        if point is None:
            return False, "invalid_bounds"
        x, y = point
        adb(f"shell input tap {x} {y}")
        time.sleep(1.2)
        return True, f"tap_{x}_{y}"
    except Exception as error:
        return False, str(error)


def tap_absolute(x: int, y: int):
    adb(f"shell input tap {x} {y}")
    time.sleep(1.2)
    return True, f"tap_{x}_{y}"


def tap_bottom_tab(index: int, total_tabs: int = 6):
    code, out, _ = adb("shell wm size")
    width = 1080
    height = 2400
    if code == 0 and "Physical size" in out:
        try:
            size = out.split(":", 1)[1].strip()
            width, height = [int(item) for item in size.split("x")]
        except Exception:
            pass
    x = int((index + 0.5) * (width / total_tabs))
    y = height - 95
    return tap_absolute(x, y)


def complete_mock_sign_in(max_attempts: int = 8):
    actions = [
        ["Start Secure Sign In", "Secure Sign In", "Sign In"],
        ["Verify & Continue", "Continue", "Next", "Verify"],
        ["Skip", "Maybe later", "Not now"],
    ]
    for _ in range(max_attempts):
        xml_path = ARTIFACT_DIR / "tmp_ui.xml"
        dump_ui_xml(xml_path)
        try:
            tree = ET.parse(xml_path)
            root = tree.getroot()

            if has_any_label(root, ["Discover", "Matches", "Engagement", "Friends", "Settings"]):
                return True

            if has_any_label(root, ["Enter mobile number", "Send OTP"]):
                edit = get_first_edit_text(root)
                if edit is not None:
                    tap_node(edit)
                    adb("shell input keyevent KEYCODE_MOVE_END")
                    adb("shell input keyevent KEYCODE_DEL")
                    adb("shell input text 9876543210")
                    time.sleep(0.6)
                tap_by_labels(["Send OTP"])
                time.sleep(1.2)

            if has_any_label(root, ["Enter verification code", "Verify & Continue"]):
                edit = get_first_edit_text(root)
                if edit is not None:
                    tap_node(edit)
                    adb("shell input text 123456")
                    time.sleep(0.6)
                tap_by_labels(["Verify & Continue", "Verify", "Continue"])
                time.sleep(2)
        except Exception:
            pass

        for label_group in actions:
            tapped, _ = tap_by_labels(label_group)
            if tapped:
                time.sleep(1.5)

        dump_ui_xml(xml_path)
        try:
            tree = ET.parse(xml_path)
            root = tree.getroot()
            if has_any_label(root, ["Discover", "Matches", "Engagement", "Friends", "Settings"]):
                return True
        except Exception:
            pass
    return False


def screenshot(name):
    remote = f"/sdcard/{name}.png"
    local = ARTIFACT_DIR / f"{name}.png"
    adb(f"shell screencap -p {remote}")
    adb(f"pull {remote} '{local}'")
    return local


def ensure_app_foreground():
    code, out, _ = adb("shell dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'")
    if code != 0:
        return False, "focus_check_failed"
    if "dating" in out.lower() or "flutter" in out.lower() or "verified" in out.lower():
        return True, "already_foreground"
    adb("shell input keyevent KEYCODE_HOME")
    time.sleep(0.8)
    ok, reason = tap_by_labels(["Verified Dating App", "verified_dating_app", "Dating apps"])
    if not ok:
        return False, f"launch_icon_not_found:{reason}"
    time.sleep(2)
    return True, "launched"


def main():
    report = {
        "generated_at": datetime.datetime.now(datetime.UTC).isoformat(),
        "device": "emulator-5554",
        "steps": [],
    }

    if not wait_for_device():
        report["fatal"] = "emulator_not_ready"
        REPORT_JSON.write_text(json.dumps(report, indent=2))
        REPORT_MD.write_text("# UI Smoke Checklist\n\n- Fatal: emulator not ready\n")
        print(REPORT_JSON)
        print("ALL_PASSED", False)
        return

    ok, reason = ensure_app_foreground()
    report["steps"].append({"screen": "App Foreground", "pass": ok, "detail": reason})
    signed_in = complete_mock_sign_in()
    report["steps"].append({"screen": "Mock Sign In", "pass": signed_in, "detail": "completed" if signed_in else "not_confirmed"})

    nav_plan = [
        ("Discover", "01_discover", 0),
        ("Matches", "02_matches", 1),
        ("Engagement", "03_engagement", 2),
        ("Friends", "04_friends", 3),
    ]

    for name, shot, tab_index in nav_plan:
        tapped, detail = tap_bottom_tab(tab_index)
        image = screenshot(shot)
        report["steps"].append(
            {
                "screen": name,
                "pass": tapped,
                "detail": detail,
                "screenshot": str(image),
            }
        )

    tap_bottom_tab(2)
    rooms_tapped, rooms_detail = tap_by_labels(["Conversation Rooms", "Rooms"])
    if not rooms_tapped:
        tap_bottom_tab(4)
        rooms_tapped, rooms_detail = tap_by_labels(["Conversation Rooms", "Rooms"])
    rooms_image = screenshot("05_rooms")
    report["steps"].append(
        {
            "screen": "Rooms",
            "pass": rooms_tapped,
            "detail": rooms_detail,
            "screenshot": str(rooms_image),
        }
    )

    all_passed = all(step.get("pass", False) for step in report["steps"])
    report["all_passed"] = all_passed

    REPORT_JSON.write_text(json.dumps(report, indent=2))

    lines = [
        "# UI Smoke Checklist",
        "",
        f"- Generated: {report['generated_at']}",
        f"- Device: {report['device']}",
        f"- All passed: {all_passed}",
        "",
        "| Screen | Result | Evidence | Detail |",
        "|---|---|---|---|",
    ]
    for step in report["steps"]:
        evidence = step.get("screenshot", "")
        lines.append(
            f"| {step['screen']} | {'Pass' if step['pass'] else 'Fail'} | {evidence} | {step.get('detail','')} |"
        )
    REPORT_MD.write_text("\n".join(lines) + "\n")

    print(REPORT_JSON)
    print(REPORT_MD)
    print("ALL_PASSED", all_passed)


if __name__ == "__main__":
    main()
