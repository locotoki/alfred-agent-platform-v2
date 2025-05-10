#!/bin/bash

# Fix script for social-intel container issues

# Replace the Dockerfile with the fixed version
mv Dockerfile.fix Dockerfile

# Clean up old container if it exists
docker-compose stop social-intel
docker-compose rm -f social-intel

# Rebuild the container with new dependencies
docker-compose build social-intel

# Start the fixed container
docker-compose up -d social-intel

# Check if the container starts successfully
echo "Waiting for container to start..."
sleep 10
docker-compose ps social-intel

# Check container logs
echo "Container logs:"
docker-compose logs social-intel | tail -n 20

echo "Fix complete. If no errors appear in the logs, the container should be running properly."