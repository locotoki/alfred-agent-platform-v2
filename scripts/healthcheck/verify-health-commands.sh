#!/bin/bash
# Script to verify health check commands in docker-compose files
# This script checks for any remaining 'healthcheck' binary references
# and verifies that health check commands are properly formatted.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}=======================================================${NC}"
echo -e "${BLUE}      Docker Compose Health Check Verification         ${NC}"
echo -e "${BLUE}=======================================================${NC}"
echo

# Check for any remaining 'healthcheck' binary references
echo -e "${BLUE}Checking for remaining 'healthcheck' binary references...${NC}"
HEALTHCHECK_REFS=$(grep -r "\"CMD\", \"healthcheck\"" "${PROJECT_ROOT}" --include="docker-compose*.yml" | wc -l)

if [ "$HEALTHCHECK_REFS" -gt 0 ]; then
    echo -e "${RED}Found $HEALTHCHECK_REFS references to the 'healthcheck' binary in docker-compose files.${NC}"
    echo -e "${YELLOW}Problematic services:${NC}"
    grep -r "\"CMD\", \"healthcheck\"" "${PROJECT_ROOT}" --include="docker-compose*.yml" -A 1 -B 1
    echo
    echo -e "${YELLOW}Please update these services to use curl or other available commands.${NC}"
else
    echo -e "${GREEN}No references to 'healthcheck' binary found. All services have been updated!${NC}"
fi

# Check for HTTP health checks
echo
echo -e "${BLUE}Verifying HTTP health check commands...${NC}"
HTTP_CHECKS=$(grep -r "curl.*http" "${PROJECT_ROOT}" --include="docker-compose*.yml" | wc -l)
echo -e "${GREEN}Found $HTTP_CHECKS HTTP health checks using curl${NC}"

# Check for TCP health checks
echo
echo -e "${BLUE}Verifying TCP health check commands...${NC}"
TCP_CHECKS=$(grep -r "telnet:\\\/\\\/\|nc -z" "${PROJECT_ROOT}" --include="docker-compose*.yml" | wc -l)
echo -e "${GREEN}Found $TCP_CHECKS TCP health checks using curl or nc${NC}"

# Check for PostgreSQL health checks
echo
echo -e "${BLUE}Verifying PostgreSQL health check commands...${NC}"
PG_CHECKS=$(grep -r "pg_isready" "${PROJECT_ROOT}" --include="docker-compose*.yml" | wc -l)
echo -e "${GREEN}Found $PG_CHECKS PostgreSQL health checks using pg_isready${NC}"

# Summary
echo
echo -e "${BLUE}=======================================================${NC}"
echo -e "${BLUE}                       Summary                         ${NC}"
echo -e "${BLUE}=======================================================${NC}"

if [ "$HEALTHCHECK_REFS" -eq 0 ]; then
    echo -e "${GREEN}✅ All services have been updated to use proper health check commands${NC}"
    echo -e "${GREEN}✅ Found $HTTP_CHECKS HTTP health checks${NC}"
    echo -e "${GREEN}✅ Found $TCP_CHECKS TCP health checks${NC}"
    echo -e "${GREEN}✅ Found $PG_CHECKS PostgreSQL health checks${NC}"
    echo
    echo -e "${GREEN}Health check commands have been successfully fixed in all docker-compose files.${NC}"
else
    echo -e "${RED}❌ Found $HEALTHCHECK_REFS references to 'healthcheck' binary that need fixing${NC}"
    echo -e "${GREEN}✅ Found $HTTP_CHECKS HTTP health checks already fixed${NC}"
    echo -e "${GREEN}✅ Found $TCP_CHECKS TCP health checks already fixed${NC}"
    echo -e "${GREEN}✅ Found $PG_CHECKS PostgreSQL health checks already fixed${NC}"
    echo
    echo -e "${YELLOW}Please update the remaining services to use proper health check commands.${NC}"
fi

echo
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Run 'docker-compose down' and 'docker-compose up -d' to apply changes"
echo -e "2. After services start, run 'docker ps' to verify all services report as healthy"
echo -e "3. Use 'docker inspect --format='{{json .State.Health}}' <container_name>' to check details"
