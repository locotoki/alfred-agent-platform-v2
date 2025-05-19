#!/bin/bash
# Script to install missing dependencies in running containers

echo "Installing PyJWT in agent-financial container..."
docker exec agent-financial pip install PyJWT

echo "Installing PyJWT in agent-legal container..."
docker exec agent-legal pip install PyJWT

echo "Restarting agent services..."
docker-compose restart agent-financial agent-legal
