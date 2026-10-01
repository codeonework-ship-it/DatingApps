import importlib.util
import json
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("validate_trust_operations.py")
SPEC = importlib.util.spec_from_file_location("trust_validator", MODULE_PATH)
assert SPEC and SPEC.loader
validator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validator)


class TrustOperationsContractTest(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(validator.DEFAULT_CONTRACT.read_text(encoding="utf-8"))

    def test_policy_and_code_are_aligned(self):
        validator.validate_shape(self.contract)
        validator.validate_anchors()

    def test_missing_staff_and_evidence_fail_launch_closed(self):
        with self.assertRaisesRegex(validator.TrustContractError, "not GO"):
            validator.validate_launch(self.contract)


if __name__ == "__main__":
    unittest.main()
