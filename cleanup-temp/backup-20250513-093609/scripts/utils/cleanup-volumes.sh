#!/bin/bash
# cleanup-volumes.sh
# Script to clean up orphaned volumes safely

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print script header
echo -e "${BOLD}Alfred Agent Platform - Volume Cleanup${NC}"
echo "This script helps clean up orphaned Docker volumes."
echo

# Define volume patterns to protect (critical data)
PROTECTED_PATTERNS=(
  "alfred-agent-platform-v2_postgres-data"
  "alfred-agent-platform-v2_qdrant"
  "alfred-agent-platform-v2_redis-data"
  "alfred-agent-platform-v2_supabase"
  "alfred-agent-platform-v2_ollama"
  "alfred-agent-platform-v2_prometheus-data"
  "alfred-agent-platform-v2_grafana-data"
)

# Function to check if a volume should be protected
is_protected() {
  local volume_name=$1
  for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ $volume_name == *"$pattern"* ]]; then
      return 0  # Protected
    fi
  done
  return 1  # Not protected
}

# Step 1: List all dangling volumes
echo -e "${BLUE}Finding orphaned volumes...${NC}"
ORPHANED_VOLUMES=$(docker volume ls -q -f dangling=true)

if [ -z "$ORPHANED_VOLUMES" ]; then
  echo -e "${GREEN}No orphaned volumes found.${NC}"
  exit 0
fi

# Count volumes
TOTAL_ORPHANED=$(echo "$ORPHANED_VOLUMES" | wc -l)
echo -e "${YELLOW}Found $TOTAL_ORPHANED orphaned volumes.${NC}"

# Step 2: Categorize volumes
ANONYMOUS_VOLUMES=()
OTHER_VOLUMES=()
PROTECTED_VOLUMES=()

for vol in $ORPHANED_VOLUMES; do
  if [[ $vol =~ ^[a-f0-9]{64}$ ]]; then
    ANONYMOUS_VOLUMES+=("$vol")
  elif is_protected "$vol"; then
    PROTECTED_VOLUMES+=("$vol")
  else
    OTHER_VOLUMES+=("$vol")
  fi
done

# Step 3: Display categorized volumes
echo
echo -e "${BLUE}Volume Categories:${NC}"
echo -e "${YELLOW}Anonymous Volumes:${NC} ${#ANONYMOUS_VOLUMES[@]}"
echo -e "${RED}Protected Project Volumes:${NC} ${#PROTECTED_VOLUMES[@]}"
echo -e "${YELLOW}Other Orphaned Volumes:${NC} ${#OTHER_VOLUMES[@]}"

# Step 4: Ask user what to do
echo
echo -e "${BOLD}Cleanup Options:${NC}"
echo "1. Clean up anonymous volumes only (safe)"
echo "2. Clean up anonymous volumes and other non-protected volumes"
echo "3. Clean up ALL orphaned volumes (DANGER: includes protected volumes)"
echo "4. Exit without cleaning up"
echo
read -p "Enter your choice (1-4): " CHOICE

case $CHOICE in
  1)
    # Clean up anonymous volumes
    echo -e "${YELLOW}Cleaning up ${#ANONYMOUS_VOLUMES[@]} anonymous volumes...${NC}"
    for vol in "${ANONYMOUS_VOLUMES[@]}"; do
      echo -n "Removing $vol... "
      if docker volume rm "$vol" > /dev/null 2>&1; then
        echo -e "${GREEN}Success${NC}"
      else
        echo -e "${RED}Failed${NC}"
      fi
    done
    ;;
  2)
    # Clean up anonymous volumes and other non-protected
    echo -e "${YELLOW}Cleaning up ${#ANONYMOUS_VOLUMES[@]} anonymous volumes and ${#OTHER_VOLUMES[@]} other volumes...${NC}"
    for vol in "${ANONYMOUS_VOLUMES[@]}" "${OTHER_VOLUMES[@]}"; do
      echo -n "Removing $vol... "
      if docker volume rm "$vol" > /dev/null 2>&1; then
        echo -e "${GREEN}Success${NC}"
      else
        echo -e "${RED}Failed${NC}"
      fi
    done
    ;;
  3)
    # Clean up ALL orphaned volumes
    echo -e "${RED}WARNING: This will remove ALL orphaned volumes, including protected ones!${NC}"
    echo -e "${RED}Protected volumes that will be removed:${NC}"
    for vol in "${PROTECTED_VOLUMES[@]}"; do
      echo "  - $vol"
    done
    echo
    read -p "Are you SURE you want to continue? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
      echo -e "${YELLOW}Aborted.${NC}"
      exit 0
    fi
    
    echo -e "${YELLOW}Cleaning up ALL ${TOTAL_ORPHANED} orphaned volumes...${NC}"
    for vol in $ORPHANED_VOLUMES; do
      echo -n "Removing $vol... "
      if docker volume rm "$vol" > /dev/null 2>&1; then
        echo -e "${GREEN}Success${NC}"
      else
        echo -e "${RED}Failed${NC}"
      fi
    done
    ;;
  4|*)
    echo -e "${YELLOW}Exiting without cleaning up.${NC}"
    exit 0
    ;;
esac

# Final step: Check how many volumes were actually removed
REMAINING_ORPHANED=$(docker volume ls -q -f dangling=true | wc -l)
REMOVED_COUNT=$((TOTAL_ORPHANED - REMAINING_ORPHANED))

echo
echo -e "${GREEN}Cleanup complete:${NC}"
echo -e "  - ${GREEN}${REMOVED_COUNT} volumes removed${NC}"
if [ $REMAINING_ORPHANED -gt 0 ]; then
  echo -e "  - ${YELLOW}${REMAINING_ORPHANED} volumes couldn't be removed (still in use)${NC}"
fi