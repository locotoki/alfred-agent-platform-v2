#!/bin/bash
# Script to fix specific health check endpoints in docker-compose-clean.yml

# Make a backup of the docker compose file
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
BACKUP_FILE="${COMPOSE_FILE}.bak-${TIMESTAMP}"

echo "Creating backup of docker-compose-clean.yml to ${BACKUP_FILE}"
cp ${COMPOSE_FILE} ${BACKUP_FILE}

# Fix specific problem areas with explicit search and replace
echo "Fixing health check endpoints in docker-compose-clean.yml..."

# Fix health check endpoints with localhost:localhost issue
sed -i 's|localhost:localhost|localhost|g' ${COMPOSE_FILE}

# Fix healthzhealth to health
sed -i 's|/healthzhealth|/health|g' ${COMPOSE_FILE}

# Fix any remaining /healthz to /health
sed -i 's|/healthz|/health|g' ${COMPOSE_FILE}

echo "Health check endpoints have been fixed."

# Create empty-credentials.json file if it doesn't exist (needed for atlas agent)
# Make credentials directory if it doesn't exist
mkdir -p /home/locotoki/projects/alfred-agent-platform-v2/config/credentials

# Create the empty credentials file
echo "Creating empty-credentials.json file..."
echo "{}" > /home/locotoki/projects/alfred-agent-platform-v2/config/credentials/empty-credentials.json

echo ""
echo "Next steps:"
echo "1. Run the patch script to add /health endpoints to services:"
echo "   python3 /home/locotoki/projects/alfred-agent-platform-v2/patches/add-health-endpoints.py"
echo ""
echo "2. Restart services to apply configuration changes:"
echo "   echo y | ./start-platform.sh -a restart"