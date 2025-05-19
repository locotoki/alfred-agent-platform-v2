#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}  Restructuring Alfred Platform Startup Scripts  ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Create archive directory for redundant scripts
echo -e "${YELLOW}Creating archive directory...${NC}"
mkdir -p ./scripts/archive

# Move redundant scripts to archive
echo -e "${YELLOW}Moving redundant scripts to archive...${NC}"
cp ./start-alfred.sh ./scripts/archive/
cp ./start-clean.sh ./scripts/archive/
cp ./start-production.sh ./scripts/archive/

# Copy unified alfred.sh to the root directory
echo -e "${YELLOW}Copying unified alfred.sh to root directory...${NC}"
cp ./refactor-unified/alfred.sh ./alfred.sh
chmod +x ./alfred.sh

# Copy our new scripts to the scripts directory
echo -e "${YELLOW}Organizing new restart scripts...${NC}"
cp ./controlled-restart.sh ./scripts/
cp ./platform-startup.sh ./scripts/
cp ./PLATFORM_SERVICES.md ./docs/

# Verify alfred.sh works correctly
echo -e "${YELLOW}Verifying alfred.sh...${NC}"
./alfred.sh help

echo -e "${GREEN}✅ Scripts restructured successfully!${NC}"
echo -e "${YELLOW}NOTE: Original scripts have been archived, not deleted.${NC}"
echo -e "${YELLOW}You can find them in ./scripts/archive/${NC}"
echo ""
echo -e "${BLUE}New script structure:${NC}"
echo "  ./alfred.sh                   - Main management script"
echo "  ./start-llm-with-keys.sh      - LLM setup with API keys"
echo "  ./restart-llm-services.sh     - Quick restart of LLM services"
echo "  ./scripts/controlled-restart.sh - Controlled restart with checks"
echo "  ./scripts/platform-startup.sh  - Startup after shutdown"
echo ""
echo -e "${YELLOW}To completely remove the old scripts, run:${NC}"
echo "  rm ./start-alfred.sh ./start-clean.sh ./start-production.sh"
echo ""
echo -e "${BLUE}===============================================${NC}"
