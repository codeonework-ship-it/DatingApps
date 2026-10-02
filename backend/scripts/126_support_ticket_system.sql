-- ─────────────────────────────────────────────────────────────────────────────
-- 126: Support ticket system (members raise queries, the support team resolves)
--
-- Replaces the foundation tables of migration 080 (growth.support_tickets,
-- growth.support_ticket_messages, growth.support_ticket_events), which were
-- never switched on in production (088 held them at foundation). Existing rows
-- are copied into the new schema once (legacy_ticket_id keeps the link) and the
-- old tables are left in place, read-only by convention, for audit.
--
--   support.tickets            one row per ticket (reference CN-YYYY-NNNNNN),
--                              raised by a member (app) or by a signed-out
--                              visitor through the website contact form
--                              (contact_email, never an account).
--   support.ticket_messages    public replies and internal notes (agents only).
--   support.ticket_attachments private images/PDFs (media kind
--                              support_attachments, key prefix private/support).
--   support.ticket_events      append-only audit trail of every change.
--   support.canned_responses   operator macros with {{placeholders}}.
--
-- Also adds the `support` operator role.
--
-- SLA targets, auto-close (7 days after resolution), the reopen window
-- (14 days after closing) and retention are applied by the BFF
-- (support_tickets.go, support worker). See
-- documents/SUPPORT_TICKET_SYSTEM_2026-10-01.md.
--
-- The member surface stays behind support_ticketing_enabled (still off since
-- 088): switching it on is an operator decision recorded in the register.
-- Safe to run repeatedly.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ── support operator role ───────────────────────────────────────────────────
ALTER TABLE user_management.auth_account_roles
  DROP CONSTRAINT IF EXISTS auth_account_roles_role_check;
ALTER TABLE user_management.auth_account_roles
  ADD CONSTRAINT auth_account_roles_role_check
  CHECK (role IN ('user','moderator','admin','ops_admin','trust_safety','analyst','finance','support'));

CREATE OR REPLACE VIEW audit.operator_action_log AS
SELECT id, occurred_at, txid, event_type, actor_user_id, actor_role,
       subject_user_id, resource_type, resource_id, correlation_id, payload
FROM audit.security_events
WHERE actor_role IN ('admin','ops_admin','trust_safety','moderator','analyst','finance','support')
ORDER BY occurred_at DESC, id DESC;

CREATE SCHEMA IF NOT EXISTS support;

-- Ticket references: CN-<year>-<6+ digit sequence>. One global sequence, so a
-- reference never repeats across years.
CREATE SEQUENCE IF NOT EXISTS support.ticket_reference_seq START 1;

CREATE OR REPLACE FUNCTION support.next_ticket_reference() RETURNS TEXT
LANGUAGE sql VOLATILE AS $$
  SELECT 'CN-' || to_char(NOW() AT TIME ZONE 'UTC', 'YYYY') || '-' ||
         lpad(nextval('support.ticket_reference_seq')::text, 6, '0')
$$;

CREATE TABLE IF NOT EXISTS support.canned_responses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 120),
  body        TEXT NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 5000),
  category    TEXT CHECK (category IS NULL OR category IN (
                'account_login','verification','payments_billing','safety_harassment',
                'matches_chat','technical','feature_request','privacy_data','other')),
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  usage_count INTEGER NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
  created_by  UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  updated_by  UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_support_canned_title
  ON support.canned_responses(lower(btrim(title)));

