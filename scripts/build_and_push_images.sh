#!/bin/bash
# Script to build and push Docker images

if [ $# -lt 2 ]; then
    echo "Usage: $0 <tag> <service>"
    exit 1
fi

TAG=$1
SERVICE=$2

echo "Building and pushing images for $SERVICE with tag $TAG"

if [ "$SERVICE" == "metrics" ] || [ "$SERVICE" == "db-metrics" ]; then
    echo "Building db-metrics service..."

    # Build the Docker image
    docker build -t db-metrics:$TAG -f services/db-metrics/Dockerfile.bak services/db-metrics/

    # Tag the image for the registry (using a dummy registry path for simulation)
    docker tag db-metrics:$TAG ghcr.io/alfred/db-metrics:$TAG

    echo "Would push image ghcr.io/alfred/db-metrics:$TAG to registry (simulation)"
    # In a real scenario, this would push to the registry
    # docker push ghcr.io/alfred/db-metrics:$TAG

    echo "Image build and push simulation complete"
else
    echo "Service $SERVICE not recognized"
    exit 1
fi
