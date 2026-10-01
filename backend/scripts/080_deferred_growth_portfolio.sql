BEGIN;

CREATE SCHEMA IF NOT EXISTS growth;

-- One operator-readable register prevents an experimental table from being
-- mistaken for an approved product. Runtime switches remain in matching so
-- the existing BFF enforcement middleware can fail closed before handlers run.
CREATE TABLE IF NOT EXISTS growth.portfolio_modules (
  module_key TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  risk_tier TEXT NOT NULL CHECK (risk_tier IN ('standard','sensitive','monetized')),
  lifecycle TEXT NOT NULL CHECK (lifecycle IN ('foundation','internal','pilot','production','blocked')),
  owner TEXT NOT NULL,
  production_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  blocker TEXT,
  decision_note TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO growth.portfolio_modules
  (module_key,display_name,risk_tier,lifecycle,owner,production_enabled,blocker,decision_note)
VALUES
  ('support_ticketing','Support ticketing','standard','production','support_operations',TRUE,NULL,
   'Member submission, conversation history and operator resolution are approved.'),
  ('referrals','Referrals','monetized','foundation','growth_product',FALSE,
   'Reward value, fraud limits and billing settlement are not approved.',
   'Codes may be modelled without granting coins, XP or paid entitlement.'),
  ('growth_events','Events','sensitive','foundation','community_operations',FALSE,
   'Host vetting, physical-safety playbook and event acceptance are pending.',
   'Only free events are permitted by the foundation contract.'),
  ('partnerships','Partnerships','monetized','foundation','business_operations',FALSE,
   'Partner due diligence, commission policy and legal terms are pending.',
   'Published partner cards may contain no payment or commission behavior.'),
  ('social_imports','Social imports','sensitive','foundation','privacy_product',FALSE,
   'Provider review and contact-data retention approval are pending.',
   'Store revocable consent only; do not ingest an address book or social graph.'),
  ('member_history','Preference and location history','sensitive','foundation','privacy_product',FALSE,
   'Retention and member-facing controls require production acceptance.',
   'Location is an explicit city check-in; precise or background coordinates are prohibited.'),
  ('recommendation_graph','Recommendation graph','sensitive','foundation','matching_product',FALSE,
   'Fairness evaluation, model card and production monitoring are pending.',
   'Every edge requires visible reasons, versioning and expiry.'),
  ('fraud_graph','Fraud graph','sensitive','internal','trust_safety',FALSE,
   'Detection evidence and reviewer playbook are pending.',
   'Signals are review-only and cannot automatically punish a member.'),
  ('admirer_gifts','Admirer gifts','monetized','blocked','gift_economy',FALSE,
   'Consent, refund, abuse and billing settlement acceptance are pending.',
   'Escrow cannot debit or deliver until the monetized launch gate is approved.'),
  ('expanded_gift_economy','Expanded gift economy','monetized','blocked','gift_economy',FALSE,
   'Marketplace, trading, shared-wallet and creator settlement rules are unapproved.',
   'Existing matched gifts remain governed by the independent gifts_enabled policy.'),
  ('paid_xp','Paid XP','monetized','blocked','progression_product',FALSE,
   'Fairness, pricing, refunds, fraud limits and billing production GO are pending.',
   'Money cannot alter XP, level, streak or recommendation rank.' )
ON CONFLICT (module_key) DO UPDATE SET
  display_name=EXCLUDED.display_name,
  risk_tier=EXCLUDED.risk_tier,
  owner=EXCLUDED.owner,
  blocker=EXCLUDED.blocker,
  decision_note=EXCLUDED.decision_note;

INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_by)
VALUES
  ('support_ticketing_enabled',TRUE,'Member support ticket submission and operator queue','migration_080'),
  ('referrals_enabled',FALSE,'Referral codes and redemption; rewards are separately gated','migration_080'),
  ('growth_events_enabled',FALSE,'Free community events and registration','migration_080'),
  ('partnerships_enabled',FALSE,'Reviewed and published partner directory','migration_080'),
  ('social_imports_enabled',FALSE,'Revocable social-import consent; no contact ingestion','migration_080'),
  ('member_history_enabled',FALSE,'Member-controlled preference and city check-in history','migration_080'),
  ('recommendation_graph_enabled',FALSE,'Explainable recommendation edges','migration_080'),
  ('fraud_graph_enabled',FALSE,'Review-only fraud relationship signals','migration_080'),
  ('admirer_gifts_enabled',FALSE,'Pre-match admirer gift escrow','migration_080'),
  ('expanded_gift_economy_enabled',FALSE,'Gift marketplace, trading and shared wallets','migration_080'),
  ('paid_xp_enabled',FALSE,'Paid XP acceleration and catch-up mechanics','migration_080')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS growth.support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('account','safety','technical','billing','feedback')),
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low','normal','high','urgent')),
  subject TEXT NOT NULL CHECK (length(trim(subject)) BETWEEN 5 AND 120),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','in_progress','waiting_member','resolved','closed')),
  assigned_to UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  first_response_due_at TIMESTAMPTZ NOT NULL,
  resolution_due_at TIMESTAMPTZ NOT NULL,
  resolved_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  idempotency_key TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(member_id,idempotency_key),
  CHECK ((status IN ('resolved','closed')) = (resolved_at IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS idx_growth_support_member ON growth.support_tickets(member_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_growth_support_queue ON growth.support_tickets(status,priority,first_response_due_at);

CREATE TABLE IF NOT EXISTS growth.support_ticket_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES growth.support_tickets(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
  author_role TEXT NOT NULL CHECK (author_role IN ('member','support')),
  body TEXT NOT NULL CHECK (length(trim(body)) BETWEEN 1 AND 4000),
  idempotency_key TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(author_id,idempotency_key)
);
CREATE INDEX IF NOT EXISTS idx_growth_support_messages ON growth.support_ticket_messages(ticket_id,created_at);

CREATE TABLE IF NOT EXISTS growth.support_ticket_events (
  sequence BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ticket_id UUID NOT NULL REFERENCES growth.support_tickets(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  actor_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE RESTRICT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_growth_support_events ON growth.support_ticket_events(ticket_id,sequence);

CREATE TABLE IF NOT EXISTS growth.referral_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL UNIQUE REFERENCES user_management.users(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE CHECK (code ~ '^[A-Z0-9]{8,16}$'),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','paused','retired')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS growth.referral_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id UUID NOT NULL REFERENCES growth.referral_codes(id) ON DELETE RESTRICT,
  referred_member_id UUID NOT NULL UNIQUE REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'recorded' CHECK (status IN ('recorded','verified','void')),
  reward_granted BOOLEAN NOT NULL DEFAULT FALSE CHECK (reward_granted=FALSE),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS growth.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL CHECK (length(trim(title)) BETWEEN 5 AND 120),
  summary TEXT NOT NULL CHECK (length(trim(summary)) BETWEEN 10 AND 1000),
  city TEXT NOT NULL,
  venue_name TEXT,
  starts_at TIMESTAMPTZ NOT NULL,
  registration_closes_at TIMESTAMPTZ NOT NULL,
  capacity INTEGER NOT NULL CHECK (capacity BETWEEN 2 AND 10000),
  safety_contact TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','cancelled','completed')),
  is_free BOOLEAN NOT NULL DEFAULT TRUE CHECK (is_free=TRUE),
  created_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (registration_closes_at<=starts_at)
);
CREATE INDEX IF NOT EXISTS idx_growth_events_public ON growth.events(status,starts_at);
CREATE TABLE IF NOT EXISTS growth.event_registrations (
  event_id UUID NOT NULL REFERENCES growth.events(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'registered' CHECK (status IN ('registered','cancelled','attended','no_show')),
  safety_terms_accepted_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(event_id,member_id)
);

CREATE TABLE IF NOT EXISTS growth.partnerships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL CHECK (category IN ('community','venue','wellbeing','safety')),
  summary TEXT NOT NULL,
  website_url TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','review','published','suspended')),
  due_diligence_completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (status<>'published' OR due_diligence_completed_at IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS growth.social_import_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('google_contacts','apple_contacts','manual')),
  scope TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  status TEXT NOT NULL CHECK (status IN ('granted','revoked','expired')),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  UNIQUE(member_id,provider),
  CHECK ((status='revoked')=(revoked_at IS NOT NULL))
);

CREATE TABLE IF NOT EXISTS growth.preference_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  snapshot JSONB NOT NULL,
  changed_fields TEXT[] NOT NULL,
  source TEXT NOT NULL DEFAULT 'member_action' CHECK (source='member_action'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_growth_preference_history ON growth.preference_history(member_id,created_at DESC);

CREATE TABLE IF NOT EXISTS growth.location_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  country TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'foreground_checkin' CHECK (source='foreground_checkin'),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW()+INTERVAL '30 days'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_growth_location_checkins ON growth.location_checkins(member_id,created_at DESC);

CREATE TABLE IF NOT EXISTS growth.recommendation_edges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  score NUMERIC(5,4) NOT NULL CHECK (score BETWEEN 0 AND 1),
  reasons JSONB NOT NULL CHECK (jsonb_typeof(reasons)='array' AND jsonb_array_length(reasons)>0),
  model_version TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(member_id,candidate_id,model_version),
  CHECK (member_id<>candidate_id)
);
CREATE INDEX IF NOT EXISTS idx_growth_recommendation_edges ON growth.recommendation_edges(member_id,score DESC);

CREATE TABLE IF NOT EXISTS growth.fraud_graph_edges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  left_member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  right_member_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  signal_type TEXT NOT NULL CHECK (signal_type IN ('shared_device','referral_velocity','gift_velocity','account_pattern')),
  confidence NUMERIC(5,4) NOT NULL CHECK (confidence BETWEEN 0 AND 1),
  evidence JSONB NOT NULL DEFAULT '{}'::jsonb,
  review_status TEXT NOT NULL DEFAULT 'open' CHECK (review_status IN ('open','dismissed','confirmed')),
  action_mode TEXT NOT NULL DEFAULT 'review_only' CHECK (action_mode='review_only'),
  reviewed_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (left_member_id<>right_member_id)
);
CREATE INDEX IF NOT EXISTS idx_growth_fraud_review ON growth.fraud_graph_edges(review_status,confidence DESC);

-- Growth tables were created after the canonical event-backbone migration, so
-- register them here. Each state change is captured in the same transaction;
-- consumers recover by sequence and never rely on the NOTIFY hint alone.
DO $$
DECLARE source RECORD;
BEGIN
  FOR source IN
    SELECT c.relname AS table_name
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='growth' AND c.relkind IN ('r','p') AND NOT c.relispartition
    ORDER BY c.relname
  LOOP
    PERFORM platform.register_event_source('growth',source.table_name,'growth.'||source.table_name);
  END LOOP;
END $$;

DROP TRIGGER IF EXISTS trg_support_ticket_events_append_only ON growth.support_ticket_events;
CREATE TRIGGER trg_support_ticket_events_append_only
BEFORE UPDATE OR DELETE ON growth.support_ticket_events
FOR EACH ROW EXECUTE FUNCTION platform.reject_domain_event_mutation();

INSERT INTO public.schema_migrations(version)
VALUES ('080_deferred_growth_portfolio')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
