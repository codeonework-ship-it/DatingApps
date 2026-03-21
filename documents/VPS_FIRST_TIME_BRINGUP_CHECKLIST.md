# VPS First-Time Bring-Up Checklist (Copy/Paste)

Use this when provisioning backend + Nginx on a fresh VPS for the first time.

## Bring-up Commands (12 commands)

```bash
# 1) SSH into VPS
ssh root@72.61.242.87

# 2) Install system deps
apt update && apt install -y git curl nginx ca-certificates

# 3) Install Go (if missing)
command -v go || (curl -fsSL https://go.dev/dl/go1.24.1.linux-amd64.tar.gz -o /tmp/go.tgz && rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tgz && echo 'export PATH=$PATH:/usr/local/go/bin' >/etc/profile.d/go.sh)

# 4) Clone repo
cd /opt && git clone <your-repo-url> "Dating apps"

# 5) Open backend
cd "/opt/Dating apps/backend"

# 6) Create backend env file
cp config/.env.example config/.env

# 7) Edit production env values (Supabase keys, DB host/password, schema mapping)
nano config/.env

# 8) Pull latest code
git pull origin main

# 9) Run backend preflight checks
go test ./... && make backend-compliance-check

# 10) Start backend services
make run-all

# 11) Install/enable nginx api proxy config
cat >/etc/nginx/sites-available/api-ip-only.conf <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location /v1/ {
        proxy_pass http://127.0.0.1:8080/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location = /healthz      { proxy_pass http://127.0.0.1:8080/healthz; }
    location = /readyz       { proxy_pass http://127.0.0.1:8080/readyz; }
    location = /openapi.yaml { proxy_pass http://127.0.0.1:8080/openapi.yaml; }
    location = /docs         { proxy_pass http://127.0.0.1:8080/docs; }
    location /docs/          { proxy_pass http://127.0.0.1:8080/docs/; }
}
NGINX

# 12) Enable nginx + verify
rm -f /etc/nginx/sites-enabled/* && ln -sf /etc/nginx/sites-available/api-ip-only.conf /etc/nginx/sites-enabled/api-ip-only.conf && nginx -t && systemctl restart nginx && systemctl --no-pager status nginx
```

## Verify Commands

```bash
curl -i http://127.0.0.1:8080/readyz
curl -i http://72.61.242.87/readyz
curl -i http://72.61.242.87/openapi.yaml | head -n 20
curl -i http://72.61.242.87/docs | head -n 20
```

## Rollback (Nginx + Backend Restarts)

Use this if a deploy causes errors or 502 responses.

```bash
# A) Keep server reachable: fallback nginx default page
cp -f /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/api-ip-only.conf
nginx -t && systemctl restart nginx

# B) Roll back backend code to previous commit
cd "/opt/Dating apps/backend"
git log --oneline -n 5
git checkout <previous-good-commit>

# C) Restart backend from rolled-back commit
make stop-all
make run-all

# D) Re-enable API nginx config after backend recovers
ln -sf /etc/nginx/sites-available/api-ip-only.conf /etc/nginx/sites-enabled/api-ip-only.conf
nginx -t && systemctl restart nginx

# E) Validate health after rollback
curl -i http://127.0.0.1:8080/readyz
curl -i http://72.61.242.87/readyz
```

## Notes

- Apply SQL migrations in `backend/scripts_run_order.txt` before enabling new API features.
- If `/v1/users/{userID}/agreements/terms` returns `502`, inspect `backend/.run/logs/mobile-bff.log` for missing schema/migration readiness.
