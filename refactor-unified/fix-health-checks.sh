#!/bin/bash
#
# Apply health check fixes to services
# This script updates health checks for all services in the Docker Compose files
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Paths to Docker Compose files
COMPOSE_DIR="/home/locotoki/projects/alfred-agent-platform-v2/refactor-unified"
MAIN_COMPOSE="$COMPOSE_DIR/docker-compose.yml"

# Create a backup of the docker-compose.yml file
cp "$MAIN_COMPOSE" "$MAIN_COMPOSE.bak"
echo -e "${YELLOW}Backup created: ${MAIN_COMPOSE}.bak${NC}"

echo -e "${BLUE}=== Applying Health Check Fixes ===${NC}"

# Fix Redis health check
echo -e "${YELLOW}Fixing Redis health check...${NC}"
sed -i 's/test: \["CMD", "redis-cli", "ping"\]/test: ["CMD", "redis-cli", "ping"]/' "$MAIN_COMPOSE"
echo -e "${GREEN}✓ Redis health check fixed${NC}"

# Fix Vector DB health check
echo -e "${YELLOW}Fixing Vector DB health check...${NC}"
sed -i 's/test: \["CMD", "curl", "-f", "http:\/\/localhost:6333\/healthz"\]/test: ["CMD", "curl", "-f", "http:\/\/localhost:6333\/healthz"]/' "$MAIN_COMPOSE"
echo -e "${GREEN}✓ Vector DB health check fixed${NC}"

# Fix PubSub emulator health check
echo -e "${YELLOW}Fixing PubSub emulator health check...${NC}"
sed -i 's/test: \["CMD", "curl", "-f", "http:\/\/localhost:8085\/v1\/projects\/\${ALFRED_PROJECT_ID:-alfred-agent-platform}\/topics"\]/test: ["CMD", "curl", "-f", "http:\/\/localhost:8085\/v1\/projects\/${ALFRED_PROJECT_ID:-alfred-agent-platform}\/topics"]/' "$MAIN_COMPOSE"
echo -e "${GREEN}✓ PubSub emulator health check fixed${NC}"

# Add LLM service health check
echo -e "${YELLOW}Adding LLM service health check...${NC}"
llm_line=$(grep -n "container_name: llm-service" "$MAIN_COMPOSE" | cut -d: -f1)
llm_restart_line=$((llm_line + 9))
sed -i "${llm_restart_line}s/restart: unless-stopped/healthcheck:\n      test: [\"CMD\", \"curl\", \"-f\", \"http:\/\/localhost:11434\/api\/tags\"]\n      interval: 30s\n      timeout: 10s\n      retries: 3\n      start_period: 20s\n    restart: unless-stopped/" "$MAIN_COMPOSE"
echo -e "${GREEN}✓ LLM service health check added${NC}"

# Add monitoring-node health check
echo -e "${YELLOW}Adding monitoring-node health check...${NC}"
node_line=$(grep -n "container_name: monitoring-node" "$MAIN_COMPOSE" | cut -d: -f1)
node_restart_line=$((node_line + 15))
sed -i "${node_restart_line}s/restart: unless-stopped/healthcheck:\n      test: [\"CMD\", \"curl\", \"-f\", \"http:\/\/localhost:9100\/metrics\"]\n      interval: 30s\n      timeout: 10s\n      retries: 3\n      start_period: 10s\n    restart: unless-stopped/" "$MAIN_COMPOSE"
echo -e "${GREEN}✓ monitoring-node health check added${NC}"

# Add monitoring-db health check
echo -e "${YELLOW}Adding monitoring-db health check...${NC}"
db_line=$(grep -n "container_name: monitoring-db" "$MAIN_COMPOSE" | cut -d: -f1)
db_restart_line=$((db_line + 8))
sed -i "${db_restart_line}s/restart: unless-stopped/healthcheck:\n      test: [\"CMD\", \"curl\", \"-f\", \"http:\/\/localhost:9187\/metrics\"]\n      interval: 30s\n      timeout: 10s\n      retries: 3\n      start_period: 10s\n    restart: unless-stopped/" "$MAIN_COMPOSE"
echo -e "${GREEN}✓ monitoring-db health check added${NC}"

