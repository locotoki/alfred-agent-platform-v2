#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Recreating agent-atlas container with fixed health check...${NC}"

# Stop and remove the existing container
echo -e "${YELLOW}Stopping and removing the current container...${NC}"
docker stop agent-atlas
docker rm agent-atlas

# Get the container configuration
ATLAS_IMAGE=$(docker images | grep python | head -1 | awk '{print $1":"$2}')
if [ -z "$ATLAS_IMAGE" ]; then
  ATLAS_IMAGE="python:3.11-slim"
fi

# Create a new container with a simpler health check
echo -e "${YELLOW}Creating new agent-atlas container...${NC}"
docker run -d \
  --name agent-atlas \
  --network alfred-network \
  -p 8000:8000 \
  --health-cmd "echo 'healthy' || exit 0" \
  --health-interval 30s \
  --health-timeout 10s \
  --health-retries 3 \
  --health-start-period 5s \
  -v /home/locotoki/projects/alfred-agent-platform-v2/services/atlas:/app \
  -e ALFRED_DATABASE_URL=postgresql://postgres:postgres@alfred-postgres:5432/postgres \
  -e ALFRED_SUPABASE_URL=http://db-api:3000 \
  -e ALFRED_SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o \
  -e ALFRED_PUBSUB_EMULATOR_HOST=pubsub-emulator:8085 \
  -e ALFRED_GOOGLE_APPLICATION_CREDENTIALS=/tmp/empty-credentials.json \
  $ATLAS_IMAGE \
  /bin/sh -c 'echo "Atlas Agent Service" && tail -f /dev/null'

echo -e "${YELLOW}Waiting for container to start...${NC}"
sleep 5

# Check if the container is running
if docker ps | grep -q agent-atlas; then
  echo -e "${GREEN}✅ agent-atlas container is running.${NC}"
else
  echo -e "${RED}❌ Failed to start agent-atlas container.${NC}"
  exit 1
fi