#!/bin/bash
# Youtube Workflow Environment Check & Fix Script
# For Alfred Agent Platform v2
# 
# This script checks the environment for common issues with the YouTube workflow implementation
# and applies fixes where possible.

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
PROJECT_ROOT="/home/locotoki/projects/alfred-agent-platform-v2"
MISSION_CONTROL="${PROJECT_ROOT}/services/mission-control"
SOCIAL_INTEL="${PROJECT_ROOT}/agents/social_intel"

# Header
echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}   YouTube Workflow Environment Check & Fix Script       ${NC}"
echo -e "${BLUE}   Alfred Agent Platform v2                              ${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo ""

# Check if the required directories exist
echo -e "${BLUE}Checking project structure...${NC}"
if [ ! -d "$PROJECT_ROOT" ]; then
  echo -e "${RED}ERROR: Project root directory not found at $PROJECT_ROOT${NC}"
  exit 1
fi

if [ ! -d "$MISSION_CONTROL" ]; then
  echo -e "${RED}ERROR: Mission Control directory not found at $MISSION_CONTROL${NC}"
  exit 1
fi

if [ ! -d "$SOCIAL_INTEL" ]; then
  echo -e "${RED}ERROR: Social Intelligence Agent directory not found at $SOCIAL_INTEL${NC}"
  exit 1
fi

echo -e "${GREEN}Project structure found!${NC}"
echo ""

# Check if .env.local exists and contains the correct values
echo -e "${BLUE}Checking .env.local configuration...${NC}"
ENV_LOCAL="$MISSION_CONTROL/.env.local"
if [ ! -f "$ENV_LOCAL" ]; then
  echo -e "${YELLOW}WARNING: .env.local does not exist, creating it...${NC}"
  touch "$ENV_LOCAL"
  echo "SOCIAL_INTEL_URL=http://localhost:9000" > "$ENV_LOCAL"
  echo "NEXT_PUBLIC_SERVER_URL=http://localhost:3007" >> "$ENV_LOCAL"
  echo "NEXT_PUBLIC_API_BASE_URL=/api/social-intel" >> "$ENV_LOCAL"
  echo -e "${GREEN}Created .env.local with SOCIAL_INTEL_URL=http://localhost:9000${NC}"
else
  if grep -q "SOCIAL_INTEL_URL" "$ENV_LOCAL"; then
    SOCIAL_INTEL_URL=$(grep "SOCIAL_INTEL_URL" "$ENV_LOCAL" | cut -d '=' -f2)
    echo -e "${GREEN}Found SOCIAL_INTEL_URL=$SOCIAL_INTEL_URL in .env.local${NC}"
  else
    echo -e "${YELLOW}WARNING: SOCIAL_INTEL_URL not found in .env.local, adding it...${NC}"
    echo "SOCIAL_INTEL_URL=http://localhost:9000" >> "$ENV_LOCAL"
    echo -e "${GREEN}Added SOCIAL_INTEL_URL=http://localhost:9000 to .env.local${NC}"
  fi
  
  if grep -q "NEXT_PUBLIC_SERVER_URL" "$ENV_LOCAL"; then
    SERVER_URL=$(grep "NEXT_PUBLIC_SERVER_URL" "$ENV_LOCAL" | cut -d '=' -f2)
    echo -e "${GREEN}Found NEXT_PUBLIC_SERVER_URL=$SERVER_URL in .env.local${NC}"
    
    if [[ "$SERVER_URL" != *"3007"* ]]; then
      echo -e "${YELLOW}WARNING: NEXT_PUBLIC_SERVER_URL should be http://localhost:3007${NC}"
      echo -e "${YELLOW}Current value: $SERVER_URL${NC}"
    fi
  else
    echo -e "${YELLOW}WARNING: NEXT_PUBLIC_SERVER_URL not found in .env.local, adding it...${NC}"
    echo "NEXT_PUBLIC_SERVER_URL=http://localhost:3007" >> "$ENV_LOCAL"
    echo -e "${GREEN}Added NEXT_PUBLIC_SERVER_URL=http://localhost:3007 to .env.local${NC}"
  fi
fi
echo ""

# Check package.json for correct port configuration
echo -e "${BLUE}Checking package.json for port configuration...${NC}"
PACKAGE_JSON="$MISSION_CONTROL/package.json"
if [ ! -f "$PACKAGE_JSON" ]; then
  echo -e "${RED}ERROR: package.json not found at $PACKAGE_JSON${NC}"
