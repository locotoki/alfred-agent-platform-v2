#!/bin/bash
# Comprehensive script to validate health check implementations across all services
# This script:
# 1. Starts required services in the correct order
# 2. Validates health endpoints for each service
# 3. Verifies metrics endpoints
# 4. Checks Docker healthcheck status
# 5. Validates Prometheus configuration
# 6. Produces a detailed report

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Set working directory to project root
cd "$(dirname "$0")/../.."
ROOT_DIR=$(pwd)

# Service definitions with health and metrics URLs
declare -A SERVICES
SERVICES=(
  ["agent-core"]="http://localhost:8011/health;http://localhost:9091/metrics"
  ["model-registry"]="http://localhost:8079/health;http://localhost:9093/metrics"
  ["model-router"]="http://localhost:8080/health;http://localhost:9094/metrics"
  ["agent-financial"]="http://localhost:9003/health;http://localhost:9096/metrics"
  ["agent-legal"]="http://localhost:9002/health;http://localhost:9097/metrics"
  ["ui-chat"]="http://localhost:8502/health;http://localhost:9098/metrics"
  ["agent-rag"]="http://localhost:8501/health;http://localhost:9099/metrics"
  # UI Admin will be added once implemented
  # ["ui-admin"]="http://localhost:3007/health;http://localhost:9100/metrics"
)

# Initialize counters
TOTAL_SERVICES=${#SERVICES[@]}
PASSED_HEALTH=0
PASSED_METRICS=0
PASSED_DOCKER=0
FAILED_SERVICES=()

# Print header
print_header() {
  echo -e "\n${BOLD}${BLUE}===== $1 =====${NC}\n"
}

# Print section
print_section() {
  echo -e "\n${YELLOW}$1${NC}"
}

# Print service status
print_service_status() {
  local service=$1
  local status=$2
  local details=$3

  if [ "$status" == "pass" ]; then
    echo -e "${GREEN}✓ $service: PASS${NC} $details"
  else
    echo -e "${RED}✗ $service: FAIL${NC} $details"
    FAILED_SERVICES+=("$service: $details")
  fi
}

# Check if Docker is running
check_docker() {
  if ! docker info &>/dev/null; then
    echo -e "${RED}Error: Docker is not running or not accessible.${NC}"
    echo "Please start Docker and try again."
    exit 1
  fi

  # Check if docker-compose is available
  if ! command -v docker-compose &>/dev/null; then
    echo -e "${RED}Error: docker-compose is not installed.${NC}"
    echo "Please install docker-compose and try again."
    exit 1
  }
}

# Check if the alfred-network exists, create if not
check_network() {
  if ! docker network inspect alfred-network &>/dev/null; then
    echo -e "${YELLOW}Creating alfred-network...${NC}"
    docker network create alfred-network
  fi
}

# Start essential services
start_services() {
  print_section "Starting essential services..."

  # Start database first
  echo "Starting database services..."
  docker-compose up -d db-postgres

  # Wait for database to be ready
  echo "Waiting for database to be healthy..."
  for i in {1..30}; do
    if docker inspect --format='{{.State.Health.Status}}' db-postgres 2>/dev/null | grep -q "healthy"; then
      echo "Database is healthy."
      break
    fi
    echo -n "."
    sleep 2
    if [ $i -eq 30 ]; then
      echo -e "\n${RED}Error: Database did not become healthy in time.${NC}"
      exit 1
    fi
  done

  # Start infrastructure services
  echo "Starting infrastructure services..."
  docker-compose up -d redis vector-db pubsub-emulator llm-service

  # Start model-registry and wait
  echo "Starting model-registry..."
  docker-compose up -d model-registry
  sleep 5

  # Start model-router and wait
  echo "Starting model-router..."
  docker-compose up -d model-router
  sleep 5

  # Start agent-core
  echo "Starting agent-core..."
  docker-compose up -d agent-core
  sleep 5

  # Start remaining services
  echo "Starting remaining services..."
  docker-compose up -d agent-rag agent-financial agent-legal ui-chat

  # Start Prometheus
  echo "Starting monitoring services..."
  docker-compose up -d monitoring-metrics

  echo -e "${GREEN}All services started.${NC}"

  # Give services time to initialize
  echo "Waiting for services to initialize (15 seconds)..."
  sleep 15
}

# Validate health endpoints
validate_health() {
  print_section "Validating health endpoints..."

  for service in "${!SERVICES[@]}"; do
    IFS=';' read -r health_url metrics_url <<< "${SERVICES[$service]}"

    echo -n "Checking $service health endpoint ($health_url)... "

    # Try to access health endpoint
    response=$(curl -s -m 5 "$health_url" 2>/dev/null || echo "CONNECTION_ERROR")

    if [[ "$response" == "CONNECTION_ERROR" ]]; then
      print_service_status "$service" "fail" "Could not connect to health endpoint"
    elif echo "$response" | grep -q '"status":"ok"'; then
      print_service_status "$service" "pass" ""
      ((PASSED_HEALTH++))
    else
      print_service_status "$service" "fail" "Invalid response format"
      echo "Response: $response"
    fi
  done
}

