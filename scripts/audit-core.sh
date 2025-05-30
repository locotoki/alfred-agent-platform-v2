#!/usr/bin/env bash
set -euo pipefail

# Capture raw inventory - deterministic output only
docker compose ps --format '{{.Name}} {{.Image}} {{.Status}}' | sort
echo '---'

# Healthcheck configuration without container IDs
docker inspect $(docker compose ps -q) \
  --format '{{.Name}} {{if .Config.Healthcheck}}{{json .Config.Healthcheck.Test}}{{else}}"no-healthcheck"{{end}}' | sort
echo '---'

# Postgres roles (stable)
docker compose exec -T -e PGPASSWORD="${POSTGRES_PASSWORD:-postgres}" db-postgres \
  psql -U postgres -Atc \
  "SELECT rolname || ':' || rolsuper FROM pg_roles ORDER BY 1;" 2>/dev/null | sort || true