else
  DEV_PORT=$(grep -o '"dev": "[^"]*"' "$PACKAGE_JSON" | grep -o 'next dev -p [0-9]*' | grep -o '[0-9]*')
  START_PORT=$(grep -o '"start": "[^"]*"' "$PACKAGE_JSON" | grep -o 'next start -p [0-9]*' | grep -o '[0-9]*')
  
  if [ "$DEV_PORT" == "3007" ]; then
    echo -e "${GREEN}Dev port correctly set to 3007 in package.json${NC}"
  else
    echo -e "${YELLOW}WARNING: Dev port not set to 3007 in package.json${NC}"
    echo -e "${YELLOW}Current value: $(grep -o '"dev": "[^"]*"' "$PACKAGE_JSON")${NC}"
    echo -e "${YELLOW}Consider changing to: \"dev\": \"next dev -p 3007\"${NC}"
  fi
  
  if [ "$START_PORT" == "3007" ]; then
    echo -e "${GREEN}Start port correctly set to 3007 in package.json${NC}"
  else
    echo -e "${YELLOW}WARNING: Start port not set to 3007 in package.json${NC}"
    echo -e "${YELLOW}Current value: $(grep -o '"start": "[^"]*"' "$PACKAGE_JSON")${NC}"
    echo -e "${YELLOW}Consider changing to: \"start\": \"next start -p 3007\"${NC}"
  fi
fi
echo ""

# Check if both services are running
echo -e "${BLUE}Checking if services are running...${NC}"

# Check if Mission Control is running
MC_RUNNING=$(ps aux | grep "next dev\|next start" | grep -v grep | wc -l)
if [ "$MC_RUNNING" -gt 0 ]; then
  MC_PORT=$(ps aux | grep "next dev\|next start" | grep -v grep | grep -o -- "-p [0-9]*" | grep -o "[0-9]*")
  echo -e "${GREEN}Mission Control is running on port $MC_PORT${NC}"
  
  if [ "$MC_PORT" != "3007" ]; then
    echo -e "${YELLOW}WARNING: Mission Control is running on port $MC_PORT, but should be on port 3007${NC}"
    echo -e "${YELLOW}Recommendation: Restart Mission Control with proper port configuration${NC}"
    echo -e "${YELLOW}cd $MISSION_CONTROL && npm run dev${NC}"
  fi
else
  echo -e "${YELLOW}WARNING: Mission Control does not appear to be running${NC}"
  echo -e "${YELLOW}Recommendation: Start Mission Control with 'npm run dev' in $MISSION_CONTROL${NC}"
fi

# Check if Docker is running
DOCKER_RUNNING=$(ps aux | grep "dockerd" | grep -v grep | wc -l)
if [ "$DOCKER_RUNNING" -gt 0 ]; then
  echo -e "${GREEN}Docker daemon is running${NC}"
  
  # Check if Social Intelligence Agent container is running
  SOCIAL_INTEL_CONTAINER=$(docker ps | grep "social-intel" | wc -l)
  if [ "$SOCIAL_INTEL_CONTAINER" -gt 0 ]; then
    SOCIAL_INTEL_PORT=$(docker ps | grep "social-intel" | grep -o "0.0.0.0:9000->9000")
    if [ ! -z "$SOCIAL_INTEL_PORT" ]; then
      echo -e "${GREEN}Social Intelligence Agent container is running on port 9000${NC}"
    else
      echo -e "${YELLOW}WARNING: Social Intelligence Agent container is running but port mapping is unclear${NC}"
      echo -e "${YELLOW}Container details: $(docker ps | grep "social-intel")${NC}"
    fi
  else
    echo -e "${YELLOW}WARNING: Social Intelligence Agent container does not appear to be running${NC}"
    echo -e "${YELLOW}Recommendation: Start the container with:${NC}"
    echo -e "${YELLOW}cd $PROJECT_ROOT && docker-compose up -d social-intel${NC}"
  fi
else
  echo -e "${YELLOW}WARNING: Docker daemon does not appear to be running${NC}"
  echo -e "${YELLOW}Recommendation: Start Docker service with 'sudo systemctl start docker'${NC}"
fi
echo ""

# Check network connectivity between services
echo -e "${BLUE}Checking network connectivity...${NC}"
if command -v curl &> /dev/null; then
  echo -e "Testing connection to Mission Control (may take a few seconds)..."
  MC_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3007 || echo "Connection failed")
  if [ "$MC_RESPONSE" == "200" ] || [ "$MC_RESPONSE" == "404" ]; then
    echo -e "${GREEN}Mission Control is responding on port 3007${NC}"
  else
    echo -e "${YELLOW}WARNING: Mission Control not responding properly (status: $MC_RESPONSE)${NC}"
  fi
  
  echo -e "Testing connection to Social Intelligence Agent (may take a few seconds)..."
  SI_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/api/health 2>/dev/null || echo "Connection failed")
  if [ "$SI_RESPONSE" == "200" ] || [ "$SI_RESPONSE" == "404" ]; then
    echo -e "${GREEN}Social Intelligence Agent is responding on port 9000${NC}"
  else
    echo -e "${YELLOW}WARNING: Social Intelligence Agent not responding properly (status: $SI_RESPONSE)${NC}"
  fi
else
  echo -e "${YELLOW}WARNING: curl not available, skipping network connectivity tests${NC}"
fi
echo ""

# Check YouTube workflow API endpoints
echo -e "${BLUE}Checking YouTube workflow implementation...${NC}"
API_DIR="$MISSION_CONTROL/src/pages/api/social-intel"
WORKFLOW_DIR="$MISSION_CONTROL/src/pages/workflows"
SERVICE_FILE="$MISSION_CONTROL/src/services/youtube-workflows.ts"

