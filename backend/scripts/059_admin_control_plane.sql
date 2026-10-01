BEGIN;

ALTER TABLE user_management.auth_account_roles
  DROP CONSTRAINT IF EXISTS auth_account_roles_role_check;

ALTER TABLE user_management.auth_account_roles
  ADD CONSTRAINT auth_account_roles_role_check
  CHECK (role IN ('user','moderator','admin','ops_admin','trust_safety','analyst'));

CREATE INDEX IF NOT EXISTS idx_auth_account_roles_role_user
  ON user_management.auth_account_roles(role, user_id);

CREATE OR REPLACE VIEW audit.operator_action_log AS
SELECT id, occurred_at, txid, event_type, actor_user_id, actor_role,
       subject_user_id, resource_type, resource_id, correlation_id, payload
FROM audit.security_events
WHERE actor_role IN ('admin','ops_admin','trust_safety','moderator','analyst')
ORDER BY occurred_at DESC, id DESC;

INSERT INTO public.schema_migrations(version)
VALUES ('059_admin_control_plane')
ON CONFLICT (version) DO UPDATE SET applied_at=EXCLUDED.applied_at;

COMMIT;
