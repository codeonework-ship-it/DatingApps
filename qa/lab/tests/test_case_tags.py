"""Static [case:...] tag scanner (qa/catalog/tools/case_tags.py)."""
import os
import sys
import textwrap

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "qa", "catalog", "tools"))

import case_tags as C  # noqa: E402


def test_tags_in_name_accepts_several_and_shorthand():
    assert C.tags_in_name("Love works [case:swipe.love.action]") == ["swipe.love.action"]
    assert C.tags_in_name("x [case:a.b] [case: c-d ] [case:a.b]") == ["a.b", "c-d"]
    assert C.tags_in_name("[case:a.b, c.d e.f]") == ["a.b", "c.d", "e.f"]
    assert C.tags_in_name("no tag [case:] [case:!!]") == []


def test_dart_tags_follow_group_and_test_names():
    src = textwrap.dedent('''
        void main() {
          group('Dock [case:swipe.dock.layout]', () {
            testWidgets('Love sends one like [case:swipe.love.action]', (tester) async {
              await tester.tap(find.text('[case:not.a.name]'));
            });
            test("plain test", () {});
          });
          testWidgets(
            'multi '
            'line [case:x.y]',
            (tester) async {},
          );
          // testWidgets('commented out [case:ignored]', ...)
        }
    ''')
    got = {t["name"]: t["cases"] for t in C.dart_tags(src)}
    assert got["Love sends one like [case:swipe.love.action]"] == ["swipe.dock.layout", "swipe.love.action"]
    assert got["plain test"] == ["swipe.dock.layout"]
    assert got["multi line [case:x.y]"] == ["x.y"]
    assert all("ignored" not in c for cs in got.values() for c in cs)
    full = [t["test"] for t in C.dart_tags(src)]
    assert "Dock [case:swipe.dock.layout] Love sends one like [case:swipe.love.action]" in full


def test_js_tags_include_describe_titles():
    src = textwrap.dedent('''
        import {test, expect} from '@playwright/test';
        test.describe('gifts [case:chat.gift.layout]', () => {
          test('free rose [case:chat.gift.free]', async ({page}) => {
            await page.getByText('[case:not.this]').click();
          });
        });
        test(`template ${1} [case:t.x]`, async () => {});
        test.skip('later [case:s.y]', async () => {});
    ''')
    got = {t["name"]: t["cases"] for t in C.js_tags(src)}
    assert got["free rose [case:chat.gift.free]"] == ["chat.gift.layout", "chat.gift.free"]
    assert got["template ${1} [case:t.x]"] == ["t.x"]
    assert got["later [case:s.y]"] == ["s.y"]


def test_pytest_markers_on_function_class_and_module():
    src = textwrap.dedent('''
        import pytest
        pytestmark = [pytest.mark.journey("x"), pytest.mark.case("mod.level")]

        @pytest.mark.case("a.one", "a.two")
        def test_a():
            pass

        @pytest.mark.case("cls.level")
        class TestK:
            @pytest.mark.case("k.y")
            def test_y(self):
                pass

        def helper():
            pass
    ''')
    got = {t["nodeid_suffix"]: t["cases"] for t in C.pytest_tags(src)}
    assert got == {"test_a": ["mod.level", "a.one", "a.two"], "TestK::test_y": ["mod.level", "cls.level", "k.y"]}


def test_go_comments_must_sit_directly_above_the_func():
    src = textwrap.dedent('''
        package mobile

        // case: auth.signin.api_contract
        // TestLogin checks the happy path.
        // case: auth.signin.negative, auth.x
        func TestLogin(t *testing.T) {
        }

        // case: orphan.not.attached

        func TestOther(t *testing.T) {}
    ''')
    got = {t["test"]: t["cases"] for t in C.go_tags(src)}
    assert got == {"TestLogin": ["auth.signin.api_contract", "auth.signin.negative", "auth.x"], "TestOther": []}


