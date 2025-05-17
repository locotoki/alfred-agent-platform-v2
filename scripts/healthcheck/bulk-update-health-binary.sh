#!/bin/bash
# Script to add the healthcheck binary to all Dockerfiles that don't have it

set -e

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SERVICES_DIR="/home/locotoki/projects/alfred-agent-platform-v2/services"
HEALTHCHECK_VERSION="0.4.0"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo -e "${BLUE}Scanning Dockerfiles...${NC}"

# Get all Dockerfiles
DOCKERFILES=$(find ${SERVICES_DIR} -name "Dockerfile*" -not -path "*/\.*" -type f | grep -v ".bak" | sort)

# Count total Dockerfiles
TOTAL_COUNT=$(echo "$DOCKERFILES" | wc -l)
echo -e "${BLUE}Found ${TOTAL_COUNT} Dockerfiles${NC}"

# Count Dockerfiles that already have the healthcheck binary
HEALTH_COUNT=$(grep -l "FROM ghcr.io/alfred/healthcheck" ${DOCKERFILES} 2>/dev/null | wc -l)
echo -e "${GREEN}${HEALTH_COUNT} Dockerfiles already include the healthcheck binary${NC}"

# Count Dockerfiles that need updating
NEED_UPDATE=$((TOTAL_COUNT - HEALTH_COUNT))
echo -e "${YELLOW}${NEED_UPDATE} Dockerfiles need updating${NC}"

# Process each Dockerfile
for dockerfile in $DOCKERFILES; do
  # Check if the file already includes the healthcheck binary
  if grep -q "FROM ghcr.io/alfred/healthcheck" "$dockerfile"; then
    echo -e "${GREEN}✅ Already has healthcheck: $dockerfile${NC}"
    continue
  fi

  echo -e "${YELLOW}⚠️ Processing: $dockerfile${NC}"
  
  # Create backup
  cp "$dockerfile" "${dockerfile}.bak-${TIMESTAMP}"
  
  # Check if this is a multi-stage build
  FINAL_STAGE=""
  if grep -q "^FROM .* AS " "$dockerfile"; then
    # Multi-stage build - find the final stage
    STAGES=$(grep "^FROM .* AS " "$dockerfile" | sed -E 's/FROM .* AS ([^ ]+).*/\1/')
    
    # Get the last stage referenced in a COPY --from statement
    COPY_FROMS=$(grep "COPY --from=" "$dockerfile" | sed -E 's/COPY --from=([^ ]+).*/\1/')
    
    # Stages that are not referenced in COPY --from are final stages
    for stage in $STAGES; do
      if ! echo "$COPY_FROMS" | grep -q "$stage"; then
        FINAL_STAGE=$stage
        break
      fi
    done
    
    if [ -z "$FINAL_STAGE" ]; then
      # If we couldn't determine the final stage, just use the last stage mentioned
      FINAL_STAGE=$(echo "$STAGES" | tail -1)
    fi
    
    echo -e "${BLUE}   Multi-stage build - Final stage: $FINAL_STAGE${NC}"
  fi
  
  # Inject healthcheck stage at the beginning
  sed -i "1s/^/FROM ghcr.io\/alfred\/healthcheck:${HEALTHCHECK_VERSION} AS healthcheck\n/" "$dockerfile"
  
  # Determine where to add the COPY --from=healthcheck command
  if [ -n "$FINAL_STAGE" ]; then
    # Add after the final stage FROM line
    FROM_LINE=$(grep -n "^FROM .* AS $FINAL_STAGE" "$dockerfile" | cut -d: -f1)
    if [ -n "$FROM_LINE" ]; then
      # Insert after the FROM line
      sed -i "$((FROM_LINE+1))i COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck" "$dockerfile"
      echo -e "${GREEN}   Added healthcheck to stage $FINAL_STAGE${NC}"
    else
      echo -e "${RED}   Error: Couldn't find final stage FROM line${NC}"
      continue
    fi
  else
    # Single-stage build - add after the first FROM line
    FROM_LINE=$(grep -n "^FROM " "$dockerfile" | head -1 | cut -d: -f1)
    if [ -n "$FROM_LINE" ]; then
      # Insert after the FROM line
      sed -i "$((FROM_LINE+1))i COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck" "$dockerfile"
      echo -e "${GREEN}   Added healthcheck to single-stage build${NC}"
    else
      echo -e "${RED}   Error: Couldn't find FROM line${NC}"
      continue
    fi
  fi
  
  # Add EXPOSE 9091 for metrics
  if ! grep -q "EXPOSE.*9091" "$dockerfile"; then
    if grep -q "EXPOSE" "$dockerfile"; then
      # Add after the last EXPOSE line
      LAST_EXPOSE_LINE=$(grep -n "EXPOSE" "$dockerfile" | tail -1 | cut -d: -f1)
      sed -i "$((LAST_EXPOSE_LINE+1))i EXPOSE 9091 # Metrics port" "$dockerfile"
      echo -e "${BLUE}   Added EXPOSE 9091 for metrics${NC}"
    else
      # Add before ENTRYPOINT or CMD, or at the end of the file
      if grep -q "^ENTRYPOINT\|^CMD" "$dockerfile"; then
        FIRST_CMD_LINE=$(grep -n "^ENTRYPOINT\|^CMD" "$dockerfile" | head -1 | cut -d: -f1)
        sed -i "$((FIRST_CMD_LINE))i EXPOSE 9091 # Metrics port" "$dockerfile"
      else
        # Add at the end
        echo -e "\nEXPOSE 9091 # Metrics port" >> "$dockerfile"
      fi
      echo -e "${BLUE}   Added EXPOSE 9091 for metrics${NC}"
    fi
  else
    echo -e "${BLUE}   EXPOSE 9091 already present${NC}"
  fi
  
  # Check if ENTRYPOINT is defined
  if grep -q "^ENTRYPOINT\|^CMD" "$dockerfile"; then
    echo -e "${BLUE}   Dockerfile already has ENTRYPOINT/CMD${NC}"
    
    # Add note about healthcheck metrics
    echo -e "\n# To expose metrics, update your ENTRYPOINT/CMD to include: /usr/local/bin/healthcheck --export-prom :9091 &" >> "$dockerfile"
  else
    echo -e "${YELLOW}   No ENTRYPOINT/CMD found - adding note${NC}"
    
    # Add template for ENTRYPOINT and CMD
    echo -e "\n# To expose metrics, add something like:\n# ENTRYPOINT [\"/usr/local/bin/healthcheck\", \"--export-prom\", \":9091\", \"&\", \"your-app-binary\"]" >> "$dockerfile"
  fi
  
  echo -e "${GREEN}✅ Updated: $dockerfile${NC}"
done

echo
echo -e "${BLUE}Summary:${NC}"
echo -e "${GREEN}${HEALTH_COUNT} Dockerfiles already had healthcheck binary${NC}"
echo -e "${YELLOW}${NEED_UPDATE} Dockerfiles were updated${NC}"
echo
echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. Review the updated Dockerfiles"
echo -e "2. Ensure ENTRYPOINT/CMD is updated to start healthcheck with --export-prom :9091"
echo -e "3. Rebuild images with: docker-compose build <service-name>"
echo -e "4. Update Prometheus configuration to scrape the new metrics endpoints"

echo
echo -e "${GREEN}Done!${NC}"