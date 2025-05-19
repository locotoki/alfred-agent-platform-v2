#!/bin/bash
# migrate-volumes.sh
# Script to migrate data from old volumes to new consistently named volumes

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print script header
echo -e "${BOLD}Alfred Agent Platform - Volume Migration${NC}"
echo "This script will migrate data from existing volumes to new consistently named volumes."
echo
echo -e "${RED}WARNING: This is a data migration operation. Make sure you have backups!${NC}"
echo

# Volume mappings (old to new)
declare -A VOLUME_MAPPING=(
  ["alfred-agent-platform-v2_redis-data"]="alfred-redis-data"
  ["alfred-agent-platform-v2_qdrant-storage"]="alfred-vector-db-data"
  ["alfred-agent-platform-v2_ollama-data"]="alfred-llm-service-data"
  ["alfred-agent-platform-v2_postgres-data"]="alfred-db-postgres-data"
  ["alfred-agent-platform-v2_supabase-storage-data"]="alfred-db-storage-data"
  ["alfred-agent-platform-v2_prometheus-data"]="alfred-monitoring-metrics-data"
  ["alfred-agent-platform-v2_grafana-data"]="alfred-monitoring-dashboard-data"
)

# Verify old volumes exist
echo -e "${BLUE}Checking for existing volumes...${NC}"
MISSING_VOLUMES=0

for old_vol in "${!VOLUME_MAPPING[@]}"; do
  if docker volume inspect "$old_vol" &>/dev/null; then
    echo -e "  ${GREEN}✓ Found:${NC} $old_vol"
  else
    echo -e "  ${RED}✗ Missing:${NC} $old_vol"
    MISSING_VOLUMES=$((MISSING_VOLUMES+1))
  fi
done

if [ $MISSING_VOLUMES -gt 0 ]; then
  echo
  echo -e "${YELLOW}Some source volumes are missing. Migration may be incomplete.${NC}"
  echo -e "${YELLOW}Do you want to continue? (y/N)${NC}"
  read -r CONTINUE
  if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Migration aborted.${NC}"
    exit 1
  fi
fi

# Check if destination volumes already exist
echo
echo -e "${BLUE}Checking for destination volumes...${NC}"
EXISTING_DEST=0

for new_vol in "${VOLUME_MAPPING[@]}"; do
  if docker volume inspect "$new_vol" &>/dev/null; then
    echo -e "  ${YELLOW}⚠ Already exists:${NC} $new_vol"
    EXISTING_DEST=$((EXISTING_DEST+1))
  else
    echo -e "  ${GREEN}✓ Will create:${NC} $new_vol"
  fi
done

if [ $EXISTING_DEST -gt 0 ]; then
  echo
  echo -e "${YELLOW}Some destination volumes already exist. Continuing will overwrite data.${NC}"
  echo -e "${YELLOW}Do you want to continue? (y/N)${NC}"
  read -r CONTINUE
  if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Migration aborted.${NC}"
    exit 1
  fi
fi

# Make sure containers are stopped
echo
echo -e "${BLUE}Stopping any running containers...${NC}"
./start-platform.sh -a down
echo -e "${GREEN}Containers stopped.${NC}"

# Create helper container for migration
echo
echo -e "${BLUE}Starting migration process...${NC}"

for old_vol in "${!VOLUME_MAPPING[@]}"; do
  new_vol="${VOLUME_MAPPING[$old_vol]}"

  echo
  echo -e "${YELLOW}Migrating:${NC} $old_vol → $new_vol"

  # Create new volume if it doesn't exist
  if ! docker volume inspect "$new_vol" &>/dev/null; then
    echo "  Creating new volume: $new_vol"
    docker volume create "$new_vol"
  fi

  # Create temporary container to copy data
  echo "  Copying data..."
  docker run --rm \
    -v "$old_vol:/from" \
    -v "$new_vol:/to" \
    alpine ash -c "cd /from && tar -cf - . | tar -xf - -C /to"

  echo -e "  ${GREEN}✓ Migration complete:${NC} $old_vol → $new_vol"
done

echo
echo -e "${GREEN}Data migration completed successfully!${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. Start the platform with the new volumes: ./start-platform.sh"
echo "2. Verify everything works correctly"
echo "3. Once confirmed, you can clean up the old volumes with: ./cleanup-volumes.sh"
echo

echo -e "${YELLOW}Would you like to start the platform now with the new volumes? (y/N)${NC}"
read -r START_NOW
if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
  ./start-platform.sh
else
  echo -e "${BLUE}You can start the platform later with:${NC} ./start-platform.sh"
fi
