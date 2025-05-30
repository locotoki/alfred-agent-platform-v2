#!/usr/bin/env bash
set -euo pipefail

echo "🔎 Core Baseline Audit Report"
echo "================================"
echo "Generated: $(date)"
echo

echo "📦 Images & Digests"
echo "-------------------"
docker compose ps --format '{{.Name}}: {{.Image}}' | sort

echo
echo "🩺 Health Check Configuration Hash"
echo "----------------------------------"
docker inspect $(docker compose ps -q) \
  --format '{{.Name}} {{if .Config.Healthcheck}}{{.Config.Healthcheck.Test}}{{else}}no-healthcheck{{end}}' \
  | sha256sum

echo
echo "🎛️ PostgreSQL Roles & Permissions"
echo "---------------------------------"
docker compose exec -T db-postgres \
  psql -U postgres -Atc \
  "SELECT rolname || ':' || rolsuper || ':' || rolreplication FROM pg_roles ORDER BY 1;" 2>/dev/null || echo "Failed to query PostgreSQL roles"

echo
echo "🔐 PostgreSQL Security Settings"
echo "-------------------------------"
if docker compose exec -T db-postgres true 2>/dev/null; then
    echo -n "SSL: "
    docker compose exec -T db-postgres psql -U postgres -Atc "SHOW ssl;" 2>/dev/null || echo "query failed"
    echo -n "Password Encryption: "
    docker compose exec -T db-postgres psql -U postgres -Atc "SHOW password_encryption;" 2>/dev/null || echo "query failed"
    echo -n "Shared Libraries: "
    docker compose exec -T db-postgres psql -U postgres -Atc "SHOW shared_preload_libraries;" 2>/dev/null || echo "query failed"
    echo -n "Log Connections: "
    docker compose exec -T db-postgres psql -U postgres -Atc "SHOW log_connections;" 2>/dev/null || echo "query failed"
else
    echo "PostgreSQL container not accessible"
fi

echo
echo "📊 Container Health Summary"
echo "--------------------------"
healthy_count=$(docker compose ps --format '{{.Status}}' | grep -c "(healthy)" || true)
unhealthy_count=$(docker compose ps --format '{{.Status}}' | grep -c "(unhealthy)" || true)
starting_count=$(docker compose ps --format '{{.Status}}' | grep -c "(health: starting)" || true)
total_count=$(docker compose ps -q | wc -l)

echo "Total containers: $total_count"
echo "Healthy: $healthy_count"
echo "Unhealthy: $unhealthy_count"
echo "Starting: $starting_count"

if [ "$unhealthy_count" -le 2 ]; then
    echo "✅ PASSING GA REQUIREMENT (≤2 unhealthy)"
else
    echo "❌ FAILING GA REQUIREMENT (>2 unhealthy)"
fi