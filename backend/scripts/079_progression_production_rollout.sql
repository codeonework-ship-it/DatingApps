BEGIN;

-- Production rollout is deliberately constrained to reviewed stages. A paused
-- experiment keeps its last cohort assignment for analysis, but no multiplier
-- is applied because runtime assignment reads active experiments only.
ALTER TABLE progression.experiments
  ADD COLUMN IF NOT EXISTS rollout_stage TEXT NOT NULL DEFAULT 'draft',
  ADD COLUMN IF NOT EXISTS safety_stop_owner TEXT,
  ADD COLUMN IF NOT EXISTS incident_response_minutes INTEGER NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS last_safety_review_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_safety_review_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS stage_evidence_uri TEXT,
  ADD COLUMN IF NOT EXISTS stage_started_at TIMESTAMPTZ;

-- Existing ungoverned exposure is stopped during adoption. Operators may
-- resume only through the reviewed API, which supplies ownership and evidence.
UPDATE progression.experiments
SET status=CASE
      WHEN status='active' OR (status='completed' AND rollout_percent<>100) THEN 'paused'
      ELSE status END,
    rollout_stage=CASE rollout_percent
      WHEN 1 THEN 'dogfood'
      WHEN 5 THEN 'five_percent'
      WHEN 25 THEN 'twenty_five_percent'
      WHEN 100 THEN 'general_availability'
      ELSE 'draft' END,
    rollout_percent=CASE WHEN rollout_percent IN (1,5,25,100) THEN rollout_percent ELSE 0 END,
    safety_stop_owner=CASE WHEN status IN ('active','paused') OR (status='completed' AND rollout_percent<>100)
      THEN COALESCE(NULLIF(trim(safety_stop_owner),''),'migration-safety-stop') ELSE safety_stop_owner END,
    last_safety_review_at=CASE WHEN status IN ('active','paused') OR (status='completed' AND rollout_percent<>100)
      THEN COALESCE(last_safety_review_at,NOW()) ELSE last_safety_review_at END,
    stage_evidence_uri=CASE WHEN status IN ('active','paused') OR (status='completed' AND rollout_percent<>100)
      THEN COALESCE(NULLIF(trim(stage_evidence_uri),''),'migration://paused-for-reviewed-rollout') ELSE stage_evidence_uri END,
    stage_started_at=CASE WHEN rollout_percent>0 THEN NOW() ELSE stage_started_at END
WHERE NOT EXISTS (
  SELECT 1 FROM public.schema_migrations
  WHERE version='079_progression_production_rollout'
);

ALTER TABLE progression.experiments
  DROP CONSTRAINT IF EXISTS progression_experiments_rollout_stage_check,
  ADD CONSTRAINT progression_experiments_rollout_stage_check
    CHECK (rollout_stage IN ('draft','dogfood','five_percent','twenty_five_percent','general_availability')),
  DROP CONSTRAINT IF EXISTS progression_experiments_rollout_percent_stage_check,
  ADD CONSTRAINT progression_experiments_rollout_percent_stage_check CHECK (
    (rollout_stage='draft' AND rollout_percent=0) OR
    (rollout_stage='dogfood' AND rollout_percent=1) OR
    (rollout_stage='five_percent' AND rollout_percent=5) OR
    (rollout_stage='twenty_five_percent' AND rollout_percent=25) OR
    (rollout_stage='general_availability' AND rollout_percent=100)
  ),
  DROP CONSTRAINT IF EXISTS progression_experiments_active_owner_check,
  ADD CONSTRAINT progression_experiments_active_owner_check CHECK (
    status NOT IN ('active','paused') OR
    (length(trim(COALESCE(safety_stop_owner,''))) >= 3
      AND incident_response_minutes BETWEEN 1 AND 60
      AND last_safety_review_at IS NOT NULL
      AND length(trim(COALESCE(stage_evidence_uri,''))) >= 3)
  );

