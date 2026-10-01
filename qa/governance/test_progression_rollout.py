import copy
import json
import unittest

from qa.governance.validate_progression_rollout import (
    DEFAULT_CONTRACT,
    ProgressionRolloutContractError,
    validate_anchors,
    validate_launch,
    validate_shape,
)


class ProgressionRolloutContractTest(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(DEFAULT_CONTRACT.read_text(encoding="utf-8"))

    def test_contract_and_anchors_are_valid(self):
        validate_shape(self.contract)
        validate_anchors(self.contract)

    def test_pending_production_evidence_blocks_launch(self):
        with self.assertRaises(ProgressionRolloutContractError):
            validate_launch(self.contract)

    def test_go_still_requires_every_production_evidence_item(self):
        contract = copy.deepcopy(self.contract)
        contract["production_acceptance"]["decision"] = "GO"
        with self.assertRaises(ProgressionRolloutContractError):
            validate_launch(contract)

    def test_stage_sequence_is_not_skippable_in_contract(self):
        contract = copy.deepcopy(self.contract)
        contract["rollout_sequence"].pop(1)
        with self.assertRaises(ProgressionRolloutContractError):
            validate_shape(contract)


if __name__ == "__main__":
    unittest.main()
