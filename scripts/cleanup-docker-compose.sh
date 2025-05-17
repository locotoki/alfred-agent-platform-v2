#!/bin/bash
# Script to clean up Docker Compose configuration files
# This script implements the strategy outlined in DOCKER-COMPOSE-CLEANUP.md

set -e

# Text formatting for better readability
BOLD=$(tput bold)
NORM=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)

# Create a backup directory with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="./backup/docker-compose-cleanup-${TIMESTAMP}"

echo -e "${BOLD}${BLUE}Docker Compose Configuration Cleanup${NORM}"
echo -e "${YELLOW}Creating backups in: ${BACKUP_DIR}${NORM}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Backup all Docker Compose files
echo -e "${BLUE}Backing up Docker Compose files...${NORM}"
find . -name "docker-compose*.yml" -not -path "./backup/*" -exec cp --parents {} "${BACKUP_DIR}" \;

# Create a log of what files were backed up
find "${BACKUP_DIR}" -name "docker-compose*.yml" | sort > "${BACKUP_DIR}/backup-file-list.txt"
echo -e "${GREEN}Backed up $(wc -l < "${BACKUP_DIR}/backup-file-list.txt") Docker Compose files${NORM}"

# Implement the rename of docker-compose-clean.yml to docker-compose.yml
if [ -f "docker-compose-clean.yml" ] && [ -f "docker-compose.yml" ]; then
  echo -e "${YELLOW}Both docker-compose-clean.yml and docker-compose.yml exist.${NORM}"
  echo -e "${YELLOW}Moving current docker-compose.yml to ${BACKUP_DIR}/docker-compose.yml.original${NORM}"
  mv "docker-compose.yml" "${BACKUP_DIR}/docker-compose.yml.original"
  
  echo -e "${BLUE}Renaming docker-compose-clean.yml to docker-compose.yml${NORM}"
  cp "docker-compose-clean.yml" "docker-compose.yml"
  
  # We don't remove the original yet until testing is complete
  echo -e "${YELLOW}Kept original docker-compose-clean.yml for backup${NORM}"
else
  if [ -f "docker-compose-clean.yml" ]; then
    echo -e "${BLUE}Renaming docker-compose-clean.yml to docker-compose.yml${NORM}"
    cp "docker-compose-clean.yml" "docker-compose.yml"
    echo -e "${YELLOW}Kept original docker-compose-clean.yml for backup${NORM}"
  else
    echo -e "${RED}docker-compose-clean.yml not found!${NORM}"
    echo -e "${RED}Cannot proceed with renaming. Please check your configuration.${NORM}"
    exit 1
  fi
fi

# Update start-platform.sh to use docker-compose.yml instead of docker-compose-clean.yml
if [ -f "start-platform.sh" ]; then
  echo -e "${BLUE}Updating start-platform.sh to use docker-compose.yml...${NORM}"
  cp "start-platform.sh" "${BACKUP_DIR}/start-platform.sh.original"
  
  # Replace the COMPOSE_FILE variable
  sed -i 's/COMPOSE_FILE="docker-compose-clean.yml"/COMPOSE_FILE="docker-compose.yml"/' "start-platform.sh"
  
  echo -e "${GREEN}Updated start-platform.sh${NORM}"
else
  echo -e "${RED}start-platform.sh not found!${NORM}"
  echo -e "${RED}Cannot update script. Please check your configuration.${NORM}"
  exit 1
fi

# Update start-platform-dryrun.sh if it exists
if [ -f "start-platform-dryrun.sh" ]; then
  echo -e "${BLUE}Updating start-platform-dryrun.sh to use docker-compose.yml...${NORM}"
  cp "start-platform-dryrun.sh" "${BACKUP_DIR}/start-platform-dryrun.sh.original"
  
  # Replace the COMPOSE_FILE variable
  sed -i 's/COMPOSE_FILE="docker-compose-clean.yml"/COMPOSE_FILE="docker-compose.yml"/' "start-platform-dryrun.sh"
  
  echo -e "${GREEN}Updated start-platform-dryrun.sh${NORM}"
fi

# Update other scripts that reference docker-compose-clean.yml
echo -e "${BLUE}Updating references in other scripts...${NORM}"
SCRIPTS_TO_UPDATE=$(grep -l "docker-compose-clean.yml" $(find ./scripts -name "*.sh") 2>/dev/null || echo "")

if [ ! -z "$SCRIPTS_TO_UPDATE" ]; then
  for script in $SCRIPTS_TO_UPDATE; do
    echo -e "${YELLOW}Updating ${script}...${NORM}"
    cp "$script" "${BACKUP_DIR}/${script}.original"
    sed -i 's/docker-compose-clean\.yml/docker-compose.yml/g' "$script"
    echo -e "${GREEN}Updated ${script}${NORM}"
  done
else
  echo -e "${YELLOW}No other scripts found with references to docker-compose-clean.yml${NORM}"
fi

# Create docker-compose.override.yml template if it doesn't exist
if [ ! -f "docker-compose.override.yml" ]; then
  echo -e "${BLUE}Creating docker-compose.override.yml template...${NORM}"
  cat > "docker-compose.override.yml" << EOF
# Docker Compose Override Configuration
# This file contains local development overrides for the main docker-compose.yml file
# It is automatically loaded when running 'docker-compose up'

version: '3.8'

services:
  # Override service configurations here
  # Example:
  # ui-chat:
  #   volumes:
  #     - ./services/streamlit-chat:/app
  #   environment:
  #     - DEBUG=true

  # Development-specific services can be added here
EOF

  echo -e "${GREEN}Created docker-compose.override.yml template${NORM}"
fi

echo -e "${BOLD}${GREEN}Docker Compose configuration cleanup completed!${NORM}"
echo -e "${YELLOW}Please test the updated configuration by running:${NORM}"
echo -e "${BOLD}./start-platform.sh${NORM}"
echo -e "${YELLOW}If everything works correctly, you can remove docker-compose-clean.yml${NORM}"
echo -e "${YELLOW}All original files have been backed up to: ${BACKUP_DIR}${NORM}"

# Generate a report of changes made
echo -e "${BLUE}Generating change report...${NORM}"
cat > "${BACKUP_DIR}/CHANGES.md" << EOF
# Docker Compose Configuration Cleanup

**Date:** $(date '+%Y-%m-%d %H:%M:%S')

## Changes Made

1. Renamed \`docker-compose-clean.yml\` to \`docker-compose.yml\`
2. Updated references in \`start-platform.sh\` and related scripts
3. Created a template \`docker-compose.override.yml\` if it didn't exist

## Backup Information

All original files have been backed up to this directory.

## Next Steps

1. Test the platform with the new configuration:
   \`\`\`
   ./start-platform.sh
   \`\`\`
   
2. If everything works correctly, remove \`docker-compose-clean.yml\`

3. Continue implementing the full cleanup strategy as outlined in \`DOCKER-COMPOSE-CLEANUP.md\`
EOF

echo -e "${GREEN}Change report generated at: ${BACKUP_DIR}/CHANGES.md${NORM}"