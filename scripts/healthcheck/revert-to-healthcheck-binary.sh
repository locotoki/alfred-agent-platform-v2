#!/bin/bash
# Script to revert curl-based health checks back to healthcheck binary
# This undoes the temporary curl fixes and standardizes on the healthcheck binary

set -e

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create a timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo -e "${BLUE}Reverting health checks to use healthcheck binary...${NC}"

# Create backup of docker-compose.yml
COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.yml"
BACKUP_FILE="${COMPOSE_FILE}.bak-${TIMESTAMP}"
cp "${COMPOSE_FILE}" "${BACKUP_FILE}"
echo -e "${GREEN}Backup created: ${BACKUP_FILE}${NC}"

# Create backup of docker-compose-clean.yml
CLEAN_COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
CLEAN_BACKUP_FILE="${CLEAN_COMPOSE_FILE}.bak-${TIMESTAMP}"
cp "${CLEAN_COMPOSE_FILE}" "${CLEAN_BACKUP_FILE}"
echo -e "${GREEN}Backup created: ${CLEAN_BACKUP_FILE}${NC}"

# Create backup of docker-compose.override.ui-chat.yml
OVERRIDE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.override.ui-chat.yml"
OVERRIDE_BACKUP_FILE="${OVERRIDE_FILE}.bak-${TIMESTAMP}"
cp "${OVERRIDE_FILE}" "${OVERRIDE_BACKUP_FILE}"
echo -e "${GREEN}Backup created: ${OVERRIDE_BACKUP_FILE}${NC}"

echo -e "${BLUE}Processing docker-compose.yml...${NC}"

# Replace curl HTTP health checks with healthcheck binary
sed -i 's/\(test: \[\)"CMD", "curl", "-f", "\([^"]*\)"\]/\1"CMD", "healthcheck", "--http", "\2"]/g' "${COMPOSE_FILE}"

# Replace curl TCP health checks with healthcheck binary
sed -i 's/\(test: \[\)"CMD", "curl", "-f", "telnet:\/\/\([^"]*\)" || "nc", "-z", "\([^"]*\)", "[^"]*"\]/\1"CMD", "healthcheck", "--tcp", "\2"]/g' "${COMPOSE_FILE}"

# Fix special case for Redis (using HTTP health check wrapper)
sed -i 's/\(test: \[\)"CMD", "curl", "-f", "http:\/\/localhost:9091\/health"\]/\1"CMD", "healthcheck", "--http", "http:\/\/localhost:9091\/health"]/g' "${COMPOSE_FILE}"

echo -e "${BLUE}Processing docker-compose-clean.yml...${NC}"

# Replace curl HTTP health checks with healthcheck binary
sed -i 's/\(test: \[\)"CMD", "curl", "-f", "\([^"]*\)"\]/\1"CMD", "healthcheck", "--http", "\2"]/g' "${CLEAN_COMPOSE_FILE}"

# Replace curl TCP health checks with healthcheck binary
sed -i 's/\(test: \[\)"CMD", "curl", "-f", "telnet:\/\/\([^"]*\)" || "nc", "-z", "\([^"]*\)", "[^"]*"\]/\1"CMD", "healthcheck", "--tcp", "\2"]/g' "${CLEAN_COMPOSE_FILE}"

# Fix special case for Redis (using HTTP health check wrapper)
sed -i 's/\(test: \[\)"CMD", "curl", "-f", "http:\/\/localhost:9091\/health"\]/\1"CMD", "healthcheck", "--http", "http:\/\/localhost:9091\/health"]/g' "${CLEAN_COMPOSE_FILE}"

echo -e "${BLUE}Processing docker-compose.override.ui-chat.yml...${NC}"

# Replace curl HTTP health checks with healthcheck binary
sed -i 's/\(test: \[\)"CMD", "curl", "-f", "\([^"]*\)"\]/\1"CMD", "healthcheck", "--http", "\2"]/g' "${OVERRIDE_FILE}"

# Count health check references
HEALTHCHECK_REFS=$(grep -c "\"CMD\", \"healthcheck\"" "${COMPOSE_FILE}" || echo 0)
CURL_REFS=$(grep -c "\"CMD\", \"curl\"" "${COMPOSE_FILE}" || echo 0)

echo
echo -e "${BLUE}Results for docker-compose.yml:${NC}"
echo -e "${GREEN}Health check binary references: ${HEALTHCHECK_REFS}${NC}"
echo -e "${YELLOW}Remaining curl references: ${CURL_REFS}${NC}"

# Count health check references in clean file
CLEAN_HEALTHCHECK_REFS=$(grep -c "\"CMD\", \"healthcheck\"" "${CLEAN_COMPOSE_FILE}" || echo 0)
CLEAN_CURL_REFS=$(grep -c "\"CMD\", \"curl\"" "${CLEAN_COMPOSE_FILE}" || echo 0)

echo
echo -e "${BLUE}Results for docker-compose-clean.yml:${NC}"
echo -e "${GREEN}Health check binary references: ${CLEAN_HEALTHCHECK_REFS}${NC}"
echo -e "${YELLOW}Remaining curl references: ${CLEAN_CURL_REFS}${NC}"

# Count health check references in override file
OVERRIDE_HEALTHCHECK_REFS=$(grep -c "\"CMD\", \"healthcheck\"" "${OVERRIDE_FILE}" || echo 0)
OVERRIDE_CURL_REFS=$(grep -c "\"CMD\", \"curl\"" "${OVERRIDE_FILE}" || echo 0)

echo
echo -e "${BLUE}Results for docker-compose.override.ui-chat.yml:${NC}"
echo -e "${GREEN}Health check binary references: ${OVERRIDE_HEALTHCHECK_REFS}${NC}"
echo -e "${YELLOW}Remaining curl references: ${OVERRIDE_CURL_REFS}${NC}"

echo
echo -e "${BLUE}Summary:${NC}"
if [ "$CURL_REFS" -eq 0 ] && [ "$CLEAN_CURL_REFS" -eq 0 ] && [ "$OVERRIDE_CURL_REFS" -eq 0 ]; then
  echo -e "${GREEN}✅ All health checks have been reverted to use the healthcheck binary.${NC}"
else
  echo -e "${YELLOW}⚠️ Some curl references remain. Manual inspection required.${NC}"
fi

echo
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Run the audit-health-binary.sh script to verify all Dockerfiles include the healthcheck binary"
echo -e "2. Ensure all service ENTRYPOINTs include --export-prom :9091"
echo -e "3. Verify Prometheus configuration has metrics_port=\"9091\" labels"

echo
echo -e "${GREEN}Done!${NC}"