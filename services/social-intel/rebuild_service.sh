#!/bin/bash
set -e

echo "Rebuilding social-intel service with fixes..."
cd /home/locotoki/projects/alfred-agent-platform-v2
docker-compose build --no-cache social-intel
docker-compose up -d social-intel

echo "Service has been rebuilt and restarted."
echo "Wait a moment for it to initialize, then check:"
echo "docker-compose logs social-intel"
