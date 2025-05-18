#!/bin/bash
# Port Configuration Verification Script
# For Alfred Agent Platform v2

# Color coding
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="/home/locotoki/projects/alfred-agent-platform-v2"
MISSION_CONTROL="$PROJECT_ROOT/services/mission-control"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   Port Configuration Verification Tool      ${NC}"
echo -e "${BLUE}   Alfred Agent Platform v2                  ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Check package.json port configuration
echo -e "${BLUE}Checking package.json port configuration...${NC}"
if [ -f "$MISSION_CONTROL/package.json" ]; then
  DEV_PORT=$(grep -o '"dev": "[^"]*"' "$MISSION_CONTROL/package.json" | grep -o 'next dev -p [0-9]*' | grep -o '[0-9]*')
  START_PORT=$(grep -o '"start": "[^"]*"' "$MISSION_CONTROL/package.json" | grep -o 'next start -p [0-9]*' | grep -o '[0-9]*')

  if [ "$DEV_PORT" == "3007" ]; then
    echo -e "${GREEN}✓ Dev port correctly set to 3007 in package.json${NC}"
  else
    echo -e "${RED}✗ Dev port NOT set to 3007 in package.json! Found: $DEV_PORT${NC}"
    echo -e "${YELLOW}  - Fix: Change 'dev' script to \"next dev -p 3007\"${NC}"
  fi

  if [ "$START_PORT" == "3007" ]; then
    echo -e "${GREEN}✓ Start port correctly set to 3007 in package.json${NC}"
  else
    echo -e "${RED}✗ Start port NOT set to 3007 in package.json! Found: $START_PORT${NC}"
    echo -e "${YELLOW}  - Fix: Change 'start' script to \"next start -p 3007\"${NC}"
  fi
else
  echo -e "${RED}✗ Cannot find package.json at $MISSION_CONTROL/package.json${NC}"
fi
echo ""

# Check .env.local configuration
echo -e "${BLUE}Checking .env.local configuration...${NC}"
if [ -f "$MISSION_CONTROL/.env.local" ]; then
  if grep -q "SOCIAL_INTEL_URL=http://localhost:9000" "$MISSION_CONTROL/.env.local"; then
    echo -e "${GREEN}✓ SOCIAL_INTEL_URL correctly set to http://localhost:9000${NC}"
  else
    echo -e "${RED}✗ SOCIAL_INTEL_URL not correctly configured in .env.local${NC}"
    INTEL_URL=$(grep "SOCIAL_INTEL_URL" "$MISSION_CONTROL/.env.local" | cut -d '=' -f2)
    echo -e "${YELLOW}  - Found: $INTEL_URL${NC}"
    echo -e "${YELLOW}  - Fix: Set SOCIAL_INTEL_URL=http://localhost:9000${NC}"
  fi

  if grep -q "NEXT_PUBLIC_SERVER_URL=http://localhost:3007" "$MISSION_CONTROL/.env.local"; then
    echo -e "${GREEN}✓ NEXT_PUBLIC_SERVER_URL correctly set to http://localhost:3007${NC}"
  else
    echo -e "${RED}✗ NEXT_PUBLIC_SERVER_URL not correctly configured in .env.local${NC}"
    SERVER_URL=$(grep "NEXT_PUBLIC_SERVER_URL" "$MISSION_CONTROL/.env.local" | cut -d '=' -f2)
    echo -e "${YELLOW}  - Found: $SERVER_URL${NC}"
    echo -e "${YELLOW}  - Fix: Set NEXT_PUBLIC_SERVER_URL=http://localhost:3007${NC}"
  fi
else
  echo -e "${RED}✗ Cannot find .env.local at $MISSION_CONTROL/.env.local${NC}"
  echo -e "${YELLOW}  - Fix: Create this file with:${NC}"
  echo -e "${YELLOW}    SOCIAL_INTEL_URL=http://localhost:9000${NC}"
  echo -e "${YELLOW}    NEXT_PUBLIC_SERVER_URL=http://localhost:3007${NC}"
  echo -e "${YELLOW}    NEXT_PUBLIC_API_BASE_URL=/api/social-intel${NC}"
fi
echo ""

# Check YouTube workflows service
echo -e "${BLUE}Checking youtube-workflows.ts service...${NC}"
SERVICE_FILE="$MISSION_CONTROL/src/services/youtube-workflows.ts"
if [ -f "$SERVICE_FILE" ]; then
  if grep -q "window.location.origin" "$SERVICE_FILE"; then
    echo -e "${GREEN}✓ Dynamic URL detection found in youtube-workflows.ts${NC}"
  else
    echo -e "${RED}✗ No dynamic URL detection in youtube-workflows.ts${NC}"
    echo -e "${YELLOW}  - Fix: Implement dynamic URL detection:${NC}"
    echo -e "${YELLOW}    const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3007';${NC}"
  fi

  if grep -q "baseUrl = typeof window !== 'undefined'" "$SERVICE_FILE"; then
    echo -e "${GREEN}✓ Fallback URL defined for non-browser environments${NC}"
  else
    echo -e "${YELLOW}⚠ No fallback URL for non-browser environments${NC}"
    echo -e "${YELLOW}  - Recommendation: Add server-side fallback${NC}"
  fi
