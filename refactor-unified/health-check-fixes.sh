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

# Function to fix redis health check
function fix_redis_health_check() {
  echo -e "${YELLOW}Fixing Redis health check...${NC}"
  
  # Define the correct health check
  local old_health_check='    healthcheck:
      test: \["CMD", "redis-cli", "ping"\]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s'
  
  local new_health_check='    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s'
  
  # Update the health check
  sed -i "s|$old_health_check|$new_health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ Redis health check fixed${NC}"
}

# Function to fix vector-db health check
function fix_vector_db_health_check() {
  echo -e "${YELLOW}Fixing Vector DB health check...${NC}"
  
  # Define the correct health check
  local old_health_check='    healthcheck:
      test: \["CMD", "curl", "-f", "http://localhost:6333/healthz"\]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s'
  
  local new_health_check='    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/healthz"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s'
  
  # Update the health check
  sed -i "s|$old_health_check|$new_health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ Vector DB health check fixed${NC}"
}

# Function to fix pubsub-emulator health check
function fix_pubsub_health_check() {
  echo -e "${YELLOW}Fixing PubSub emulator health check...${NC}"
  
  # Define the correct health check
  local old_health_check='    healthcheck:
      test: \["CMD", "curl", "-f", "http://localhost:8085/v1/projects/\${ALFRED_PROJECT_ID:-alfred-agent-platform}/topics"\]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s'
  
  local new_health_check='    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8085/v1/projects/${ALFRED_PROJECT_ID:-alfred-agent-platform}/topics"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s'
  
  # Update the health check
  sed -i "s|$old_health_check|$new_health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ PubSub emulator health check fixed${NC}"
}

# Function to add llm-service health check
function add_llm_service_health_check() {
  echo -e "${YELLOW}Adding LLM service health check...${NC}"
  
  # Define the marker and health check
  local marker="    restart: unless-stopped"
  local health_check="    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:11434/api/tags\"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s
    restart: unless-stopped"
  
  # Update the file
  sed -i "s|$marker|$health_check|g" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ LLM service health check added${NC}"
}

# Function to add monitoring-node health check
function add_monitoring_node_health_check() {
  echo -e "${YELLOW}Adding monitoring-node health check...${NC}"
  
  # Define the marker and health check
  local marker="    restart: unless-stopped"
  local health_check="    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:9100/metrics\"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    restart: unless-stopped"
  
  # Find the right occurrence of the marker
  local line_number=$(grep -n "container_name: monitoring-node" "$MAIN_COMPOSE" | cut -d: -f1)
  line_number=$((line_number + 15))  # Adjust to where the restart line should be
  
  # Update the file at that specific occurrence
  sed -i "${line_number}s|$marker|$health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ monitoring-node health check added${NC}"
}

# Function to add monitoring-db health check
function add_monitoring_db_health_check() {
  echo -e "${YELLOW}Adding monitoring-db health check...${NC}"
  
  # Define the marker and health check
  local marker="    restart: unless-stopped"
  local health_check="    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:9187/metrics\"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    restart: unless-stopped"
  
  # Find the right occurrence of the marker
  local line_number=$(grep -n "container_name: monitoring-db" "$MAIN_COMPOSE" | cut -d: -f1)
  line_number=$((line_number + 8))  # Adjust to where the restart line should be
  
  # Update the file at that specific occurrence
  sed -i "${line_number}s|$marker|$health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ monitoring-db health check added${NC}"
}

# Function to fix ui-chat health check
function fix_ui_chat_health_check() {
  echo -e "${YELLOW}Fixing ui-chat health check...${NC}"
  
  # Define the correct health check
  local old_health_check='    healthcheck:
      test: \["CMD", "wget", "--spider", "http://localhost:8501"\]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s'
  
  local new_health_check='    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8501"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s'
  
  # Update the health check
  sed -i "s|$old_health_check|$new_health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ ui-chat health check fixed${NC}"
}

# Function to fix agent-core health check
function fix_agent_core_health_check() {
  echo -e "${YELLOW}Fixing agent-core health check...${NC}"
  
  # Define the correct health check
  local old_health_check='    healthcheck:
      test: \["CMD", "curl", "-f", "http://localhost:8011/health"\]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s'
  
  local new_health_check='    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8011/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s'
  
  # Update the health check
  sed -i "s|$old_health_check|$new_health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ agent-core health check fixed${NC}"
}

# Function to fix agent-rag health check
function fix_agent_rag_health_check() {
  echo -e "${YELLOW}Fixing agent-rag health check...${NC}"
  
  # Define the correct health check
  local old_health_check='    healthcheck:
      test: \["CMD", "curl", "-f", "http://localhost:8501/health"\]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s'
  
  local new_health_check='    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8501/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s'
  
  # Update the health check
  sed -i "s|$old_health_check|$new_health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ agent-rag health check fixed${NC}"
}

# Function to fix agent-atlas health check
function fix_agent_atlas_health_check() {
  echo -e "${YELLOW}Fixing agent-atlas health check...${NC}"
  
  # Define the correct health check
  local old_health_check='    healthcheck:
      test: \["CMD", "python", "-c", "import socket; socket.socket\(\).connect\(\(\'localhost\', 8000\)\)"\]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s'
  
  local new_health_check='    healthcheck:
      test: ["CMD", "python", "-c", "import socket; socket.socket().connect(('"'"'localhost'"'"', 8000))"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s'
  
  # Update the health check
  sed -i "s|$old_health_check|$new_health_check|" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ agent-atlas health check fixed${NC}"
}

# Function to add health checks for stub services
function add_stub_service_health_checks() {
  echo -e "${YELLOW}Adding health checks for stub services...${NC}"
  
  # Define the marker and health check
  local marker="    command: sh -c 'echo \".*Stub Service\" && tail -f /dev/null'"
  local health_check="    command: sh -c 'echo \".*Stub Service\" && tail -f /dev/null'
    healthcheck:
      test: [\"CMD-SHELL\", \"ps aux | grep -v grep | grep 'tail -f /dev/null' || exit 1\"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s"
  
  # Update all occurrences
  sed -i "s|$marker|$health_check|g" "$MAIN_COMPOSE"
  
  echo -e "${GREEN}✓ Stub service health checks added${NC}"
}

# Main function
function main() {
  echo -e "${BLUE}=== Applying Health Check Fixes ===${NC}"
  
  # Create a backup of the docker-compose.yml file
  cp "$MAIN_COMPOSE" "$MAIN_COMPOSE.bak"
  echo -e "${YELLOW}Backup created: ${MAIN_COMPOSE}.bak${NC}"
  
  # Fix specific service health checks
  fix_redis_health_check
  fix_vector_db_health_check
  fix_pubsub_health_check
  add_llm_service_health_check
  add_monitoring_node_health_check
  add_monitoring_db_health_check
  fix_ui_chat_health_check
  fix_agent_core_health_check
  fix_agent_rag_health_check
  fix_agent_atlas_health_check
  add_stub_service_health_checks
  
  # Run the health check test again to verify fixes
  echo -e "\n${BLUE}Running health check test to verify fixes...${NC}"
  cd "$COMPOSE_DIR" && ./tests/test-service-health.sh
  local test_result=$?
  
  # Print summary
  if [[ "$test_result" -eq 0 ]]; then
    echo -e "\n${GREEN}✓ All health check fixes were successful${NC}"
  else
    echo -e "\n${RED}✗ Some health check issues remain - check the output above${NC}"
  fi
}

# Run main function
main