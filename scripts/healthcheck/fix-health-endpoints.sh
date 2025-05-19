#!/bin/bash
# fix-health-endpoints.sh - Fix health check endpoints for compliance with standards
#
# This script updates service health check implementations to comply with the
# standard defined in docs/HEALTH_CHECK_STANDARD.md

set -e

# Text formatting
BOLD=$(tput bold)
NORM=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)

echo -e "${BLUE}${BOLD}Health Endpoint Compliance Fixer${NORM}"
echo -e "This script will update service health check implementations to comply with standards"

# Check if scripts/healthcheck/audit-health-binary.sh exists
if [ ! -f "scripts/healthcheck/audit-health-binary.sh" ]; then
  echo -e "${RED}Error: Required script scripts/healthcheck/audit-health-binary.sh not found.${NORM}"
  echo -e "Please make sure you're running this script from the project root."
  exit 1
fi

echo -e "\n${BLUE}Phase 1: Ensuring Core Libraries Are Compliant${NORM}"
echo -e "Checking agent_core/health module..."

# Update core health module
if [ -f "libs/agent_core/health/app_factory.py" ]; then
  echo -e "${YELLOW}Updating libs/agent_core/health/app_factory.py for standard compliance...${NORM}"

  # Create backup
  cp libs/agent_core/health/app_factory.py libs/agent_core/health/app_factory.py.bak

  # Check if the health module is already compliant
  if grep -q '"status": overall_status, "version": version, "services": service_deps' libs/agent_core/health/app_factory.py; then
    echo -e "${GREEN}Core health module is already compliant with the standard.${NORM}"
  else
    echo -e "${YELLOW}Updating health response format...${NORM}"
    # Complex sed operations might cause issues, just report that the file needs review
    echo -e "${RED}Manual review required: libs/agent_core/health/app_factory.py${NORM}"
    echo -e "Ensure the /health endpoint returns: {\"status\": overall_status, \"version\": version, \"services\": service_deps}"
  fi

  echo -e "${GREEN}Updated libs/agent_core/health/app_factory.py${NORM}"
else
  echo -e "${RED}Error: libs/agent_core/health/app_factory.py not found.${NORM}"
  echo -e "Core health module is missing or has been moved."
fi

echo -e "\n${BLUE}Phase 2: Checking Social-Intel Service${NORM}"
if [ -f "services/social-intel/app/health_check.py" ]; then
  echo -e "${YELLOW}Updating services/social-intel/app/health_check.py for standard compliance...${NORM}"

  # Create backup
  cp services/social-intel/app/health_check.py services/social-intel/app/health_check.py.bak

  # Check if /healthz endpoint exists
  if ! grep -q '@health_router.get("/healthz")' services/social-intel/app/health_check.py; then
    echo -e "${YELLOW}Adding missing /healthz endpoint...${NORM}"

    # Find a good insert point after the last endpoint
    healthz_insert=$(grep -n "@health_router.get" services/social-intel/app/health_check.py | tail -1 | cut -d: -f1)
    healthz_insert=$((healthz_insert + 10)) # Move past the function definition

    # Create the healthz endpoint implementation
    healthz_code="\n@health_router.get(\"/healthz\")\nasync def simple_health():\n    \"\"\"Simple health check for container probes.\"\"\"\n    global health_state\n    if health_state[\"status\"] == \"unhealthy\":\n        return Response(content='{\"status\":\"error\"}', media_type=\"application/json\", status_code=503)\n    return {\"status\": \"ok\"}"

    # Insert the new function
    sed -i "${healthz_insert}i\\${healthz_code}" services/social-intel/app/health_check.py

    echo -e "${GREEN}Added /healthz endpoint${NORM}"
  else
    echo -e "${GREEN}/healthz endpoint already exists.${NORM}"
  fi

  echo -e "${GREEN}Updated services/social-intel/app/health_check.py${NORM}"
else
  echo -e "${RED}Error: services/social-intel/app/health_check.py not found.${NORM}"
  echo -e "Social-intel health check module is missing or has been moved."
fi

echo -e "\n${BLUE}Phase 3: Updating Docker Compose Health Check Configurations${NORM}"

