#!/bin/bash
# Apply comprehensive health check fixes to Docker Compose services
# This script applies the health fix override file and validates the results

set -euo pipefail

echo "🔧 Applying comprehensive health check fixes..."

# Check if override file exists
if [ ! -f "docker-compose.override.health-fixes.yml" ]; then
    echo "❌ Health fixes override file not found!"
    exit 1
fi

# Stop current services
echo "📦 Stopping current services..."
docker compose down || true

# Apply the override file
echo "🔄 Applying health fixes override..."
export COMPOSE_FILE="docker-compose.yml:docker-compose.override.health-fixes.yml"

# Validate the compose configuration
echo "✅ Validating Docker Compose configuration..."
docker compose config > /dev/null

# Start services with health fixes
echo "🚀 Starting services with health fixes..."
docker compose up -d

# Wait for services to initialize
echo "⏳ Waiting for services to initialize (60s)..."
sleep 60

# Check health status
echo "🏥 Checking service health status..."
./scripts/compose-health-check.sh

echo "✅ Health fixes applied successfully!"
