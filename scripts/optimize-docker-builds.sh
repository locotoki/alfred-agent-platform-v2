#!/usr/bin/env bash
set -euo pipefail

# Docker build optimization script for Alfred platform
# Optimizes build cache usage and implements multi-stage builds

echo "=== Docker Build Optimization ==="

# Enable Docker BuildKit for better caching and performance
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build optimized base images first
echo "Building shared Python base image..."
docker build -t alfred-python-base:latest base-images/python-base/

# Build optimized core services
echo "Building optimized agent-core..."
if [ -f services/alfred-core/Dockerfile.optimized ]; then
    docker build -f services/alfred-core/Dockerfile.optimized \
        -t ghcr.io/locotoki/agent-core:optimized \
        --cache-from ghcr.io/locotoki/agent-core:optimized \
        .
fi

echo "Building optimized atlas-worker..."
if [ -f services/atlas-worker/Dockerfile.optimized ]; then
    docker build -f services/atlas-worker/Dockerfile.optimized \
        -t ghcr.io/locotoki/atlas-worker:optimized \
        --cache-from ghcr.io/locotoki/atlas-worker:optimized \
        .
fi

# Build other services with cache optimization
echo "Building metrics services with cache..."
docker build -t pubsub-metrics:optimized \
    --cache-from pubsub-metrics:optimized \
    alfred/metrics/

# Tag optimized images for use in compose
docker tag ghcr.io/locotoki/agent-core:optimized agent-core:latest
docker tag ghcr.io/locotoki/atlas-worker:optimized atlas-worker:latest

echo "=== Optimization Complete ==="
echo "Optimized images:"
echo "- alfred-python-base:latest"  
echo "- agent-core:latest (optimized)"
echo "- atlas-worker:latest (optimized)"
echo "- pubsub-metrics:optimized"

# Clean up build cache if requested
if [[ "${1:-}" == "--clean" ]]; then
    echo "Cleaning build cache..."
    docker builder prune -f
fi

echo "Build optimization completed!"