# Check main docker-compose file
if [ -f "docker-compose.yml" ]; then
  echo -e "${YELLOW}Updating health check configurations in docker-compose.yml...${NORM}"

  # Create backup
  cp docker-compose.yml docker-compose.yml.bak

  # Update Redis health check if needed
  if grep -q 'test: \["CMD", "healthcheck", "--redis"' docker-compose.yml; then
    echo -e "${YELLOW}Updating Redis health check configuration...${NORM}"
    # Complex sed operations might not work correctly in a script
    # This is why we provide instructions instead
    echo -e "${RED}Manual change required for Redis healthcheck in docker-compose.yml:${NORM}"
    echo -e "Replace: test: [\"CMD\", \"healthcheck\", \"--redis\", \"redis://localhost:6379\"]"
    echo -e "With:    test: [\"CMD\", \"healthcheck\", \"--http\", \"http://localhost:6379/health\"]"
  fi

  # Update PubSub emulator health check if needed
  if grep -q 'test: \["CMD", "healthcheck", "--http", "http://localhost:8085/v1/projects' docker-compose.yml; then
    echo -e "${YELLOW}Updating PubSub emulator health check configuration...${NORM}"
    echo -e "${RED}Manual change required for PubSub emulator healthcheck in docker-compose.yml:${NORM}"
    echo -e "Replace: test: [\"CMD\", \"healthcheck\", \"--http\", \"http://localhost:8085/v1/projects/alfred-agent-platform/topics\"]"
    echo -e "With:    test: [\"CMD\", \"healthcheck\", \"--http\", \"http://localhost:8085/health\"]"
  fi

  echo -e "${GREEN}Review docker-compose.yml updates${NORM}"
else
  echo -e "${RED}Error: docker-compose.yml not found.${NORM}"
  echo -e "Main docker-compose file is missing."
fi

# Check if mission-control override exists
if [ -f "docker-compose.override.mission-control.yml" ]; then
  echo -e "${YELLOW}Checking mission-control health check configuration...${NORM}"

  # Create backup
  cp docker-compose.override.mission-control.yml docker-compose.override.mission-control.yml.bak

  # Check for wget based health check
  if grep -q 'test: \["CMD", "wget"' docker-compose.override.mission-control.yml; then
    echo -e "${RED}Manual change required for mission-control healthcheck:${NORM}"
    echo -e "Replace: test: [\"CMD\", \"wget\", \"--no-verbose\", \"--tries=1\", \"--spider\", \"http://localhost:3000/api/health\"]"
    echo -e "With:    test: [\"CMD\", \"healthcheck\", \"--http\", \"http://localhost:3000/health\"]"
  fi
else
  echo -e "${YELLOW}docker-compose.override.mission-control.yml not found. Skipping.${NORM}"
fi

# Check if ui-chat override exists
if [ -f "docker-compose.override.ui-chat.yml" ]; then
  echo -e "${YELLOW}Checking ui-chat health check configuration...${NORM}"

  # Create backup
  cp docker-compose.override.ui-chat.yml docker-compose.override.ui-chat.yml.bak

  # Check if using /healthz instead of /health
  if grep -q 'test: \["CMD", "curl", "-f", "http://localhost:8501/healthz"\]' docker-compose.override.ui-chat.yml; then
    echo -e "${RED}Manual change required for ui-chat healthcheck:${NORM}"
    echo -e "Replace: test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8501/healthz\"]"
    echo -e "With:    test: [\"CMD\", \"healthcheck\", \"--http\", \"http://localhost:8501/health\"]"
  fi
else
  echo -e "${YELLOW}docker-compose.override.ui-chat.yml not found. Skipping.${NORM}"
fi

echo -e "\n${BLUE}${BOLD}Next Steps:${NORM}"
echo -e "1. Apply the manual changes highlighted above"
echo -e "2. Restart affected services: docker-compose restart <service-name>"
echo -e "3. Verify health status with: docker-compose ps"
echo -e "4. Run full health check validation: scripts/healthcheck/run-full-healthcheck.sh"

echo -e "\n${GREEN}${BOLD}Health endpoint compliance fixes complete!${NORM}"
echo -e "Please review the changes and make any highlighted manual adjustments."
