#!/bin/bash
# Sync rotated secrets, fix missing artifacts, and revive failing services
set -euo pipefail

# 0 — Pull fresh secrets from vault/1Password (replace with your secret backend)
export POSTGRES_PASSWORD="$(pass show org/infra/postgres/password)"
export REDIS_PASSWORD="$(pass show org/infra/redis/password)"

# 1 — Ensure .env carries the new creds
grep -q '^POSTGRES_PASSWORD=' .env && sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${POSTGRES_PASSWORD}/" .env \
  || echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" >> .env
grep -q '^REDIS_PASSWORD=' .env && sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=${REDIS_PASSWORD}/" .env \
  || echo "REDIS_PASSWORD=${REDIS_PASSWORD}" >> .env

# 2 — Inject creds into all services that still hard-code them (needs yq v4)
yq -i '
  (.services[] | select(.image | test("postgres|supabase"))).environment.POSTGRES_PASSWORD = strenv(POSTGRES_PASSWORD) |
  (.services[] | select(.depends_on? | any(. == "redis"))).environment.REDIS_PASSWORD    = strenv(REDIS_PASSWORD)
' docker-compose.override.yml

# 3 — Recover ui-chat & crm-sync runtime blockers
docker compose cp services/ui-chat/streamlit_chat.py ui-chat:/app/streamlit_chat.py
docker compose exec crm-sync pip install --no-cache-dir --force-reinstall hubspot_mock_client

# 4 — Recreate the broken PostgreSQL stacks with fresh secrets
docker compose up -d --force-recreate db-storage db-auth db-api

# 5 — Restart all Redis-dependent services for new auth
docker compose up -d --force-recreate $(docker compose config --services | grep -vE '^(redis|db-|ui-chat|crm-sync)')

# 6 — Verify cluster health
docker compose ps
docker compose exec agent-core curl -fsSL http://localhost:8000/alfred/health
