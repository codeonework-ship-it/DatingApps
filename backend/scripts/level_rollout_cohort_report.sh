#!/usr/bin/env bash
# Per-variant cohort evidence and safety-stop evaluation for a staged Level/XP
# rollout.
#
# `progression.experiments.safety_stop_report_rate` has existed since migration
# 064 and nothing has ever read it. Every other column on that table is wired
# up — `rollout_percent` drives assignment and the operator console edits it —
# but the safety threshold is written and then ignored, so an experiment whose
# cohort is being reported at twice its configured rate would keep running at
# whatever percentage it was last set to.
#
# This is the review gate for the dogfood/5%/25% stages: it reports what each
# variant cohort actually did and fails when an active experiment breaches its
# own threshold.
#
# Empty cohorts are reported as NOT PROVEN rather than passed. A rollout stage
# that produced no exposure looks identical to a safe one if you only check
# that the rate is under the limit, and this repository has already shipped one
# gate that passed on an empty window.
set -euo pipefail

psql_bin="${PSQL_BIN:-/opt/homebrew/opt/postgresql@17/bin/psql}"
database_url="${LOCAL_DATABASE_URL:-postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable}"
window_days="${LEVEL_ROLLOUT_WINDOW_DAYS:-7}"
require_exposure="${LEVEL_ROLLOUT_REQUIRE_EXPOSURE:-false}"
report_dir="${LEVEL_ROLLOUT_REPORT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/qa/reports/progression}"
report="${LEVEL_ROLLOUT_REPORT:-$report_dir/level-rollout-cohorts.txt}"

mkdir -p "$report_dir"

# Cohort metrics per experiment variant. Reports are counted against cohort
# members as the reported party, inside the review window.
read -r -d '' cohort_sql <<SQL || true
WITH cohort AS (
  SELECT a.experiment_key, a.variant, a.user_id
  FROM progression.experiment_assignments a
  JOIN progression.experiments e ON e.key = a.experiment_key
  WHERE e.status = 'active'
),
reports AS (
  SELECT c.experiment_key, c.variant, COUNT(DISTINCT r.id) AS report_count
  FROM cohort c
  JOIN matching.moderation_reports r ON r.reported_user_id = c.user_id
  WHERE r.created_at >= NOW() - INTERVAL '${window_days} days'
  GROUP BY 1,2
),
xp AS (
  SELECT c.experiment_key, c.variant,
         COALESCE(SUM(l.awarded_xp),0) AS awarded_xp,
         COUNT(*) FILTER (WHERE l.sequence_id IS NOT NULL) AS ledger_rows
  FROM cohort c
  LEFT JOIN progression.xp_ledger l
    ON l.user_id = c.user_id
   AND l.created_at >= NOW() - INTERVAL '${window_days} days'
  GROUP BY 1,2
),
levels AS (
  SELECT c.experiment_key, c.variant, COUNT(t.id) AS level_ups
  FROM cohort c
  LEFT JOIN progression.level_transitions t
    ON t.user_id = c.user_id
   AND t.created_at >= NOW() - INTERVAL '${window_days} days'
  GROUP BY 1,2
),
fraud AS (
  SELECT c.experiment_key, c.variant,
         COUNT(f.id) FILTER (WHERE f.status IN ('open','reviewing')) AS fraud_open,
         COUNT(f.id) FILTER (WHERE f.status = 'confirmed') AS fraud_confirmed
  FROM cohort c
  LEFT JOIN progression.fraud_cases f ON f.user_id = c.user_id
  GROUP BY 1,2
),
sizes AS (
  SELECT experiment_key, variant, COUNT(*) AS cohort_size
  FROM cohort GROUP BY 1,2
)
SELECT s.experiment_key, s.variant, s.cohort_size,
       COALESCE(r.report_count,0),
       ROUND(COALESCE(r.report_count,0)::NUMERIC / NULLIF(s.cohort_size,0), 5),
       e.safety_stop_report_rate,
       e.rollout_percent,
       COALESCE(x.awarded_xp,0), COALESCE(x.ledger_rows,0),
       COALESCE(lv.level_ups,0),
       COALESCE(f.fraud_open,0), COALESCE(f.fraud_confirmed,0)
FROM sizes s
JOIN progression.experiments e ON e.key = s.experiment_key
LEFT JOIN reports r ON r.experiment_key=s.experiment_key AND r.variant=s.variant
LEFT JOIN xp x ON x.experiment_key=s.experiment_key AND x.variant=s.variant
LEFT JOIN levels lv ON lv.experiment_key=s.experiment_key AND lv.variant=s.variant
LEFT JOIN fraud f ON f.experiment_key=s.experiment_key AND f.variant=s.variant
ORDER BY s.experiment_key, s.variant;
SQL

rows="$("$psql_bin" "$database_url" -X -AtF '|' -v ON_ERROR_STOP=1 -c "$cohort_sql")"

{
  echo "Level/XP staged rollout cohort report"
  echo "window_days=$window_days generated_from=progression.experiment_assignments"
  echo
} > "$report"

if [[ -z "$rows" ]]; then
  active="$("$psql_bin" "$database_url" -X -At -v ON_ERROR_STOP=1 \
    -c "SELECT COUNT(*) FROM progression.experiments WHERE status='active';")"
  {
    echo "active_experiments=$active"
    echo "assigned_cohorts=0"
    echo "SAFETY STOP NOT PROVEN: no active experiment has any assigned cohort."
  } | tee -a "$report"
  if [[ "$require_exposure" == true ]]; then
    echo "level rollout cohort gate failed: exposure required but no cohorts exist" >&2
    exit 1
  fi
  echo "Report written: $report"
  exit 0
fi

breached=0
empty=0
printf '%-18s %-18s %8s %8s %10s %10s %8s %8s %7s\n' \
  EXPERIMENT VARIANT COHORT REPORTS RATE THRESHOLD ROLLOUT% LEVELUPS FRAUD | tee -a "$report"

while IFS='|' read -r key variant size reports rate threshold rollout xp ledger levelups fraud_open fraud_conf; do
  [[ -z "$key" ]] && continue
  printf '%-18s %-18s %8s %8s %10s %10s %8s %8s %7s\n' \
    "$key" "$variant" "$size" "$reports" "${rate:-n/a}" "$threshold" "$rollout" "$levelups" "$fraud_open/$fraud_conf" \
    | tee -a "$report"

  if [[ "$size" -eq 0 || -z "$rate" ]]; then
    empty=$((empty + 1))
    continue
  fi
  if awk -v actual="$rate" -v limit="$threshold" 'BEGIN { exit !(actual > limit) }'; then
    breached=$((breached + 1))
    echo "SAFETY STOP: $key/$variant report rate $rate exceeds $threshold" | tee -a "$report"
  fi
done <<< "$rows"

echo | tee -a "$report"
if (( breached > 0 )); then
  echo "level rollout safety stop triggered for $breached cohort(s)" | tee -a "$report" >&2
  echo "Report written: $report"
  exit 1
fi

if (( empty > 0 )); then
  echo "SAFETY STOP NOT PROVEN for $empty cohort(s) with no assigned members." | tee -a "$report"
  if [[ "$require_exposure" == true ]]; then
    echo "level rollout cohort gate failed: exposure required" >&2
    echo "Report written: $report"
    exit 1
  fi
fi

echo "level rollout cohort report passed" | tee -a "$report"
echo "Report written: $report"
