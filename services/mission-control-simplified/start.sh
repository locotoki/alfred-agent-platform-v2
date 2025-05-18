#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Check if alfred-network exists, create if not
if ! docker network inspect alfred-network &> /dev/null; then
    echo "Creating Docker network: alfred-network"
    docker network create alfred-network
fi

# Stop any existing container
echo "Stopping any existing mission-control container..."
docker stop mission-control 2>/dev/null || true
docker rm mission-control 2>/dev/null || true

# Build and start the container
echo "Building and starting mission-control..."
docker-compose up -d --build

# Wait for the service to start
echo "Waiting for mission-control to start..."
sleep 5

# Verify the service is running
if docker ps | grep -q "mission-control"; then
  echo -e "\n======================="
  echo "Mission Control started successfully!"
  echo "Access the application at: http://localhost:3007"
  echo "======================="
else
  echo "Error: Failed to start mission-control container"
  docker-compose logs
  exit 1
fi
