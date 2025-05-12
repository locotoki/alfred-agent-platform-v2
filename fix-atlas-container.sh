#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing Atlas container health check...${NC}"

# Check if the container is running
if ! docker ps | grep -q agent-atlas; then
  echo -e "${RED}Container agent-atlas is not running.${NC}"
  exit 1
fi

# Execute the correct tail command in the container
echo -e "${YELLOW}Ensuring the proper process is running for health check...${NC}"
docker exec -d agent-atlas sh -c "nohup tail -f /dev/null > /dev/null 2>&1 &"

# Wait a moment for health check to update
echo -e "${YELLOW}Waiting for health check to update...${NC}"
sleep 10

# Check the health status
if docker inspect --format='{{.State.Health.Status}}' agent-atlas | grep -q "healthy"; then
  echo -e "${GREEN}✅ Atlas container is now healthy.${NC}"
else
  echo -e "${RED}❌ Atlas container is still showing as unhealthy. Further investigation needed.${NC}"
  echo -e "${YELLOW}Current health status: $(docker inspect --format='{{.State.Health.Status}}' agent-atlas)${NC}"
fi