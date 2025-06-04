#!/usr/bin/env bash
# Quick health check for core services

echo "🏥 Core Services Health Check"
echo "============================="
echo "Time: $(date)"
echo

# Check container states
healthy=0
unhealthy=0
starting=0
total=0

# Get all container statuses
statuses=$(docker compose -p ${COMPOSE_PROJECT:-alfred} -f ${COMPOSE_FILE:-docker-compose.yml} ps --all --format '{{.Name}}: {{.Status}}' 2>/dev/null)

# Process each line
while IFS= read -r line; do
    if [[ -z "$line" ]]; then
        continue
    fi
    
    total=$((total + 1))
    
    if [[ "$line" == *"(healthy)"* ]]; then
        echo "✅ ${line%%:*}: healthy"
        healthy=$((healthy + 1))
    elif [[ "$line" == *"(unhealthy)"* ]]; then
        echo "❌ ${line%%:*}: unhealthy"
        unhealthy=$((unhealthy + 1))
    elif [[ "$line" == *"(health: starting)"* ]]; then
        echo "⏳ ${line%%:*}: starting"
        starting=$((starting + 1))
    else
        echo "❓ $line"
    fi
done <<< "$statuses"

echo
echo "📊 Summary:"
echo "  Healthy: $healthy"
echo "  Unhealthy: $unhealthy"
echo "  Starting: $starting"
echo "  Total: $total"

if [ $unhealthy -le 2 ]; then
    echo
    echo "✅ PASSING GA REQUIREMENT (≤2 unhealthy)"
    exit 0
else
    echo
    echo "❌ FAILING GA REQUIREMENT (>2 unhealthy)"
    exit 1
fi