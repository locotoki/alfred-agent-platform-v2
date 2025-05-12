#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}      Alfred Platform Health Check Fixer      ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Check if scripts exist
if [ ! -f "./fix-atlas-container.sh" ] || [ ! -f "./fix-agent-core.sh" ] || [ ! -f "./fix-agent-rag.sh" ] || [ ! -f "./fix-ui-admin.sh" ] || [ ! -f "./fix-monitoring-db.sh" ] || [ ! -f "./fix-vector-db.sh" ]; then
  echo -e "${RED}Error: One or more fix scripts are missing.${NC}"
  echo -e "${YELLOW}Please ensure all fix scripts are in the current directory.${NC}"
  exit 1
fi

# Make all scripts executable
chmod +x ./fix-*.sh

# Check which containers are unhealthy
echo -e "${YELLOW}Checking current container health status...${NC}"
UNHEALTHY_CONTAINERS=$(docker ps --format "{{.Names}}" --filter "health=unhealthy")

if [ -z "$UNHEALTHY_CONTAINERS" ]; then
  echo -e "${GREEN}All containers are healthy! No fixes needed.${NC}"
  exit 0
fi

echo -e "${YELLOW}The following containers are unhealthy:${NC}"
echo "$UNHEALTHY_CONTAINERS"
echo

# Ask for confirmation before proceeding
read -p "Do you want to fix all unhealthy containers? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Operation canceled.${NC}"
  exit 0
fi

# Function to run a fix script if container is unhealthy
run_fix_if_unhealthy() {
  CONTAINER_NAME=$1
  SCRIPT_NAME=$2
  
  if docker ps --format "{{.Names}}" --filter "health=unhealthy" | grep -q "$CONTAINER_NAME"; then
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}      Fixing $CONTAINER_NAME      ${NC}"
    echo -e "${BLUE}===============================================${NC}"
    ./$SCRIPT_NAME
    echo
  else
    echo -e "${GREEN}$CONTAINER_NAME is already healthy. Skipping.${NC}"
  fi
}

# Run fix scripts for unhealthy containers
if echo "$UNHEALTHY_CONTAINERS" | grep -q "agent-atlas"; then
  run_fix_if_unhealthy "agent-atlas" "fix-atlas-container.sh"
fi

if echo "$UNHEALTHY_CONTAINERS" | grep -q "agent-core"; then
  run_fix_if_unhealthy "agent-core" "fix-agent-core.sh"
fi

if echo "$UNHEALTHY_CONTAINERS" | grep -q "agent-rag"; then
  run_fix_if_unhealthy "agent-rag" "fix-agent-rag.sh"
fi

if echo "$UNHEALTHY_CONTAINERS" | grep -q "ui-admin"; then
  run_fix_if_unhealthy "ui-admin" "fix-ui-admin.sh"
fi

if echo "$UNHEALTHY_CONTAINERS" | grep -q "monitoring-db"; then
  run_fix_if_unhealthy "monitoring-db" "fix-monitoring-db.sh"
fi

if echo "$UNHEALTHY_CONTAINERS" | grep -q "vector-db"; then
  run_fix_if_unhealthy "vector-db" "fix-vector-db.sh"
fi

# Final status check
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}      Final Health Check Status      ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Wait a bit for health checks to update
echo -e "${YELLOW}Waiting for health checks to update...${NC}"
sleep 20

# Check if any containers are still unhealthy
STILL_UNHEALTHY=$(docker ps --format "{{.Names}}: {{.Status}}" --filter "health=unhealthy")

if [ -z "$STILL_UNHEALTHY" ]; then
  echo -e "${GREEN}✅ All containers are now healthy!${NC}"
else
  echo -e "${YELLOW}⚠️ Some containers are still showing as unhealthy:${NC}"
  echo "$STILL_UNHEALTHY"
  echo
  echo -e "${YELLOW}Note: Some containers might need more time for health checks to update.${NC}"
  echo -e "${YELLOW}Try running the following command after a few minutes:${NC}"
  echo "docker ps --filter health=unhealthy"
fi

echo
echo -e "${GREEN}Health check fixes have been applied.${NC}"
echo -e "${YELLOW}It's recommended to test the platform functionality to ensure everything is working correctly.${NC}"