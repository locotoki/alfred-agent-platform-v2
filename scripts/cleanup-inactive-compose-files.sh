#!/bin/bash
# Script to identify and move inactive docker-compose files to backup directory

set -e

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create a timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/home/locotoki/projects/alfred-agent-platform-v2/backup/inactive-compose-files-${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

echo -e "${BLUE}Identifying active docker-compose files...${NC}"

# Define active files (those used by the platform startup)
ACTIVE_FILES=(
  "/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.yml"
  "/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.dev.yml"
  "/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.prod.yml"
  "/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.override.yml"
  "/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.override.social-intel.yml"
  "/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.override.ui-chat.yml"
  "/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
)

# Find all docker-compose files (excluding backup directories)
FOUND_FILES=$(find /home/locotoki/projects/alfred-agent-platform-v2 -name "docker-compose*.yml" -not -path "*/backup/*" -not -path "*/node_modules/*" | sort)

INACTIVE_COUNT=0
ACTIVE_COUNT=0

echo -e "${BLUE}Processing files...${NC}"
echo

# Process each found file
for file in $FOUND_FILES; do
  # Check if file is in active list
  ACTIVE=false
  for active_file in "${ACTIVE_FILES[@]}"; do
    if [ "$file" == "$active_file" ]; then
      ACTIVE=true
      break
    fi
  done

  if [ "$ACTIVE" = true ]; then
    echo -e "${GREEN}ACTIVE: $file${NC}"
    ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
  else
    # This is an inactive file
    echo -e "${YELLOW}INACTIVE: $file${NC}"
    # Create the directory structure in the backup directory
    target_dir="${BACKUP_DIR}/$(dirname ${file#/home/locotoki/projects/alfred-agent-platform-v2/})"
    mkdir -p "$target_dir"
    # Copy the file to the backup directory with its relative path preserved
    cp "$file" "${BACKUP_DIR}/$(dirname ${file#/home/locotoki/projects/alfred-agent-platform-v2/})/$(basename $file)"
    INACTIVE_COUNT=$((INACTIVE_COUNT + 1))
  fi
done

echo
echo -e "${BLUE}Summary:${NC}"
echo -e "${GREEN}Active docker-compose files: $ACTIVE_COUNT${NC}"
echo -e "${YELLOW}Inactive docker-compose files: $INACTIVE_COUNT${NC}"
echo -e "${BLUE}Backup directory: $BACKUP_DIR${NC}"

# Ask user if they want to delete inactive files
if [ $INACTIVE_COUNT -gt 0 ]; then
  echo
  echo -e "${YELLOW}Do you want to delete the inactive docker-compose files? (yes/no)${NC}"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${BLUE}Deleting inactive files...${NC}"

    for file in $FOUND_FILES; do
      # Check if file is in active list
      ACTIVE=false
      for active_file in "${ACTIVE_FILES[@]}"; do
        if [ "$file" == "$active_file" ]; then
          ACTIVE=true
          break
        fi
      done

      if [ "$ACTIVE" = false ]; then
        echo -e "${YELLOW}Deleting: $file${NC}"
        rm "$file"
      fi
    done

    echo -e "${GREEN}Deletion complete. All inactive files were backed up to $BACKUP_DIR${NC}"
  else
    echo -e "${BLUE}No files were deleted. All inactive files were backed up to $BACKUP_DIR${NC}"
  fi
else
  echo -e "${GREEN}No inactive files found. Nothing to delete.${NC}"
fi
