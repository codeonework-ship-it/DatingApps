import copy
import json
import unittest

from qa.governance.validate_product_screen_acceptance import (
    DEFAULT_CONTRACT,
    ProductScreenContractError,
    validate_anchors,
    validate_launch,
    validate_shape,
)


class ProductScreenAcceptanceContractTest(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(DEFAULT_CONTRACT.read_text(encoding="utf-8"))

    def test_contract_and_anchors_are_valid(self):
        validate_shape(self.contract)
        validate_anchors(self.contract)

    def test_pending_representative_devices_block_launch(self):
        with self.assertRaises(ProductScreenContractError):
            validate_launch(self.contract)

    def test_go_still_requires_every_device_evidence_item(self):
        contract = copy.deepcopy(self.contract)
        contract["production_acceptance"]["decision"] = "GO"
        with self.assertRaises(ProductScreenContractError):
            validate_launch(contract)


if __name__ == "__main__":
    unittest.main()
