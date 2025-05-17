#!/usr/bin/env bash
# Run a full health check of all services and report status

set -eo pipefail

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Change to project root
cd "${PROJECT_ROOT}"

# Header
echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}    ALFRED PLATFORM HEALTH CHECK    ${NC}"
echo -e "${GREEN}=========================================${NC}\n"

# Get all running services with docker-compose
echo -e "${GREEN}Getting running services...${NC}"
SERVICES=$(docker-compose ps --services --filter "status=running")

# Function to check a service's health
check_service_health() {
  local service=$1
  local host=$service
  local port="9091"  # Default metrics port
  local endpoint="/health"
  local url="http://${host}:${port}${endpoint}"
  
  echo -e "\n${GREEN}Checking ${service}...${NC}"
  
  # Get container ID for the service
  CONTAINER_ID=$(docker-compose ps -q ${service})
  if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}Service ${service} is not running${NC}"
    return 1
  fi
  
  # Get service IP address
  SERVICE_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_ID})
  if [ -z "$SERVICE_IP" ]; then
    echo -e "${YELLOW}Could not get IP for ${service}${NC}"
    return 1
  fi
  
  # Try to get health status
  echo -e "Checking health at ${url}..."
  local health_output
  if ! health_output=$(curl -s -m 5 -f ${url} 2>/dev/null); then
    echo -e "${YELLOW}Service ${service} does not expose /health endpoint on port 9091${NC}"
    # Try alternative legacy health endpoints
    if [[ "$service" == "alfred-bot" ]]; then
      url="http://${host}:8011/health"
    elif [[ "$service" == "social-intel" ]]; then
      url="http://${host}:9000/health"
    elif [[ "$service" == "financial-tax" ]]; then
      url="http://${host}:9003/health"
    elif [[ "$service" == "legal-compliance" ]]; then
      url="http://${host}:9002/health" 
    fi
    
    echo -e "Trying alternative endpoint: ${url}..."
    if ! health_output=$(curl -s -m 5 -f ${url} 2>/dev/null); then
      echo -e "${RED}Service ${service} is not exposing a health endpoint${NC}"
      return 1
    fi
  fi
  
  # Parse status from response
  local status
  if [[ "$health_output" == *"status"* ]]; then
    status=$(echo "$health_output" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
  else
    status="unknown"
  fi
  
  # Report status with color
  if [[ "$status" == "healthy" ]]; then
    echo -e "${GREEN}Service ${service} is ${status}${NC}"
  elif [[ "$status" == "degraded" ]]; then
    echo -e "${YELLOW}Service ${service} is ${status}${NC}"
  else
    echo -e "${RED}Service ${service} is ${status}${NC}"
  fi
  
  # Check for service dependencies
  if [[ "$health_output" == *"services"* ]]; then
    echo -e "\nDependencies:"
    local deps=$(echo "$health_output" | grep -o '"services":{[^}]*}' | sed 's/"services":{//g' | sed 's/}//g')
    local IFS=','
    read -ra DEP_ARRAY <<< "$deps"
    for dep in "${DEP_ARRAY[@]}"; do
      local dep_name=$(echo "$dep" | cut -d'"' -f2)
      local dep_status=$(echo "$dep" | cut -d'"' -f4)
      
      if [[ "$dep_status" == "healthy" ]]; then
        echo -e "  - ${GREEN}${dep_name}: ${dep_status}${NC}"
      elif [[ "$dep_status" == "degraded" ]]; then
        echo -e "  - ${YELLOW}${dep_name}: ${dep_status}${NC}"
      else
        echo -e "  - ${RED}${dep_name}: ${dep_status}${NC}"
      fi
    done
  fi
  
  # Check metrics endpoint if health check passed
  local metrics_url="http://${host}:${port}/metrics"
  echo -e "\nChecking metrics endpoint at ${metrics_url}..."
  if ! metrics_output=$(curl -s -m 5 -f ${metrics_url} 2>/dev/null); then
    echo -e "${YELLOW}Service ${service} does not expose /metrics endpoint${NC}"
  else
    # Count number of metrics
    local metric_count=$(echo "$metrics_output" | grep -v "^#" | wc -l)
    echo -e "${GREEN}Service ${service} exposes ${metric_count} metrics${NC}"
  fi
  
  return 0
}

# Check docker-compose health status
echo -e "\n${GREEN}Docker Compose Health Status:${NC}"
docker-compose ps | grep -v "NAME\|----" | awk '{print $1 " " $NF}' | while read container status; do
  if [[ "$status" == "(healthy)" ]]; then
    echo -e "  ${GREEN}${container}: ${status}${NC}"
  else
    echo -e "  ${RED}${container}: ${status}${NC}"
  fi
done

# Check services individually
for service in $SERVICES; do
  check_service_health $service
done

# Prometheus status
echo -e "\n${GREEN}Checking Prometheus targets...${NC}"
PROMETHEUS_CONTAINER=$(docker-compose ps -q prometheus 2>/dev/null || echo "")
if [ -n "$PROMETHEUS_CONTAINER" ]; then
  echo -e "Prometheus is running, checking targets..."
  PROMETHEUS_URL="http://localhost:9090/api/v1/targets"
  if ! targets_output=$(curl -s -m 5 -f ${PROMETHEUS_URL} 2>/dev/null); then
    echo -e "${RED}Could not connect to Prometheus API${NC}"
  else
    # Parse targets
    echo -e "\n${GREEN}Prometheus Targets:${NC}"
    echo "$targets_output" | grep -o '"job":"[^"]*"' | sort | uniq | while read job; do
      job_name=$(echo $job | cut -d'"' -f4)
      # Count up/down targets for this job
      up_count=$(echo "$targets_output" | grep -o "\"job\":\"$job_name\".*\"health\":\"up\"" | wc -l)
      down_count=$(echo "$targets_output" | grep -o "\"job\":\"$job_name\".*\"health\":\"down\"" | wc -l)
      
      if [ $down_count -eq 0 ]; then
        echo -e "  ${GREEN}${job_name}: ${up_count} up, ${down_count} down${NC}"
      else
        echo -e "  ${RED}${job_name}: ${up_count} up, ${down_count} down${NC}"
      fi
    done
  fi
else
  echo -e "${YELLOW}Prometheus is not running${NC}"
fi

# Summary
echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}    HEALTH CHECK SUMMARY    ${NC}"
echo -e "${GREEN}=========================================${NC}\n"

# Count healthy vs unhealthy services
HEALTHY_COUNT=$(docker-compose ps | grep "healthy" | wc -l)
TOTAL_SERVICES=$(docker-compose ps | grep -v "NAME\|----" | wc -l)
PERCENT=$((HEALTHY_COUNT * 100 / TOTAL_SERVICES))

if [ $PERCENT -eq 100 ]; then
  echo -e "${GREEN}All services are healthy! (${HEALTHY_COUNT}/${TOTAL_SERVICES})${NC}"
elif [ $PERCENT -ge 80 ]; then
  echo -e "${YELLOW}Most services are healthy: ${HEALTHY_COUNT}/${TOTAL_SERVICES} (${PERCENT}%)${NC}"
else
  echo -e "${RED}Warning: Only ${HEALTHY_COUNT}/${TOTAL_SERVICES} services healthy (${PERCENT}%)${NC}"
fi

echo -e "\n${GREEN}Health check complete!${NC}"