#!/bin/bash
# Script to inject the healthcheck binary into all unhealthy containers

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}Healthcheck Binary Injection Fix${NC}"
echo -e "${BLUE}This script will inject the healthcheck binary into all unhealthy containers${NC}\n"

# Check if docker-compose.healthcheck-fix.yml exists
if [ ! -f "docker-compose.healthcheck-fix.yml" ]; then
  echo -e "${RED}Error: docker-compose.healthcheck-fix.yml not found!${NC}"
  exit 1
fi

# Stop services and recreate with the healthcheck fix
echo -e "${BLUE}Stopping services...${NC}"
docker-compose stop

echo -e "${BLUE}Creating healthcheck binary volume...${NC}"
docker volume create alfred-healthcheck-binary

echo -e "${BLUE}Starting services with healthcheck fix...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.healthcheck-fix.yml up -d

echo -e "${BLUE}Waiting for healthcheck-provider to initialize...${NC}"
sleep 5

echo -e "${GREEN}Healthcheck binary has been injected into all services${NC}"
echo -e "${YELLOW}Check container health status after a minute with:${NC}"
echo -e "${YELLOW}docker ps --format \"{{.Names}}:{{.Status}}\" | grep -i \"unhealthy\"${NC}"

echo -e "\n${BLUE}${BOLD}Note:${NC} This is a temporary fix. For a permanent solution, update the Dockerfiles."
echo -e "${BLUE}You can create updated Dockerfiles using:${NC}"
echo -e "${YELLOW}./scripts/healthcheck/bulk-update-health-binary.sh${NC}\n"