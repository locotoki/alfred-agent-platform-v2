#!/bin/bash

# Production deployment script for Alfred Streamlit Chat Interface

echo "Alfred Streamlit Chat Interface - Production Deployment"
echo "======================================================="

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Create backup of current configuration
echo "Creating backup of current configuration..."
timestamp=$(date +"%Y%m%d-%H%M%S")
backup_dir="./backup-$timestamp"
mkdir -p "$backup_dir"
cp docker-compose.prod.yml "$backup_dir/"
cp .env.production "$backup_dir/" 2>/dev/null || echo "No .env.production file to backup."

# Ensure we have a production .env file
if [ ! -f ".env.production" ]; then
    echo "Warning: No .env.production file found. Creating from template..."
    cp .env.production.sample .env.production 2>/dev/null || echo "No .env.production.sample file found."
    echo "Please edit .env.production with your configuration."
fi

# Stop any existing services
echo "Stopping existing services..."
docker-compose -f docker-compose.prod.yml down

# Build and start services
echo "Building and starting services..."
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to start
echo "Waiting for services to be healthy..."
sleep 10

# Run health check
echo "Running integration check..."
ENVIRONMENT=production ./check-integration.sh

if [ $? -eq 0 ]; then
    echo "Deployment completed successfully!"
    echo ""
    echo "Streamlit UI: http://localhost:8502"
    echo "Alfred API: http://localhost:8012"
    echo ""
    echo "To check logs, run:"
    echo "docker-compose -f docker-compose.prod.yml logs -f"
else
    echo "Deployment failed! Services might not be running correctly."
    echo "Check logs with: docker-compose -f docker-compose.prod.yml logs -f"
    exit 1
fi