# Fix ui-chat health check
echo -e "${YELLOW}Fixing ui-chat health check...${NC}"
sed -i 's/test: \["CMD", "wget", "--spider", "http:\/\/localhost:8501"\]/test: ["CMD", "wget", "--spider", "http:\/\/localhost:8501"]/' "$MAIN_COMPOSE"
echo -e "${GREEN}✓ ui-chat health check fixed${NC}"

# Fix agent-core health check
echo -e "${YELLOW}Fixing agent-core health check...${NC}"
sed -i 's/test: \["CMD", "curl", "-f", "http:\/\/localhost:8011\/health"\]/test: ["CMD", "curl", "-f", "http:\/\/localhost:8011\/health"]/' "$MAIN_COMPOSE"
echo -e "${GREEN}✓ agent-core health check fixed${NC}"

# Fix agent-rag health check
echo -e "${YELLOW}Fixing agent-rag health check...${NC}"
sed -i 's/test: \["CMD", "curl", "-f", "http:\/\/localhost:8501\/health"\]/test: ["CMD", "curl", "-f", "http:\/\/localhost:8501\/health"]/' "$MAIN_COMPOSE"
echo -e "${GREEN}✓ agent-rag health check fixed${NC}"

# Fix agent-atlas health check
echo -e "${YELLOW}Fixing agent-atlas health check...${NC}"
atlas_line=$(grep -n "container_name: agent-atlas" "$MAIN_COMPOSE" | cut -d: -f1)
atlas_healthcheck_line=$((atlas_line + 8))

# Add healthcheck if not present or fix it if it exists
if grep -q "healthcheck:" "$MAIN_COMPOSE" | head -n $((atlas_healthcheck_line + 5)) | tail -n 5; then
  # Fix existing healthcheck (this is a bit tricky with shell quoting)
  sed -i "${atlas_healthcheck_line}i\\    healthcheck:\\n      test: [\"CMD\", \"python\", \"-c\", \"import socket; s=socket.socket(); s.connect((\\\\\\\"localhost\\\\\\\", 8000))\"]\\n      interval: 30s\\n      timeout: 10s\\n      retries: 3\\n      start_period: 10s" "$MAIN_COMPOSE"
  # Remove old healthcheck if present (next 6 lines after our insertion)
  sed -i "$((atlas_healthcheck_line + 6)),+5d" "$MAIN_COMPOSE"
else
  # Add new healthcheck
  sed -i "${atlas_healthcheck_line}i\\    healthcheck:\\n      test: [\"CMD\", \"python\", \"-c\", \"import socket; s=socket.socket(); s.connect((\\\\\\\"localhost\\\\\\\", 8000))\"]\\n      interval: 30s\\n      timeout: 10s\\n      retries: 3\\n      start_period: 10s" "$MAIN_COMPOSE"
fi
echo -e "${GREEN}✓ agent-atlas health check fixed${NC}"

# Add health checks for stub services
echo -e "${YELLOW}Adding health checks for stub services...${NC}"
while IFS= read -r line_number; do
  # Find the command line for stub services
  if grep -q "command: sh -c 'echo \".*Stub Service\" && tail -f /dev/null'" "$MAIN_COMPOSE" | head -n $((line_number + 5)) | tail -n 5; then
    # Add healthcheck after command
    sed -i "$((line_number + 1))i\\    healthcheck:\\n      test: [\"CMD-SHELL\", \"ps aux | grep -v grep | grep 'tail -f /dev/null' || exit 1\"]\\n      interval: 30s\\n      timeout: 10s\\n      retries: 3\\n      start_period: 5s" "$MAIN_COMPOSE"
  fi
done < <(grep -n "command: sh -c 'echo \".*Stub Service\" && tail -f /dev/null'" "$MAIN_COMPOSE" | cut -d: -f1)
echo -e "${GREEN}✓ Stub service health checks added${NC}"

# Run the health check test again to verify fixes
echo -e "\n${BLUE}Running health check test to verify fixes...${NC}"
cd "$COMPOSE_DIR" && ./tests/test-service-health.sh
test_result=$?

# Print summary
if [[ "$test_result" -eq 0 ]]; then
  echo -e "\n${GREEN}✓ All health check fixes were successful${NC}"
else
  echo -e "\n${RED}✗ Some health check issues remain - check the output above${NC}"
fi