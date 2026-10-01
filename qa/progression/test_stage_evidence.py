import copy
import json
import unittest

from qa.progression.validate_stage_evidence import CONTRACT, StageEvidenceError, validate_stage_evidence


class ProgressionStageEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self.evidence = {
            "stage": "dogfood",
            "rollout_percent": 1,
            "exposed_members": 25,
            "observation_days": 7,
            "moderation_report_denominator": 500,
            "moderation_report_rate": 0.01,
            "safety_stop_report_rate": 0.05,
            "day7_retention_regression_percentage_points": -1.5,
            "fraud_cases_in_window": 8,
            "resolved_fraud_cases": 8,
            "fraud_false_positive_rate": 0.10,
            "critical_fraud_cases_over_sla": 0,
            "xp_inflation_rate": 0.03,
            "projection_completion_p95_seconds": 1.2,
            "projection_oldest_pending_age_seconds": 5,
            "projection_dead_letters": 0,
            "safety_stop_owner": "progression-oncall",
            "evidence_uri": "https://monitoring.example/review/123",
            "decision_note": "Dogfood gates reviewed and passed.",
            "decision": "promote",
        }

    def test_complete_nonzero_stage_evidence_passes(self):
        validate_stage_evidence(self.contract, self.evidence, "dogfood")

    def test_empty_cohort_fails(self):
        evidence = copy.deepcopy(self.evidence)
        evidence["exposed_members"] = 0
        with self.assertRaises(StageEvidenceError):
            validate_stage_evidence(self.contract, evidence, "dogfood")

    def test_each_safety_boundary_fails_closed(self):
        failures = {
            "moderation_report_rate": 0.06,
            "day7_retention_regression_percentage_points": 2.1,
            "fraud_false_positive_rate": 0.11,
            "critical_fraud_cases_over_sla": 1,
            "xp_inflation_rate": 0.051,
            "projection_completion_p95_seconds": 2.01,
            "projection_oldest_pending_age_seconds": 31,
            "projection_dead_letters": 1,
        }
        for field, value in failures.items():
            with self.subTest(field=field):
                evidence = copy.deepcopy(self.evidence)
                evidence[field] = value
                with self.assertRaises(StageEvidenceError):
                    validate_stage_evidence(self.contract, evidence, "dogfood")

    def test_unreviewed_decision_fails(self):
        evidence = copy.deepcopy(self.evidence)
        evidence["decision"] = "hold"
        with self.assertRaises(StageEvidenceError):
            validate_stage_evidence(self.contract, evidence, "dogfood")


if __name__ == "__main__":
    unittest.main()
