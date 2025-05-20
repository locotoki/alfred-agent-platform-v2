#!/bin/bash
# start-all-services.sh - Start all Alfred platform services
# Created by Claude Code

# Text formatting
BOLD=$(tput bold)
NORM=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)

echo -e "${BLUE}${BOLD}Alfred Agent Platform v2 - Full Service Starter${NORM}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}${BOLD}Docker daemon is not running!${NORM}"
  echo -e "${YELLOW}Please start Docker with: ${BOLD}sudo service docker start${NORM}"
  echo -e "${YELLOW}Then run this script again.${NORM}"
  exit 1
fi

# Ensure network exists
echo -e "${BLUE}Ensuring alfred-network exists...${NORM}"
docker network inspect alfred-network >/dev/null 2>&1 || docker network create alfred-network

# Start all services
echo -e "${BLUE}Starting all platform services...${NORM}"
docker compose --env-file .env --env-file .env.local -f docker-compose.generated.yml --profile full up -d

# Check status
echo -e "${GREEN}${BOLD}Service Status:${NORM}"
docker ps

echo -e "
${GREEN}${BOLD}Alfred Platform Services Started!${NORM}

${YELLOW}You can now access:${NORM}
  ${BOLD}Mission Control:${NORM} http://localhost:3000
  ${BOLD}Slack Commands:${NORM} Try /alfred help and /diag health in your Slack workspace

${BLUE}To view logs for a specific service:${NORM}
  ${BOLD}docker logs -f <service_name>${NORM}

${YELLOW}To stop all services:${NORM}
  ${BOLD}docker compose -f docker-compose.generated.yml down${NORM}
"