CREATE TABLE IF NOT EXISTS support.tickets (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference                TEXT NOT NULL UNIQUE CHECK (reference ~ '^CN-[0-9]{4}-[0-9]{6,}$'),
  -- A member ticket names the member; a website ticket carries only the
  -- address the visitor typed. Erasure keeps the (anonymised) member id.
  requester_member_id      UUID REFERENCES user_management.users(id) ON DELETE CASCADE,
  contact_email            TEXT CHECK (contact_email IS NULL OR char_length(contact_email) BETWEEN 3 AND 254),
  contact_name             TEXT CHECK (contact_name IS NULL OR char_length(contact_name) <= 100),
  category                 TEXT NOT NULL CHECK (category IN (
                             'account_login','verification','payments_billing','safety_harassment',
                             'matches_chat','technical','feature_request','privacy_data','other')),
  subject                  TEXT NOT NULL CHECK (char_length(subject) BETWEEN 1 AND 200),
  status                   TEXT NOT NULL DEFAULT 'new' CHECK (status IN (
                             'new','open','pending_member','on_hold','resolved','closed')),
  priority                 TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low','normal','high','urgent')),
  team                     TEXT NOT NULL DEFAULT 'general' CHECK (team IN (
                             'general','trust_safety','billing','privacy','technical')),
  channel                  TEXT NOT NULL DEFAULT 'app' CHECK (channel IN ('app','website','email')),
  assignee_id              UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  tags                     TEXT[] NOT NULL DEFAULT '{}' CHECK (cardinality(tags) <= 20),
  app_version              TEXT CHECK (app_version IS NULL OR char_length(app_version) <= 32),
  platform                 TEXT CHECK (platform IS NULL OR platform IN ('android','ios','web','macos','windows','linux')),
  os_version               TEXT CHECK (os_version IS NULL OR char_length(os_version) <= 32),
  device_model             TEXT CHECK (device_model IS NULL OR char_length(device_model) <= 64),
  locale                   TEXT CHECK (locale IS NULL OR char_length(locale) <= 16),
  -- Linked by an operator, never by the app: crash reports are anonymous.
  client_error_issue_id    UUID REFERENCES platform.client_error_issues(id) ON DELETE SET NULL,
  first_response_due_at    TIMESTAMPTZ NOT NULL,
  resolution_due_at        TIMESTAMPTZ NOT NULL,
  first_responded_at       TIMESTAMPTZ,
  resolved_at              TIMESTAMPTZ,
  closed_at                TIMESTAMPTZ,
  -- The resolution clock stops while the ticket waits on the member.
  sla_paused_at            TIMESTAMPTZ,
  -- Latched when a target is missed so reports survive later changes.
  first_response_breached  BOOLEAN NOT NULL DEFAULT FALSE,
  resolution_breached      BOOLEAN NOT NULL DEFAULT FALSE,
  satisfaction_rating      SMALLINT CHECK (satisfaction_rating IS NULL OR satisfaction_rating BETWEEN 1 AND 5),
  satisfaction_comment     TEXT CHECK (satisfaction_comment IS NULL OR char_length(satisfaction_comment) <= 1000),
  rated_at                 TIMESTAMPTZ,
  merged_into_id           UUID REFERENCES support.tickets(id) ON DELETE SET NULL,
  member_last_read_at      TIMESTAMPTZ,
  last_member_message_at   TIMESTAMPTZ,
  last_agent_reply_at      TIMESTAMPTZ,
  last_activity_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- sha256 of category+subject+description: the duplicate guard.
  request_hash             TEXT NOT NULL DEFAULT '',
  legacy_ticket_id         UUID UNIQUE,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (requester_member_id IS NOT NULL OR contact_email IS NOT NULL),
  CHECK (status <> 'resolved' OR resolved_at IS NOT NULL),
  CHECK (status <> 'closed' OR closed_at IS NOT NULL),
  CHECK (merged_into_id IS NULL OR merged_into_id <> id)
);
CREATE INDEX IF NOT EXISTS idx_support_tickets_requester
  ON support.tickets(requester_member_id, created_at DESC) WHERE requester_member_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_tickets_contact
  ON support.tickets(lower(contact_email), created_at DESC) WHERE contact_email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_tickets_queue
  ON support.tickets(status, priority, first_response_due_at);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assignee
  ON support.tickets(assignee_id, status) WHERE assignee_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_tickets_team
  ON support.tickets(team, status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_resolved
  ON support.tickets(resolved_at) WHERE status = 'resolved';
CREATE INDEX IF NOT EXISTS idx_support_tickets_closed
  ON support.tickets(closed_at) WHERE status = 'closed';
CREATE INDEX IF NOT EXISTS idx_support_tickets_created
  ON support.tickets(created_at);

CREATE TABLE IF NOT EXISTS support.ticket_messages (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id          UUID NOT NULL REFERENCES support.tickets(id) ON DELETE CASCADE,
  author_kind        TEXT NOT NULL CHECK (author_kind IN ('member','contact','agent','system')),
  author_id          UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
  visibility         TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public','internal')),
  body               TEXT NOT NULL CHECK (char_length(body) <= 10000),
  canned_response_id UUID REFERENCES support.canned_responses(id) ON DELETE SET NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Members and visitors can only ever write public messages.
  CHECK (visibility = 'public' OR author_kind IN ('agent','system'))
);
CREATE INDEX IF NOT EXISTS idx_support_messages_ticket
  ON support.ticket_messages(ticket_id, created_at, id);
CREATE INDEX IF NOT EXISTS idx_support_messages_author
  ON support.ticket_messages(author_id) WHERE author_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS support.ticket_attachments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- NULL until the upload is attached to a ticket message.
  ticket_id     UUID REFERENCES support.tickets(id) ON DELETE CASCADE,
  message_id    UUID REFERENCES support.ticket_messages(id) ON DELETE CASCADE,
  uploader_kind TEXT NOT NULL CHECK (uploader_kind IN ('member','agent')),
  uploader_id   UUID REFERENCES user_management.users(id) ON DELETE CASCADE,
  filename      TEXT NOT NULL CHECK (char_length(filename) BETWEEN 1 AND 255),
  content_type  TEXT NOT NULL CHECK (content_type IN ('image/jpeg','image/png','application/pdf')),
  size_bytes    INTEGER NOT NULL CHECK (size_bytes > 0 AND size_bytes <= 10485760),
  sha256        TEXT NOT NULL CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  width_px      INTEGER,
  height_px     INTEGER,
  storage_path  TEXT NOT NULL UNIQUE,
  -- An unattached upload is released after this time.
  expires_at    TIMESTAMPTZ,
  -- Set when the bytes must go (erasure, retention); the worker deletes the
  -- object, then the row.
  deleted_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK ((ticket_id IS NULL) = (message_id IS NULL))
);
CREATE INDEX IF NOT EXISTS idx_support_attachments_message
  ON support.ticket_attachments(message_id) WHERE message_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_attachments_pending
  ON support.ticket_attachments(uploader_id, created_at) WHERE message_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_support_attachments_release
  ON support.ticket_attachments(deleted_at) WHERE deleted_at IS NOT NULL;

