"""QA Lab in the console (views_qa_lab.py, qa_lab.py): read-only views of
the files QA Lab writes, gated by QA_LAB_ENABLED and the operator's role.

Fixtures are shaped like the real files under qa/results/qa_lab (run
20261003-062043-6521) and qa/catalog/feature_catalog.json: runs/index.json,
runs/<id>/run.json, cases.json, results.json, diff.json, ledger.json and
manual_checks.json. Gap reasons come from qa/lab/coverage_gate.py itself.
"""
from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path

from django.test import Client, override_settings
from django.urls import reverse

from control_panel import qa_lab

from .case_support import ConsoleCaseTest, login, workbook

XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
LATEST = "20261003-062043-6521"
PREVIOUS = "20261002-132900-e1ca"
PASS = "auth.account_recovery.recovery_submit.action"
FAIL = "auth.account_recovery.recovery_username_input.action"
SKIP = "blog.blog_editor.story_toolbar.action"
NOT_RUN = "blog.blog_editor.publish.action"
NOT_AUTOMATED = "web.web_icebreaker_page.x_send.action"
MANUAL = "blog.blog_editor.print_preview.manual"
FAIL_MESSAGE = "Error: expect(locator).toHaveValue(expected) failed\nExpected: \"<script>alert(1)</script>\""


def _case(cid, title, ctype="happy", status="automated", tests=None):
    tests = tests if tests is not None else [{"suite": "flutter", "file": "app/test/features/auth/auth_controls_test.dart",
                                              "test": f"{title} [case:{cid}]", "via": "tag"}]
    return {"id": cid, "title": title, "type": ctype, "steps": ["Sign in as the seeded member", f"Do {title}"],
            "expected": "It works", "seed_needs": ["signed-in member with completed profile"], "automated_by": tests,
            "status": status, "heuristic_status": "not_automated", "mapped_by": "tag" if tests else "none"}


def catalog():
    return {
        "generated": "2026-10-03", "generator": "qa/catalog/tools/regenerate.py", "conventions": {},
        "stats": {"features": 3, "cases": 6},
        "features": [
            {"id": "auth.account_recovery", "area": "Auth & Onboarding", "screen": "AccountRecoveryScreen",
             "route": "opened from: auth", "source_files": [], "controls": [],
             "cases": [_case(PASS, "Submit a recovery code"), _case(FAIL, "Type into Username", ctype="negative")]},
            {"id": "blog.blog_editor", "area": "Blog / Chapters", "screen": "BlogEditorScreen", "route": "/blog/new",
             "source_files": [], "controls": [],
             "cases": [_case(SKIP, "Story toolbar keeps the cursor", ctype="edge"), _case(NOT_RUN, "Publish a chapter"),
                       _case(MANUAL, "Print preview looks right", ctype="layout", status="manual", tests=[])]},
            {"id": "web.web_icebreaker_page", "area": "Web Workspace", "screen": "WebIcebreakerPage", "route": "/web/icebreakers",
             "source_files": [], "controls": [],
             "cases": [_case(NOT_AUTOMATED, "Send an icebreaker", status="not_automated", tests=[])]},
        ],
    }


def _test(cid, status, message=None, suite="flutter"):
    t = {"suite": suite, "file": "website/tests/blog-editor.spec.js" if suite == "playwright" else "app/test/features/auth/auth_controls_test.dart",
         "test": f"proves {cid} [case:{cid}]", "status": status}
    if message:
        t["message"] = message
    return t


def ledger():
    at = "2026-10-03T06:40:09Z"
    return {
        PASS: {"result": "pass", "via": "tag", "run": LATEST, "at": at, "tests": [_test(PASS, "passed")]},
        FAIL: {"result": "fail", "via": "tag", "run": LATEST, "at": at,
               "tests": [_test(FAIL, "passed"), _test(FAIL, "failed", FAIL_MESSAGE, suite="playwright")]},
        SKIP: {"result": "skipped", "via": "tag", "run": LATEST, "at": at, "tests": [_test(SKIP, "skipped")]},
    }