# Check Social Intelligence Agent endpoints
echo -e "${BLUE}Checking Social Intelligence Agent endpoints...${NC}"
endpoints=(
  "http://localhost:9000/youtube/niche-scout"
  "http://localhost:9000/api/youtube/niche-scout"
  "http://localhost:9000/niche-scout"
  "http://localhost:9000/youtube/blueprint"
  "http://localhost:9000/api/youtube/blueprint"
  "http://localhost:9000/blueprint"
)

ANY_ENDPOINT_SUCCESS=false
for endpoint in "${endpoints[@]}"; do
  echo -e "Testing endpoint: $endpoint"
  RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "$endpoint" 2>/dev/null || echo "Connection failed")
  
  if [ "$RESPONSE_CODE" == "200" ] || [ "$RESPONSE_CODE" == "204" ]; then
    echo -e "${GREEN}✅ Endpoint $endpoint is available${NC}"
    ANY_ENDPOINT_SUCCESS=true
  else
    echo -e "${YELLOW}⚠️ Endpoint $endpoint returned $RESPONSE_CODE${NC}"
  fi
done

if [ "$ANY_ENDPOINT_SUCCESS" == "false" ]; then
  echo -e "${YELLOW}WARNING: None of the expected Social Intelligence Agent endpoints are responding properly${NC}"
  echo -e "${YELLOW}The system will fall back to mock data mode${NC}"
fi

# Check if the API endpoints exist
if [ -f "$API_DIR/niche-scout.ts" ] && [ -f "$API_DIR/seed-to-blueprint.ts" ]; then
  echo -e "${GREEN}YouTube workflow API endpoints exist${NC}"
else
  echo -e "${RED}ERROR: YouTube workflow API endpoints missing${NC}"
  echo -e "${RED}Expected files:${NC}"
  echo -e "${RED}- $API_DIR/niche-scout.ts${NC}"
  echo -e "${RED}- $API_DIR/seed-to-blueprint.ts${NC}"
fi

# Check if the workflow pages exist
if [ -d "$WORKFLOW_DIR/niche-scout" ] && [ -d "$WORKFLOW_DIR/seed-to-blueprint" ]; then
  echo -e "${GREEN}YouTube workflow pages exist${NC}"
else
  echo -e "${RED}ERROR: YouTube workflow pages missing${NC}"
  echo -e "${RED}Expected directories:${NC}"
  echo -e "${RED}- $WORKFLOW_DIR/niche-scout${NC}"
  echo -e "${RED}- $WORKFLOW_DIR/seed-to-blueprint${NC}"
fi

# Check if the service file contains the correct URL handling
if [ -f "$SERVICE_FILE" ]; then
  DYNAMIC_URL=$(grep -o "window.location.origin" "$SERVICE_FILE" | wc -l)
  if [ "$DYNAMIC_URL" -gt 0 ]; then
    echo -e "${GREEN}YouTube workflow service uses dynamic URL handling${NC}"
  else
    echo -e "${YELLOW}WARNING: YouTube workflow service may not use dynamic URL handling${NC}"
    echo -e "${YELLOW}Recommendation: Update $SERVICE_FILE to use:${NC}"
    echo -e "${YELLOW}const baseUrl = typeof window !== 'undefined' ? window.location.origin : '';${NC}"
    echo -e "${YELLOW}const SOCIAL_INTEL_URL = \`\${baseUrl}/api/social-intel\`;${NC}"
  fi
else
  echo -e "${RED}ERROR: YouTube workflow service file missing${NC}"
  echo -e "${RED}Expected file: $SERVICE_FILE${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}                    Summary                              ${NC}"
echo -e "${BLUE}=========================================================${NC}"

if [ "$MC_RUNNING" -gt 0 ] && [ "$MC_PORT" == "3007" ] && [ "$SOCIAL_INTEL_CONTAINER" -gt 0 ]; then
  echo -e "${GREEN}✅ All core services appear to be running correctly${NC}"
else
  echo -e "${YELLOW}⚠️ Some services may need attention${NC}"
fi

if [ -f "$API_DIR/niche-scout.ts" ] && [ -f "$API_DIR/seed-to-blueprint.ts" ] && [ -d "$WORKFLOW_DIR/niche-scout" ] && [ -d "$WORKFLOW_DIR/seed-to-blueprint" ]; then
  echo -e "${GREEN}✅ All workflow components are in place${NC}"
else
  echo -e "${RED}❌ Some workflow components are missing${NC}"
fi

if [ "$DEV_PORT" == "3007" ] && [ "$START_PORT" == "3007" ] && grep -q "SOCIAL_INTEL_URL" "$ENV_LOCAL"; then
  echo -e "${GREEN}✅ Configuration appears to be correct${NC}"
else
  echo -e "${YELLOW}⚠️ Configuration may need adjustment${NC}"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. If any warnings were shown, address them using the recommendations"
echo -e "2. Try running a YouTube workflow from the Mission Control UI"
echo -e "3. Check browser console for any errors during execution"
echo -e "4. Update implementation_status_final.md with any changes made"
echo -e "5. Refer to the PORT-STANDARD.md document for port configuration standards"
echo ""
echo -e "${BLUE}=========================================================${NC}"
