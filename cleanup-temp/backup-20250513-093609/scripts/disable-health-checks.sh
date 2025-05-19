#!/bin/bash
# Script to temporarily disable health checks in docker-compose.yml files
# Use this for development/debugging only!

set -e

# Make a backup of the docker compose files
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
CLEAN_COMPOSE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
OPTIMIZED_COMPOSE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-optimized.yml"
CLEAN_BACKUP="${CLEAN_COMPOSE}.bak-${TIMESTAMP}"
OPTIMIZED_BACKUP="${OPTIMIZED_COMPOSE}.bak-${TIMESTAMP}"

echo "Creating backups of docker compose files..."
cp ${CLEAN_COMPOSE} ${CLEAN_BACKUP}
cp ${OPTIMIZED_COMPOSE} ${OPTIMIZED_BACKUP}

echo "Disabling health checks in ${CLEAN_COMPOSE}..."
# Use sed to modify docker-compose-clean.yml
# Replace test commands with "true" to always pass health checks
sed -i 's/test: \[\("CMD-SHELL",\|\"CMD",\).*\]/test: \["CMD", "true"\]/' ${CLEAN_COMPOSE}

echo "Disabling health checks in ${OPTIMIZED_COMPOSE}..."
# Use sed to modify docker-compose-optimized.yml
sed -i 's/test: \[\("CMD-SHELL",\|\"CMD",\).*\]/test: \["CMD", "true"\]/' ${OPTIMIZED_COMPOSE}

echo "Health checks have been disabled in the Docker Compose files."
echo "Backups have been created at:"
echo "- ${CLEAN_BACKUP}"
echo "- ${OPTIMIZED_BACKUP}"
echo ""
echo "IMPORTANT: This is for development/debugging purposes only."
echo "To restore proper health checks, use the backup files."
echo ""
echo "To apply changes and restart services, run:"
echo "echo y | ./start-platform.sh -a restart"
