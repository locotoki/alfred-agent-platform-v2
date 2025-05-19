#!/bin/bash
# Script to fix healthcheck in Dockerfiles

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}Fixing healthcheck in Dockerfiles${NC}"

# Fix all Dockerfiles with multi-stage builds
find ./services -name "Dockerfile*" -type f -exec grep -l "FROM.*healthcheck.*AS" {} \; | while read -r dockerfile; do
  echo -e "\n${BLUE}Fixing $dockerfile...${NC}"

  # Check if it has a circular dependency
  if grep -q "COPY --from=healthcheck /healthcheck" "$dockerfile"; then
    # Backup the file
    cp "$dockerfile" "${dockerfile}.bak"

    # Fix the COPY line
    sed -i 's|COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck|COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck|' "$dockerfile"

    echo -e "${GREEN}Fixed COPY path in $dockerfile${NC}"
  fi

  # Let's also fix CMD to ensure it uses the healthcheck binary
  if ! grep -q "CMD \[\"healthcheck\"" "$dockerfile" && ! grep -q "ENTRYPOINT \[\"healthcheck\"" "$dockerfile"; then
    # Get the ENTRYPOINT and CMD
    entrypoint=$(grep -E "^ENTRYPOINT \[" "$dockerfile" | tail -1)
    cmd=$(grep -E "^CMD \[" "$dockerfile" | tail -1)

    if [ -n "$entrypoint" ] && [ -z "$cmd" ]; then
      # Extract the entrypoint parts
      entrypoint_parts=$(echo "$entrypoint" | sed 's/ENTRYPOINT \[\(.*\)\]/\1/')

      # Create new ENTRYPOINT with healthcheck
      new_entrypoint="ENTRYPOINT [\"healthcheck\", \"--export-prom\", \":9091\", \"--\", $entrypoint_parts]"

      # Replace the ENTRYPOINT line
      sed -i "s|$entrypoint|$new_entrypoint|" "$dockerfile"

      echo -e "${GREEN}Updated ENTRYPOINT to use healthcheck binary${NC}"
    elif [ -n "$cmd" ]; then
      # Extract the command parts
      cmd_parts=$(echo "$cmd" | sed 's/CMD \[\(.*\)\]/\1/')

      # Create new CMD with healthcheck
      new_cmd="CMD [\"healthcheck\", \"--export-prom\", \":9091\", \"--\", $cmd_parts]"

      # Replace the CMD line
      sed -i "s|$cmd|$new_cmd|" "$dockerfile"

      echo -e "${GREEN}Updated CMD to use healthcheck binary${NC}"
    else
      echo -e "${RED}Could not find CMD or ENTRYPOINT to update${NC}"
    fi
  fi

  # Ensure EXPOSE 9091 is present
  if ! grep -q "EXPOSE 9091" "$dockerfile"; then
    # Find the last EXPOSE line
    last_expose=$(grep -n "EXPOSE" "$dockerfile" | tail -1 | cut -d: -f1)

    if [ -n "$last_expose" ]; then
      # Add EXPOSE 9091 after the last EXPOSE line
      sed -i "$((last_expose+1))i\\EXPOSE 9091  # Metrics port" "$dockerfile"
    else
      # Add EXPOSE 9091 near the end of the file
      echo -e "\n# Expose metrics port\nEXPOSE 9091" >> "$dockerfile"
    fi

    echo -e "${GREEN}Added EXPOSE 9091 for metrics port${NC}"
  fi
done

echo -e "\n${BLUE}${BOLD}Next Steps:${NC}"
echo -e "${YELLOW}1. Review the fixed Dockerfiles${NC}"
echo -e "${YELLOW}2. Rebuild the containers with: docker-compose build --no-cache${NC}"
echo -e "${YELLOW}3. Restart the services with: docker-compose up -d${NC}"
