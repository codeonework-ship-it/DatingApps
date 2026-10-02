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
