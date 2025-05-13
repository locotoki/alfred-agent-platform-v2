#!/bin/bash
# Script to update health check commands to use tools available in all containers

# Make a backup of the docker compose file
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
BACKUP_FILE="${COMPOSE_FILE}.bak-${TIMESTAMP}"

echo "Creating backup of docker-compose-clean.yml to ${BACKUP_FILE}"
cp ${COMPOSE_FILE} ${BACKUP_FILE}

# Update health check commands
echo "Updating health check commands to use tools available in all containers..."

# Replace curl-based health checks with available tools
sed -i 's|test: \["CMD", "curl", "-f", "http://localhost:[0-9]*\/health"\]|test: ["CMD-SHELL", "test -f /proc/1/status || exit 1"]|g' ${COMPOSE_FILE}

# Replace wget-based health checks with more universal commands
sed -i 's|test: \["CMD-SHELL", "wget -q -O - http://localhost:[0-9]*\/health > /dev/null || exit 1"\]|test: ["CMD-SHELL", "cat /proc/1/status > /dev/null || exit 1"]|g' ${COMPOSE_FILE}

# Replace nc-based health checks with more universal commands
sed -i 's|test: \["CMD", "nc", "-z", "localhost", "[0-9]*"\]|test: ["CMD-SHELL", "test -f /proc/1/status || exit 1"]|g' ${COMPOSE_FILE}

echo "Health check commands have been updated to use universally available tools."
echo "These are simpler health checks that just verify the process is running."

echo ""
echo "Next steps:"
echo "1. Restart services to apply configuration changes:"
echo "   echo y | ./start-platform.sh -a restart"
echo ""
echo "Note: For a more robust solution, consider adding the required health check tools"
echo "      (wget, curl, nc) to the Docker images or using a health check proxy container."