BEGIN;

-- PEN-45 / Epic 7: database enforcement for the reviewed Level/XP rollout.
--
-- Migration 079 enforced ordered stages on UPDATE only, left the stage history
-- mutable, and relied on a JSON contract validator for the rule that every
-- promotion needs real exposure. This migration moves those rules into the
-- database so neither the API nor direct SQL can bypass them:
--
--   1. A promotion out of an exposed stage (dogfood -> 5% -> 25% -> GA) needs a
--      nonempty exposed cohort for the current stage. draft -> dogfood is the
--      entry to the first cohort and cannot have exposure yet. Pause/resume at
--      the current stage and completion at GA are not promotions, so a safety
--      stop never waits on cohort data.
--   2. progression.rollout_stage_history is append-only.
--   3. A new experiment row must start at the draft stage with draft status;
--      every later state is reached through the checked UPDATE path.

-- Stage order shared by the transition trigger. NULL for an unknown stage;
-- the rollout_stage CHECK constraint already rejects those.
CREATE OR REPLACE FUNCTION progression.rollout_stage_rank(p_stage TEXT)
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_stage
    WHEN 'draft' THEN 0
    WHEN 'dogfood' THEN 1
    WHEN 'five_percent' THEN 2
    WHEN 'twenty_five_percent' THEN 3
    WHEN 'general_availability' THEN 4
  END
$$;

-- The exposed cohort of a stage: members assigned to a treatment variant (any
-- variant other than 'control') since the stage started. Runtime assignment
-- (progressionExperimentMultiplier) writes progression.experiment_assignments
-- only while the experiment is active, and members bucketed outside the rollout
-- percentage are recorded as 'control', so control rows are not exposure.
-- Assignments from an earlier stage do not count: a previous pass cannot
-- authorise a later cohort. A NULL stage start counts every assignment.
-- The mobile BFF calls this same function before promoting, so the API and
-- the trigger share one definition.
CREATE OR REPLACE FUNCTION progression.rollout_exposed_cohort_size(
  p_experiment_key TEXT,
  p_stage_started_at TIMESTAMPTZ
)
RETURNS BIGINT
LANGUAGE sql
STABLE
AS $$
  SELECT COUNT(*)::BIGINT
  FROM progression.experiment_assignments a
  WHERE a.experiment_key = p_experiment_key
    AND a.variant <> 'control'
    AND a.assigned_at >= COALESCE(p_stage_started_at, '-infinity'::TIMESTAMPTZ)
$$;

-- Replaces the 079 body. The four UPDATE checks and their messages are
-- unchanged; INSERT coverage and the cohort requirement are added.
CREATE OR REPLACE FUNCTION progression.enforce_rollout_stage_transition() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  old_rank INTEGER;
  new_rank INTEGER;
  exposed BIGINT;
BEGIN
  new_rank := progression.rollout_stage_rank(NEW.rollout_stage);

  IF TG_OP = 'INSERT' THEN
    IF NEW.rollout_stage <> 'draft' OR NEW.status <> 'draft' THEN
      RAISE EXCEPTION 'progression rollout must start at the draft stage with draft status (got stage %, status %)',
          NEW.rollout_stage, NEW.status
        USING ERRCODE = 'check_violation',
              CONSTRAINT = 'progression_rollout_initial_stage';
    END IF;
    RETURN NEW;
  END IF;

  old_rank := progression.rollout_stage_rank(OLD.rollout_stage);

  IF NEW.status='completed' AND NEW.rollout_stage<>'general_availability' THEN
    RAISE EXCEPTION 'progression rollout may complete only from general availability';
  END IF;
  IF new_rank > old_rank + 1 THEN
    RAISE EXCEPTION 'progression rollout cannot skip a cohort stage';
  END IF;
  IF new_rank > old_rank AND NEW.status<>'active' THEN
    RAISE EXCEPTION 'progression rollout promotion requires active status and reviewed evidence';
  END IF;
  IF new_rank < old_rank THEN
    RAISE EXCEPTION 'use paused status for a safety stop; rollout stages are immutable';
  END IF;

  IF new_rank > old_rank AND old_rank >= 1 THEN
    exposed := progression.rollout_exposed_cohort_size(OLD.key, OLD.stage_started_at);
    IF exposed = 0 THEN
      RAISE EXCEPTION 'progression rollout promotion from % to % requires a nonempty exposed cohort',
          OLD.rollout_stage, NEW.rollout_stage
        USING ERRCODE = 'check_violation',
              CONSTRAINT = 'progression_rollout_promotion_cohort',
              HINT = 'No treatment-variant assignment exists in progression.experiment_assignments since the current stage started. Pause instead of promoting.';
    END IF;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_progression_rollout_stage_transition ON progression.experiments;
CREATE TRIGGER trg_progression_rollout_stage_transition
BEFORE INSERT OR UPDATE OF status,rollout_stage,rollout_percent ON progression.experiments
FOR EACH ROW EXECUTE FUNCTION progression.enforce_rollout_stage_transition();

-- Stage history is the immutable decision record. Corrections are new rows.
CREATE OR REPLACE FUNCTION progression.reject_rollout_stage_history_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'progression.rollout_stage_history is append-only';
END;
$$;

DROP TRIGGER IF EXISTS trg_progression_rollout_history_immutable ON progression.rollout_stage_history;
CREATE TRIGGER trg_progression_rollout_history_immutable
BEFORE UPDATE OR DELETE ON progression.rollout_stage_history
FOR EACH ROW EXECUTE FUNCTION progression.reject_rollout_stage_history_mutation();

DROP TRIGGER IF EXISTS trg_progression_rollout_history_no_truncate ON progression.rollout_stage_history;
CREATE TRIGGER trg_progression_rollout_history_no_truncate
BEFORE TRUNCATE ON progression.rollout_stage_history
FOR EACH STATEMENT EXECUTE FUNCTION progression.reject_rollout_stage_history_mutation();

CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO public.schema_migrations(version)
VALUES ('086_progression_rollout_enforcement')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