# Validate metrics endpoints
validate_metrics() {
  print_section "Validating metrics endpoints..."

  for service in "${!SERVICES[@]}"; do
    IFS=';' read -r health_url metrics_url <<< "${SERVICES[$service]}"

    echo -n "Checking $service metrics endpoint ($metrics_url)... "

    # Try to access metrics endpoint
    response=$(curl -s -m 5 "$metrics_url" 2>/dev/null || echo "CONNECTION_ERROR")

    if [[ "$response" == "CONNECTION_ERROR" ]]; then
      print_service_status "$service" "fail" "Could not connect to metrics endpoint"
    elif echo "$response" | grep -q "service_health"; then
      print_service_status "$service" "pass" ""
      ((PASSED_METRICS++))
    else
      print_service_status "$service" "fail" "No service_health metric found"
      echo "Response start: ${response:0:100}..."
    fi
  done
}

# Check Docker health status
validate_docker_health() {
  print_section "Validating Docker health status..."

  for service in "${!SERVICES[@]}"; do
    echo -n "Checking $service Docker health status... "

    # Get Docker container health status
    health_status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-health-check{{end}}' "$service" 2>/dev/null || echo "not-running")

    if [[ "$health_status" == "not-running" ]]; then
      print_service_status "$service" "fail" "Container not running"
    elif [[ "$health_status" == "no-health-check" ]]; then
      print_service_status "$service" "fail" "No health check defined"
    elif [[ "$health_status" == "healthy" ]]; then
      print_service_status "$service" "pass" ""
      ((PASSED_DOCKER++))
    else
      print_service_status "$service" "fail" "Health check status: $health_status"
    fi
  done
}

# Validate Prometheus configuration
validate_prometheus() {
  print_section "Validating Prometheus configuration..."

  # Check if Prometheus is running
  if ! docker ps | grep -q monitoring-metrics; then
    echo -e "${RED}Error: Prometheus (monitoring-metrics) is not running.${NC}"
    return
  fi

  # Get the prometheus.yml file
  prometheus_config="$ROOT_DIR/monitoring/prometheus/prometheus.yml"

  # Check if service_health job exists
  if grep -q "job_name: 'service_health'" "$prometheus_config"; then
    echo -e "${GREEN}✓ Prometheus has service_health job${NC}"
  else
    echo -e "${RED}✗ Prometheus does not have service_health job${NC}"
  fi

  # Check if alfred_health_dashboard job exists
  if grep -q "job_name: 'alfred_health_dashboard'" "$prometheus_config"; then
    echo -e "${GREEN}✓ Prometheus has alfred_health_dashboard job${NC}"
  else
    echo -e "${RED}✗ Prometheus does not have alfred_health_dashboard job${NC}"
  fi

  # Verify targets in service_health job
  for service in "${!SERVICES[@]}"; do
    if grep -q "'$service:" "$prometheus_config"; then
      echo -e "${GREEN}✓ Prometheus includes $service in targets${NC}"
    else
      echo -e "${RED}✗ Prometheus does not include $service in targets${NC}"
    fi
  done
}

# Generate summary report
generate_report() {
  print_header "Health Check Validation Summary"

  echo -e "Services validated: ${TOTAL_SERVICES}"
  echo -e "Health endpoints passed: ${PASSED_HEALTH}/${TOTAL_SERVICES} ($(( PASSED_HEALTH * 100 / TOTAL_SERVICES ))%)"
  echo -e "Metrics endpoints passed: ${PASSED_METRICS}/${TOTAL_SERVICES} ($(( PASSED_METRICS * 100 / TOTAL_SERVICES ))%)"
  echo -e "Docker health checks passed: ${PASSED_DOCKER}/${TOTAL_SERVICES} ($(( PASSED_DOCKER * 100 / TOTAL_SERVICES ))%)"

  if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}All health checks passed!${NC}"
  else
    echo -e "\n${RED}${BOLD}Failed health checks:${NC}"
    for failed in "${FAILED_SERVICES[@]}"; do
      echo -e "  ${RED}- $failed${NC}"
    done

    echo -e "\n${YELLOW}Recommendations for failed services:${NC}"
    echo -e "1. Check the service container logs: ${BLUE}docker logs <service-name>${NC}"
    echo -e "2. Verify health endpoint implementation in service code"
    echo -e "3. Check Docker healthcheck configuration in docker-compose.yml"
    echo -e "4. Ensure metrics server is running on port 9091 in the container"
    echo -e "5. Verify port mapping for metrics endpoint in docker-compose.yml"
  fi

  echo -e "\n${YELLOW}Next Steps:${NC}"
  echo -e "1. Complete UI Admin service implementation"
  echo -e "2. Create Grafana dashboard for service health"
  echo -e "3. Set up alerts for service degradation"
  echo -e "4. Update operational documentation"

  echo -e "\n${BOLD}Report generated at: $(date)${NC}"
}

# Clean up function to stop services
cleanup() {
  print_section "Cleaning up..."

  read -p "Do you want to stop all services? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Stopping all services..."
    docker-compose down
    echo -e "${GREEN}All services stopped.${NC}"
  else
    echo "Services left running."
  fi
}

# Main function
main() {
  print_header "Alfred Agent Platform v2 - Health Check Validation"

  # Check prerequisites
  check_docker
  check_network

  # Ask if user wants to start services
  read -p "Do you want to start all services for testing? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    start_services
  else
    echo "Skipping service startup. Using existing running services."
  fi

  # Validate health checks
  validate_health
  validate_metrics
  validate_docker_health
  validate_prometheus

  # Generate report
  generate_report

  # Clean up
  cleanup
}

# Run main function
main
