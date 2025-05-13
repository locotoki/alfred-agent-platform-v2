#!/bin/bash
# Script to properly fix health check endpoints in docker-compose-clean.yml

# Make a backup of the docker compose file
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
BACKUP_FILE="${COMPOSE_FILE}.bak-${TIMESTAMP}"

echo "Creating backup of docker-compose-clean.yml to ${BACKUP_FILE}"
cp ${COMPOSE_FILE} ${BACKUP_FILE}

# Fix specific problematic health checks
echo "Fixing health check endpoints in docker-compose-clean.yml..."

# Fix vector-db health check
sed -i 's|test: \["CMD", "curl", "-f", "http://localhost:localhost:6333/healthzhealth"\]|test: \["CMD", "curl", "-f", "http://localhost:6333/health"\]|g' ${COMPOSE_FILE}

# Fix RAG service health check
sed -i 's|test: \["CMD-SHELL", "wget -q -O - http://localhost:localhost:8501/healthzhealth > /dev/null || exit 1"\]|test: \["CMD-SHELL", "wget -q -O - http://localhost:8501/health > /dev/null || exit 1"\]|g' ${COMPOSE_FILE}

# Fix Atlas agent health check
sed -i 's|test: \["CMD-SHELL", "wget -q -O - http://localhost:localhost:8000/healthzhealth > /dev/null || exit 1"\]|test: \["CMD-SHELL", "wget -q -O - http://localhost:8000/health > /dev/null || exit 1"\]|g' ${COMPOSE_FILE}

# Fix UI chat health check
sed -i 's|test: \["CMD-SHELL", "wget -q -O - http://localhost:localhost:8501/healthzhealth > /dev/null || exit 1"\]|test: \["CMD-SHELL", "wget -q -O - http://localhost:8501/health > /dev/null || exit 1"\]|g' ${COMPOSE_FILE}

# Fix auth UI health check
sed -i 's|test: \["CMD-SHELL", "wget -q -O - http://localhost:localhost:80/healthzhealth > /dev/null || exit 1"\]|test: \["CMD-SHELL", "wget -q -O - http://localhost:80/health > /dev/null || exit 1"\]|g' ${COMPOSE_FILE}

echo "Health check endpoints have been fixed."
echo ""
echo "Next steps:"
echo "1. Run the patch script to add /health endpoints to services:"
echo "   python3 /home/locotoki/projects/alfred-agent-platform-v2/patches/add-health-endpoints.py"
echo ""
echo "2. Restart services to apply configuration changes:"
echo "   ./start-platform.sh -a restart"