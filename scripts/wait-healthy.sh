#!/bin/bash
set -euo pipefail
trap "docker compose -f docker-compose.ci-core.yml down -v" EXIT

# Wait for healthy status on core services
max_attempts=60
attempt=0

echo "Waiting for services to become healthy..."

while [ $attempt -lt $max_attempts ]; do
    unhealthy=$(docker compose -f docker-compose.ci-core.yml ps --format json | jq -r 'select(.Health == "unhealthy" or .Health == "starting") | .Name' | wc -l)
    
    if [ "$unhealthy" -eq 0 ]; then
        echo "✅ healthy"
        exit 0
    fi
    
    echo "Attempt $((attempt + 1))/$max_attempts: $unhealthy services still unhealthy/starting"
    sleep 10
    ((attempt++))
done

echo "❌ Timeout: Services did not become healthy within $((max_attempts * 10)) seconds"
docker compose -f docker-compose.ci-core.yml ps
exit 1
# Trigger CI