CREATE TABLE IF NOT EXISTS support.ticket_events (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ticket_id   UUID NOT NULL REFERENCES support.tickets(id) ON DELETE CASCADE,
  event_type  TEXT NOT NULL CHECK (event_type ~ '^[a-z_]{3,40}$'),
  actor_kind  TEXT NOT NULL CHECK (actor_kind IN ('member','contact','agent','system')),
  -- No foreign key: the trail must not change when an account does.
  actor_id    UUID,
  from_value  TEXT CHECK (from_value IS NULL OR char_length(from_value) <= 200),
  to_value    TEXT CHECK (to_value IS NULL OR char_length(to_value) <= 200),
  payload     JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_support_events_ticket ON support.ticket_events(ticket_id, id);

-- The trail is append-only. Whole tickets may still be purged by retention
-- (the cascade deletes their events), so only UPDATE is refused.
CREATE OR REPLACE FUNCTION support.reject_event_update() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'support.ticket_events is append-only';
END;
$$;
DROP TRIGGER IF EXISTS trg_support_events_append_only ON support.ticket_events;
CREATE TRIGGER trg_support_events_append_only
BEFORE UPDATE ON support.ticket_events
FOR EACH ROW EXECUTE FUNCTION support.reject_event_update();

-- Macro edits are operator configuration: keep the generic change audit.
DROP TRIGGER IF EXISTS trg_audit_row_change ON support.canned_responses;
CREATE TRIGGER trg_audit_row_change AFTER INSERT OR DELETE OR UPDATE ON support.canned_responses
  FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change();

-- ── starter macros ──────────────────────────────────────────────────────────
INSERT INTO support.canned_responses (id, title, body, category) VALUES
  ('6a0f6e8e-0c1a-4b51-9a01-000000000001', 'Acknowledge — looking into it',
   E'Hi {{member_name}},\n\nThanks for getting in touch. We''re looking into this now and will update you on {{reference}} as soon as we know more.\n\n{{agent_name}}, Connect Support', NULL),
  ('6a0f6e8e-0c1a-4b51-9a01-000000000002', 'Need more details',
   E'Hi {{member_name}},\n\nCould you tell us a little more so we can help? Steps you took, what you expected and what happened instead are all useful — a screenshot helps too.\n\n{{agent_name}}, Connect Support', NULL),
  ('6a0f6e8e-0c1a-4b51-9a01-000000000003', 'Resolved — anything else?',
   E'Hi {{member_name}},\n\nThis should now be sorted. If anything still isn''t right, just reply here and the ticket reopens.\n\n{{agent_name}}, Connect Support', NULL),
  ('6a0f6e8e-0c1a-4b51-9a01-000000000004', 'Verification guidance',
   E'Hi {{member_name}},\n\nVerification usually fails when the selfie is dark or the face is partly covered. Please retake it in good light, facing the camera, without sunglasses or a hat, then submit again from Profile → Verification.\n\n{{agent_name}}, Connect Support', 'verification'),
  ('6a0f6e8e-0c1a-4b51-9a01-000000000005', 'Safety — escalated to Trust & Safety',
   E'Hi {{member_name}},\n\nThank you for telling us. Your report ({{reference}}) is with our Trust & Safety team, who review these first. You can block the person from their profile at any time. If you are in immediate danger, please contact your local emergency services.\n\n{{agent_name}}, Connect Support', 'safety_harassment')
ON CONFLICT (id) DO NOTHING;

-- ── copy the foundation tickets (migration 080) once ────────────────────────
INSERT INTO support.tickets (
  id, reference, requester_member_id, category, subject, status, priority, team, channel,
  assignee_id, first_response_due_at, resolution_due_at, resolved_at, closed_at,
  last_activity_at, request_hash, legacy_ticket_id, created_at, updated_at)
SELECT gen_random_uuid(), support.next_ticket_reference(), g.member_id,
       CASE g.category WHEN 'account' THEN 'account_login' WHEN 'safety' THEN 'safety_harassment'
                       WHEN 'billing' THEN 'payments_billing' WHEN 'feedback' THEN 'feature_request'
                       ELSE 'technical' END,
       left(g.subject, 200),
       CASE g.status WHEN 'in_progress' THEN 'open' WHEN 'waiting_member' THEN 'pending_member' ELSE g.status END,
       g.priority,
       CASE g.category WHEN 'safety' THEN 'trust_safety' WHEN 'billing' THEN 'billing'
                       WHEN 'technical' THEN 'technical' ELSE 'general' END,
       'app', g.assigned_to, g.first_response_due_at, g.resolution_due_at,
       CASE WHEN g.status IN ('resolved','closed') THEN g.resolved_at END,
       CASE WHEN g.status = 'closed' THEN COALESCE(g.closed_at, g.resolved_at, g.updated_at) END,
       g.updated_at, g.request_hash, g.id, g.created_at, g.updated_at
FROM growth.support_tickets g
WHERE to_regclass('growth.support_tickets') IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM support.tickets t WHERE t.legacy_ticket_id = g.id)
ORDER BY g.created_at;

