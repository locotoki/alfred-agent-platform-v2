#!/usr/bin/env bash
set -e
TIMEOUT=${1:-90}            # max seconds to wait
INTERVAL=2                  # poll interval
elapsed=0

echo "Waiting for containers to be healthy..."

while true; do
  # Simple check - just ensure all expected containers are running
  running=$(docker compose ps --format "table {{.Service}}" | tail -n +2 | wc -l)
  if [[ $running -ge 4 ]]; then
    echo "✅ All $running containers running"
    exit 0
  fi

  if (( elapsed >= TIMEOUT )); then
    echo "❌ Timed out waiting for containers (only $running running)" >&2
    exit 1
  fi

  sleep $INTERVAL
  elapsed=$((elapsed+INTERVAL))
done
