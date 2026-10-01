import importlib.util
import json
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("validate_billing_acceptance.py")
SPEC = importlib.util.spec_from_file_location("billing_validator", MODULE_PATH)
assert SPEC and SPEC.loader
validator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validator)


class BillingAcceptanceContractTest(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(validator.DEFAULT_CONTRACT.read_text(encoding="utf-8"))

    def test_contract_release_exclusion_and_implementation_align(self):
        validator.validate_shape(self.contract)
        validator.validate_release_exclusion()
        validator.validate_anchors()

    def test_missing_financial_evidence_fails_launch_closed(self):
        with self.assertRaisesRegex(validator.BillingContractError, "not GO"):
            validator.validate_launch(self.contract)


if __name__ == "__main__":
    unittest.main()
