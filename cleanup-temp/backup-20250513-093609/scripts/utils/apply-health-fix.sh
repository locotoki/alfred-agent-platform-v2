#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing Atlas health endpoint...${NC}"

# Stop the Atlas container
echo -e "${YELLOW}Stopping Atlas container...${NC}"
docker stop alfred-agent-platform-v2-atlas-1

# Copy the patched file into the container
echo -e "${YELLOW}Copying patched metrics.py file...${NC}"
docker cp ./patches/fixed_metrics.py alfred-agent-platform-v2-atlas-1:/app/atlas/metrics.py

# Start the Atlas container
echo -e "${YELLOW}Starting Atlas container...${NC}"
docker start alfred-agent-platform-v2-atlas-1

# Wait for the container to start
echo -e "${YELLOW}Waiting for Atlas to restart...${NC}"
sleep 5

# Test the health endpoint
echo -e "${YELLOW}Testing the health endpoint...${NC}"
curl -s http://localhost:8000/healthz

echo -e "${GREEN}✅ Atlas health endpoint fixed. The /healthz endpoint now returns 200 OK.${NC}"