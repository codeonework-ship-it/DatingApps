BEGIN;

CREATE SCHEMA IF NOT EXISTS progression;

CREATE TABLE IF NOT EXISTS progression.level_definitions (
  level SMALLINT PRIMARY KEY CHECK (level BETWEEN 1 AND 10),
  name TEXT NOT NULL,
  threshold_xp INTEGER NOT NULL UNIQUE CHECK (threshold_xp >= 0),
  trust_gate BOOLEAN NOT NULL DEFAULT FALSE,
  reward_summary TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO progression.level_definitions(level,name,threshold_xp,trust_gate,reward_summary)
VALUES
  (1,'Onboarded',0,FALSE,'Base progression profile'),
  (2,'Active Starter',100,FALSE,'Starter profile accent'),
  (3,'Reliable Participant',250,FALSE,'Weekly visibility micro-boost'),
  (4,'Conversation Builder',500,FALSE,'Advanced icebreaker suggestions'),
  (5,'Trust Builder',900,TRUE,'Compatible-prompt priority'),
  (6,'Circle Contributor',1400,TRUE,'Circle highlight eligibility'),
  (7,'Voice Confident',2100,TRUE,'Voice-first prompt pack'),
  (8,'Social Connector',3000,TRUE,'Expanded social feature toggles'),
  (9,'High-Quality Regular',4200,TRUE,'Visibility scheduling tools'),
  (10,'Community Anchor',6000,TRUE,'Prestige frame and mentor badge')
ON CONFLICT (level) DO UPDATE SET
  name=EXCLUDED.name,threshold_xp=EXCLUDED.threshold_xp,
  trust_gate=EXCLUDED.trust_gate,reward_summary=EXCLUDED.reward_summary,
  updated_at=NOW();

CREATE TABLE IF NOT EXISTS progression.xp_source_policies (
  source TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  base_xp INTEGER NOT NULL CHECK (base_xp BETWEEN 0 AND 500),
  daily_xp_cap INTEGER NOT NULL CHECK (daily_xp_cap BETWEEN 0 AND 300),
  daily_event_cap INTEGER NOT NULL CHECK (daily_event_cap BETWEEN 1 AND 100),
  cooldown_seconds INTEGER NOT NULL DEFAULT 0 CHECK (cooldown_seconds BETWEEN 0 AND 86400),
  decay_multipliers NUMERIC(4,3)[] NOT NULL DEFAULT ARRAY[1.0,0.75,0.5,0.25]::NUMERIC[],
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO progression.xp_source_policies
  (source,display_name,base_xp,daily_xp_cap,daily_event_cap,cooldown_seconds)
VALUES
  ('profile_completed','Profile completed',50,50,1,0),
  ('daily_prompt_submitted','Daily prompt submitted',20,20,1,0),
  ('mini_activity_completed','Mini activity completed',30,90,3,300),
  ('circle_challenge_submitted','Circle challenge submitted',35,70,2,1800),
  ('voice_icebreaker_played','Voice icebreaker sent and played',40,120,3,600),
  ('streak_3','Three-day streak bonus',20,20,1,0),
  ('streak_7','Seven-day streak bonus',60,60,1,0),
  ('streak_14','Fourteen-day streak bonus',140,140,1,0),
  ('admin_adjustment','Audited operator adjustment',0,300,20,0)
ON CONFLICT (source) DO NOTHING;

CREATE TABLE IF NOT EXISTS progression.experiments (
  key TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','paused','completed')),
  rollout_percent SMALLINT NOT NULL DEFAULT 0 CHECK (rollout_percent BETWEEN 0 AND 100),
  variants JSONB NOT NULL CHECK (jsonb_typeof(variants)='object'),
  safety_stop_report_rate NUMERIC(6,5) NOT NULL DEFAULT 0.05000,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  updated_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO progression.experiments(key,name,status,rollout_percent,variants)
VALUES ('xp_weighting_v1','XP weighting fairness test','draft',0,
  '{"control":{"multiplier":1.0},"prompt_heavy":{"daily_prompt_submitted":1.25,"mini_activity_completed":0.85},"voice_circle_bonus":{"voice_icebreaker_played":1.20,"circle_challenge_submitted":1.20}}')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS progression.experiment_assignments (
  experiment_key TEXT NOT NULL REFERENCES progression.experiments(key) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  variant TEXT NOT NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (experiment_key,user_id)
);
CREATE INDEX IF NOT EXISTS idx_progression_assignment_user ON progression.experiment_assignments(user_id,experiment_key);

CREATE TABLE IF NOT EXISTS progression.account_controls (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  progression_frozen BOOLEAN NOT NULL DEFAULT FALSE,
  risk_multiplier NUMERIC(4,3) NOT NULL DEFAULT 1.000 CHECK (risk_multiplier BETWEEN 0.500 AND 1.000),
  reason TEXT,
  expires_at TIMESTAMPTZ,
  updated_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS progression.xp_ledger (
  sequence_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
  source TEXT NOT NULL REFERENCES progression.xp_source_policies(source),
  source_event_id TEXT,
  idempotency_key TEXT NOT NULL CHECK (length(idempotency_key) BETWEEN 1 AND 255),
  request_hash TEXT NOT NULL CHECK (request_hash ~ '^[0-9a-f]{64}$'),
  base_xp INTEGER NOT NULL,
  quality_multiplier NUMERIC(4,3) NOT NULL CHECK (quality_multiplier BETWEEN 0.500 AND 1.250),
  experiment_multiplier NUMERIC(4,3) NOT NULL DEFAULT 1.000 CHECK (experiment_multiplier BETWEEN 0.500 AND 1.500),
  awarded_xp INTEGER NOT NULL CHECK (awarded_xp BETWEEN -10000 AND 300),
  event_date DATE NOT NULL DEFAULT CURRENT_DATE,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  actor_type TEXT NOT NULL DEFAULT 'system' CHECK (actor_type IN ('system','user','admin')),
  actor_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id,idempotency_key)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_xp_ledger_source_event
  ON progression.xp_ledger(user_id,source,source_event_id)
  WHERE source_event_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_xp_ledger_user_timeline
  ON progression.xp_ledger(user_id,sequence_id DESC)
  INCLUDE (source,awarded_xp,occurred_at);
CREATE INDEX IF NOT EXISTS idx_xp_ledger_user_daily_source
  ON progression.xp_ledger(user_id,event_date,source,sequence_id)
  INCLUDE (awarded_xp,occurred_at);

CREATE OR REPLACE FUNCTION progression.reject_xp_ledger_mutation() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'xp_ledger is append-only; post a compensating adjustment';
END $$;
DROP TRIGGER IF EXISTS trg_xp_ledger_append_only ON progression.xp_ledger;
CREATE TRIGGER trg_xp_ledger_append_only BEFORE UPDATE OR DELETE ON progression.xp_ledger
FOR EACH ROW EXECUTE FUNCTION progression.reject_xp_ledger_mutation();

CREATE TABLE IF NOT EXISTS progression.projection_outbox (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ledger_sequence BIGINT NOT NULL UNIQUE REFERENCES progression.xp_ledger(sequence_id) ON DELETE RESTRICT,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','retry','completed','dead_letter')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  locked_at TIMESTAMPTZ,
  worker_id TEXT,
  last_error TEXT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_progression_projection_claim
  ON progression.projection_outbox(available_at,id)
  INCLUDE (ledger_sequence,user_id,attempt_count)
  WHERE status IN ('pending','retry');

CREATE TABLE IF NOT EXISTS progression.user_level_state (
  user_id UUID PRIMARY KEY REFERENCES user_management.users(id) ON DELETE CASCADE,
  total_xp INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
  current_level SMALLINT NOT NULL DEFAULT 1 REFERENCES progression.level_definitions(level),
  current_level_xp INTEGER NOT NULL DEFAULT 0 CHECK (current_level_xp >= 0),
  next_level_xp INTEGER,
  progress_percent NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
  trust_gate_satisfied BOOLEAN NOT NULL DEFAULT TRUE,
  progression_frozen BOOLEAN NOT NULL DEFAULT FALSE,
  version BIGINT NOT NULL DEFAULT 1,
  last_ledger_sequence BIGINT NOT NULL DEFAULT 0,
  projected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS progression.level_transitions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  from_level SMALLINT NOT NULL,
  to_level SMALLINT NOT NULL,
  total_xp INTEGER NOT NULL,
  trigger_ledger_sequence BIGINT NOT NULL REFERENCES progression.xp_ledger(sequence_id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id,to_level)
);
CREATE INDEX IF NOT EXISTS idx_level_transitions_user ON progression.level_transitions(user_id,created_at DESC);

CREATE TABLE IF NOT EXISTS progression.reward_catalog (
  reward_key TEXT PRIMARY KEY,
  level SMALLINT NOT NULL REFERENCES progression.level_definitions(level),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  reward_type TEXT NOT NULL CHECK (reward_type IN ('cosmetic','visibility','feature','prompt_pack')),
  payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  trust_required BOOLEAN NOT NULL DEFAULT FALSE,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0
);
INSERT INTO progression.reward_catalog(reward_key,level,name,description,reward_type,payload,trust_required,sort_order)
VALUES
 ('starter_accent',2,'Starter accent','A profile accent earned through activity.','cosmetic','{"accent":"sunrise"}',FALSE,20),
 ('weekly_micro_boost',3,'Weekly micro-boost','One bounded discovery freshness window.','visibility','{"minutes":15,"claims":"once"}',FALSE,30),
 ('advanced_icebreakers',4,'Advanced icebreakers','Unlock advanced guided suggestions.','feature','{"feature":"advanced_icebreakers"}',FALSE,40),
 ('trust_prompt_priority',5,'Trust prompt priority','Priority in compatible prompt surfaces.','feature','{"feature":"trust_prompt_priority"}',TRUE,50),
 ('circle_highlight',6,'Circle highlight','Eligibility for circle contribution highlights.','feature','{"feature":"circle_highlight"}',TRUE,60),
 ('voice_prompt_pack',7,'Voice prompt pack','A voice-first prompt collection.','prompt_pack','{"pack":"voice_confident"}',TRUE,70),
 ('social_connector',8,'Social connector tools','Expanded social participation tools.','feature','{"feature":"social_connector"}',TRUE,80),
 ('visibility_scheduler',9,'Visibility scheduler','Additional bounded visibility scheduling.','visibility','{"feature":"visibility_scheduler"}',TRUE,90),
 ('community_anchor',10,'Community Anchor','Prestige frame and mentor-style badge.','cosmetic','{"frame":"community_anchor","badge":"mentor"}',TRUE,100)
ON CONFLICT (reward_key) DO UPDATE SET name=EXCLUDED.name,description=EXCLUDED.description,
 reward_type=EXCLUDED.reward_type,payload=EXCLUDED.payload,trust_required=EXCLUDED.trust_required;
CREATE INDEX IF NOT EXISTS idx_progression_rewards_level ON progression.reward_catalog(level,sort_order) WHERE enabled;

CREATE TABLE IF NOT EXISTS progression.reward_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  reward_key TEXT NOT NULL REFERENCES progression.reward_catalog(reward_key),
  level SMALLINT NOT NULL,
  idempotency_key TEXT NOT NULL,
  claim_payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id,reward_key),
  UNIQUE(user_id,idempotency_key)
);
CREATE INDEX IF NOT EXISTS idx_reward_claims_user ON progression.reward_claims(user_id,claimed_at DESC);

CREATE TABLE IF NOT EXISTS progression.fraud_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  rule_code TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('low','medium','high','critical')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','reviewing','dismissed','confirmed')),
  evidence JSONB NOT NULL DEFAULT '{}'::JSONB,
  resolution TEXT,
  reviewed_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_progression_open_fraud_rule
  ON progression.fraud_cases(user_id,rule_code) WHERE status IN ('open','reviewing');
CREATE INDEX IF NOT EXISTS idx_progression_fraud_queue ON progression.fraud_cases(status,severity,created_at);

CREATE TABLE IF NOT EXISTS progression.telemetry_events (
  sequence_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  event_name TEXT NOT NULL CHECK (event_name IN ('level_xp_earned','level_up','level_reward_claimed','acceleration_used','level_progress_blocked_safety','xp_cap_reached','level_progress_recovered','fraud_case_updated')),
  properties JSONB NOT NULL DEFAULT '{}'::JSONB,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_progression_telemetry_event_time
  ON progression.telemetry_events(event_name,occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_progression_telemetry_user_time
  ON progression.telemetry_events(user_id,occurred_at DESC);

INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_at)
VALUES ('level_progression_enabled',TRUE,'Activity-first Level/XP progression',NOW())
ON CONFLICT (key) DO UPDATE SET description=EXCLUDED.description,updated_at=NOW();

COMMIT;

-- Rollback requires a product-approved data export because xp_ledger is an
-- immutable audit ledger. Disable level_progression_enabled before rollback.
