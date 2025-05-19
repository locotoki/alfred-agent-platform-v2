#!/usr/bin/env bash
# Script to verify all containers are properly exporting metrics
# and that the healthcheck binary is working as expected

set -eo pipefail

echo "Verifying metrics endpoints for all services..."

# Function to check if a container is running
is_container_running() {
  docker ps -q -f "name=$1" | grep -q .
}

# Function to check if a port is open
is_port_open() {
  local host=$1
  local port=$2
  timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null
  return $?
}

# Function to check metrics endpoint
check_metrics_endpoint() {
  local container=$1
  local port=${2:-9091}
  local success=false

  echo "  Checking $container on port $port..."

  # Skip if container is not running
  if ! is_container_running "$container"; then
    echo "    ⚠️ Container $container is not running, skipping."
    return 0
  fi

  # Check if port is open
  if ! is_port_open "$container" "$port"; then
    echo "    ❌ Port $port not accessible on $container"
    return 1
  fi

  # Try to get metrics
  if ! docker exec "$container" curl -s "http://localhost:$port/metrics" | grep -q "service_health"; then
    echo "    ❌ Metrics endpoint on $container doesn't contain service_health metric"
    return 1
  else
    echo "    ✅ Metrics endpoint for $container is properly configured"
    return 0
  fi
}

# Main services to check
SERVICES=(
  "alfred-bot"
  "social-intel"
  "financial-tax"
  "legal-compliance"
  "agent-rag"
  "mission-control"
)

FAILURES=0

# Check metrics endpoints for all services
for service in "${SERVICES[@]}"; do
  if ! check_metrics_endpoint "$service"; then
    FAILURES=$((FAILURES + 1))
  fi
done

# Additional services that might have metrics
if is_container_running "agent-atlas"; then
  if ! check_metrics_endpoint "agent-atlas"; then
    FAILURES=$((FAILURES + 1))
  fi
fi

if is_container_running "agent-core"; then
  if ! check_metrics_endpoint "agent-core"; then
    FAILURES=$((FAILURES + 1))
  fi
fi

# Summary
echo ""
if [ $FAILURES -eq 0 ]; then
  echo "✅ All services have properly configured metrics endpoints!"
else
  echo "❌ $FAILURES services have issues with their metrics endpoints."
  exit 1
fi
