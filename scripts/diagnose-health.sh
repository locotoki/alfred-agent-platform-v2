#!/bin/bash
# Health diagnostics for P0 stability freeze requirement

echo "🏥 Health Diagnostics - $(date)"
echo "================================"
echo "Goal: ≤2 unhealthy containers"
echo ""

# Count statuses
TOTAL=$(docker ps -q | wc -l)
HEALTHY=$(docker ps --format "{{.Status}}" | grep -c "(healthy)" || true)
UNHEALTHY=$(docker ps --format "{{.Status}}" | grep -c "(unhealthy)" || true)

echo "📊 Summary: $HEALTHY healthy, $UNHEALTHY unhealthy (of $TOTAL total)"

if [ $UNHEALTHY -le 2 ]; then
    echo "✅ PASSING GA REQUIREMENT"
else
    echo "❌ FAILING GA REQUIREMENT"
fi

echo ""
echo "📋 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v "NAMES"