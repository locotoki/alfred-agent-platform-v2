#!/bin/bash
# *********************************************************************
# DEPRECATED: This script is deprecated and will be removed in a future version.
# Please use the healthcheck binary v0.4.0 instead, which is now standardized
# across all services. See PR #22 for details.
# *********************************************************************

echo "DEPRECATED: This script is deprecated. See comments in the script for details."
echo "Updating health endpoints to use simple /health pattern..."

cd /home/locotoki/projects/alfred-agent-platform-v2

# Stop containers
echo "Stopping containers..."
docker compose down

# Rebuild services with updated health checks
echo "Rebuilding services..."
docker compose build --no-cache alfred-bot social-intel financial-tax legal-compliance

# Start services
echo "Starting services..."
docker compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Test new health endpoints
echo "Testing health endpoints..."
echo -e "\nAlfred Bot (should use /health):"
curl -s http://localhost:8011/health

echo -e "\n\nSocial Intel (should use /health):"
curl -s http://localhost:9000/health

echo -e "\n\nFinancial Tax (should use /health):"
curl -s http://localhost:9003/health

echo -e "\n\nLegal Compliance (should use /health):"
curl -s http://localhost:9002/health || echo "Legal compliance not running"

echo -e "\n\nDone!"