def index_entry(run_id, status="failed", mode="all", by="local_control_admin", day=3, hour=6):
    return {
        "id": run_id, "status": status, "mode": mode, "by": by,
        "startedAt": f"2026-10-{day:02d}T{hour:02d}:20:43Z", "finishedAt": f"2026-10-{day:02d}T{hour:02d}:40:09Z",
        "suites": ["flutter", "playwright", "api_e2e", "go", "django"],
        "tests": {"total": 7176, "passed": 7098, "failed": 10, "skipped": 68},
        "cases": {"inScope": 2807, "pass": 2761, "fail": 39, "skipped": 5, "notRun": 1, "unmatched": 0},
        "coverage": {"automatedPct": 100, "automatedOrManualPct": 100, "verifiedPct": 98.4},
    }


def run_json():
    return {
        "id": LATEST, "status": "failed", "mode": "all", "by": "local_control_admin",
        "startedAt": "2026-10-03T06:20:43Z", "finishedAt": "2026-10-03T06:40:09Z",
        "request": {"suites": ["flutter", "playwright"], "areas": [], "features": [], "cases": None, "seed": True, "rescan": "full"},
        "steps": [
            {"name": "rescan", "status": "passed", "startedAt": "2026-10-03T06:20:43Z", "detail": "{\"cases\": 2807}",
             "finishedAt": "2026-10-03T06:21:30Z"},
            {"name": "flutter", "status": "passed", "startedAt": "2026-10-03T06:21:37Z", "counts": {"passed": 4708, "failed": 0, "skipped": 4},
             "exitCode": 0, "finishedAt": "2026-10-03T06:24:02Z"},
            {"name": "playwright", "status": "failed", "startedAt": "2026-10-03T06:24:02Z", "counts": {"passed": 305, "failed": 6, "skipped": 4},
             "exitCode": 1, "finishedAt": "2026-10-03T06:36:07Z"},
        ],
        "progress": None,
        "summary": {
            "tests": {"total": 7176, "passed": 7098, "failed": 10, "skipped": 68},
            "cases": {"inScope": 2807, "pass": 2761, "fail": 39, "skipped": 5, "notRun": 1, "unmatched": 0},
            "unknownTags": ["site.contact.renders_all_locales"],
            "diff": {"against": PREVIOUS, "fixed": 1, "regressed": 1, "newlyPassing": 1, "newlyFailing": 0, "noLongerRun": 0},
            "coverage": {"automatedPct": 100, "automatedOrManualPct": 100, "verifiedPct": 98.4},
        },
    }


def run_cases():
    return {
        PASS: {"feature": "auth.account_recovery", "area": "Auth & Onboarding", "automated": True, "via": "tag", "result": "pass",
               "tests": [_test(PASS, "passed")]},
        FAIL: {"feature": "auth.account_recovery", "area": "Auth & Onboarding", "automated": True, "via": "tag", "result": "fail",
               "tests": [_test(FAIL, "passed"), _test(FAIL, "failed", FAIL_MESSAGE, suite="playwright")], "testsTotal": 17},
    }


def run_results():
    return [
        {"suite": "flutter", "file": "app/test/core/config/app_runtime_config_test.dart",
         "test": "AppRuntimeConfig uses safe defaults when env is empty", "status": "passed", "durationMs": 14, "cases": []},
        {"suite": "flutter", "file": "app/test/features/auth/auth_controls_test.dart", "test": f"proves {PASS}",
         "status": "passed", "durationMs": 9, "cases": [PASS]},
        {"suite": "playwright", "file": "website/tests/blog-editor.spec.js", "test": "story toolbar keeps the cursor in the story",
         "status": "failed", "durationMs": 17791, "cases": [FAIL, "bad/id"], "message": FAIL_MESSAGE},
        {"suite": "api_e2e", "file": "qa/api_e2e/test_blog.py", "test": "test_blog_skip", "status": "skipped",
         "durationMs": 0, "cases": [SKIP], "nodeid": "qa/api_e2e/test_blog.py::test_blog_skip"},
    ]


