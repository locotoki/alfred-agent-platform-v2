#!/bin/bash
# Script to fix the agent-rag service health check issues
#
# This script:
# 1. Ensures the health_patch.py file is properly copied to the Docker image
# 2. Rebuilds and restarts the agent-rag service

set -euo pipefail

echo "Fixing agent-rag service health check issues..."

# Ensure the script is run from the project root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# Service paths
SERVICE_DIR="$PROJECT_ROOT/services/rag-service"
APP_DIR="$SERVICE_DIR/app"

echo "Ensuring health_patch.py is accessible..."

# Verify health_patch.py is present
if [ ! -f "$APP_DIR/health_patch.py" ]; then
  echo "Error: health_patch.py is missing!"
  exit 1
fi

# Make sure curl is installed in the container
echo "Modifying requirements.txt to ensure all dependencies are available..."
if ! grep -q "fastapi" "$SERVICE_DIR/requirements.txt"; then
  echo "fastapi" >> "$SERVICE_DIR/requirements.txt"
fi
if ! grep -q "pydantic" "$SERVICE_DIR/requirements.txt"; then
  echo "pydantic" >> "$SERVICE_DIR/requirements.txt"
fi
if ! grep -q "uvicorn" "$SERVICE_DIR/requirements.txt"; then
  echo "uvicorn" >> "$SERVICE_DIR/requirements.txt"
fi

# Rebuild and restart the service
echo "Rebuilding agent-rag service..."
docker-compose -f docker-compose-clean.yml build agent-rag

echo "Restarting agent-rag service..."
docker-compose -f docker-compose-clean.yml stop agent-rag
docker-compose -f docker-compose-clean.yml rm -f agent-rag
docker-compose -f docker-compose-clean.yml up -d agent-rag

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
