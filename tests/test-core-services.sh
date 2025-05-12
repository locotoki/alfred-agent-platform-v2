#!/bin/bash
#
# Test core services
# This script tests that the core services can be started and are working properly
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory with alfred.sh script
ALFRED_DIR="/home/locotoki/projects/alfred-agent-platform-v2/refactor-unified"
ALFRED_SCRIPT="$ALFRED_DIR/alfred.sh"

# Function to start core services
function start_core_services() {
  echo -e "${YELLOW}Starting core services...${NC}"
  
  # Create a basic .env file for testing
  cat > "$ALFRED_DIR/.env" << EOF
# Test environment variables
DB_USER=postgres
DB_PASSWORD=test-password
DB_NAME=postgres
DB_JWT_SECRET=test-jwt-secret
ALFRED_ENVIRONMENT=development
ALFRED_DEBUG=true
ALFRED_PROJECT_ID=alfred-agent-platform
EOF
  
  # Start core services
  if ! "$ALFRED_SCRIPT" start --components=core --clean; then
    echo -e "${RED}Error: Failed to start core services${NC}"
    return 1
  fi
  
  # Wait for services to start
  echo -e "${YELLOW}Waiting for services to start...${NC}"
  sleep 10
  
  echo -e "${GREEN}✓ Core services started${NC}"
  return 0
}

# Function to check if services are running
function check_core_services() {
  echo -e "${YELLOW}Checking if core services are running...${NC}"
  
  # Get list of running services
  local running_services=$("$ALFRED_SCRIPT" status | grep -E "Up [0-9]+" | wc -l)
  
  if [[ "$running_services" -lt 4 ]]; then
    echo -e "${RED}Error: Expected at least 4 core services, found $running_services${NC}"
    "$ALFRED_SCRIPT" status
    return 1
  fi
  
  # Check Redis
  if ! docker exec redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${RED}Error: Redis is not responding${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✓ Redis is running and responding${NC}"
  
  # Check PostgreSQL
  if ! docker exec db-postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${RED}Error: PostgreSQL is not responding${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✓ PostgreSQL is running and responding${NC}"
  
  echo -e "${GREEN}✓ Core services are running and responding${NC}"
  return 0
}

# Function to stop services
function stop_services() {
  echo -e "${YELLOW}Stopping all services...${NC}"
  
  # Stop services
  if ! "$ALFRED_SCRIPT" stop --force; then
    echo -e "${RED}Error: Failed to stop services${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✓ Services stopped${NC}"
  return 0
}

# Main function
function main() {
  echo -e "${BLUE}=== Testing Core Services ===${NC}"
  
  # Check if alfred.sh exists and is executable
  if [[ ! -x "$ALFRED_SCRIPT" ]]; then
    echo -e "${RED}Error: alfred.sh not found or not executable${NC}"
    exit 1
  fi
  
  # Run tests
  local test_success=true
  
  if ! start_core_services; then
    test_success=false
  fi
  
  if [[ "$test_success" == true ]]; then
    if ! check_core_services; then
      test_success=false
    fi
  fi
  
  # Clean up
  stop_services
  
  # Print summary
  if [[ "$test_success" == true ]]; then
    echo -e "\n${GREEN}✓ All core service tests passed${NC}"
    exit 0
  else
    echo -e "\n${RED}✗ Some core service tests failed${NC}"
    exit 1
  fi
}

# Run main function
main