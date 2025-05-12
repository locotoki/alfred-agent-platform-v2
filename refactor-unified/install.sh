#!/bin/bash
#
# Alfred Agent Platform v2 - Installation Script
# This script helps with installation of the refactored Docker Compose configuration
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default target directory - use current directory as default
DEFAULT_TARGET_DIR="$(pwd)"
TARGET_DIR=${1:-$DEFAULT_TARGET_DIR}

# Source directory - where the refactored files are located
SOURCE_DIR="/home/locotoki/projects/alfred-agent-platform-v2/refactor-unified"

# Print banner
echo -e "${BLUE}"
echo "    _    _  __               _   "
echo "   / \  | |/ _|_ __ ___  __| |  "
echo "  / _ \ | | |_| '__/ _ \/ _\` |  "
echo " / ___ \| |  _| | |  __/ (_| |  "
echo "/_/   \_\_|_| |_|  \___|\__,_|  "
echo "                               "
echo " Agent Platform v2 - Installation"
echo -e "${NC}"

# Function to create backup of existing files
function backup_existing_files() {
  local backup_dir="$TARGET_DIR/backup_$(date +%Y%m%d_%H%M%S)"
  
  echo -e "${YELLOW}Creating backup at $backup_dir...${NC}"
  mkdir -p "$backup_dir"
  
  # Backup existing Docker Compose files
  if ls $TARGET_DIR/docker-compose*.yml 1> /dev/null 2>&1; then
    echo -e "${YELLOW}Backing up Docker Compose files...${NC}"
    cp $TARGET_DIR/docker-compose*.yml "$backup_dir/" 2>/dev/null || true
  fi
  
  # Backup existing alfred.sh or equivalent
  if [[ -f "$TARGET_DIR/alfred.sh" ]]; then
    echo -e "${YELLOW}Backing up alfred.sh...${NC}"
    cp $TARGET_DIR/alfred.sh "$backup_dir/"
  fi
  
  # Backup .env file if it exists
  if [[ -f "$TARGET_DIR/.env" ]]; then
    echo -e "${YELLOW}Backing up .env file...${NC}"
    cp $TARGET_DIR/.env "$backup_dir/"
  fi
  
  echo -e "${GREEN}Backup complete at $backup_dir${NC}"
}

# Function to install files
function install_files() {
  echo -e "${YELLOW}Installing files to $TARGET_DIR...${NC}"
  
  # Create target directory if it doesn't exist
  mkdir -p "$TARGET_DIR"
  
  # First create a backup
  backup_existing_files
  
  # Copy Docker Compose files
  echo -e "${YELLOW}Copying Docker Compose files...${NC}"
  cp $SOURCE_DIR/docker-compose*.yml "$TARGET_DIR/"
  
  # Copy alfred.sh script
  echo -e "${YELLOW}Copying alfred.sh script...${NC}"
  cp $SOURCE_DIR/alfred.sh "$TARGET_DIR/"
  chmod +x "$TARGET_DIR/alfred.sh"
  
  # Copy documentation
  echo -e "${YELLOW}Copying documentation...${NC}"
  cp $SOURCE_DIR/README.md "$TARGET_DIR/"
  cp $SOURCE_DIR/MIGRATION.md "$TARGET_DIR/"
  cp $SOURCE_DIR/DEPLOYMENT_CHECKLIST.md "$TARGET_DIR/"
  cp $SOURCE_DIR/COMPLETION_REPORT.md "$TARGET_DIR/"
  
  # Copy .env files
  if [[ ! -f "$TARGET_DIR/.env" ]]; then
    echo -e "${YELLOW}Copying .env.example to $TARGET_DIR/.env...${NC}"
    cp $SOURCE_DIR/.env.example "$TARGET_DIR/.env"
    echo -e "${YELLOW}Please update $TARGET_DIR/.env with your settings${NC}"
  else
    echo -e "${YELLOW}$TARGET_DIR/.env already exists. Keeping existing file.${NC}"
    echo -e "${YELLOW}Please check .env.example for any new variables${NC}"
    cp $SOURCE_DIR/.env.example "$TARGET_DIR/.env.example"
  fi
  
  # Create tests directory if it doesn't exist
  if [[ ! -d "$TARGET_DIR/tests" ]]; then
    echo -e "${YELLOW}Creating tests directory...${NC}"
    mkdir -p "$TARGET_DIR/tests"
    cp -r $SOURCE_DIR/tests/* "$TARGET_DIR/tests/"
    chmod +x "$TARGET_DIR/tests"/*.sh
  else
    echo -e "${YELLOW}Updating tests directory...${NC}"
    cp -r $SOURCE_DIR/tests/* "$TARGET_DIR/tests/"
    chmod +x "$TARGET_DIR/tests"/*.sh
  fi
  
  echo -e "${GREEN}Installation complete!${NC}"
  echo -e "${YELLOW}Next steps:${NC}"
  echo -e "1. Review $TARGET_DIR/DEPLOYMENT_CHECKLIST.md"
  echo -e "2. Update $TARGET_DIR/.env with your settings"
  echo -e "3. Run: cd $TARGET_DIR && ./tests/validate-compose.sh"
  echo -e "4. Start services: cd $TARGET_DIR && ./alfred.sh start --components=core"
}

# Check if target dir is the source dir
if [[ "$TARGET_DIR" == "$SOURCE_DIR" ]]; then
  echo -e "${RED}Error: Target directory cannot be the same as source directory${NC}"
  echo -e "${YELLOW}Please specify a different target directory${NC}"
  exit 1
fi

# Ask for confirmation
echo -e "${YELLOW}This will install the refactored Docker Compose configuration to:${NC}"
echo -e "${BLUE}$TARGET_DIR${NC}"
echo -e "${YELLOW}Existing files will be backed up before installation.${NC}"
read -p "Continue? (y/n) " -n 1 -r
echo ""

# Check user response
if [[ $REPLY =~ ^[Yy]$ ]]; then
  install_files
else
  echo -e "${RED}Installation cancelled${NC}"
  exit 1
fi