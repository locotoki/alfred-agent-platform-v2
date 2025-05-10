#!/bin/bash
#
# Script to start both mission-control and agent-orchestrator in development mode
# This allows side-by-side comparison and testing during migration

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Starting Development Environments ===${NC}"
echo "This script will start both mission-control and agent-orchestrator"
echo "for side-by-side development and testing."
echo ""

# Define directories
PROJECT_ROOT="/home/locotoki/projects/alfred-agent-platform-v2"
MISSION_CONTROL_DIR="$PROJECT_ROOT/services/mission-control"
AGENT_ORCHESTRATOR_DIR="$PROJECT_ROOT/services/agent-orchestrator"

# Check if social-intel service is running
echo -e "${BLUE}Checking if social-intel service is running...${NC}"
if docker ps | grep -q social-intel; then
  echo -e "${GREEN}✓ Social-intel service is running${NC}"
else
  echo -e "${RED}✗ Social-intel service is not running${NC}"
  echo -e "Would you like to start it? (y/n)"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Starting social-intel service..."
    cd "$PROJECT_ROOT" && docker-compose up -d social-intel
    # Wait for service to start
    echo "Waiting for social-intel service to be healthy..."
    while ! docker ps | grep -q "social-intel.*healthy"; do
      echo -n "."
      sleep 2
    done
    echo -e "\n${GREEN}✓ Social-intel service is now running${NC}"
  else
    echo "Continuing without social-intel service. Mock data will be used."
  fi
fi

# Function to start a service in a new terminal
start_service() {
  local service_dir=$1
  local service_name=$2
  local start_command=$3
  local port=$4

  echo -e "${BLUE}Starting $service_name on port $port...${NC}"
  
  # For WSL use this approach
  if grep -q Microsoft /proc/version; then
    cmd.exe /c start wsl.exe -d Ubuntu-20.04 -e bash -c "cd $service_dir && $start_command; exec bash"
  else
    # For native Linux use this approach
    gnome-terminal --title="$service_name" -- bash -c "cd $service_dir && $start_command; exec bash" &
  fi
  
  echo -e "${GREEN}✓ Started $service_name${NC}"
  echo -e "  Access at: ${BLUE}http://localhost:$port${NC}"
}

# Start mission-control
start_service "$MISSION_CONTROL_DIR" "Mission Control" "npm run dev" "3007"

# Start agent-orchestrator
start_service "$AGENT_ORCHESTRATOR_DIR" "Agent Orchestrator" "npm run dev" "8080"

echo ""
echo -e "${GREEN}=== Development environments started ===${NC}"
echo "Mission Control: http://localhost:3007"
echo "Agent Orchestrator: http://localhost:8080"
echo ""
echo "Press Ctrl+C to exit this script (services will continue running)"
echo "To stop services, close their terminal windows or use Ctrl+C in each window"

# Keep script running to allow killing both with Ctrl+C
wait