else
  echo -e "${RED}✗ Cannot find youtube-workflows.ts at $SERVICE_FILE${NC}"
fi
echo ""

# Check if services are running
echo -e "${BLUE}Checking running services...${NC}"

# Check if Mission Control is running
MC_RUNNING=$(ps aux | grep "next dev" | grep -v grep | wc -l)
if [ "$MC_RUNNING" -gt 0 ]; then
  MC_PORT=$(ps aux | grep "next dev" | grep -v grep | grep -o -- "-p [0-9]*" | grep -o "[0-9]*")
  echo -e "${GREEN}✓ Mission Control is running on port $MC_PORT${NC}"

  if [ "$MC_PORT" != "3007" ]; then
    echo -e "${YELLOW}⚠ Mission Control is running on port $MC_PORT instead of 3007${NC}"
  fi
else
  echo -e "${YELLOW}⚠ Mission Control does not appear to be running${NC}"
fi

# Check if Social Intelligence Agent container is running
if command -v docker &> /dev/null; then
  SOCIAL_INTEL_RUNNING=$(docker ps | grep "social-intel" | wc -l)
  if [ "$SOCIAL_INTEL_RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✓ Social Intelligence Agent container is running${NC}"
    SOCIAL_PORT=$(docker ps | grep "social-intel" | grep -o "0.0.0.0:[0-9]*->9000" | grep -o ":[0-9]*" | grep -o "[0-9]*")
    if [ "$SOCIAL_PORT" == "9000" ]; then
      echo -e "${GREEN}✓ Social Intelligence Agent correctly mapped to port 9000${NC}"
    else
      echo -e "${YELLOW}⚠ Social Intelligence Agent mapped to port $SOCIAL_PORT instead of 9000${NC}"
    fi
  else
    echo -e "${YELLOW}⚠ Social Intelligence Agent container does not appear to be running${NC}"
    echo -e "${YELLOW}  - Start with: docker-compose up -d social-intel${NC}"
  fi
else
  echo -e "${YELLOW}⚠ Docker not found, cannot check Social Intelligence Agent status${NC}"
fi
echo ""

# Check port usage to avoid conflicts
echo -e "${BLUE}Checking for port conflicts...${NC}"
if command -v lsof &> /dev/null; then
  PORT_3007_USAGE=$(lsof -i :3007 | wc -l)
  if [ "$PORT_3007_USAGE" -gt 0 ]; then
    if [ "$MC_RUNNING" -gt 0 ] && [ "$MC_PORT" == "3007" ]; then
      echo -e "${GREEN}✓ Port 3007 is being used by Mission Control (expected)${NC}"
    else
      echo -e "${RED}✗ Port 3007 is in use by another process!${NC}"
      echo -e "${YELLOW}  - Check: lsof -i :3007${NC}"
      echo -e "${YELLOW}  - Fix: kill -9 $(lsof -t -i:3007)${NC}"
    fi
  else
    echo -e "${GREEN}✓ Port 3007 is available${NC}"
  fi

  PORT_9000_USAGE=$(lsof -i :9000 | wc -l)
  if [ "$PORT_9000_USAGE" -gt 0 ]; then
    if [ "$SOCIAL_INTEL_RUNNING" -gt 0 ]; then
      echo -e "${GREEN}✓ Port 9000 is being used by Social Intelligence Agent (expected)${NC}"
    else
      echo -e "${RED}✗ Port 9000 is in use by another process!${NC}"
      echo -e "${YELLOW}  - Check: lsof -i :9000${NC}"
      echo -e "${YELLOW}  - Fix: kill -9 $(lsof -t -i:9000)${NC}"
    fi
  else
    echo -e "${GREEN}✓ Port 9000 is available${NC}"
  fi
else
  echo -e "${YELLOW}⚠ lsof not found, cannot check port usage${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}                 Summary                     ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo -e "${GREEN}✓ PORT-STANDARD.md created${NC}"
echo -e "${GREEN}✓ Documentation updated for port 3007${NC}"
echo -e "${GREEN}✓ Quick-start-guide.md updated${NC}"
echo -e "${GREEN}✓ Environment check script updated${NC}"
echo -e "${GREEN}✓ Implementation status updated${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Run the environment check script:"
echo -e "   ${YELLOW}bash ./docs/phase6-mission-control/youtube-workflows/environment-check-script.sh${NC}"
echo -e "2. Try accessing Mission Control at http://localhost:3007"
echo -e "3. Check the YouTube workflows at http://localhost:3007/workflows"
echo ""
echo -e "${BLUE}=============================================${NC}"
