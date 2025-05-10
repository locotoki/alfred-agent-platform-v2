#!/bin/bash

# Script to start the Agent Orchestrator and connect to Alfred Agent Platform

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

# Check if Social Intelligence service is running
if ! docker ps | grep -q social-intel; then
    echo "Social Intelligence service is not running."
    read -p "Do you want to use mock data instead? (y/n): " use_mock
    if [ "$use_mock" = "y" ]; then
        # Update .env to use mock data
        if grep -q "VITE_USE_MOCK_DATA" .env; then
            # Replace existing value
            sed -i 's/VITE_USE_MOCK_DATA=.*/VITE_USE_MOCK_DATA=true/' .env
        else
            # Add new value
            echo "VITE_USE_MOCK_DATA=true" >> .env
        fi
        echo "Set to use mock data."
    else
        echo "Please start the Social Intelligence service and try again."
        exit 1
    fi
else
    # Reset mock data setting
    if grep -q "VITE_USE_MOCK_DATA" .env; then
        sed -i 's/VITE_USE_MOCK_DATA=.*/VITE_USE_MOCK_DATA=false/' .env
    else
        echo "VITE_USE_MOCK_DATA=false" >> .env
    fi
    echo "Social Intelligence service detected."
fi

# Start the Agent Orchestrator
echo "Starting Agent Orchestrator..."
if [ "$1" = "docker" ]; then
    # Start in Docker
    docker-compose up -d
    echo "Agent Orchestrator started in Docker."
    echo "Access the UI at http://localhost:5173"
    docker-compose logs -f
else
    # Start locally
    echo "Starting in development mode..."
    npm install
    npm run dev
fi