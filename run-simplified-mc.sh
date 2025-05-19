#!/bin/bash

# Run the Simplified Mission Control along with the Alfred Agent Platform

echo "Starting Alfred Agent Platform with Simplified Mission Control..."

# Make sure we're in the project root
cd "$(dirname "$0")"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running. Please start Docker and try again."
  exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null; then
  echo "Docker Compose is not installed. Please install Docker Compose and try again."
  exit 1
fi

# Check if alfred-network exists, create if not
if ! docker network inspect alfred-network > /dev/null 2>&1; then
  echo "Creating Docker network: alfred-network"
  docker network create alfred-network
fi

# Check if the simplified Mission Control image exists
if ! docker images | grep -q "mission-control-simplified"; then
  echo "Building Simplified Mission Control image..."
  docker-compose -f docker-compose.yml -f docker-compose.override.simplified-mc.yml build mission-control-simplified
fi

# Start the platform with Simplified Mission Control
docker-compose -f docker-compose.yml -f docker-compose.override.simplified-mc.yml up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Check if Simplified Mission Control is running
if docker ps | grep -q "mission-control-simplified"; then
  echo -e "\n======================="
  echo "Alfred Agent Platform with Simplified Mission Control started successfully!"
  echo "Access the Simplified Mission Control at: http://localhost:3007"
  echo "======================="
else
  echo "Error: Failed to start Simplified Mission Control container"
  docker-compose -f docker-compose.yml -f docker-compose.override.simplified-mc.yml logs mission-control-simplified
  exit 1
fi

# Display running containers
echo -e "\nRunning containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "mission-control|intel|bot|tax|compliance|supabase"
