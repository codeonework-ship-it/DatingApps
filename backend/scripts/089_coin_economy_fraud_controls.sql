-- ─────────────────────────────────────────────────────────────────────────────
-- 089: Coin-economy fraud and velocity controls (PEN-13 / RG-112)
--
-- Hard transaction limits remain in the application as a fail-safe. These
-- durable rules add review signals and feature-controlled warn, throttle and
-- temporary-lock responses with an attributed false-positive recovery path.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

CREATE TABLE IF NOT EXISTS matching.coin_economy_fraud_rules (
  rule_code          TEXT PRIMARY KEY,
  event_type         TEXT NOT NULL CHECK (event_type IN ('gift_send','coin_checkout')),
  metric             TEXT NOT NULL CHECK (metric IN (
                       'paid_gift_sends','paid_gift_coins','distinct_gift_recipients',
                       'same_recipient_paid_gifts','received_gift_reports',
                       'coin_checkout_count','coin_checkout_coins'
                     )),
  window_seconds     INTEGER NOT NULL CHECK (window_seconds BETWEEN 60 AND 2678400),
  trigger_value      INTEGER NOT NULL CHECK (trigger_value > 0),
  response_action    TEXT NOT NULL CHECK (response_action IN ('warn','throttle','temporary_lock')),
  lock_seconds       INTEGER NOT NULL DEFAULT 0 CHECK (lock_seconds BETWEEN 0 AND 604800),
  severity           TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low','medium','high','critical')),
  enabled            BOOLEAN NOT NULL DEFAULT TRUE,
  description        TEXT NOT NULL,
  updated_by         UUID,
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (response_action <> 'temporary_lock' OR lock_seconds >= 300)
);

INSERT INTO matching.coin_economy_fraud_rules
  (rule_code,event_type,metric,window_seconds,trigger_value,response_action,lock_seconds,severity,description)
VALUES
  ('gift_burst_warning','gift_send','paid_gift_sends',300,6,'warn',0,'low',
   'Warn and open a review signal on the sixth paid gift inside five minutes.'),
  ('gift_burst_temporary_lock','gift_send','paid_gift_sends',300,10,'temporary_lock',1800,'high',
   'Temporarily lock paid gifting on the tenth paid gift inside five minutes.'),
  ('gift_same_recipient_throttle','gift_send','same_recipient_paid_gifts',3600,9,'throttle',0,'medium',
   'Throttle the ninth paid gift to the same member inside one hour.'),
  ('gift_daily_coin_throttle','gift_send','paid_gift_coins',86400,201,'throttle',0,'high',
   'Throttle paid gift sends that would exceed 200 coins inside one UTC day.'),
  ('gift_daily_recipient_throttle','gift_send','distinct_gift_recipients',86400,16,'throttle',0,'high',
   'Throttle paid gift sends to a sixteenth distinct member inside one UTC day.'),
  ('gift_report_temporary_lock','gift_send','received_gift_reports',2592000,3,'temporary_lock',86400,'high',
   'Temporarily lock paid gifting after three received-gift reports in thirty days.'),
  ('coin_checkout_hourly_throttle','coin_checkout','coin_checkout_count',3600,4,'throttle',0,'medium',
   'Throttle the fourth coin checkout attempt inside one hour.'),
  ('coin_checkout_daily_throttle','coin_checkout','coin_checkout_count',86400,11,'throttle',0,'high',
   'Throttle the eleventh coin checkout attempt inside one UTC day.'),
  ('coin_checkout_daily_coin_throttle','coin_checkout','coin_checkout_coins',86400,10001,'throttle',0,'high',
   'Throttle checkout attempts that would exceed 10000 coins inside one UTC day.')
ON CONFLICT (rule_code) DO NOTHING;