def test_django_comments_above_method_and_decorators():
    src = textwrap.dedent('''
        class LoginTest(TestCase):
            # case: console.login.login.renders
            @override_settings(DEBUG=False)
            def test_login_page(self):
                pass

            def test_untagged(self):
                pass
    ''')
    got = {t["test"]: t["cases"] for t in C.django_tags(src)}
    assert got == {"LoginTest.test_login_page": ["console.login.login.renders"], "LoginTest.test_untagged": []}


def test_pytest_eval_resolves_constants_params_and_helpers():
    src = textwrap.dedent('''
        from __future__ import annotations
        from dataclasses import dataclass
        import pytest
        from journeys import match  # outside the stdlib: inert during the scan
        from client import CONFIG

        PAIR = ("c.one", "c.two")
        KEYS = [("k1", "n.k1"), ("k2", "n.k2")]
        TABLE = {"t.a": [1], "t.b": [2]}

        @dataclass(frozen=True)
        class D:
            name: str
            extra: tuple = ()

        def _ids(name, extra=()):
            return tuple(k for k in TABLE if k.endswith(name)) + tuple(extra)

        def _param(d):
            return pytest.param(d, id=d.name, marks=[pytest.mark.xfail(strict=True), pytest.mark.case(*_ids(d.name, d.extra))])

        @pytest.mark.case(*PAIR)
        def test_starred(make_member):
            match(make_member)

        @pytest.mark.parametrize("key", [pytest.param(k, id=k, marks=pytest.mark.case(c)) for k, c in KEYS])
        def test_comprehension(key):
            pass

        @pytest.mark.parametrize("case_id", [pytest.param(c, id=c, marks=pytest.mark.case(c)) for c in TABLE])
        def test_dict_keys(case_id):
            pass

        @pytest.mark.parametrize("d", [_param(x) for x in [D("a", ("x.extra",)), D("b")]])
        def test_helper(d):
            pass

        @pytest.mark.parametrize("v", [1, 2])
        def test_untagged(v):
            CONFIG.base_url
    ''')
    got = {t["nodeid_suffix"]: t for t in C.pytest_tags_eval(src)}
    assert got["test_starred"]["cases"] == ["c.one", "c.two"]
    assert got["test_comprehension"]["param_cases"] == {"k1": ["n.k1"], "k2": ["n.k2"]}
    assert got["test_dict_keys"]["cases"] == ["t.a", "t.b"]
    assert got["test_helper"]["param_cases"] == {"a": ["t.a", "x.extra"], "b": ["t.b"]}
    assert got["test_untagged"]["cases"] == [] and "param_cases" not in got["test_untagged"]
    idx = C.index({"api_e2e": [{"suite": "api_e2e", "file": "f.py", "test": n, "nodeid": "tests/f.py::" + n, **t}
                               for n, t in got.items()]})
    assert idx["n.k1"][0]["nodeid"] == "tests/f.py::test_comprehension[k1]"
    assert idx["c.one"][0]["test"] == "test_starred"


def test_pytest_eval_never_runs_tests_or_opens_files():
    src = textwrap.dedent('''
        import pytest
        DATA = open("does-not-matter.json").read()   # blocked during the scan, statement skipped

        @pytest.mark.case("still.read")
        def test_x():
            raise SystemExit("a test body must never run")
    ''')
    assert [t["cases"] for t in C.pytest_tags_eval(src)] == [["still.read"]]


def test_go_comment_variants():
    src = textwrap.dedent('''
        // TestA proves [case:x.one] as well.
        // cases: x.two x.three
        func TestA(t *testing.T) {}

        // case: y.one,y.two
        func  TestB( tt *testing.T ) {}
    ''')
    got = {t["test"]: t["cases"] for t in C.go_tags(src)}
    assert got == {"TestA": ["x.one", "x.two", "x.three"], "TestB": ["y.one", "y.two"]}


