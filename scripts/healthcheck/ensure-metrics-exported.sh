#!/usr/bin/env bash
# Script to verify all containers are properly exporting metrics
# and that the healthcheck binary is working as expected.
# This script checks:
#  1. Runtime metrics endpoints on running containers
#  2. Docker compose configuration for prometheus.metrics.port labels
#  3. Dockerfile configuration to include healthcheck binary
#  4. Prometheus configuration for scraping metrics endpoints

set -eo pipefail

# Base directory - automatically determine from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCKER_COMPOSE_FILE="${BASE_DIR}/docker-compose.yml"
PROMETHEUS_CONFIG="${BASE_DIR}/monitoring/prometheus/prometheus.yml"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Verifying metrics endpoints for all services ===${NC}"
echo ""

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
  
  echo -e "  ${YELLOW}Checking $container on port $port...${NC}"
  
  # Skip if container is not running
  if ! is_container_running "$container"; then
    echo -e "    ${YELLOW}⚠️ Container $container is not running, skipping.${NC}"
    return 0
  fi
  
  # Check if port is open
  if ! is_port_open "$container" "$port"; then
    echo -e "    ${RED}❌ Port $port not accessible on $container${NC}"
    return 1
  fi
  
  # Try to get metrics
  if ! docker exec "$container" curl -s "http://localhost:$port/metrics" | grep -q "service_health"; then
    echo -e "    ${RED}❌ Metrics endpoint on $container doesn't contain service_health metric${NC}"
    return 1
  else
    echo -e "    ${GREEN}✅ Metrics endpoint for $container is properly configured${NC}"
    return 0
  fi
}

# Function to check if compose file has proper metrics port labels
check_compose_metrics_labels() {
  echo -e "${GREEN}=== Checking docker-compose.yml for Prometheus metrics labels ===${NC}"
  echo ""
  
  if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Docker compose file not found at $DOCKER_COMPOSE_FILE${NC}"
    return 1
  fi
  
  # Extract service names from docker-compose.yml
  local services=$(grep -A 1 "services:" "$DOCKER_COMPOSE_FILE" | grep -v "services:" | grep -v "\-\-" | awk '{print $1}' | sed 's/://g')
  
  local label_failures=0
  
  for service in $services; do
    # Skip empty service names or comments
    [[ "$service" == "#"* || -z "$service" ]] && continue
    
    # Check if service has prometheus.metrics.port label
    if grep -q -A 20 "^  $service:" "$DOCKER_COMPOSE_FILE" | grep -q "prometheus.metrics.port"; then
      # Extract the port value
      local port_value=$(grep -A 20 "^  $service:" "$DOCKER_COMPOSE_FILE" | grep -m 1 "prometheus.metrics.port" | awk -F'"' '{print $2}')
      echo -e "  ${GREEN}✅ Service $service has prometheus.metrics.port: $port_value${NC}"
    else
      echo -e "  ${RED}❌ Service $service missing prometheus.metrics.port label${NC}"
      label_failures=$((label_failures + 1))
    fi
  done
  
  echo ""
  if [ $label_failures -eq 0 ]; then
    echo -e "${GREEN}✅ All services in docker-compose.yml have proper metrics labels${NC}"
    return 0
  else
    echo -e "${RED}❌ $label_failures services are missing prometheus.metrics.port labels${NC}"
    return 1
  fi
}

# Function to check if Dockerfiles have healthcheck binary
check_dockerfile_healthcheck() {
  echo -e "${GREEN}=== Checking Dockerfiles for healthcheck binary and port exposure ===${NC}"
  echo ""
  
  local dockerfile_failures=0
  
  # Find all Dockerfiles in the project
  local dockerfiles=$(find "${BASE_DIR}" -name "Dockerfile" | grep -v "node_modules")
  
  for dockerfile in $dockerfiles; do
    local service_dir=$(dirname "$dockerfile")
    local service_name=$(basename "$service_dir")
    
    echo -e "  ${YELLOW}Checking $service_name Dockerfile...${NC}"
    
    # Check for healthcheck binary
    if grep -q "healthcheck:.*" "$dockerfile" || grep -q "COPY --from=healthcheck" "$dockerfile"; then
      echo -e "    ${GREEN}✅ Has healthcheck binary${NC}"
    else
      echo -e "    ${RED}❌ Missing healthcheck binary${NC}"
      dockerfile_failures=$((dockerfile_failures + 1))
    fi
    
    # Check for port 9091 exposure
    if grep -q "EXPOSE.*9091" "$dockerfile"; then
      echo -e "    ${GREEN}✅ Exposes port 9091 for metrics${NC}"
    else
      echo -e "    ${RED}❌ Not exposing port 9091 for metrics${NC}"
      dockerfile_failures=$((dockerfile_failures + 1))
    fi
    
    # Check for --export-prom in CMD or ENTRYPOINT
    if grep -q "export-prom" "$dockerfile"; then
      echo -e "    ${GREEN}✅ Has metrics export configured in CMD/ENTRYPOINT${NC}"
    else
      echo -e "    ${YELLOW}⚠️ May be missing --export-prom in CMD/ENTRYPOINT${NC}"
      # This is just a warning, not a failure
    fi
    
    echo ""
  done
  
  if [ $dockerfile_failures -eq 0 ]; then
    echo -e "${GREEN}✅ All Dockerfiles properly configured for healthcheck${NC}"
    return 0
  else
    echo -e "${RED}❌ $dockerfile_failures issues found in Dockerfiles${NC}"
    return 1
  fi
}

