#!/bin/bash
# Script to fix FastAPI route issues in agent services

set -e

echo "=== Alfred Agent Platform - FastAPI Route Fix Script ==="
echo "This script will fix the FastAPI route issues in both financial and legal agent services."

# Make the Python script executable
chmod +x ./helpers/fix-fastapi-routes.py

# Run the Python script to fix the FastAPI route issues
echo "Running fix-fastapi-routes.py..."
python3 ./helpers/fix-fastapi-routes.py

# Restart the services
echo "Restarting agent services..."
docker-compose down agent-financial agent-legal || true
docker-compose up -d agent-financial agent-legal

# Check the status of the restarted services
echo "Checking service status..."
sleep 10  # Wait for services to start
docker ps | grep -E 'agent-financial|agent-legal'

# Check service logs for errors
echo "Checking service logs for errors..."
docker logs agent-financial --tail 20
echo "---------------------------------------"
docker logs agent-legal --tail 20

echo "Fix process completed. Verify services are running properly."