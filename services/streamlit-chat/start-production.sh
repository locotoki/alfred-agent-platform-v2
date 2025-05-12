#!/bin/bash

# Production startup script for Alfred Chat Interface

echo "Starting Alfred Chat Interface in production mode..."

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker compose is installed
if ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if running with proper permissions
if [ "$EUID" -ne 0 ] && ! groups | grep -q docker; then
    echo "Warning: You are not running as root or a member of the docker group."
    echo "Some Docker operations may fail. Continuing anyway..."
fi

# Start services
echo "Starting services with Docker Compose..."
docker compose -f docker-compose.prod.yml up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 5

# Check status
if ! docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "Error: Failed to start services. Check the logs with:"
    echo "docker compose -f docker-compose.prod.yml logs"
    exit 1
fi

# Show status
echo "Services started successfully!"
echo ""
echo "Streamlit UI: http://localhost:8502"
echo "Alfred API: http://localhost:8012"
echo ""
echo "To check logs, run:"
echo "docker compose -f docker-compose.prod.yml logs -f"
echo ""
echo "To stop services, run:"
echo "docker compose -f docker-compose.prod.yml down"