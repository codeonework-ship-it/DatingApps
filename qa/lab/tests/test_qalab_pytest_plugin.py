"""The qalab_pytest plugin records outcomes and case markers as JSON lines."""
import json
import os
import subprocess
import sys
import textwrap

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))


def test_plugin_writes_cases_and_outcomes(tmp_path):
    (tmp_path / "pytest.ini").write_text("[pytest]\naddopts = --strict-markers -p no:cacheprovider\n")
    (tmp_path / "test_sample.py").write_text(textwrap.dedent('''
        import pytest

        @pytest.mark.case("auth.signin.action", "auth.signin.api_contract")
        def test_pass():
            assert True

        @pytest.mark.case("auth.signin.negative")
        def test_fail():
            assert 1 == 2

        @pytest.mark.skip(reason="later")
        @pytest.mark.case("auth.x")
        def test_skip():
            pass

        @pytest.mark.xfail(strict=True, reason="known defect")
        def test_xfail():
            assert False

        @pytest.fixture
        def broken():
            raise RuntimeError("setup boom")

        def test_error(broken):
            pass
    '''))
    out = tmp_path / "out.jsonl"
    env = {**os.environ, "PYTHONPATH": os.path.join(ROOT, "qa", "lab"), "QA_LAB_PYTEST_JSON": str(out)}
    subprocess.run([sys.executable, "-m", "pytest", "-p", "qalab_pytest", "-q"], cwd=tmp_path, env=env, capture_output=True, text=True, timeout=120)
    recs = {r["test"]: r for r in map(json.loads, out.read_text().splitlines())}
    assert recs["test_pass"]["outcome"] == "passed"
    assert recs["test_pass"]["cases"] == ["auth.signin.action", "auth.signin.api_contract"]
    assert recs["test_fail"]["outcome"] == "failed" and "assert 1 == 2" in recs["test_fail"]["message"]
    assert recs["test_skip"]["outcome"] == "skipped" and recs["test_skip"]["cases"] == ["auth.x"]
    assert recs["test_xfail"]["outcome"] == "skipped"
    assert recs["test_error"]["outcome"] == "error" and "setup boom" in recs["test_error"]["message"]
