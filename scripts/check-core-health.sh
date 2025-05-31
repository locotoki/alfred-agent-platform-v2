#!/usr/bin/env bash
# Quick health check for core services

set -euo pipefail

echo "🏥 Core Services Health Check"
echo "============================="
echo "Time: $(date)"
echo

# Check container states
healthy=0
unhealthy=0
starting=0

while IFS=: read -r name status; do
    name=$(echo "$name" | xargs)
    status=$(echo "$status" | xargs)
    
    if [[ "$status" == *"(healthy)"* ]]; then
        echo "✅ $name: healthy"
        ((healthy++))
    elif [[ "$status" == *"(unhealthy)"* ]]; then
        echo "❌ $name: unhealthy"
        ((unhealthy++))
    elif [[ "$status" == *"(health: starting)"* ]]; then
        echo "⏳ $name: starting"
        ((starting++))
    else
        echo "❓ $name: $status"
    fi
done < <(docker compose -p ${COMPOSE_PROJECT:-alfred} -f ${COMPOSE_FILE:-docker-compose.yml} ps --all --format '{{.Name}}: {{.Status}}')

echo
echo "📊 Summary:"
echo "  Healthy: $healthy"
echo "  Unhealthy: $unhealthy"
echo "  Starting: $starting"
echo "  Total: $((healthy + unhealthy + starting))"

if [ $unhealthy -le 2 ]; then
    echo
    echo "✅ PASSING GA REQUIREMENT (≤2 unhealthy)"
    exit 0
else
    echo
    echo "❌ FAILING GA REQUIREMENT (>2 unhealthy)"
    exit 1
fi