#!/bin/bash
# Script to validate health checks across all services

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Alfred Agent Platform Health Check Validation ===${NC}"
echo "Validating health checks for all services..."

# Get all running containers
CONTAINERS=$(docker ps --format '{{.Names}}' | grep 'alfred-agent-platform-v2')

if [[ -z "$CONTAINERS" ]]; then
  echo -e "${RED}No running containers found. Is the platform running?${NC}"
  exit 1
fi

# Test results counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to check if a container has health check configured
check_health_config() {
  local container=$1
  
  # Check if container has HEALTHCHECK configuration
  local has_health=$(docker inspect --format='{{if .Config.Healthcheck}}true{{else}}false{{end}}' "$container")
  
  if [[ "$has_health" == "true" ]]; then
    local health_cmd=$(docker inspect --format='{{.Config.Healthcheck.Test}}' "$container")
    echo -e "${GREEN}✓${NC} Health check configured: $health_cmd"
    return 0
  else
    echo -e "${RED}✗${NC} No health check configured"
    return 1
  fi
}

# Function to check health check binary in container
check_health_binary() {
  local container=$1
  
  # Check if healthcheck binary exists
  if docker exec "$container" which healthcheck &>/dev/null; then
    local version=$(docker exec "$container" healthcheck --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓${NC} Health check binary found: $version"
    return 0
  else
    echo -e "${RED}✗${NC} Health check binary not found"
    return 1
  fi
}

# Function to check current health status
check_health_status() {
  local container=$1
  
  # Check current health status if container has health check
  local has_health=$(docker inspect --format='{{if .State.Health}}true{{else}}false{{end}}' "$container")
  
  if [[ "$has_health" == "true" ]]; then
    local status=$(docker inspect --format='{{.State.Health.Status}}' "$container")
    
    case "$status" in
      "healthy")
        echo -e "${GREEN}✓${NC} Current status: $status"
        return 0
        ;;
      "starting")
        echo -e "${YELLOW}⚠${NC} Current status: $status (still initializing)"
        return 2
        ;;
      "unhealthy")
        echo -e "${RED}✗${NC} Current status: $status"
        # Get the last health check log
        local log=$(docker inspect --format='{{range .State.Health.Log}}{{println .Output}}{{end}}' "$container" | tail -1)
        echo -e "${RED}   Last check output: ${log}${NC}"
        return 1
        ;;
      *)
        echo -e "${YELLOW}⚠${NC} Current status: $status (unknown state)"
        return 2
        ;;
    esac
  else
    echo -e "${YELLOW}⚠${NC} Health status not available"
    return 2
  fi
}

# Test each container
for container in $CONTAINERS; do
  echo -e "\n${BLUE}Testing container:${NC} $container"
  
  # Check health configuration
  config_result=0
  check_health_config "$container" || config_result=$?
  
  # Check health binary
  binary_result=0
  check_health_binary "$container" || binary_result=$?
  
  # Check health status
  status_result=0
  check_health_status "$container" || status_result=$?
  
  # Determine overall result for this container
  if [[ $config_result -eq 0 && $binary_result -eq 0 && $status_result -eq 0 ]]; then
    echo -e "${GREEN}Container health check validation PASSED${NC}"
    ((PASSED++))
  elif [[ $status_result -eq 2 ]]; then
    echo -e "${YELLOW}Container health check validation WARNING${NC}"
    ((WARNINGS++))
  else
    echo -e "${RED}Container health check validation FAILED${NC}"
    ((FAILED++))
  fi
done

# Print summary
echo -e "\n${BLUE}=== Health Check Validation Summary ===${NC}"
echo -e "${GREEN}PASSED:${NC} $PASSED containers"
echo -e "${YELLOW}WARNINGS:${NC} $WARNINGS containers"
echo -e "${RED}FAILED:${NC} $FAILED containers"

# Exit with appropriate status code
if [[ $FAILED -gt 0 ]]; then
  echo -e "\n${RED}Health check validation FAILED${NC}"
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo -e "\n${YELLOW}Health check validation PASSED with WARNINGS${NC}"
  exit 0
else
  echo -e "\n${GREEN}Health check validation PASSED${NC}"
  exit 0
fi