def diff_json():
    return {"against": PREVIOUS, "fixed": [PASS], "regressed": [FAIL], "newlyPassing": ["blog.blog_editor.other.action"],
            "newlyFailing": [], "noLongerRun": []}


class QaLabFiles:
    """A temporary QA_LAB_RESULTS_DIR and catalog with real-shaped files."""

    def __init__(self, *, runs=None):
        self.root = Path(tempfile.mkdtemp(prefix="qa-lab-test-"))
        self.results = self.root / "results"
        self.catalog = self.root / "feature_catalog.json"
        self.manual = self.root / "manual_cases.json"
        (self.results / "runs").mkdir(parents=True)
        self.write(self.catalog, catalog())
        self.write(self.manual, {MANUAL: "needs a person to look at print output"})
        self.write(self.results / "ledger.json", ledger())
        self.write(self.results / "manual_checks.json",
                   {MANUAL: [{"result": "fail", "by": "op", "at": "2026-10-01T10:00:00Z"},
                             {"result": "pass", "by": "op", "note": "looks right", "at": "2026-10-02T10:00:00Z"}]})
        index = runs if runs is not None else [index_entry(LATEST), index_entry(PREVIOUS, day=2, hour=13)]
        self.write(self.results / "runs" / "index.json", index)
        run_dir = self.results / "runs" / LATEST
        run_dir.mkdir()
        self.write(run_dir / "run.json", run_json())
        self.write(run_dir / "cases.json", run_cases())
        self.write(run_dir / "results.json", run_results())
        self.write(run_dir / "diff.json", diff_json())

    @staticmethod
    def write(path: Path, data) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data), encoding="utf-8")

    def settings(self, **extra):
        values = {"QA_LAB_ENABLED": True, "QA_LAB_RESULTS_DIR": str(self.results), "QA_LAB_CATALOG_PATH": str(self.catalog),
                  "QA_LAB_MANUAL_CASES_PATH": str(self.manual), "QA_LAB_URL": "http://127.0.0.1:4190/qa-lab/"}
        values.update(extra)
        return override_settings(**values)

    def cleanup(self):
        shutil.rmtree(self.root, ignore_errors=True)


class QaLabCase(ConsoleCaseTest):
    runs = None

    def setUp(self):
        super().setUp()
        self.files = QaLabFiles(runs=self.runs)
        self.addCleanup(self.files.cleanup)
        qa_lab.clear_cache()
        self.addCleanup(qa_lab.clear_cache)
        overrides = self.files.settings()
        overrides.enable()
        self.addCleanup(overrides.disable)
        self.bff()  # the health badge
        self.client = login(Client(), roles=["admin"])

    def sidebar(self, response) -> str:
        html = response.content.decode()
        return html[html.index('<aside class="sidebar'):html.index("</aside>")]


