# Authentication and Authorization Security Foundation

Status: implemented and verified for the native PostgreSQL runtime  
Migration: `052_auth_security_foundation.sql`

## Security boundary

Every `/v1` route is bearer-authenticated in native local mode except health,
documentation, login, signup, refresh, password recovery, public master data,
billing-plan discovery, and public media reads. Caller-supplied `X-User-ID` and
`X-Admin-User` headers are overwritten from the validated session principal.

The middleware enforces self-owned path identifiers, rejects actor identifiers
in JSON bodies that differ from the authenticated user, and validates match
membership against `matching.matches`. Admin routes require an `admin` role
stored in `user_management.auth_account_roles`.

## Session and password lifecycle

- Access tokens expire after 30 minutes and are stored only as SHA-256 hashes.
- Refresh tokens expire after 30 days, rotate on every use, and cannot be
  replayed after rotation.
- Logout revokes the current server session; revoke-all invalidates every
  session for the account.
- Password change and password recovery revoke every existing session.
- Recovery uses a long, random, display-once code because phone and email are
  not authentication factors. Only its hash is stored and it is single-use.
- Five failed logins within 15 minutes lock the account for 15 minutes.
- Disabled, inactive, banned, or effectively suspended accounts are rejected
  during bearer validation. Ban/suspend revokes every active session in the
  same transaction as the account state and immutable audit event.

## API contracts

- `POST /v1/auth/refresh`
- `POST /v1/auth/logout`
- `POST /v1/auth/sessions/revoke`
- `POST /v1/auth/password/change`
- `POST /v1/auth/recovery-code/rotate`
- `POST /v1/auth/password/recover`

The Flutter client attaches bearer tokens, performs a single synchronized
refresh-and-retry after a protected request receives `401`, and calls the
server logout endpoint before clearing its local in-memory session.

## Local administrator provisioning

Roles are not self-service. A local database operator may grant the admin role
explicitly after reviewing the account:

```sql
INSERT INTO user_management.auth_account_roles (user_id, role)
SELECT user_id, 'admin'
FROM user_management.auth_credentials
WHERE username = '<reviewed-username>'
ON CONFLICT (user_id, role) DO NOTHING;
```

## Safety enforcement extension

Migration 055 extends this boundary with native transactional report, appeal,
SOS, verification, block, suspension, and ban workflows. Details and live
negative-security evidence are recorded in
`documents/SAFETY_MODERATION_ENFORCEMENT_LOCAL_POSTGRES.md`.
