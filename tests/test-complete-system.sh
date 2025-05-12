#!/bin/bash
#
# Alfred Agent Platform v2 - Complete System Test
# This script runs a comprehensive test of the entire platform
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration variables
COMPOSE_FILE="../docker-compose.complete-test.yml"
TEST_TIMEOUT=300  # 5 minutes timeout for all services to be healthy

# Display ASCII art banner
function print_banner() {
  echo -e "${BLUE}"
  echo "    _    _  __               _   "
  echo "   / \  | |/ _|_ __ ___  __| |  "
  echo "  / _ \ | | |_| '__/ _ \/ _\` |  "
  echo " / ___ \| |  _| | |  __/ (_| |  "
  echo "/_/   \_\_|_| |_|  \___|\__,_|  "
  echo "                               "
  echo " Agent Platform v2 - Complete System Test"
  echo -e "${NC}"
}

# Check if all required services are defined in the compose file
function check_service_definitions() {
  echo -e "${YELLOW}Checking service definitions...${NC}"
  
  # Define required services
  local REQUIRED_SERVICES=(
    "redis"
    "vector-db"
    "pubsub-emulator"
    "db-postgres"
    "agent-core"
    "agent-rag"
    "monitoring-metrics"
    "monitoring-dashboard"
  )
  
  # Check if docker-compose file exists
  if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo -e "${RED}Error: Docker Compose file not found at $COMPOSE_FILE${NC}"
    exit 1
  else
    echo -e "${GREEN}✓ Docker Compose file found${NC}"
  fi
  
  # Get list of services from docker-compose file
  local DEFINED_SERVICES=$(docker-compose -f "$COMPOSE_FILE" config --services)
  
  # Check each required service
  local MISSING_SERVICES=()
  for service in "${REQUIRED_SERVICES[@]}"; do
    if echo "$DEFINED_SERVICES" | grep -q "$service"; then
      echo -e "${GREEN}✓ Service $service is defined${NC}"
    else
      echo -e "${RED}✗ Service $service is missing${NC}"
      MISSING_SERVICES+=("$service")
    fi
  done
  
  # Exit if any required services are missing
  if [[ ${#MISSING_SERVICES[@]} -gt 0 ]]; then
    echo -e "${RED}Error: Missing required services: ${MISSING_SERVICES[*]}${NC}"
    exit 1
  fi
}

# Start all services and validate they come up correctly
function start_and_validate_services() {
  echo -e "${YELLOW}Starting services...${NC}"
  
  # Start services in detached mode
  cd $(dirname "$COMPOSE_FILE") && docker-compose -f $(basename "$COMPOSE_FILE") up -d
  
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to start services${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}Waiting for services to be ready (up to $TEST_TIMEOUT seconds)...${NC}"
  local START_TIME=$(date +%s)
  local END_TIME=$((START_TIME + TEST_TIMEOUT))
  local ALL_HEALTHY=false
  
  while [[ $(date +%s) -lt $END_TIME ]]; do
    local UNHEALTHY_SERVICES=()
    local SERVICES=$(docker-compose -f "$COMPOSE_FILE" ps --services)
    
    for service in $SERVICES; do
      local STATUS=$(docker inspect --format='{{.State.Health.Status}}' $(docker-compose -f "$COMPOSE_FILE" ps -q $service) 2>/dev/null)
      
      # If the service doesn't have a health check, consider it running if it's up
      if [[ "$STATUS" == "<nil>" || -z "$STATUS" ]]; then
        STATUS=$(docker inspect --format='{{.State.Status}}' $(docker-compose -f "$COMPOSE_FILE" ps -q $service) 2>/dev/null)
        if [[ "$STATUS" == "running" ]]; then
          echo -e "${GREEN}✓ $service is running (no health check)${NC}"
        else
          echo -e "${RED}✗ $service is not running${NC}"
          UNHEALTHY_SERVICES+=("$service")
        fi
      elif [[ "$STATUS" == "healthy" ]]; then
        echo -e "${GREEN}✓ $service is healthy${NC}"
      else
        echo -e "${YELLOW}⟳ $service is $STATUS${NC}"
        UNHEALTHY_SERVICES+=("$service")
      fi
    done
    
    if [[ ${#UNHEALTHY_SERVICES[@]} -eq 0 ]]; then
      ALL_HEALTHY=true
      break
    fi
    
    echo -e "${YELLOW}Waiting for ${#UNHEALTHY_SERVICES[@]} services to be ready: ${UNHEALTHY_SERVICES[*]}${NC}"
    sleep 10
  done
  
  if [[ "$ALL_HEALTHY" == true ]]; then
    echo -e "${GREEN}All services are ready!${NC}"
  else
    echo -e "${RED}Error: Not all services became ready within the timeout period${NC}"
    exit 1
  fi
}

# Check API endpoints for each service
function test_api_endpoints() {
  echo -e "${YELLOW}Testing API endpoints...${NC}"
  
  # Test agent-core endpoints
  echo -e "${YELLOW}Testing agent-core endpoints...${NC}"
  local CORE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8011/health)
  if [[ "$CORE_STATUS" == "200" ]]; then
    echo -e "${GREEN}✓ agent-core health endpoint is responding${NC}"
  else
    echo -e "${RED}✗ agent-core health endpoint returned $CORE_STATUS${NC}"
  fi
  
  # Test agent-rag endpoints
  echo -e "${YELLOW}Testing agent-rag endpoints...${NC}"
  local RAG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8501/health)
  if [[ "$RAG_STATUS" == "200" ]]; then
    echo -e "${GREEN}✓ agent-rag health endpoint is responding${NC}"
  else
    echo -e "${RED}✗ agent-rag health endpoint returned $RAG_STATUS${NC}"
  fi
  
  # Test monitoring endpoints
  echo -e "${YELLOW}Testing monitoring endpoints...${NC}"
  local PROMETHEUS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy)
  if [[ "$PROMETHEUS_STATUS" == "200" ]]; then
    echo -e "${GREEN}✓ Prometheus health endpoint is responding${NC}"
  else
    echo -e "${RED}✗ Prometheus health endpoint returned $PROMETHEUS_STATUS${NC}"
  fi
  
  local GRAFANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3005/api/health)
  if [[ "$GRAFANA_STATUS" == "200" ]]; then
    echo -e "${GREEN}✓ Grafana health endpoint is responding${NC}"
  else
    echo -e "${RED}✗ Grafana health endpoint returned $GRAFANA_STATUS${NC}"
  fi
  
  # Test database connection
  echo -e "${YELLOW}Testing database connection...${NC}"
  local DB_CMD="PGPASSWORD=${DB_PASSWORD:-your-super-secret-password} psql -h localhost -U ${DB_USER:-postgres} -d ${DB_NAME:-postgres} -c 'SELECT 1;'"
  local DB_RESULT=$(eval $DB_CMD 2>&1)
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Database connection is working${NC}"
  else
    echo -e "${RED}✗ Database connection failed: $DB_RESULT${NC}"
  fi
  
  # Test Redis connection
  echo -e "${YELLOW}Testing Redis connection...${NC}"
  local REDIS_RESULT=$(docker exec -i redis redis-cli PING)
  if [[ "$REDIS_RESULT" == "PONG" ]]; then
    echo -e "${GREEN}✓ Redis connection is working${NC}"
  else
    echo -e "${RED}✗ Redis connection failed: $REDIS_RESULT${NC}"
  fi
}

# Clean up services after testing
function cleanup_services() {
  echo -e "${YELLOW}Cleaning up services...${NC}"
  cd $(dirname "$COMPOSE_FILE") && docker-compose -f $(basename "$COMPOSE_FILE") down
  
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Warning: Failed to clean up services${NC}"
  else
    echo -e "${GREEN}Services cleaned up successfully${NC}"
  fi
}

# Main function
function main() {
  print_banner
  
  check_service_definitions
  start_and_validate_services
  test_api_endpoints
  
  echo -e "${GREEN}All tests completed successfully!${NC}"
  
  # Ask if services should be kept running
  read -p "Keep services running? (y/n) [n]: " KEEP_RUNNING
  if [[ "${KEEP_RUNNING,,}" != "y" ]]; then
    cleanup_services
  else
    echo -e "${YELLOW}Services are still running.${NC}"
    echo -e "To stop them later, run: cd $(dirname "$COMPOSE_FILE") && docker-compose -f $(basename "$COMPOSE_FILE") down"
  fi
}

# Execute main function
main