#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Checking critical services health..."

# Define critical services
critical_services=(
    "redis"
    "db-postgres"
    "pubsub-emulator"
    "slack-bot"
)

# Check each service
all_healthy=true
for service in "${critical_services[@]}"; do
    status=$(docker compose ps --format '{{.Name}}\t{{.State}}\t{{.Health}}' | grep "^${service}" | awk '{print $2 "\t" $3}')
    if [[ -z "$status" ]]; then
        echo "❌ $service: not found"
        all_healthy=false
    elif [[ "$status" == *"running"*"healthy"* ]]; then
        echo "✅ $service: running & healthy"
    else
        echo "❌ $service: $status"
        all_healthy=false
    fi
done

echo ""
if [ "$all_healthy" = true ]; then
    echo "✅ All critical services are healthy!"
    echo ""
    echo "🔧 Testing Slack bot endpoint..."
    if curl -sf http://localhost:3012/health | jq; then
        echo ""
        echo "✅ Slack bot v3.1.0 is fully operational!"
    else
        echo "❌ Slack bot health check failed"
    fi
else
    echo "❌ Some critical services are unhealthy"
    exit 1
fi