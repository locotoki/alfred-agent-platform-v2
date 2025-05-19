#!/bin/bash
# Script to update CMD/ENTRYPOINT to use healthcheck binary

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}Updating CMD/ENTRYPOINT for healthcheck${NC}"

# Array of priority services to fix
SERVICES=(
  "agent-core"
  "agent-social"
  "agent-financial"
  "agent-legal"
  "agent-rag"
  "model-router"
  "model-registry"
  "ui-admin"
  "ui-chat"
)

# Function to update CMD or ENTRYPOINT in a Dockerfile
update_dockerfile() {
  local service=$1
  local dockerfile="./services/${service}/Dockerfile"
  local dockerfile_path="${dockerfile//agent-/}"

  # Try different paths if file doesn't exist
  if [ ! -f "$dockerfile" ]; then
    # Try with underscores instead of hyphens
    dockerfile="./services/${service//-/_}/Dockerfile"
  fi

  # Try with service's actual directory name
  if [ ! -f "$dockerfile" ]; then
    for dir in ./services/*/; do
      dir_name=$(basename "$dir")
      container_name=$(docker ps --format "{{.Names}}:{{.Image}}" | grep -E "^${service}:" | cut -d: -f2)

      if [ "$dir_name" = "$container_name" ] || [[ "$container_name" == *"$dir_name"* ]]; then
        dockerfile="$dir/Dockerfile"
        break
      fi
    done
  fi

  # If still not found, try to search for it
  if [ ! -f "$dockerfile" ]; then
    echo -e "${RED}Could not find Dockerfile for $service${NC}"
    return 1
  fi

  echo -e "${BLUE}Updating $dockerfile...${NC}"

  # Backup the file
  cp "$dockerfile" "${dockerfile}.bak"

  # Check if it already has a healthcheck CMD/ENTRYPOINT
  if grep -q "CMD \[\"healthcheck\"" "$dockerfile" || grep -q "ENTRYPOINT \[\"healthcheck\"" "$dockerfile"; then
    echo -e "${GREEN}Already has healthcheck in CMD/ENTRYPOINT${NC}"
    return 0
  fi

  # Get the current CMD/ENTRYPOINT
  cmd=$(grep -E "^CMD \[" "$dockerfile" | tail -1)
  entrypoint=$(grep -E "^ENTRYPOINT \[" "$dockerfile" | tail -1)

  if [ -n "$cmd" ]; then
    # Extract the command parts
    cmd_parts=$(echo "$cmd" | sed 's/CMD \[\(.*\)\]/\1/')

    # Create new CMD with healthcheck
    new_cmd="CMD [\"healthcheck\", \"--export-prom\", \":9091\", \"--\", $cmd_parts]"

    # Replace the CMD line
    sed -i "s|$cmd|$new_cmd|" "$dockerfile"

    echo -e "${GREEN}Updated CMD to use healthcheck binary${NC}"
  elif [ -n "$entrypoint" ]; then
    # Extract the entrypoint parts
    entrypoint_parts=$(echo "$entrypoint" | sed 's/ENTRYPOINT \[\(.*\)\]/\1/')

    # Create new ENTRYPOINT with healthcheck
    new_entrypoint="ENTRYPOINT [\"healthcheck\", \"--export-prom\", \":9091\", \"--\", $entrypoint_parts]"

    # Replace the ENTRYPOINT line
    sed -i "s|$entrypoint|$new_entrypoint|" "$dockerfile"

    echo -e "${GREEN}Updated ENTRYPOINT to use healthcheck binary${NC}"
  else
    echo -e "${RED}Could not find CMD or ENTRYPOINT to update${NC}"
    return 1
  fi

  # Ensure EXPOSE 9091 is present
  if ! grep -q "EXPOSE 9091" "$dockerfile"; then
    # Find the last EXPOSE line
    last_expose=$(grep -n "EXPOSE" "$dockerfile" | tail -1 | cut -d: -f1)

    if [ -n "$last_expose" ]; then
      # Add EXPOSE 9091 after the last EXPOSE line
      sed -i "$((last_expose+1))i\EXPOSE 9091  # Metrics port" "$dockerfile"
    else
      # Add EXPOSE 9091 near the end of the file
      echo -e "\n# Expose metrics port\nEXPOSE 9091" >> "$dockerfile"
    fi

    echo -e "${GREEN}Added EXPOSE 9091 for metrics port${NC}"
  fi

  return 0
}

# Process each service
for service in "${SERVICES[@]}"; do
  echo -e "\n${BLUE}Processing $service...${NC}"
  update_dockerfile "$service"
done

echo -e "\n${BLUE}${BOLD}Next Steps:${NC}"
echo -e "${YELLOW}1. Review the changes to the Dockerfiles${NC}"
echo -e "${YELLOW}2. Rebuild the containers with: docker-compose build --no-cache <service-name>${NC}"
echo -e "${YELLOW}3. Restart the services with: docker-compose up -d${NC}"
echo -e "${YELLOW}4. Check health status with: docker ps --format \"{{.Names}}:{{.Status}}\" | grep -i \"unhealthy\"${NC}"
