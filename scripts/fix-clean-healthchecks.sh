#!/bin/bash
# Script to fix healthcheck commands in docker-compose-clean.yml

set -e

COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
BACKUP_FILE="${COMPOSE_FILE}.bak-$(date +%Y%m%d-%H%M%S)"

# Create backup
cp "${COMPOSE_FILE}" "${BACKUP_FILE}"
echo "Backup created: ${BACKUP_FILE}"

# Replace HTTP healthchecks
sed -i 's/\(test: \[\)"CMD", "healthcheck", "--http", \([^]]*\)\]/\1"CMD", "curl", "-f", \2]/g' "${COMPOSE_FILE}"

# Replace TCP healthchecks
sed -i 's/\(test: \[\)"CMD", "healthcheck", "--tcp", \([^]]*\)\]/\1"CMD", "curl", "-f", "telnet:\/\/\2" || "nc", "-z", "\2", "80"]/g' "${COMPOSE_FILE}"

# Replace Redis healthchecks
sed -i 's/\(test: \[\)"CMD", "healthcheck", "--redis", "[^"]*"\]/\1"CMD", "curl", "-f", "http:\/\/localhost:9091\/health"]/g' "${COMPOSE_FILE}"

# Replace Postgres healthchecks (make sure this doesn't conflict with existing pg_isready)
sed -i 's/\(test: \[\)"CMD", "healthcheck", "--postgres", "[^"]*"\]/\1"CMD", "pg_isready", "-U", "postgres"]/g' "${COMPOSE_FILE}"

echo "Health check commands have been updated in ${COMPOSE_FILE}"

# Count updated health checks
HTTP_COUNT=$(grep -c "\"CMD\", \"curl\", \"-f\", \"http" "${COMPOSE_FILE}" || echo 0)
TCP_COUNT=$(grep -c "\"CMD\", \"curl\", \"-f\", \"telnet:" "${COMPOSE_FILE}" || echo 0)
PG_COUNT=$(grep -c "\"CMD\", \"pg_isready\"" "${COMPOSE_FILE}" || echo 0)

echo "Updated:"
echo "- HTTP health checks: ${HTTP_COUNT}"
echo "- TCP health checks: ${TCP_COUNT}"
echo "- PostgreSQL health checks: ${PG_COUNT}"

# Check for remaining legacy health checks
REMAINING=$(grep -c "\"CMD\", \"healthcheck\"" "${COMPOSE_FILE}" || echo 0)
if [ "${REMAINING}" -gt 0 ]; then
  echo "WARNING: There are still ${REMAINING} legacy health check commands. Manual inspection required."
else
  echo "SUCCESS: All legacy health check commands have been updated."
fi
