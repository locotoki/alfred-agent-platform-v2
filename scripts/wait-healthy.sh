#!/bin/bash
set -euo pipefail

# Wait for healthy status on core services
max_attempts=60
attempt=0

echo "Waiting for services to become healthy..."

while [ $attempt -lt $max_attempts ]; do
    # Get unhealthy count, handle potential errors
    unhealthy=$(docker compose -f docker-compose.ci-core.yml ps --format json 2>/dev/null | \
                jq -r 'select(.Health == "unhealthy" or .Health == "starting") | .Name' 2>/dev/null | \
                wc -l || echo "999")
    
    if [ "$unhealthy" -eq 0 ]; then
        echo "✅ All services are healthy!"
        exit 0
    fi
    
    echo "Attempt $((attempt + 1))/$max_attempts: $unhealthy services still unhealthy/starting"
    sleep 10
    ((attempt++))
done

echo "❌ Timeout: Services did not become healthy within $((max_attempts * 10)) seconds"
echo "Current service status:"
docker compose -f docker-compose.ci-core.yml ps
exit 1