#!/bin/bash

# This script starts the mission-control service using Docker Compose

# Default to production mode
MODE=${1:-"production"}

echo "Starting Mission Control service using Docker in $MODE mode..."

# Change to the project root directory
cd "$(dirname "$0")/../.."

# Check if docker-compose override file exists
if [ "$MODE" == "development" ]; then
  OVERRIDE_FILE="docker-compose.override.mission-control.dev.yml"
  echo "Running in DEVELOPMENT mode"
else
  OVERRIDE_FILE="docker-compose.override.mission-control.yml"
  echo "Running in PRODUCTION mode"
fi

if [ -f "$OVERRIDE_FILE" ]; then
  echo "Found mission-control override file: $OVERRIDE_FILE"
else
  echo "Error: Missing $OVERRIDE_FILE"
  exit 1
fi

# Stop the service if it's already running
echo "Stopping any existing mission-control containers..."
docker-compose -f docker-compose.yml -f $OVERRIDE_FILE stop mission-control

# Build and start the service
echo "Building and starting mission-control..."
docker-compose -f docker-compose.yml -f $OVERRIDE_FILE up -d --build mission-control

# Wait for the service to start
echo "Waiting for mission-control to start..."
sleep 5

# Verify the service is running
if docker-compose -f docker-compose.yml -f $OVERRIDE_FILE ps | grep -q "mission-control.*Up"; then
  echo -e "\n======================="
  echo "Mission Control started successfully!"
  echo "Access the application at: http://localhost:3007"
  echo "======================="
else
  echo "Error: Failed to start mission-control service"
  docker-compose -f docker-compose.yml -f $OVERRIDE_FILE logs mission-control
  exit 1
fi