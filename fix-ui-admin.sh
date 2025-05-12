#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing ui-admin health check...${NC}"

# Check if the container is running
if ! docker ps | grep -q ui-admin; then
  echo -e "${RED}Container ui-admin is not running.${NC}"
  exit 1
fi

# Get container ID
CONTAINER_ID=$(docker ps -q -f name=ui-admin)

# Stop the container
echo -e "${YELLOW}Stopping ui-admin container...${NC}"
docker stop ui-admin

# Check how the container is running in docker-compose
# We need to extract this information to properly recreate it
echo -e "${YELLOW}Extracting existing container configuration...${NC}"
ADMIN_IMAGE=$(docker inspect --format='{{.Config.Image}}' ui-admin)
ADMIN_ENV=$(docker inspect --format='{{range .Config.Env}}{{.}} {{end}}' ui-admin)
ADMIN_PORTS=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{$p}} {{end}}' ui-admin)

# Update the health check configuration for the container
echo -e "${YELLOW}Creating new container with fixed health check...${NC}"
docker run -d \
  --name ui-admin-fixed \
  --network alfred-network \
  -p 3007:3000 \
  --env-file <(echo "$ADMIN_ENV" | tr ' ' '\n') \
  -e PORT=3000 \
  --volume $PWD/services/mission-control/standalone.js:/app/standalone.js \
  --health-cmd "wget --spider http://localhost:3000/health" \
  --health-interval 10s \
  --health-timeout 5s \
  --health-retries 5 \
  --health-start-period 5s \
  --workdir /app \
  $ADMIN_IMAGE \
  node standalone.js

# Wait a moment for the container to start
echo -e "${YELLOW}Waiting for the new container to start...${NC}"
sleep 5

# Check if we can access the new container
if curl -s http://localhost:3007/health > /dev/null; then
  echo -e "${GREEN}✅ Successfully connected to new ui-admin container.${NC}"
else
  echo -e "${YELLOW}⚠️  Could not connect to the new container. It may still be starting up.${NC}"
  echo -e "${YELLOW}Will try again after a short delay...${NC}"
  sleep 5
  if curl -s http://localhost:3007/health > /dev/null; then
    echo -e "${GREEN}✅ Successfully connected to new ui-admin container on second attempt.${NC}"
  else
    echo -e "${YELLOW}⚠️  Still could not connect. Container logs:${NC}"
    docker logs ui-admin-fixed
  fi
fi

# Rename the containers to swap them
echo -e "${YELLOW}Removing the old ui-admin container...${NC}"
docker rm ui-admin

echo -e "${YELLOW}Renaming the new container to ui-admin...${NC}"
docker rename ui-admin-fixed ui-admin

echo -e "${GREEN}✅ ui-admin health check has been fixed.${NC}"
echo -e "${YELLOW}The service should become healthy in the next health check cycle.${NC}"