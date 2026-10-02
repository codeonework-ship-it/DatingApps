# Signup Workflow Engine — Native PostgreSQL

Status: implemented and verified locally  
Last updated: 2026-08-03

## Decision

Signup and login use a canonical username and password. Username is the primary
credential identifier and is globally unique/case-normalized. UUID remains the
internal relational key so username changes cannot break relationships; the
database makes usernames immutable once the user profile exists. Phone number
and email are optional profile/contact data and are never authentication inputs.

Flutter connects only to the backend API. Database credentials stay in the Go
services. Local mode uses native PostgreSQL directly through the pgx driver; it
does not initialize Supabase, PostgREST, Supabase Auth, Supabase Storage, or
Docker.

## Durable workflow

| State | Current activity | Durable outcome |
|---|---|---|
| `credentials_created` | `bootstrap_profile` | Bcrypt credential, workflow, and opaque session created atomically |
| `basics_captured` | `accept_terms` | User, profile draft, and default settings created atomically |
| `terms_accepted` | `build_profile` | Versioned agreement timestamp stored |
| `profile_in_progress` | `build_profile` | Every draft mutation is persisted and resumable |
| `completed` | `done` | User, preferences, photos, draft, audit, and workflow committed atomically |

Every activity is recorded in
`user_management.signup_workflow_activities`. Login returns `workflow_state`,
`current_activity`, and `signup_required`; this is the server authority used by
Flutter to resume incomplete accounts.

The Flutter path is username/password + account basics -> terms -> photos ->
about/bio -> preview/completion. The entry engine loads the durable draft and
resumes at photos, about, or preview according to the first unmet completion
requirement. Preferences have safe defaults and remain editable after signup;
they are not allowed to bypass the required bio/preview activities.

Completion requires a valid name, date of birth, gender, at least two photos, a
bio of at least 10 characters, at least one sought gender, and accepted terms.
The completion transaction writes `profile_completion=100` only if all durable
writes succeed.

## Local database

Start the isolated native PostgreSQL 17 cluster:

```bash
cd backend
scripts/local_postgres.sh up
```

Apply the full local rebuild and migrations through 051:

```bash
scripts/migrate_local_postgres.sh
```

The default DSN is:

```text
postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable
```

The rebuild script is destructive only to this dedicated `dating_app` database.
It uses migration 036 as the consolidated baseline, applies non-embedded deltas
and all subsequent migrations, and uses
`041_local_photos_storage_path.sql` instead of the Supabase Storage bucket/RLS
portion of migration 041. Supabase-only public API role grants in migration 030
are not applicable to native PostgreSQL and are not applied.

Use `backend/config/.env.local-postgres.example` as the service configuration.
The isolated native signup stack listens on gateway port `18080` and BFF port
`18081`, avoiding collisions with Docker/Colima or other development servers.
Start it with `backend/scripts/local_signup_stack.sh up`.

## API contract

- `POST /v1/auth/signup`
- `POST /v1/auth/login`
- `POST /v1/auth/signup/bootstrap`
- `GET /v1/auth/signup/workflow/{userID}`
- `GET|PATCH /v1/users/{userID}/agreements/terms`
- `GET|PATCH /v1/profile/{userID}/draft`
- `POST /v1/profile/{userID}/photos`
- `POST /v1/profile/{userID}/complete`

All signup endpoints after credential creation require the opaque bearer access
token and bind the requested `userID` to the authenticated session.
