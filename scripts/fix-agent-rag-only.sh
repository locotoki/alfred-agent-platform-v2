#!/bin/bash
# Script to fix ONLY the agent-rag service health check issues
#
# This script:
# 1. Rebuilds the agent-rag service
# 2. Restarts ONLY the agent-rag service
# 3. Checks if the service is healthy

set -euo pipefail

echo "Fixing agent-rag service health check issues..."

# Ensure the script is run from the project root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# Rebuild the service
echo "Rebuilding agent-rag service..."
docker-compose -f docker-compose-clean.yml build agent-rag

# Stop and remove the agent-rag container only
echo "Stopping agent-rag service..."
docker-compose -f docker-compose-clean.yml stop agent-rag
docker-compose -f docker-compose-clean.yml rm -f agent-rag

# Start only the agent-rag service with force-recreate
echo "Starting agent-rag service..."
docker-compose -f docker-compose-clean.yml up -d --no-deps --force-recreate agent-rag

echo "Waiting for service to start..."
sleep 15

# Check if the service is now healthy
echo "Checking agent-rag service health..."
if curl -s http://localhost:8501/healthz | grep -q "ok"; then
  echo "✅ agent-rag service is now healthy!"
else
  echo "❌ agent-rag service is still having issues."
  echo "Checking container logs:"
  docker-compose -f docker-compose-clean.yml logs --tail=50 agent-rag
fi

echo "Done."