CREATE TABLE IF NOT EXISTS matching.coin_economy_fraud_cases (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  rule_code           TEXT NOT NULL REFERENCES matching.coin_economy_fraud_rules(rule_code),
  event_type          TEXT NOT NULL CHECK (event_type IN ('gift_send','coin_checkout')),
  status              TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','reviewing','cleared','confirmed')),
  severity            TEXT NOT NULL CHECK (severity IN ('low','medium','high','critical')),
  recommended_action  TEXT NOT NULL CHECK (recommended_action IN ('warn','throttle','temporary_lock')),
  action_taken        TEXT NOT NULL CHECK (action_taken IN ('review_only','warn','throttle','temporary_lock')),
  observed_value      INTEGER NOT NULL CHECK (observed_value >= 0),
  trigger_value       INTEGER NOT NULL CHECK (trigger_value > 0),
  window_seconds      INTEGER NOT NULL CHECK (window_seconds BETWEEN 60 AND 2678400),
  occurrence_count    INTEGER NOT NULL DEFAULT 1 CHECK (occurrence_count > 0),
  match_id            UUID,
  receiver_user_id    UUID,
  evidence            JSONB NOT NULL DEFAULT '{}'::JSONB CHECK (
                        jsonb_typeof(evidence)='object' AND octet_length(evidence::TEXT) <= 8192
                      ),
  first_detected_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_detected_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  lock_until          TIMESTAMPTZ,
  resolved_at         TIMESTAMPTZ,
  resolved_by         UUID,
  resolution_note     TEXT CHECK (resolution_note IS NULL OR char_length(resolution_note) BETWEEN 10 AND 1000),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_coin_economy_fraud_case_open
  ON matching.coin_economy_fraud_cases(user_id,rule_code)
  WHERE status IN ('open','reviewing');
CREATE INDEX IF NOT EXISTS idx_coin_economy_fraud_case_queue
  ON matching.coin_economy_fraud_cases(status,severity,last_detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_coin_economy_fraud_case_user
  ON matching.coin_economy_fraud_cases(user_id,last_detected_at DESC);

ALTER TABLE matching.user_wallets
  ADD COLUMN IF NOT EXISTS risk_locked_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS risk_lock_reason TEXT,
  ADD COLUMN IF NOT EXISTS risk_lock_case_id UUID
    REFERENCES matching.coin_economy_fraud_cases(id) ON DELETE SET NULL;

INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_by)
VALUES
  ('coin_economy_fraud_responses_enabled', TRUE,
   'Apply configured coin-economy fraud responses; detection and cases remain active when disabled.', 'system'),
  ('coin_economy_fraud_warn_enabled', TRUE,
   'Allow configured coin-economy warning responses.', 'system'),
  ('coin_economy_fraud_throttle_enabled', TRUE,
   'Allow configured coin-economy throttle responses.', 'system'),
  ('coin_economy_fraud_temporary_lock_enabled', TRUE,
   'Allow configured temporary paid-spend locks.', 'system')
ON CONFLICT (key) DO NOTHING;

SELECT platform.register_event_source(
  'matching','coin_economy_fraud_rules','fraud.economy_rule'
);
SELECT platform.register_event_source(
  'matching','coin_economy_fraud_cases','fraud.economy_case'
);

INSERT INTO platform.aggregate_ownership(
  aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy
) VALUES
  ('fraud.economy_rule','billing','matching','coin_economy_fraud_rules',
   'operator command transaction','versioned operator correction with audit event'),
  ('fraud.economy_case','trust_safety','matching','coin_economy_fraud_cases',
   'same transaction as decision or refused command','re-evaluate source ledger and clear attributed false positive')
ON CONFLICT (aggregate_type) DO UPDATE SET
  owner_component=EXCLUDED.owner_component,
  source_schema=EXCLUDED.source_schema,
  source_table=EXCLUDED.source_table,
  transaction_boundary=EXCLUDED.transaction_boundary,
  recovery_strategy=EXCLUDED.recovery_strategy,
  updated_at=NOW();

INSERT INTO platform.required_aggregates(aggregate_type)
VALUES ('fraud.economy_case')
ON CONFLICT DO NOTHING;

INSERT INTO public.schema_migrations(version)
VALUES ('089_coin_economy_fraud_controls')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
