#!/bin/bash
# start-slack-commands.sh - Start services required for Slack slash commands
# Created by Claude Code

# Text formatting
BOLD=$(tput bold)
NORM=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)

echo -e "${BLUE}${BOLD}Alfred Platform - Slack Services Starter${NORM}"

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

# Start services
echo -e "${BLUE}Starting Redis and Slack MCP Gateway services...${NORM}"
docker compose --env-file .env --env-file .env.local -f docker-compose.generated.yml up -d redis slack_mcp_gateway

# Check status
echo -e "${GREEN}${BOLD}Service Status:${NORM}"
docker ps | grep -E "redis|slack_mcp_gateway"

echo -e "${BLUE}${BOLD}Checking service logs:${NORM}"
docker logs --tail=5 slack_mcp_gateway

echo -e "
${GREEN}${BOLD}Slack Services Started!${NORM}

${YELLOW}You can now test the following Slack commands:${NORM}
  ${BOLD}/alfred help${NORM}    - Shows available commands
  ${BOLD}/alfred status${NORM}  - Shows platform status

${BLUE}To view logs in real-time:${NORM}
  ${BOLD}docker logs -f slack_mcp_gateway${NORM}

${YELLOW}To stop these services:${NORM}
  ${BOLD}docker compose -f docker-compose.generated.yml down${NORM}
"
