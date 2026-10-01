-- ─────────────────────────────────────────────────────────────────────────────
-- 088: Hold support ticketing at foundation until its workflow is accepted
--
-- 080 registered support ticketing as `production` with its runtime flag on
-- while the member submission, operator queue and resolution workflow were
-- still being built. Product decision (2026-09-27): keep it switched off and
-- out of production until that workflow is complete and accepted. Turning it
-- on is an explicit operator action (flag) plus a register update, recorded
-- with who approved it.
-- Runs after 080. Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE growth.portfolio_modules
SET lifecycle = 'foundation',
    production_enabled = FALSE,
    blocker = 'Member submission, operator queue and resolution workflow must be completed and accepted before exposure.',
    decision_note = 'Held at foundation by product decision on 2026-09-27; enable through an approved register update and the support_ticketing_enabled flag.',
    updated_at = NOW()
WHERE module_key = 'support_ticketing'
  AND (lifecycle <> 'foundation' OR production_enabled);

UPDATE matching.platform_feature_flags
SET value_bool = FALSE,
    description = 'Member support ticket submission and operator queue (held off until accepted)',
    updated_by = 'migration_088'
WHERE key = 'support_ticketing_enabled' AND value_bool;
