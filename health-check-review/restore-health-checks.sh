#!/bin/bash
# Script to restore health checks from the most recent backup

set -e

CLEAN_COMPOSE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
OPTIMIZED_COMPOSE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-optimized.yml"

# Find the most recent backup of each file
CLEAN_BACKUP=$(ls -t ${CLEAN_COMPOSE}.bak-* | head -n 1)
OPTIMIZED_BACKUP=$(ls -t ${OPTIMIZED_COMPOSE}.bak-* | head -n 1)

if [ -z "${CLEAN_BACKUP}" ]; then
  echo "No backup found for ${CLEAN_COMPOSE}"
  exit 1
fi

if [ -z "${OPTIMIZED_BACKUP}" ]; then
  echo "No backup found for ${OPTIMIZED_COMPOSE}"
  exit 1
fi

echo "Restoring ${CLEAN_COMPOSE} from ${CLEAN_BACKUP}..."
cp ${CLEAN_BACKUP} ${CLEAN_COMPOSE}

echo "Restoring ${OPTIMIZED_COMPOSE} from ${OPTIMIZED_BACKUP}..."
cp ${OPTIMIZED_BACKUP} ${OPTIMIZED_COMPOSE}

echo "Health checks have been restored from backups."
echo ""
echo "To apply changes and restart services, run:"
echo "echo y | ./start-platform.sh -a restart"