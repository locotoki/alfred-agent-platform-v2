#!/bin/bash
# Script to identify and fix health check binary issues across containers

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}Healthcheck Binary Fix Script${NC}"
echo -e "${BLUE}This script will identify containers missing the healthcheck binary and fix their Dockerfiles${NC}\n"

# Get list of unhealthy containers
echo -e "${BLUE}Finding unhealthy containers...${NC}"
UNHEALTHY_CONTAINERS=$(docker ps --format "{{.Names}}" --filter "health=unhealthy")

if [ -z "$UNHEALTHY_CONTAINERS" ]; then
  echo -e "${GREEN}No unhealthy containers found!${NC}"
  exit 0
fi

echo -e "${YELLOW}Found $(echo "$UNHEALTHY_CONTAINERS" | wc -l) unhealthy containers${NC}"

# Check each container for the healthcheck issue
CONTAINERS_TO_FIX=()
for CONTAINER in $UNHEALTHY_CONTAINERS; do
  echo -e "\n${BLUE}Checking $CONTAINER...${NC}"
  
  # Get the health check command
  HEALTH_CMD=$(docker inspect --format='{{json .Config.Healthcheck.Test}}' "$CONTAINER" | grep -o 'healthcheck')
  
  # Get the last health check output
  HEALTH_OUTPUT=$(docker inspect --format='{{json .State.Health.Log}}' "$CONTAINER" | grep -o 'healthcheck.*executable file not found')
  
  if [ -n "$HEALTH_CMD" ] && [ -n "$HEALTH_OUTPUT" ]; then
    echo -e "${RED}⚠️ $CONTAINER is using healthcheck binary but it's missing${NC}"
    
    # Find the corresponding service directory and Dockerfile
    SERVICE_NAME=$(echo "$CONTAINER" | sed 's/^agent-//' | sed 's/-metrics$//' | sed 's/-/_/g')
    
    # Try different possible locations for the Dockerfile
    DOCKERFILE_PATHS=(
      "./services/$CONTAINER/Dockerfile"
      "./services/${CONTAINER//-/_}/Dockerfile"
      "./services/${CONTAINER//agent-/}/Dockerfile"
      "./services/${SERVICE_NAME}/Dockerfile"
    )
    
    DOCKERFILE=""
    for PATH in "${DOCKERFILE_PATHS[@]}"; do
      if [ -f "$PATH" ]; then
        DOCKERFILE="$PATH"
        break
      fi
    done
    
    if [ -n "$DOCKERFILE" ]; then
      echo -e "${GREEN}Found Dockerfile at $DOCKERFILE${NC}"
      CONTAINERS_TO_FIX+=("$CONTAINER:$DOCKERFILE")
    else
      echo -e "${RED}Could not find Dockerfile for $CONTAINER${NC}"
    fi
  else
    echo -e "${YELLOW}$CONTAINER has a different health check issue${NC}"
  fi
done

