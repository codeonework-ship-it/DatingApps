import importlib.util
import json
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("validate_release_contract.py")
SPEC = importlib.util.spec_from_file_location("release_contract_validator", MODULE_PATH)
assert SPEC and SPEC.loader
validator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validator)


class ReleaseContractTest(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(validator.DEFAULT_CONTRACT.read_text(encoding="utf-8"))

    def test_contract_and_implementation_are_aligned(self):
        validator.validate_shape(self.contract)
        validator.validate_implementation_anchors()

    def test_current_production_decision_fails_closed(self):
        with self.assertRaisesRegex(validator.ContractError, "not GO"):
            validator.validate_launch(self.contract)

    def test_enabled_and_excluded_scope_cannot_overlap(self):
        self.contract["release_scope"]["enabled_capabilities"].append("digital_gifts")
        with self.assertRaisesRegex(validator.ContractError, "both enabled and excluded"):
            validator.validate_shape(self.contract)


if __name__ == "__main__":
    unittest.main()
