#!/usr/bin/env bash
set -euo pipefail

# Define core services list (matching CI workflow - excluding agent-core due to llm-service dependency)
CORE_SERVICES="redis|redis-exporter|db-postgres|db-api|telegram-adapter|pubsub-emulator|pubsub-metrics|monitoring-metrics|monitoring-dashboard"

# Capture raw inventory - deterministic output only
docker compose ps --format '{{.Name}} {{.Image}} {{.Status}}' | grep -E "^($CORE_SERVICES) " | LC_ALL=C sort
echo '---'

# Healthcheck configuration without container IDs - only core services
docker compose ps --format '{{.Name}}' | grep -E "^($CORE_SERVICES)$" | while read container; do
  docker inspect "$container" \
    --format '{{.Name}} {{if .Config.Healthcheck}}{{json .Config.Healthcheck.Test}}{{else}}"no-healthcheck"{{end}}'
done | LC_ALL=C sort
echo '---'

# Postgres roles (stable)
docker compose exec -T -e PGPASSWORD="${POSTGRES_PASSWORD:-postgres}" db-postgres \
  psql -U postgres -Atc \
  "SELECT rolname || ':' || rolsuper FROM pg_roles ORDER BY 1;" 2>/dev/null | LC_ALL=C sort || true