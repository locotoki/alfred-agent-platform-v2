#!/usr/bin/env bash
set -euo pipefail

echo "=== Docker Compose Health Check ==="
echo ""

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "✗ Docker is not running"
    exit 1
fi
echo "✓ Docker is running"

# Check compose file exists
if [ ! -f "docker-compose.generated.yml" ]; then
    echo "✗ docker-compose.generated.yml not found"
    echo "  Run 'make compose-generate' first"
    exit 1
fi
echo "✓ docker-compose.generated.yml exists"

# Count running services
RUNNING=$(docker compose -f docker-compose.generated.yml ps --format json | jq -r 'select(.State == "running")' | wc -l || echo "0")
TOTAL=$(docker compose -f docker-compose.generated.yml ps --format json | wc -l || echo "0")

echo ""
echo "Services: $RUNNING/$TOTAL running"

# Check key services
echo ""
echo "Key services status:"

for service in redis db-postgres grafana prometheus; do
    if docker compose -f docker-compose.generated.yml ps --format json | jq -r --arg svc "$service" 'select(.Service == $svc) | .State' | grep -q "running"; then
        echo "✓ $service is running"
    else
        echo "✗ $service is not running"
    fi
done

echo ""
echo "Use 'make up' to start all services"
echo "Use 'make down' to stop all services"