echo -e "\n${BLUE}${BOLD}Summary${NC}"
if [ ${#CONTAINERS_TO_FIX[@]} -eq 0 ]; then
  echo -e "${YELLOW}No containers with missing healthcheck binary identified${NC}"
  echo -e "${YELLOW}The health check issues may be related to other problems${NC}"
  exit 0
fi

echo -e "${GREEN}Will fix ${#CONTAINERS_TO_FIX[@]} containers with missing healthcheck binary${NC}"

# Ask for confirmation
echo -e "\n${YELLOW}Do you want to automatically fix these issues? (y/n)${NC}"
read -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Aborted.${NC}"
  exit 0
fi

# Fix each Dockerfile
for ENTRY in "${CONTAINERS_TO_FIX[@]}"; do
  IFS=':' read -r CONTAINER DOCKERFILE <<< "$ENTRY"
  echo -e "\n${BLUE}Fixing $CONTAINER using $DOCKERFILE...${NC}"
  
  # Backup the original Dockerfile
  cp "$DOCKERFILE" "$DOCKERFILE.bak"
  echo -e "${YELLOW}Backed up to $DOCKERFILE.bak${NC}"
  
  # Check if it's a multi-stage build with healthcheck
  if grep -q "FROM.*healthcheck.*AS" "$DOCKERFILE"; then
    # It already has the healthcheck stage but is missing the COPY command
    if ! grep -q "COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck" "$DOCKERFILE"; then
      # Add the COPY command after the FROM line for the final stage
      FINAL_FROM_LINE=$(grep -n "FROM" "$DOCKERFILE" | tail -1 | cut -d: -f1)
      sed -i "$((FINAL_FROM_LINE+1))i\\\n# Copy the healthcheck binary from the first stage\nCOPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck" "$DOCKERFILE"
      
      echo -e "${GREEN}Added COPY command for healthcheck binary${NC}"
    fi
  else
    # It's missing the healthcheck stage entirely
    # Add the healthcheck stage at the beginning
    sed -i '1s/^/FROM ghcr.io\/alfred\/healthcheck:0.4.0 AS healthcheck\n/' "$DOCKERFILE"
    
    # Add the COPY command after the FROM line for the final stage
    FINAL_FROM_LINE=$(grep -n "FROM" "$DOCKERFILE" | tail -1 | cut -d: -f1)
    sed -i "$((FINAL_FROM_LINE+1))i\\\n# Copy the healthcheck binary from the first stage\nCOPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck" "$DOCKERFILE"
    
    echo -e "${GREEN}Added healthcheck stage and COPY command${NC}"
  fi
  
  # Check and fix CMD/ENTRYPOINT to use healthcheck for metrics
  if ! grep -q "CMD \[\"healthcheck\"" "$DOCKERFILE" && ! grep -q "ENTRYPOINT \[\"healthcheck\"" "$DOCKERFILE"; then
    # Get the current CMD/ENTRYPOINT
    CMD=$(grep -E "^CMD \[" "$DOCKERFILE" | tail -1)
    ENTRYPOINT=$(grep -E "^ENTRYPOINT \[" "$DOCKERFILE" | tail -1)
    
    if [ -n "$CMD" ]; then
      # Extract the command parts
      CMD_PARTS=$(echo "$CMD" | sed 's/CMD \[\(.*\)\]/\1/')
      
      # Create new CMD with healthcheck
      NEW_CMD="CMD [\"healthcheck\", \"--export-prom\", \":9091\", \"--\", $CMD_PARTS]"
      
      # Replace the CMD line
      sed -i "s|$CMD|$NEW_CMD|" "$DOCKERFILE"
      
      echo -e "${GREEN}Updated CMD to use healthcheck binary${NC}"
    elif [ -n "$ENTRYPOINT" ]; then
      # Extract the entrypoint parts
      ENTRYPOINT_PARTS=$(echo "$ENTRYPOINT" | sed 's/ENTRYPOINT \[\(.*\)\]/\1/')
      
      # Create new ENTRYPOINT with healthcheck
      NEW_ENTRYPOINT="ENTRYPOINT [\"healthcheck\", \"--export-prom\", \":9091\", \"--\", $ENTRYPOINT_PARTS]"
      
      # Replace the ENTRYPOINT line
      sed -i "s|$ENTRYPOINT|$NEW_ENTRYPOINT|" "$DOCKERFILE"
      
      echo -e "${GREEN}Updated ENTRYPOINT to use healthcheck binary${NC}"
    else
      echo -e "${RED}Could not find CMD or ENTRYPOINT to update${NC}"
    fi
  fi
  
  # Ensure EXPOSE 9091 is present
  if ! grep -q "EXPOSE 9091" "$DOCKERFILE"; then
    # Find the last EXPOSE line
    LAST_EXPOSE=$(grep -n "EXPOSE" "$DOCKERFILE" | tail -1 | cut -d: -f1)
    
    if [ -n "$LAST_EXPOSE" ]; then
      # Add EXPOSE 9091 after the last EXPOSE line
      sed -i "$((LAST_EXPOSE+1))i\EXPOSE 9091  # Metrics port" "$DOCKERFILE"
    else
      # Add EXPOSE 9091 near the end of the file
      echo -e "\n# Expose metrics port\nEXPOSE 9091" >> "$DOCKERFILE"
    fi
    
    echo -e "${GREEN}Added EXPOSE 9091 for metrics port${NC}"
  fi
  
  echo -e "${GREEN}Fixed Dockerfile for $CONTAINER${NC}"
done

echo -e "\n${BLUE}${BOLD}Next Steps:${NC}"
echo -e "${YELLOW}1. Review the changes to the Dockerfiles${NC}"
echo -e "${YELLOW}2. Rebuild the containers with: docker-compose build --no-cache <service-name>${NC}"
echo -e "${YELLOW}3. Restart the containers with: docker-compose restart <service-name>${NC}"
echo -e "${YELLOW}4. Check health status with: docker ps --format \"{{.Names}}:{{.Status}}\" | grep -i \"unhealthy\"${NC}"

echo -e "\n${GREEN}${BOLD}Bulk Rebuild Command:${NC}"
REBUILD_CMD="docker-compose build --no-cache"
for ENTRY in "${CONTAINERS_TO_FIX[@]}"; do
  IFS=':' read -r CONTAINER _ <<< "$ENTRY"
  REBUILD_CMD="$REBUILD_CMD $CONTAINER"
done
echo -e "${YELLOW}$REBUILD_CMD${NC}\n"