#!/bin/bash
# Script to fix model router health check

echo "Checking model router status..."
docker ps | grep model-router

# Fix model router health check
echo "Fixing model router health check..."
docker exec model-router bash -c 'echo "#!/bin/sh
wget -q --spider http://127.0.0.1:8080/health || exit 1
exit 0" > /usr/local/bin/healthcheck.sh && chmod +x /usr/local/bin/healthcheck.sh'

# Restart the model router
echo "Restarting model router..."
docker restart model-router

echo "Waiting for model router to restart..."
sleep 10

# Check status after restart
echo "Checking model router status after restart..."
docker ps | grep model-router

# Test model router health endpoint
echo "Testing model router health endpoint..."
curl -s http://localhost:8080/health

echo "Fix completed."