def test_django_docstring_tags():
    src = textwrap.dedent('''
        class ReportsTest(TestCase):
            def test_catalog(self):
                """Every report is listed. [case:console.reports.report_catalog.renders]"""

            @override_settings(DEBUG=False)
            def test_export(
                self,
            ):
                """Exports.

                [case:console.reports.report_view.export_xlsx] [case:a.b, c.d]
                """

            # case: from.comment
            def test_both(self):
                """[case:from.doc]"""

            def test_none(self):
                x = "[case:not.a.docstring]"
    ''')
    got = {t["test"]: t["cases"] for t in C.django_tags(src)}
    assert got == {"ReportsTest.test_catalog": ["console.reports.report_catalog.renders"],
                   "ReportsTest.test_export": ["console.reports.report_view.export_xlsx", "a.b", "c.d"],
                   "ReportsTest.test_both": ["from.comment", "from.doc"],
                   "ReportsTest.test_none": []}


def test_index_inverts_tests_to_cases():
    scan = {"flutter": [{"suite": "flutter", "file": "app/test/a_test.dart", "test": "A [case:x.y]", "cases": ["x.y"]}],
            "api_e2e": [{"suite": "api_e2e", "file": "qa/api_e2e/tests/t.py", "test": "test_a", "nodeid": "tests/t.py::test_a", "cases": ["x.y", "z"]}]}
    idx = C.index(scan)
    assert [r["suite"] for r in idx["x.y"]] == ["flutter", "api_e2e"]
    assert idx["z"][0]["nodeid"] == "tests/t.py::test_a"
    assert all(r["via"] == "tag" for rs in idx.values() for r in rs)


def test_repo_scan_finds_every_suite():
    scan = C.scan_all(ROOT)
    assert set(scan) == {"flutter", "playwright", "api_e2e", "appium", "go", "django"}
    assert all(len(v) > 10 for v in scan.values()), {k: len(v) for k, v in scan.items()}
    tagged = {k: sum(1 for t in v if t["cases"]) for k, v in scan.items()}
    # the repo's own conventions are all read: Django docstrings, Go comments, pytest marks incl. params
    assert tagged["django"] > 300 and tagged["go"] >= 4 and tagged["api_e2e"] >= 40, tagged


def test_dart_strings_with_nested_interpolation_do_not_hide_later_tests():
    # Regression: '${List.filled(depth, '/*').join()}' was read as a string followed by
    # a block comment, so every test after it in the file was invisible to the scanner.
    src = textwrap.dedent("""
        void main() {
          for (var depth = 1; depth <= 5; depth++) {
            api.json('GET ${List.filled(depth, '/*').join()}', <String, dynamic>{});
          }
          testWidgets('after the interpolation [case:a.after]', (tester) async {});
        }
    """)
    assert [t["cases"] for t in C.dart_tags(src)] == [["a.after"]]


def test_interpolated_tags_become_patterns_expanded_only_to_file_literals():
    src = textwrap.dedent("""
        void main() {
          for (final (name, key) in const [('privacy_show_age', 'qa.privacy.show_age')]) {
            testWidgets('$key saves [case:common.privacy_safety.$name.action] [case:x.fixed]', (t) async {});
          }
        }
    """)
    (t,) = C.dart_tags(src)
    assert t["cases"] == ["x.fixed"]
    assert t["case_patterns"] == ["common.privacy_safety.{}.action"]
    known = ["common.privacy_safety.privacy_show_age.action", "common.privacy_safety.privacy_retry.action"]
    assert C.expand_pattern(t["case_patterns"][0], C.file_literals(src), known) == ["common.privacy_safety.privacy_show_age.action"]
    js = "for (const path of ['/', '/features']) { test(`${path} [case:site.${path === '/' ? 'index' : path.slice(1)}.renders_all_locales]`, async () => {}); }"
    (j,) = C.js_tags(js)
    assert j["cases"] == [] and j["case_patterns"] == ["site.{}.renders_all_locales"]
    assert C.expand_pattern(j["case_patterns"][0], C.file_literals(js) + ["index"],
                            ["site.index.renders_all_locales", "site.features.renders_all_locales", "site.contact.renders_all_locales"]) == \
        ["site.features.renders_all_locales", "site.index.renders_all_locales"]
