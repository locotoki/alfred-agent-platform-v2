#!/bin/bash
# Script to improve health check settings in docker-compose-optimized.yml

# Make a backup of the docker compose file
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-optimized.yml"
BACKUP_FILE="${COMPOSE_FILE}.bak-${TIMESTAMP}"

echo "Creating backup of docker-compose-optimized.yml to ${BACKUP_FILE}"
cp ${COMPOSE_FILE} ${BACKUP_FILE}

# Update health check settings in the YAML file
echo "Updating health check settings in docker-compose-optimized.yml..."

# Use temporary file for sed operations
TMP_FILE="${COMPOSE_FILE}.tmp"

# Extract the current health check settings
HEALTH_CHECK_SETTINGS=$(grep -A4 "x-health-check-settings" ${COMPOSE_FILE})

# Update the health check settings
cat ${COMPOSE_FILE} | sed '/x-health-check-settings:/,/start_period: [0-9]*s/{
  s/interval: [0-9]*s/interval: 30s/
  s/timeout: [0-9]*s/timeout: 20s/
  s/retries: [0-9]*/retries: 5/
  s/start_period: [0-9]*s/start_period: 45s/
}' > ${TMP_FILE}

mv ${TMP_FILE} ${COMPOSE_FILE}

# Fix health check endpoints with localhost:localhost issue
sed -i 's|localhost:localhost|localhost|g' ${COMPOSE_FILE}

# Fix healthzhealth to health
sed -i 's|/healthzhealth|/health|g' ${COMPOSE_FILE}

# Fix any remaining /healthz to /health
sed -i 's|/healthz|/health|g' ${COMPOSE_FILE}

echo "Health check settings in docker-compose-optimized.yml have been updated."
echo "New settings:"
grep -A4 "x-health-check-settings" ${COMPOSE_FILE}

echo ""
echo "Next steps:"
echo "1. Restart services to apply configuration changes:"
echo "   echo y | ./start-platform.sh -a restart -e prod"