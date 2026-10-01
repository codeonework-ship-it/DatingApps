#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
report_dir="${QA_RELEASE_REPORT_DIR:-$root_dir/qa/reports/release}"
mode="${1:-contract}"

if [[ "$mode" != "contract" && "$mode" != "launch" ]]; then
  echo "usage: $0 [contract|launch]" >&2
  exit 2
fi

mkdir -p "$report_dir"
python3 -m unittest "$root_dir/qa/governance/test_release_contract.py"
python3 -m unittest "$root_dir/qa/governance/test_trust_operations.py"
python3 -m unittest "$root_dir/qa/governance/test_provider_acceptance.py"
python3 -m unittest "$root_dir/qa/governance/test_billing_acceptance.py"
python3 -m unittest "$root_dir/qa/governance/test_correctness_recovery.py"
python3 -m unittest "$root_dir/qa/governance/test_product_screen_acceptance.py"
python3 -m unittest "$root_dir/qa/governance/test_progression_rollout.py"
python3 -m unittest "$root_dir/qa/progression/test_stage_evidence.py"
python3 "$root_dir/qa/governance/validate_release_contract.py" \
  --mode "$mode" \
  --report "$report_dir/release-governance-$mode.json"
python3 "$root_dir/qa/governance/validate_trust_operations.py" \
  --mode "$mode" \
  --report "$report_dir/trust-operations-$mode.json"
python3 "$root_dir/qa/governance/validate_provider_acceptance.py" \
  --mode "$mode" \
  --report "$report_dir/provider-acceptance-$mode.json"
python3 "$root_dir/qa/governance/validate_billing_acceptance.py" \
  --mode "$mode" \
  --report "$report_dir/billing-acceptance-$mode.json"
python3 "$root_dir/qa/governance/validate_correctness_recovery.py" \
  --mode "$mode" \
  --report "$report_dir/correctness-recovery-$mode.json"
python3 "$root_dir/qa/governance/validate_product_screen_acceptance.py" \
  --mode "$mode" \
  --report "$report_dir/product-screen-acceptance-$mode.json"
python3 "$root_dir/qa/governance/validate_progression_rollout.py" \
  --mode "$mode" \
  --report "$report_dir/progression-rollout-$mode.json"
