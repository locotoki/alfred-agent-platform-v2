#!/bin/bash

# Text formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Alfred Agent Platform v2 - Container Restart Utility ===${NC}"
echo -e "${YELLOW}This script will stop all running containers, clean up, and restart with the unified configuration.${NC}"
echo

# Function to show progress
function show_progress() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to show success
function show_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to show error
function show_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup containers
function cleanup_containers() {
  show_progress "Stopping all running containers..."
  docker stop $(docker ps -aq) > /dev/null 2>&1 || true
  
  show_progress "Removing all containers..."
  docker rm $(docker ps -aq) > /dev/null 2>&1 || true
  
  show_success "Container cleanup completed"
}

# Function to ensure network exists
function ensure_network() {
  NETWORK_EXISTS=$(docker network ls --format "{{.Name}}" | grep -x "alfred_network" || true)
  if [[ ! -z "$NETWORK_EXISTS" ]]; then
    show_progress "Removing existing alfred_network..."
    docker network rm alfred_network || true
  fi

  # No need to create the network as Docker Compose will create it
  show_progress "Network will be created by Docker Compose"
}

# Function to ensure volumes exist
function ensure_volumes() {
  VOLUMES_TO_CREATE=(
    "redis-data"
    "vector-db-data"
    "llm-service-data"
    "db-postgres-data"
    "db-storage-data"
    "monitoring-metrics-data"
    "monitoring-dashboard-data"
  )
  
  for volume in "${VOLUMES_TO_CREATE[@]}"; do
    VOLUME_EXISTS=$(docker volume ls --format "{{.Name}}" | grep -x "$volume" || true)
    if [[ -z "$VOLUME_EXISTS" ]]; then
      show_progress "Creating volume $volume..."
      docker volume create "$volume"
      show_success "Volume $volume created"
    fi
  done
}

# Start containers with unified configuration
function start_containers() {
  show_progress "Starting containers with unified configuration..."
  docker-compose -f docker-compose.unified.yml up -d
  
  if [ $? -eq 0 ]; then
    show_success "Containers started successfully"
  else
    show_error "There was an issue starting containers"
    exit 1
  fi
}

# Show container status
function show_status() {
  echo
  echo -e "${BLUE}=== Container Status ===${NC}"
  docker ps

  echo
  echo -e "${BLUE}=== Health Status ===${NC}"
  docker ps --format "{{.Names}}: {{.Status}}" | sort
}

# Function to verify all core services are running
function verify_core_services() {
  echo
  echo -e "${BLUE}=== Core Services Verification ===${NC}"

  # Define core services that must be running
  CORE_SERVICES=(
    "redis"
    "db-postgres"
    "pubsub-emulator"
    "vector-db"
    "model-registry"
    "model-router"
  )

  # Check each core service
  ALL_CORE_RUNNING=true
  for service in "${CORE_SERVICES[@]}"; do
    STATUS=$(docker ps --format "{{.Status}}" --filter "name=$service" | grep -i "up" || echo "")
    if [[ -z "$STATUS" ]]; then
      show_error "Core service $service is not running"
      ALL_CORE_RUNNING=false
    else
      show_success "Core service $service is running: $STATUS"
    fi
  done

  # Summary
  if [[ "$ALL_CORE_RUNNING" == "true" ]]; then
    echo -e "${GREEN}All core services are running! The platform should be operational.${NC}"
  else
    echo -e "${YELLOW}Some core services are not running. The platform may be partially operational.${NC}"
  fi
}

# Main execution
cleanup_containers
ensure_network
ensure_volumes
start_containers
show_status
verify_core_services

echo
echo -e "${GREEN}=== Restart process completed ===${NC}"
echo -e "${YELLOW}You can check container logs with: docker logs <container-name>${NC}"
echo -e "${BLUE}Use the following commands to access services:${NC}"
echo -e "  - ${GREEN}Web UI:${NC} http://localhost:8502"
echo -e "  - ${GREEN}Admin Dashboard:${NC} http://localhost:3007"
echo -e "  - ${GREEN}Monitoring Dashboard:${NC} http://localhost:3005"
echo -e "  - ${GREEN}Mail Interface:${NC} http://localhost:8025"
echo -e "  - ${GREEN}LLM API:${NC} http://localhost:11434"