INSERT INTO support.ticket_messages (id, ticket_id, author_kind, author_id, visibility, body, created_at)
SELECT m.id, t.id, CASE m.author_role WHEN 'support' THEN 'agent' ELSE 'member' END,
       m.author_id, 'public', m.body, m.created_at
FROM growth.support_ticket_messages m
JOIN support.tickets t ON t.legacy_ticket_id = m.ticket_id
ON CONFLICT (id) DO NOTHING;

INSERT INTO support.ticket_events (ticket_id, event_type, actor_kind, actor_id, payload, created_at)
SELECT t.id, 'migrated', 'system', NULL, jsonb_build_object('legacy_ticket_id', t.legacy_ticket_id), NOW()
FROM support.tickets t
WHERE t.legacy_ticket_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM support.ticket_events e WHERE e.ticket_id = t.id AND e.event_type = 'migrated');

UPDATE support.tickets t SET
  last_member_message_at = (SELECT MAX(created_at) FROM support.ticket_messages m WHERE m.ticket_id = t.id AND m.author_kind = 'member'),
  last_agent_reply_at    = (SELECT MAX(created_at) FROM support.ticket_messages m WHERE m.ticket_id = t.id AND m.author_kind = 'agent'),
  first_responded_at     = (SELECT MIN(created_at) FROM support.ticket_messages m WHERE m.ticket_id = t.id AND m.author_kind = 'agent')
WHERE t.legacy_ticket_id IS NOT NULL AND t.last_member_message_at IS NULL;

COMMENT ON TABLE growth.support_tickets IS 'Superseded by support.tickets (migration 126); kept read-only for audit.';
COMMENT ON TABLE growth.support_ticket_messages IS 'Superseded by support.ticket_messages (migration 126); kept read-only for audit.';
COMMENT ON TABLE growth.support_ticket_events IS 'Superseded by support.ticket_events (migration 126); kept read-only for audit.';

-- The register still holds the module at foundation (088); record that the
-- workflow now exists and only acceptance is outstanding.
UPDATE growth.portfolio_modules
SET blocker = 'Workflow implemented by migration 126 (documents/SUPPORT_TICKET_SYSTEM_2026-10-01.md); awaiting product acceptance before support_ticketing_enabled is switched on.',
    updated_at = NOW()
WHERE module_key = 'support_ticketing' AND lifecycle = 'foundation'
  AND blocker IS DISTINCT FROM 'Workflow implemented by migration 126 (documents/SUPPORT_TICKET_SYSTEM_2026-10-01.md); awaiting product acceptance before support_ticketing_enabled is switched on.';

INSERT INTO public.schema_migrations(version)
VALUES ('126_support_ticket_system')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
