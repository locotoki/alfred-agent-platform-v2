#\!/usr/bin/env bash
set -e
TIMEOUT=${1:-90}            # max seconds to wait
INTERVAL=2                  # poll interval
elapsed=0
while true; do
  unhealthy=$(docker compose ps --format json  < /dev/null |  jq -r '.[] | select(.State \!= "running" or .Health\!="healthy") | .Name')
  if [[ -z "$unhealthy" ]]; then
    echo "✅ All containers healthy"
    exit 0
  fi
  if (( elapsed >= TIMEOUT )); then
    echo "❌ Timed out waiting for healthy containers:" $unhealthy >&2
    exit 1
  fi
  sleep $INTERVAL
  elapsed=$((elapsed+INTERVAL))
done
