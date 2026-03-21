# VPS Nginx + Flutter Production Runbook

This runbook is the production checklist for:
- Go backend on VPS (`72.61.242.87`)
- Supabase-backed configuration and migrations
- Nginx reverse proxy (IP-only)
- Local Flutter app pointing to production API

For first-time server setup with copy/paste-only commands, use: `documents/VPS_FIRST_TIME_BRINGUP_CHECKLIST.md`.

## 1) SSH and navigate to backend on VPS

```bash
ssh root@72.61.242.87
cd /opt
git clone <your-repo-url> "Dating apps"   # first-time only
cd "/opt/Dating apps/backend"
git pull origin main
```

If `ssh` fails from local machine, validate firewall/security-group inbound rule for TCP `22`.

## 2) Backend environment and Supabase config

Create backend runtime env file:

```bash
cd "/opt/Dating apps/backend"
cp config/.env.example config/.env
```

Edit `config/.env` with production values:

```dotenv
ENVIRONMENT=production
LOG_LEVEL=info

API_GATEWAY_ADDR=:8080
MOBILE_BFF_ADDR=:8081
MOBILE_BFF_UPSTREAM_URL=http://127.0.0.1:8081

SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE=<service-role-key>

SUPABASE_DB_HOST=db.<project-ref>.supabase.co
SUPABASE_DB_PORT=5432
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres
SUPABASE_DB_PASSWORD=<db-password>
SUPABASE_DB_SSLMODE=require

SUPABASE_USER_SCHEMA=user_management
SUPABASE_MATCHING_SCHEMA=matching
SUPABASE_ENGAGEMENT_SCHEMA=matching
SUPABASE_USERS_TABLE=users
SUPABASE_PREFERENCES_TABLE=preferences
SUPABASE_PHOTOS_TABLE=photos
SUPABASE_SWIPES_TABLE=swipes
SUPABASE_MATCHES_TABLE=matches
SUPABASE_MESSAGES_TABLE=messages
SUPABASE_UNLOCK_STATES_TABLE=match_unlock_states
SUPABASE_QUEST_TEMPLATES_TABLE=match_quest_templates
SUPABASE_QUEST_WORKFLOWS_TABLE=match_quest_workflows
SUPABASE_GESTURES_TABLE=match_gestures
```

Notes:
- `scripts/dev_up.sh` requires non-empty `SUPABASE_URL`.
- If `SUPABASE_URL` is omitted and `SUPABASE_DB_HOST=db.<project-ref>.supabase.co`, URL can be derived automatically.
- Keep `GATEWAY_SKIP_POSTGRES_PROBE=false` in production.

## 3) Apply required migrations in order

Run SQL migrations exactly in `backend/scripts_run_order.txt` order.

Minimum durable engagement set includes:
- `014_engagement_unlock_tables.sql`
- `018_match_gestures_effort_signals.sql`
- `020_engagement_surfaces_tables.sql`
- `021_social_graph_and_tag_filter_indexes.sql`
- `025_terms_acceptance_columns.sql`
- `028_daily_prompt_streak_tables.sql`
- `029_community_groups_tables.sql`
- `030_public_master_data_views.sql`
- `031_activity_notifications.sql`

This is critical because mobile-bff startup enforces `validateDurableEngagementReadiness`.

## 4) Build and start backend services

```bash
cd "/opt/Dating apps/backend"
go test ./...
make backend-compliance-check
make run-all
```

Stop services:

```bash
make stop-all
```

Read logs:

```bash
tail -f .run/logs/api-gateway.log
tail -f .run/logs/mobile-bff.log
```

Backend readiness checks (on VPS):

```bash
curl -i http://127.0.0.1:8080/healthz
curl -i http://127.0.0.1:8080/readyz
curl -i http://127.0.0.1:8081/healthz
curl -i http://127.0.0.1:8081/readyz
```

## 5) Nginx reverse proxy configuration (IP-only)

Create `/etc/nginx/sites-available/api-ip-only.conf`:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 25m;

    location /v1/ {
        proxy_pass http://127.0.0.1:8080/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        proxy_connect_timeout 10s;
    }

    location = /healthz      { proxy_pass http://127.0.0.1:8080/healthz; }
    location = /readyz       { proxy_pass http://127.0.0.1:8080/readyz; }
    location = /openapi.yaml { proxy_pass http://127.0.0.1:8080/openapi.yaml; }
    location = /docs         { proxy_pass http://127.0.0.1:8080/docs; }
    location /docs/          { proxy_pass http://127.0.0.1:8080/docs/; }

    location = / {
        return 200 "Dating API gateway is running\n";
        add_header Content-Type text/plain;
    }
}
```

Enable + restart Nginx:

```bash
sudo rm -f /etc/nginx/sites-enabled/*
sudo ln -sf /etc/nginx/sites-available/api-ip-only.conf /etc/nginx/sites-enabled/api-ip-only.conf
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx --no-pager
```

## 6) Public endpoint verification

Run from VPS or local machine:

```bash
curl -i http://72.61.242.87/healthz
curl -i http://72.61.242.87/readyz
curl -i http://72.61.242.87/openapi.yaml | head -n 20
curl -i http://72.61.242.87/docs | head -n 20
curl -i -X POST http://72.61.242.87/v1/auth/send-otp \
  -H 'Content-Type: application/json' \
  -d '{"email":"smoke@example.com"}'
```

Expected:
- `200 OK` for health/ready/docs/openapi
- `/v1/...` routes proxied correctly to gateway

## 7) Server operations and restart commands

Nginx:

```bash
sudo systemctl restart nginx
sudo systemctl reload nginx
sudo journalctl -u nginx -n 100 --no-pager
```

Backend processes managed by script:

```bash
cd "/opt/Dating apps/backend"
make stop-all
make run-all
cat .run/pids
```

If you use `tmux`/`screen` for persistent SSH sessions, restart inside that session.

## 8) Flutter production endpoint config (local)

In `app/.env.local`:

```dotenv
API_ENV=production
API_LOCAL_BASE_URL=http://10.0.2.2:8080/v1
API_PROD_BASE_URL=http://72.61.242.87/v1
```

Optional hard override (highest priority):

```dotenv
API_BASE_URL=http://72.61.242.87/v1
```

## 9) Troubleshooting

Nginx failed config test:

```bash
sudo nginx -t
sudo journalctl -xeu nginx.service --no-pager | tail -n 80
```

Backend not ready:

```bash
tail -n 150 .run/logs/mobile-bff.log
tail -n 150 .run/logs/api-gateway.log
```

Common cause: missing migration for terms/engagement tables can produce 502 on routes like `/v1/users/{userID}/agreements/terms`.
