#!/bin/bash
# YouTube Workflows E2E Tests Runner
#
# This script will:
# 1. Verify that Mission Control and Social Intelligence Agent are running
# 2. Install Playwright if needed
# 3. Run the e2e tests

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
PROJECT_ROOT="/home/locotoki/projects/alfred-agent-platform-v2"
MISSION_CONTROL="${PROJECT_ROOT}/services/mission-control"
TEST_DIR="${PROJECT_ROOT}/tests/e2e"

# Header
echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}   YouTube Workflow E2E Test Runner                      ${NC}"
echo -e "${BLUE}   Alfred Agent Platform v2                              ${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo ""

# Check if Mission Control is running
echo -e "${BLUE}Checking if Mission Control is running...${NC}"
MC_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3005 || echo "Connection failed")

if [ "$MC_RESPONSE" == "200" ] || [ "$MC_RESPONSE" == "404" ]; then
  echo -e "${GREEN}Mission Control is responding on port 3005${NC}"
else
  echo -e "${RED}Mission Control is not running or not responding on port 3005${NC}"
  echo -e "${YELLOW}Starting Mission Control...${NC}"

  # Navigate to Mission Control directory
  cd "$MISSION_CONTROL"

  # Check if the process is already running but not responding
  MC_PID=$(ps aux | grep "next dev\|next start" | grep -v grep | awk '{print $2}')
  if [ ! -z "$MC_PID" ]; then
    echo -e "${YELLOW}Killing existing Mission Control process (PID: $MC_PID)${NC}"
    kill -9 "$MC_PID"
  fi

  # Start Mission Control in the background
  echo -e "${YELLOW}Starting Mission Control using npm run dev...${NC}"
  npm run dev > /dev/null 2>&1 &

  # Wait for Mission Control to start
  echo -e "${YELLOW}Waiting for Mission Control to start...${NC}"
  for i in {1..30}; do
    MC_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3005 || echo "Connection failed")
    if [ "$MC_RESPONSE" == "200" ] || [ "$MC_RESPONSE" == "404" ]; then
      echo -e "${GREEN}Mission Control started successfully!${NC}"
      break
    fi
    sleep 1
    echo -n "."
  done

  if [ "$MC_RESPONSE" != "200" ] && [ "$MC_RESPONSE" != "404" ]; then
    echo -e "${RED}Failed to start Mission Control. Please start it manually with 'npm run dev' in $MISSION_CONTROL${NC}"
    exit 1
  fi
fi

# Check if Social Intelligence Agent is running
echo -e "${BLUE}Checking if Social Intelligence Agent is running...${NC}"
SOCIAL_INTEL_CONTAINER=$(docker ps | grep "social-intel" | wc -l)

if [ "$SOCIAL_INTEL_CONTAINER" -gt 0 ]; then
  echo -e "${GREEN}Social Intelligence Agent container is running${NC}"
else
  echo -e "${YELLOW}Social Intelligence Agent container is not running${NC}"
  echo -e "${YELLOW}Starting Social Intelligence Agent container...${NC}"

  # Start the container
  cd "$PROJECT_ROOT"
  docker-compose up -d social-intel

  # Wait for the container to start
  echo -e "${YELLOW}Waiting for Social Intelligence Agent to start...${NC}"
  for i in {1..30}; do
    SOCIAL_INTEL_CONTAINER=$(docker ps | grep "social-intel" | wc -l)
    if [ "$SOCIAL_INTEL_CONTAINER" -gt 0 ]; then
      echo -e "${GREEN}Social Intelligence Agent started successfully!${NC}"
      break
    fi
    sleep 1
    echo -n "."
  done

  if [ "$SOCIAL_INTEL_CONTAINER" -eq 0 ]; then
    echo -e "${RED}Failed to start Social Intelligence Agent. Tests will run with mock data only.${NC}"
  fi
fi

# Check if Playwright is installed
cd "$TEST_DIR"
echo -e "${BLUE}Checking if Playwright is installed...${NC}"

if [ ! -d "node_modules/@playwright" ]; then
  echo -e "${YELLOW}Playwright not found. Installing Playwright...${NC}"
  npm install -D @playwright/test
  npx playwright install chromium
  echo -e "${GREEN}Playwright installed successfully!${NC}"
else
  echo -e "${GREEN}Playwright is already installed${NC}"
fi

# Run the tests
echo -e "${BLUE}Running E2E tests...${NC}"
echo -e "${YELLOW}Note: Tests may take some time to complete as they interact with real UI and APIs${NC}"
echo -e "${YELLOW}You can view the UI automation in the browser window that will open${NC}"

# Run the tests
npx playwright test

# Check the test results
if [ $? -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
else
  echo -e "${RED}Some tests failed. Check the test report for details.${NC}"
  echo -e "${YELLOW}Opening test report...${NC}"
  npx playwright show-report
fi

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}   Test run complete                                     ${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Print path to HTML report
echo -e "${YELLOW}HTML report is available at: ${TEST_DIR}/playwright-report/index.html${NC}"
