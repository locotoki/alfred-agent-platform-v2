#!/bin/bash
#
# Validate Core Services
# This script validates that the core services configuration is correct
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory with Docker Compose files
COMPOSE_DIR="/home/locotoki/projects/alfred-agent-platform-v2/refactor-unified"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
COMPOSE_CORE_FILE="$COMPOSE_DIR/docker-compose.core.yml"

echo -e "${BLUE}=== Validating Core Services Configuration ===${NC}"

# Check if the core compose file exists
if [[ ! -f "$COMPOSE_CORE_FILE" ]]; then
  echo -e "${RED}Error: Core services file not found at $COMPOSE_CORE_FILE${NC}"
  exit 1
else
  echo -e "${GREEN}✓ Core services file found${NC}"
fi

# Count the number of services in the core file
echo -e "${YELLOW}Counting services in core file...${NC}"
SERVICE_COUNT=$(grep -c "^  [a-zA-Z0-9_-]*:" "$COMPOSE_CORE_FILE")
echo -e "${GREEN}Found $SERVICE_COUNT services in core file${NC}"

# Validate that critical core services are defined
echo -e "${YELLOW}Checking for critical core services...${NC}"
CRITICAL_SERVICES=("redis" "db-postgres" "vector-db" "pubsub-emulator")
MISSING_SERVICES=()

for service in "${CRITICAL_SERVICES[@]}"; do
  if grep -q "^  $service:" "$COMPOSE_CORE_FILE"; then
    echo -e "${GREEN}✓ $service service found${NC}"
  else
    echo -e "${RED}✗ $service service not found${NC}"
    MISSING_SERVICES+=("$service")
  fi
done

# Validate that the compose configuration is valid
echo -e "${YELLOW}Validating docker-compose configuration...${NC}"
if docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_CORE_FILE" config > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Docker Compose configuration is valid${NC}"
else
  echo -e "${RED}✗ Docker Compose configuration is invalid${NC}"
  exit 1
fi

# Print summary
if [[ ${#MISSING_SERVICES[@]} -eq 0 ]]; then
  echo -e "\n${GREEN}✓ All critical core services are defined${NC}"
  echo -e "${GREEN}✓ Core services configuration is valid${NC}"
  exit 0
else
  echo -e "\n${RED}✗ Some critical core services are missing${NC}"
  for service in "${MISSING_SERVICES[@]}"; do
    echo -e "${RED}  - $service${NC}"
  done
  exit 1
fi