CREATE TABLE IF NOT EXISTS progression.rollout_stage_history (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  experiment_key TEXT NOT NULL REFERENCES progression.experiments(key) ON DELETE RESTRICT,
  from_stage TEXT NOT NULL,
  to_stage TEXT NOT NULL,
  from_status TEXT NOT NULL,
  to_status TEXT NOT NULL,
  rollout_percent SMALLINT NOT NULL,
  safety_stop_owner TEXT NOT NULL,
  evidence_uri TEXT NOT NULL,
  decision_note TEXT NOT NULL CHECK (length(trim(decision_note)) >= 10),
  actor_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_progression_rollout_history
  ON progression.rollout_stage_history(experiment_key,created_at DESC);

CREATE OR REPLACE FUNCTION progression.enforce_rollout_stage_transition() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
  old_rank INTEGER;
  new_rank INTEGER;
BEGIN
  old_rank := CASE OLD.rollout_stage WHEN 'draft' THEN 0 WHEN 'dogfood' THEN 1
    WHEN 'five_percent' THEN 2 WHEN 'twenty_five_percent' THEN 3
    WHEN 'general_availability' THEN 4 END;
  new_rank := CASE NEW.rollout_stage WHEN 'draft' THEN 0 WHEN 'dogfood' THEN 1
    WHEN 'five_percent' THEN 2 WHEN 'twenty_five_percent' THEN 3
    WHEN 'general_availability' THEN 4 END;

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
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_progression_rollout_stage_transition ON progression.experiments;
CREATE TRIGGER trg_progression_rollout_stage_transition
BEFORE UPDATE OF status,rollout_stage,rollout_percent ON progression.experiments
FOR EACH ROW EXECUTE FUNCTION progression.enforce_rollout_stage_transition();

-- Fraud controls are tuneable, attributed and bounded. They remain review-only;
-- neither this policy nor an experiment can silently punish or ban a member.
CREATE TABLE IF NOT EXISTS progression.fraud_rule_policies (
  rule_code TEXT PRIMARY KEY,
  rejected_attempt_threshold INTEGER NOT NULL CHECK (rejected_attempt_threshold BETWEEN 2 AND 20),
  window_seconds INTEGER NOT NULL CHECK (window_seconds BETWEEN 60 AND 86400),
  severity TEXT NOT NULL CHECK (severity IN ('low','medium','high','critical')),
  response_action TEXT NOT NULL DEFAULT 'review_only' CHECK (response_action='review_only'),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  review_sla_minutes INTEGER NOT NULL CHECK (review_sla_minutes BETWEEN 5 AND 10080),
  tuning_note TEXT NOT NULL CHECK (length(trim(tuning_note)) >= 10),
  updated_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO progression.fraud_rule_policies
  (rule_code,rejected_attempt_threshold,window_seconds,severity,response_action,
   enabled,review_sla_minutes,tuning_note)
VALUES ('repeated_source_cap',4,86400,'medium','review_only',TRUE,240,
  'Initial deterministic threshold from the approved local XP policy.')
ON CONFLICT (rule_code) DO NOTHING;

-- One queryable source backs the operator console and Prometheus collector.
CREATE OR REPLACE VIEW progression.production_health AS
SELECT
  COUNT(*) FILTER (WHERE status IN ('pending','retry'))::BIGINT AS queue_depth,
  COUNT(*) FILTER (WHERE status='processing')::BIGINT AS processing,
  COUNT(*) FILTER (WHERE status='dead_letter')::BIGINT AS dead_letters,
  COALESCE(MAX(EXTRACT(EPOCH FROM NOW()-created_at))
    FILTER (WHERE status IN ('pending','retry')),0)::DOUBLE PRECISION AS oldest_pending_age_seconds,
  COALESCE(percentile_cont(0.95) WITHIN GROUP
    (ORDER BY EXTRACT(EPOCH FROM completed_at-created_at))
    FILTER (WHERE status='completed' AND completed_at>=NOW()-INTERVAL '15 minutes'),0)::DOUBLE PRECISION
    AS completion_p95_seconds
FROM progression.projection_outbox;

CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO public.schema_migrations(version)
VALUES ('079_progression_production_rollout')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
