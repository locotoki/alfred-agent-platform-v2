#!/bin/bash
# Verify all health endpoints are working correctly

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Service definitions - name, health url, metrics url
declare -a SERVICES=(
  "agent-core;http://localhost:8011/health;http://localhost:9091/metrics"
  "model-registry;http://localhost:8079/health;http://localhost:9093/metrics"
  "model-router;http://localhost:8080/health;http://localhost:9094/metrics"
  "agent-financial;http://localhost:9003/health;http://localhost:9096/metrics"
  "agent-legal;http://localhost:9002/health;http://localhost:9097/metrics"
  "ui-chat;http://localhost:8502/health;http://localhost:9098/metrics"
  "agent-rag;http://localhost:8501/health;http://localhost:9099/metrics"
)

# Header
echo -e "${YELLOW}===== Health Check Validation =====${NC}"
echo "Testing health endpoints for all services..."
echo

# Function to check URL and parse response
check_endpoint() {
  local name=$1
  local url=$2
  local type=$3
  
  echo -n "Checking $name $type endpoint ($url): "
  
  # Try to get the URL with a short timeout
  response=$(curl -s -m 2 "$url" 2>/dev/null || echo "ERROR")
  
  if [[ "$response" == "ERROR" ]]; then
    echo -e "${RED}FAILED (connection error)${NC}"
    return 1
  elif [[ "$type" == "health" ]]; then
    # Check for status field in JSON response
    if echo "$response" | grep -q '"status":"ok"'; then
      echo -e "${GREEN}OK${NC}"
      return 0
    else
      echo -e "${RED}FAILED (bad status)${NC}"
      echo "Response: $response"
      return 1
    fi
  elif [[ "$type" == "metrics" ]]; then
    # Check for service_health in Prometheus output
    if echo "$response" | grep -q "service_health"; then
      echo -e "${GREEN}OK${NC}"
      return 0
    else
      echo -e "${RED}FAILED (missing metrics)${NC}"
      echo "Response: ${response:0:100}..."
      return 1
    fi
  fi
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}Error: Docker is not running or not accessible.${NC}"
  exit 1
fi

# Check if our services are running
if ! docker-compose ps | grep -q "agent-core"; then
  echo -e "${RED}Error: Services are not running. Start with 'docker-compose up -d'${NC}"
  exit 1
fi

# Track failures
FAILURES=0

# Check each service
for service in "${SERVICES[@]}"; do
  IFS=';' read -r name health_url metrics_url <<< "$service"
  
  echo -e "${YELLOW}Service: $name${NC}"
  check_endpoint "$name" "$health_url" "health" || ((FAILURES++))
  check_endpoint "$name" "$metrics_url" "metrics" || ((FAILURES++))
  echo
done

# Summary
echo -e "${YELLOW}===== Summary =====${NC}"

if [ $FAILURES -eq 0 ]; then
  echo -e "${GREEN}All health checks passed!${NC}"
  exit 0
else
  echo -e "${RED}$FAILURES health checks failed.${NC}"
  echo "Please check the individual services for issues."
  exit 1
fi