# Function to check if Prometheus is configured to scrape metrics
check_prometheus_config() {
  echo -e "${GREEN}=== Checking Prometheus configuration for metrics scraping ===${NC}"
  echo ""
  
  if [ ! -f "$PROMETHEUS_CONFIG" ]; then
    echo -e "${RED}❌ Prometheus config not found at $PROMETHEUS_CONFIG${NC}"
    return 1
  fi
  
  # Check if prometheus.yml has metrics_path
  if grep -q "metrics_path: '/metrics'" "$PROMETHEUS_CONFIG"; then
    echo -e "  ${GREEN}✅ Prometheus is configured with correct metrics_path${NC}"
  else
    echo -e "  ${RED}❌ Prometheus missing metrics_path: '/metrics' configuration${NC}"
    return 1
  fi
  
  # Check for port 9091
  if grep -q "port: '9091'" "$PROMETHEUS_CONFIG"; then
    echo -e "  ${GREEN}✅ Prometheus is configured to scrape port 9091${NC}"
  else
    echo -e "  ${RED}❌ Prometheus may not be configured to scrape port 9091${NC}"
    return 1
  fi
  
  echo -e "  ${GREEN}✅ Prometheus configuration appears correct${NC}"
  return 0
}

# Main services to check at runtime
SERVICES=(
  "agent-core"
  "agent-social"
  "agent-financial"
  "agent-legal"
  "agent-rag"
  "model-registry"
)

RUNTIME_FAILURES=0

echo -e "${GREEN}=== Checking runtime metrics endpoints on running containers ===${NC}"
echo ""

# Check metrics endpoints for all running services
for service in "${SERVICES[@]}"; do
  if ! check_metrics_endpoint "$service"; then
    RUNTIME_FAILURES=$((RUNTIME_FAILURES + 1))
  fi
done

# Additional services that might have metrics
if is_container_running "agent-atlas"; then
  if ! check_metrics_endpoint "agent-atlas"; then
    RUNTIME_FAILURES=$((RUNTIME_FAILURES + 1))
  fi
fi

if is_container_running "ui-chat"; then
  if ! check_metrics_endpoint "ui-chat"; then
    RUNTIME_FAILURES=$((RUNTIME_FAILURES + 1))
  fi
fi

# Check configuration files
CONFIG_FAILURES=0

# Check Docker Compose configuration
if ! check_compose_metrics_labels; then
  CONFIG_FAILURES=$((CONFIG_FAILURES + 1))
fi

# Check Dockerfile configuration
if ! check_dockerfile_healthcheck; then
  CONFIG_FAILURES=$((CONFIG_FAILURES + 1))
fi

# Check Prometheus configuration
if ! check_prometheus_config; then
  CONFIG_FAILURES=$((CONFIG_FAILURES + 1))
fi

# Final summary
echo ""
echo -e "${GREEN}=== Metrics Export Verification Summary ===${NC}"
echo ""

if [ $RUNTIME_FAILURES -eq 0 ]; then
  echo -e "${GREEN}✅ All running services have properly configured metrics endpoints!${NC}"
else
  echo -e "${RED}❌ $RUNTIME_FAILURES running services have issues with their metrics endpoints.${NC}"
fi

if [ $CONFIG_FAILURES -eq 0 ]; then
  echo -e "${GREEN}✅ All configuration files are properly set up for metrics export!${NC}"
else
  echo -e "${RED}❌ $CONFIG_FAILURES configuration issues found that need to be fixed.${NC}"
fi

TOTAL_FAILURES=$((RUNTIME_FAILURES + CONFIG_FAILURES))
if [ $TOTAL_FAILURES -eq 0 ]; then
  echo -e "${GREEN}✅ Overall: Metrics export is properly configured!${NC}"
  exit 0
else
  echo -e "${RED}❌ Overall: $TOTAL_FAILURES issues found with metrics export configuration.${NC}"
  echo ""
  echo -e "${YELLOW}Fix suggestions:${NC}"
  echo -e "  1. Update Dockerfiles to include healthcheck binary:"
  echo -e "     FROM ghcr.io/alfred/healthcheck:0.4.0 as healthcheck"
  echo -e "     COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/"
  echo -e "  2. Expose port 9091 in Dockerfiles: EXPOSE 9091"
  echo -e "  3. Add prometheus.metrics.port: \"9091\" label in docker-compose.yml"
  echo -e "  4. Update ENTRYPOINT/CMD to start healthcheck with --export-prom :9091"
  echo -e "  5. Update Prometheus configuration to include port 9091 and metrics_path"
  exit 1
fi