class QaLabOverviewTest(QaLabCase):
    def test_overview_renders_coverage_gate_and_latest_run(self):
        """Automated and verified (gate) %, case status, by-area table, latest run and gaps grouped by the gate's reasons. [case:console.qa_lab.qa_lab.renders]"""
        response = self.client.get(reverse("qa_lab"))
        self.assertEqual(response.status_code, 200)
        ctx = response.context
        self.assertEqual((ctx["total"], ctx["automated"], ctx["verified"]), (6, 4, 2))
        self.assertEqual((ctx["automated_pct"], ctx["verified_pct"]), (66.7, 33.3))
        self.assertEqual({b["key"]: b["count"] for b in ctx["breakdown"]},
                         {"pass": 1, "fail": 1, "not_run": 1, "skipped": 1, "manual": 1, "not_automated": 1})
        self.assertTrue(ctx["gate_loaded"])
        # Gap reasons and their wording come from qa/lab/coverage_gate.py.
        gate = qa_lab.gate_module()
        self.assertEqual({g["reason"]: g["count"] for g in ctx["gaps"]},
                         {"fail": 1, "not_run": 1, "skipped": 1, "not_automated": 1})
        self.assertContains(response, gate.REASONS["fail"])
        self.assertContains(response, gate.REASONS["not_automated"])
        areas = {a["area"]: a for a in ctx["by_area"]}
        self.assertEqual({k: areas["Auth & Onboarding"][k] for k in ("cases", "pass", "fail", "not_run", "gaps")},
                         {"cases": 2, "pass": 1, "fail": 1, "not_run": 0, "gaps": 1})
        self.assertEqual({k: areas["Blog / Chapters"][k] for k in ("cases", "pass", "fail", "not_run", "gaps")},
                         {"cases": 3, "pass": 0, "fail": 0, "not_run": 2, "gaps": 2})
        self.assertEqual(ctx["latest"]["id"], LATEST)
        self.assertContains(response, f'href="{reverse("qa_lab_run_detail", args=[LATEST])}"')
        self.assertContains(response, "7,098 passed")
        self.assertContains(response, "1 regressed")
        self.assertContains(response, f'href="{reverse("qa_lab_case_detail", args=[FAIL])}"')
        self.assertContains(response, 'href="http://127.0.0.1:4190/qa-lab/"')
        self.assertContains(response, "Open QA Lab to start a run")
        self.assertContains(response, f'href="{reverse("qa_lab")}"')  # sidebar entry
        self.assertIn("QA Lab", self.sidebar(response))

    def test_missing_files_show_an_empty_state(self):
        """No catalog, ledger or runs yet: friendly empty states, never a 500. [case:console.qa_lab.qa_lab.renders]"""
        empty = Path(tempfile.mkdtemp(prefix="qa-lab-empty-"))
        self.addCleanup(shutil.rmtree, empty, True)
        with override_settings(QA_LAB_RESULTS_DIR=str(empty / "results"), QA_LAB_CATALOG_PATH=str(empty / "missing.json")):
            overview = self.client.get(reverse("qa_lab"))
            runs = self.client.get(reverse("qa_lab_runs"))
            cases = self.client.get(reverse("qa_lab_cases"))
            run = self.client.get(reverse("qa_lab_run_detail", args=[LATEST]))
        self.assertEqual(overview.status_code, 200)
        self.assertContains(overview, "No QA Lab data yet")
        self.assertContains(overview, "No runs yet")
        self.assertContains(overview, "not found yet")
        self.assertEqual(runs.status_code, 200)
        self.assertContains(runs, "No runs yet")
        self.assertEqual(cases.status_code, 200)
        self.assertContains(cases, "No catalog cases yet")
        self.assertEqual(run.status_code, 404)

    def test_corrupt_files_warn_instead_of_failing(self):
        """Corrupt or wrongly shaped JSON is reported as unreadable and shown as empty; every page still renders. [case:console.qa_lab.qa_lab.renders]"""
        self.files.catalog.write_text("{not json", encoding="utf-8")
        (self.files.results / "ledger.json").write_text("[1, 2]", encoding="utf-8")
        (self.files.results / "runs" / "index.json").write_text('{"runs": "nope"}', encoding="utf-8")
        (self.files.results / "runs" / LATEST / "run.json").write_text("garbage", encoding="utf-8")
        (self.files.results / "runs" / LATEST / "results.json").write_text("{}", encoding="utf-8")
        for name, args in (("qa_lab", []), ("qa_lab_runs", []), ("qa_lab_cases", []), ("qa_lab_run_detail", [LATEST])):
            response = self.client.get(reverse(name, args=args))
            self.assertEqual(response.status_code, 200, name)
            self.assertContains(response, "could not be read", msg_prefix=name)
        overview = self.client.get(reverse("qa_lab"))
        self.assertEqual(overview.context["total"], 0)

    def test_without_the_gate_script_results_come_from_the_ledger(self):
        """If qa/lab/coverage_gate.py cannot be loaded the page says so and still shows ledger results. [case:console.qa_lab.qa_lab.renders]"""
        with override_settings(QA_LAB_GATE_PATH=str(self.files.root / "no_gate.py")):
            response = self.client.get(reverse("qa_lab"))
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.context["gate_loaded"])
        self.assertContains(response, "could not be loaded")
        self.assertEqual(response.context["verified"], 2)


