#!/bin/bash
# Script to fix health_patch.py in containers

# Copy health_patch.py to agent-rag container
echo "Copying health_patch.py to agent-rag container..."
docker cp /home/locotoki/projects/alfred-agent-platform-v2/services/alfred-core/app/health_patch.py agent-rag:/app/app/health_patch.py

# Copy health_patch.py to agent-core container (in case it's not there)
echo "Copying health_patch.py to agent-core container..."
docker cp /home/locotoki/projects/alfred-agent-platform-v2/services/alfred-core/app/health_patch.py agent-core:/app/app/health_patch.py

# Restart both services
echo "Restarting agent-rag..."
docker restart agent-rag

echo "Restarting agent-core..."
docker restart agent-core

echo "Waiting for services to restart..."
sleep 10

# Check health status
echo "Checking agent-rag health status..."
docker ps | grep agent-rag

echo "Checking agent-core health status..."
docker ps | grep agent-core

# Check service logs for errors
echo "Checking agent-rag logs..."
docker logs agent-rag --tail 10

echo "Checking agent-core logs..."
docker logs agent-core --tail 10

echo "Fix attempt completed."
