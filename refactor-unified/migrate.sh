#!/bin/bash
#
# Alfred Agent Platform v2 - Migration One-liner
# This script helps migrate from old to new Docker Compose structure
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "    _    _  __               _   "
echo "   / \  | |/ _|_ __ ___  __| |  "
echo "  / _ \ | | |_| '__/ _ \/ _\` |  "
echo " / ___ \| |  _| | |  __/ (_| |  "
echo "/_/   \_\_|_| |_|  \___|\__,_|  "
echo "                               "
echo " Agent Platform v2 - Migration"
echo -e "${NC}"

# Check if user is in the refactor-unified directory
if [[ "$(basename "$(pwd)")" != "refactor-unified" ]]; then
  echo -e "${RED}Error: This script must be run from the refactor-unified directory${NC}"
  exit 1
fi

# Ask for target directory
echo -e "${YELLOW}Enter the path to your main Alfred Agent Platform directory:${NC}"
read -p "> " TARGET_DIR

# Validate target directory
if [[ ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: $TARGET_DIR is not a valid directory${NC}"
  exit 1
fi

# Execute the install script
./install.sh "$TARGET_DIR"

echo -e "\n${YELLOW}Migration steps:${NC}"
echo -e "1. ${GREEN}✓${NC} Files copied to $TARGET_DIR"
echo -e "2. ${YELLOW}⟳${NC} Review $TARGET_DIR/DEPLOYMENT_CHECKLIST.md"
echo -e "3. ${YELLOW}⟳${NC} Update $TARGET_DIR/.env with your settings"
echo -e "4. ${YELLOW}⟳${NC} Validate with: cd $TARGET_DIR && ./tests/validate-compose.sh"
echo -e "5. ${YELLOW}⟳${NC} Start core services: cd $TARGET_DIR && ./alfred.sh start --components=core"
echo -e "6. ${YELLOW}⟳${NC} Add remaining components as needed"

echo -e "\n${BLUE}See $TARGET_DIR/MIGRATION.md for detailed migration instructions${NC}"