class QaLabRunsTest(QaLabCase):
    runs = ([index_entry(LATEST)]
            + [index_entry(f"202609{d:02d}-101500-{d:04x}", status="passed" if d % 3 else "failed",
                           mode="area" if d % 2 else "all", by="qa_operator" if d % 5 == 0 else "local_control_admin", day=1)
               for d in range(1, 29)]
            + [{"id": "../../etc", "status": "passed"}, "not a dict"])

    def test_runs_render_history(self):
        """The run history lists QA Lab runs newest first; rows with an invalid id are dropped. [case:console.qa_lab.qa_lab_runs.renders]"""
        response = self.client.get(reverse("qa_lab_runs"))
        self.assertEqual(response.status_code, 200)
        page = response.context["page"]
        self.assertEqual(page.total, 29)
        self.assertEqual(page.rows[0]["id"], LATEST)
        self.assertContains(response, f'href="{reverse("qa_lab_run_detail", args=[LATEST])}"')
        self.assertContains(response, "19m 26s")
        self.assertContains(response, "98.4%")
        self.assertNotContains(response, "../../etc")
        self.assertContains(response, "Export Excel")

    def test_runs_filters_search_and_paging(self):
        """Status and mode filters, search and server-side paging; unknown filter values are ignored. [case:console.qa_lab.qa_lab_runs.filters]"""
        response = self.client.get(reverse("qa_lab_runs"), {"page_size": "10", "page": "2"})
        page = response.context["page"]
        self.assertEqual((page.start, page.end, page.total, page.pages), (11, 20, 29, 3))
        self.assertIn("page=3", page.next_url)
        failed = self.client.get(reverse("qa_lab_runs"), {"status": "failed"}).context["page"]
        self.assertEqual(failed.total, 1 + sum(1 for d in range(1, 29) if d % 3 == 0))
        self.assertTrue(all(r["status"] == "failed" for r in failed.rows))
        both = self.client.get(reverse("qa_lab_runs"), {"status": "passed", "mode": "area"}).context["page"]
        self.assertTrue(both.rows and all(r["status"] == "passed" and r["mode"] == "area" for r in both.rows))
        search = self.client.get(reverse("qa_lab_runs"), {"q": "qa_operator"}).context["page"]
        self.assertEqual(search.total, 5)
        ignored = self.client.get(reverse("qa_lab_runs"), {"status": "exploded"}).context["page"]
        self.assertEqual(ignored.total, 29)
        past_end = self.client.get(reverse("qa_lab_runs"), {"page": "99", "page_size": "10"}).context["page"]
        self.assertEqual(past_end.query.page, 3)

    def test_runs_excel_export(self):
        """Export Excel holds every filtered run with its test, case and coverage numbers. [case:console.qa_lab.qa_lab_runs.export]"""
        response = self.client.get(reverse("qa_lab_runs"), {"export": "xlsx", "status": "failed", "page": "2"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], XLSX)
        self.assertIn('filename="qa-lab-runs-', response["Content-Disposition"])
        sheets, about = workbook(response)
        rows = sheets["QA Lab runs"]
        self.assertEqual(rows[0][:4], ("Run", "Status", "Mode", "By"))
        self.assertEqual(len(rows) - 1, 1 + sum(1 for d in range(1, 29) if d % 3 == 0))
        first = dict(zip(rows[0], rows[1]))
        self.assertEqual((first["Run"], first["Tests passed"], first["Cases fail"], first["Verified %"]), (LATEST, 7098, 39, 98.4))
        self.assertEqual(about["Filter: status"], "failed")


