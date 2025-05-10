#!/bin/bash

# Script to build and start the Agent Orchestrator in production mode

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

# Check if the Alfred network exists, create if not
if ! docker network inspect alfred-network &> /dev/null; then
    echo "Creating Docker network: alfred-network"
    docker network create alfred-network
fi

# Set to production mode
if grep -q "NODE_ENV" .env; then
    sed -i 's/NODE_ENV=.*/NODE_ENV=production/' .env
else
    echo "NODE_ENV=production" >> .env
fi

# Ask for environment configuration
read -p "Enter the Social Intelligence Service URL (default: http://social-intel:9000): " social_intel_url
social_intel_url=${social_intel_url:-http://social-intel:9000}

if grep -q "VITE_SOCIAL_INTEL_URL" .env; then
    sed -i "s|VITE_SOCIAL_INTEL_URL=.*|VITE_SOCIAL_INTEL_URL=${social_intel_url}|" .env
else
    echo "VITE_SOCIAL_INTEL_URL=${social_intel_url}" >> .env
fi

if grep -q "VITE_API_URL" .env; then
    sed -i "s|VITE_API_URL=.*|VITE_API_URL=${social_intel_url}|" .env
else
    echo "VITE_API_URL=${social_intel_url}" >> .env
fi

echo "Building and starting the Agent Orchestrator..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d

echo "Agent Orchestrator started in production mode."
echo "Access the UI at http://localhost:5173"

# Show logs
docker-compose logs -f