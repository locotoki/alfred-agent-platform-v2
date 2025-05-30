#!/usr/bin/env bash
# scripts/run-core-slice.sh  ─ run only GA-critical services

set -euo pipefail

CORE_SVCS=(
  redis redis-exporter
  db-postgres db-api
  agent-core telegram-adapter
  pubsub-metrics monitoring-metrics monitoring-dashboard
)

echo "🧹  Stopping ALL containers…"
docker compose down --remove-orphans

echo "🚀  Bringing up Core Slice only…"
docker compose up -d --no-deps "${CORE_SVCS[@]}"

echo "⏳  Waiting 60 s for health probes…"
sleep 60

echo "📊  Health status:"
docker compose ps --services --filter "status=running" | \
  xargs -I {} bash -c 'printf "%-22s" {}; docker inspect -f "{{.State.Health.Status}}" {} || echo "n/a"'