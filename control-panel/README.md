# AegisConnect Control Panel

Django-based, username/password-authenticated operator console for the complete
eight-section administration plane.

## Architecture

- UI/BFF consumer only: no business/domain models are implemented in Django.
- All business logic and data models remain in Go microservices.
- Django communicates with bearer-protected Go BFF admin APIs. Access tokens
  are refreshed server-side in the Django session; caller-supplied admin
  headers are never credentials.
- The command center combines truthful metric definitions, SLA queue status,
  product events, canonical domain-event pipeline health, deployment readiness
  and the immutable operator audit log.
- The console covers dashboard, gift catalog, users, moderation and
  verification, engagement, billing, feature flags/live config, and safety/SOS.
- Representative APIs include:
  - `GET /v1/admin/verifications`
  - `POST /v1/admin/verifications/{userID}/approve`
  - `POST /v1/admin/verifications/{userID}/reject`
  - `GET /v1/admin/activities`
  - `GET /v1/admin/audit-events`
  - `GET /v1/admin/events`
  - `GET /v1/admin/events/metrics`
  - `GET /v1/admin/moderation/appeals`
  - `POST /v1/admin/moderation/appeals/{appealID}/action`
  - `GET /v1/admin/analytics/overview`

## Run

```bash
cd control-panel
cp .env.example .env
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
../backend/scripts/provision_local_operator.sh
python manage.py runserver 127.0.0.1:8000
```

Open `http://localhost:8000`.

Local operator credentials created by the provisioning command:

- Username: `local_control_admin`
- Password: `LocalAdmin123!`

These are local-development credentials only. Override them with
`LOCAL_OPERATOR_USERNAME` and `LOCAL_OPERATOR_PASSWORD`; never reuse them in a
deployed environment.

Run the complete security and eight-section acceptance gate with:

```bash
../qa/admin/run_admin_control_plane_gate.sh
../qa/event_architecture/run_event_architecture_gate.sh
```

## Personalized Kibana dashboard

Set these env vars in `control-panel/.env` to enable the embedded Kibana section on the dashboard page:

- `KIBANA_BASE_URL` (default: `http://localhost:5601`)
- `KIBANA_DISCOVER_INDEX` (default: `dating-app-logs-*`)
- `KIBANA_DASHBOARD_PATH` (default: `/app/dashboards`)

Use `/?user_id=<uuid>` on the dashboard URL to pre-filter Discover KQL for that user.

On the production VPS logs go to Loki and are browsed in Grafana instead
(`documents/MONITORING_AND_OBSERVABILITY_2026-10-01.md`). Point the links there with:

- `LOGS_BACKEND=loki` (default `kibana`)
- `GRAFANA_BASE_URL=https://<domain>/grafana`

`/?user_id=<uuid>` then opens Grafana Explore with a Loki line filter for that member.

## QA Lab results

The **QA Lab** section (sidebar, under Quality) shows QA Lab's test runs, case
coverage and coverage-gate gaps, read from the files QA Lab writes. It is
read-only: runs are started in QA Lab itself (`website/qa-lab`, `QA_LAB=1`).

- `QA_LAB_ENABLED` (unset: on only when `DJANGO_DEBUG` is true; off: every page is a 404 and the link is hidden)
- `QA_LAB_URL` (default `http://127.0.0.1:4190/qa-lab/`, the "Open QA Lab" button)
- `QA_LAB_RESULTS_DIR` (default `../qa/results/qa_lab`), `QA_LAB_CATALOG_PATH`,
  `QA_LAB_MANUAL_CASES_PATH`, `QA_LAB_GATE_PATH` (default `../qa/lab/coverage_gate.py`)

Admin, ops_admin and analyst operators can read it; other or unknown roles get a 403.