class QaLabRunDetailTest(QaLabCase):
    def test_run_detail_shows_summary_suites_failures_and_diff(self):
        """Summary, per-step and per-suite counts, failed tests with escaped messages, and the diff against the previous run. [case:console.qa_lab.qa_lab_run_detail.renders]"""
        response = self.client.get(reverse("qa_lab_run_detail", args=[LATEST]))
        self.assertEqual(response.status_code, 200)
        ctx = response.context
        self.assertEqual(ctx["head"]["status"], "failed")
        self.assertEqual({s["suite"]: (s["total"], s["passed"], s["failed"], s["skipped"]) for s in ctx["suites"]},
                         {"flutter": (2, 2, 0, 0), "playwright": (1, 0, 1, 0), "api_e2e": (1, 0, 0, 1)})
        self.assertContains(response, "4,708")  # flutter step counts
        self.assertContains(response, "story toolbar keeps the cursor in the story")
        self.assertContains(response, "&lt;script&gt;alert(1)&lt;/script&gt;")
        self.assertNotContains(response, "<script>alert(1)</script>")
        self.assertEqual(ctx["failed_total"], 1)
        diff = {d["key"]: d["count"] for d in ctx["diff_lists"]}
        self.assertEqual(diff, {"regressed": 1, "newlyFailing": 0, "fixed": 1, "newlyPassing": 1, "noLongerRun": 0})
        self.assertContains(response, f'href="{reverse("qa_lab_case_detail", args=[FAIL])}"')
        self.assertContains(response, "bad/id")  # shown, but not linked
        self.assertEqual(ctx["failing_cases_total"], 1)
        self.assertContains(response, "site.contact.renders_all_locales")
        self.assertContains(response, PREVIOUS)

    def test_invalid_or_unknown_run_ids_are_404(self):
        """Run ids must match QA Lab's format and exist; nothing else reaches the file system. [case:console.qa_lab.qa_lab_run_detail.renders]"""
        for bad in ("..", "20261003-062043-652", "20261003-062043-ZZZZ", "..%2F..%2Fetc", "20261003_062043_6521", "20261003-062043-6521x"):
            self.assertEqual(self.client.get(f"/qa-lab/runs/{bad}/").status_code, 404, bad)
        self.assertEqual(self.client.get(reverse("qa_lab_run_detail", args=["20261003-062043-ffff"])).status_code, 404)
        self.assertIsNone(qa_lab.run_dir("../runs"))

    def test_latest_redirects_to_the_newest_run(self):
        """/qa-lab/runs/latest/ is a stable link to the newest run (404 when there are none). [case:console.qa_lab.qa_lab_run_detail.renders]"""
        response = self.client.get(reverse("qa_lab_run_detail", args=["latest"]))
        self.assertRedirects(response, reverse("qa_lab_run_detail", args=[LATEST]))
        QaLabFiles.write(self.files.results / "runs" / "index.json", [])
        self.assertEqual(self.client.get(reverse("qa_lab_run_detail", args=["latest"])).status_code, 404)

    def test_detail_without_diff_still_renders(self):
        """A run with no diff.json (the first run) renders without a diff. [case:console.qa_lab.qa_lab_run_detail.renders]"""
        (self.files.results / "runs" / LATEST / "diff.json").unlink()
        response = self.client.get(reverse("qa_lab_run_detail", args=[LATEST]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "No diff recorded")


class QaLabCasesTest(QaLabCase):
    def test_cases_render_with_result_and_gate(self):
        """Every catalog case with its result, gate verdict and test count. [case:console.qa_lab.qa_lab_cases.renders]"""
        response = self.client.get(reverse("qa_lab_cases"))
        self.assertEqual(response.status_code, 200)
        page = response.context["page"]
        self.assertEqual(page.total, 6)
        rows = {r["id"]: r for r in page.rows}
        self.assertEqual({k: rows[k]["result"] for k in rows},
                         {PASS: "pass", FAIL: "fail", SKIP: "skipped", NOT_RUN: "not_run", MANUAL: "manual", NOT_AUTOMATED: "not_automated"})
        self.assertTrue(rows[MANUAL]["ok"])  # manual and its last check passed
        self.assertEqual(rows[FAIL]["reason"], "fail")
        self.assertContains(response, f'href="{reverse("qa_lab_case_detail", args=[PASS])}"')

    def test_case_filters_search_and_paging(self):
        """Area, result, kind and gap-reason filters, search over ids, titles and test files, and paging. [case:console.qa_lab.qa_lab_cases.filters]"""
        get = lambda **q: self.client.get(reverse("qa_lab_cases"), q).context["page"]  # noqa: E731
        self.assertEqual([r["id"] for r in get(area="Auth & Onboarding").rows], [PASS, FAIL])
        self.assertEqual([r["id"] for r in get(result="fail").rows], [FAIL])
        self.assertEqual([r["id"] for r in get(result="not_run").rows], [NOT_RUN])
        self.assertEqual([r["id"] for r in get(result="skipped").rows], [SKIP])
        self.assertEqual([r["id"] for r in get(result="manual").rows], [MANUAL])
        self.assertEqual([r["id"] for r in get(kind="negative").rows], [FAIL])
        self.assertEqual([r["id"] for r in get(reason="not_automated").rows], [NOT_AUTOMATED])
        self.assertEqual([r["id"] for r in get(q="icebreaker send").rows], [NOT_AUTOMATED])
        self.assertEqual(get(q="auth_controls_test.dart").total, 4)  # test file names are searchable
        self.assertEqual(get(area="Blog / Chapters", result="pass").total, 0)
        self.assertEqual(get(area="No such area").total, 6)  # unknown choice ignored
        paged = get(page_size="10", page="1")
        self.assertEqual((paged.start, paged.end, paged.total), (1, 6, 6))
        response = self.client.get(reverse("qa_lab_cases"))
        self.assertContains(response, '<option value="Web Workspace">Web Workspace</option>')
        self.assertContains(response, '<option value="layout">Layout</option>')

    def test_cases_excel_export(self):
        """Export Excel holds every filtered case with result, gate verdict and reason. [case:console.qa_lab.qa_lab_cases.export]"""
        response = self.client.get(reverse("qa_lab_cases"), {"export": "xlsx", "area": "Blog / Chapters"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], XLSX)
        self.assertIn('filename="qa-lab-cases-', response["Content-Disposition"])
        sheets, about = workbook(response)
        rows = sheets["QA Lab cases"]
        header = rows[0]
        self.assertEqual(header[:3], ("Case", "Title", "Area"))
        body = {r[0]: dict(zip(header, r)) for r in rows[1:]}
        self.assertEqual(set(body), {SKIP, NOT_RUN, MANUAL})
        self.assertEqual((body[MANUAL]["Result"], body[MANUAL]["Verified (gate)"]), ("Manual", "Yes"))
        self.assertEqual(body[SKIP]["Gap reason"], qa_lab.gate_module().REASONS["skipped"])
        self.assertEqual(about["Filter: area"], "Blog / Chapters")


class QaLabCaseDetailTest(QaLabCase):
    def test_case_detail_shows_proving_tests_and_latest_results(self):
        """The tests that prove a case, its latest results (with the failure message escaped) and recent runs. [case:console.qa_lab.qa_lab_case_detail.renders]"""
        response = self.client.get(reverse("qa_lab_case_detail", args=[FAIL]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Type into Username")
        self.assertContains(response, f"Type into Username [case:{FAIL}]")  # automated_by
        self.assertContains(response, "&lt;script&gt;alert(1)&lt;/script&gt;")
        self.assertContains(response, f'href="{reverse("qa_lab_run_detail", args=[LATEST])}"')
        history = response.context["history"]
        self.assertEqual([(h["run"]["id"], h["result"], h["tests_total"]) for h in history], [(LATEST, "fail", 17)])
        self.assertContains(response, "17 in total")
        self.assertEqual(response.context["row"]["reason"], "fail")

    def test_manual_case_shows_its_last_check(self):
        """A manual case shows the latest checklist mark. [case:console.qa_lab.qa_lab_case_detail.renders]"""
        response = self.client.get(reverse("qa_lab_case_detail", args=[MANUAL]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "looks right")
        self.assertContains(response, "Verified (gate)")

    def test_unknown_case_is_404(self):
        """Unknown or malformed case ids are a 404. [case:console.qa_lab.qa_lab_case_detail.renders]"""
        self.assertEqual(self.client.get(reverse("qa_lab_case_detail", args=["no.such.case"])).status_code, 404)
        self.assertEqual(self.client.get("/qa-lab/cases/%3Cscript%3E/").status_code, 404)


class QaLabGateTest(QaLabCase):
    URLS = (("qa_lab", []), ("qa_lab_runs", []), ("qa_lab_cases", []), ("qa_lab_run_detail", [LATEST]),
            ("qa_lab_case_detail", [PASS]))

    def test_disabled_flag_hides_the_section(self):
        """QA_LAB_ENABLED=False: every QA Lab URL is a 404 and the sidebar has no entry. [case:console.qa_lab.qa_lab.renders]"""
        with override_settings(QA_LAB_ENABLED=False):
            for name, args in self.URLS:
                self.assertEqual(self.client.get(reverse(name, args=args)).status_code, 404, name)
            response = self.client.get(reverse("activity_feed"))
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("/qa-lab/", self.sidebar(response))

    def test_unset_flag_follows_debug(self):
        """Unset QA_LAB_ENABLED is on only when DEBUG is. [case:console.qa_lab.qa_lab.renders]"""
        with override_settings(QA_LAB_ENABLED=None, DEBUG=False):
            self.assertEqual(self.client.get(reverse("qa_lab")).status_code, 404)
        with override_settings(QA_LAB_ENABLED=None, DEBUG=True):
            self.assertEqual(self.client.get(reverse("qa_lab")).status_code, 200)

    def test_roles_admin_ops_admin_and_analyst_read_others_are_refused(self):
        """Admin, ops_admin and analyst may read QA Lab; other or unknown roles get a 403 and no sidebar entry. [case:console.qa_lab.qa_lab.renders]"""
        for role in ("admin", "ops_admin", "analyst"):
            client = login(Client(), roles=[role])
            for name, args in self.URLS:
                self.assertEqual(client.get(reverse(name, args=args)).status_code, 200, f"{role} {name}")
            self.assertIn("/qa-lab/", self.sidebar(client.get(reverse("activity_feed"))), role)
        for roles in (["support"], ["finance"], ["trust_safety"], ["moderator"], [], None):
            client = login(Client(), roles=roles)
            for name, args in self.URLS:
                response = client.get(reverse(name, args=args))
                self.assertEqual(response.status_code, 403, f"{roles} {name}")
            self.assertContains(response, "not available to your role", status_code=403)
            self.assertNotIn("/qa-lab/", self.sidebar(response), roles)

    def test_anonymous_and_post_are_refused(self):
        """Anonymous visitors go to the login page; the pages are read-only (POST is 405). [case:console.qa_lab.qa_lab.renders]"""
        anonymous = Client().get(reverse("qa_lab"))
        self.assertEqual(anonymous.status_code, 302)
        self.assertTrue(anonymous["Location"].startswith("/login/?next="))
        for name, args in self.URLS:
            self.assertEqual(self.client.post(reverse(name, args=args)).status_code, 405, name)
