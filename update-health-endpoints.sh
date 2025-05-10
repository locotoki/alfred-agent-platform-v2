#!/bin/bash

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
