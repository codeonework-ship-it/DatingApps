# AegisConnect Control Panel

Django-based operator console for eKYC/cKYC review and user activity monitoring.

## Architecture

- UI/BFF consumer only: no business/domain models are implemented in Django.
- All business logic and data models remain in Go microservices.
- Django communicates with Go BFF admin APIs:
  - `GET /v1/admin/verifications`
  - `POST /v1/admin/verifications/{userID}/approve`
  - `POST /v1/admin/verifications/{userID}/reject`
  - `GET /v1/admin/activities`
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
python manage.py runserver 0.0.0.0:8000
```

Open `http://localhost:8000`.

