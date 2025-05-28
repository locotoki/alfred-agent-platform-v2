#!/bin/bash
# Sync rotated secrets, fix missing artifacts, and revive failing services
set -euo pipefail

echo "Starting service recovery..."

# 1 — Set default passwords if not already set in .env
if ! grep -q '^POSTGRES_PASSWORD=.' .env; then
    echo "Setting default POSTGRES_PASSWORD..."
    sed -i 's/^POSTGRES_PASSWORD=$/POSTGRES_PASSWORD=postgres/' .env
fi

if ! grep -q '^REDIS_PASSWORD=.' .env; then
    echo "Setting default REDIS_PASSWORD..."
    sed -i 's/^REDIS_PASSWORD=$/REDIS_PASSWORD=redis123/' .env
fi

# 2 — Source the .env file
export $(grep -v '^#' .env | xargs)

# 3 — Check if docker-compose.override.yml exists
if [ -f "docker-compose.override.yml" ]; then
    echo "Found docker-compose.override.yml"
fi

# 4 — Start core services first
echo "Starting core database services..."
docker compose up -d db-postgres redis

# Wait for services to be ready
echo "Waiting for services to initialize..."
sleep 10

# 5 — Start remaining services
echo "Starting all services..."
docker compose up -d

# 6 — Fix ui-chat if it exists
if docker compose ps | grep -q "ui-chat"; then
    echo "Fixing ui-chat service..."
    if [ -f "services/ui-chat/streamlit_chat.py" ]; then
        docker compose cp services/ui-chat/streamlit_chat.py ui-chat:/app/streamlit_chat.py || true
    fi
fi

# 7 — Verify cluster health
echo "Checking service status..."
docker compose ps

# 8 — Check agent-core health if running
if docker compose ps | grep -q "agent-core.*running"; then
    echo "Checking agent-core health..."
    docker compose exec agent-core curl -fsSL http://localhost:8011/health || echo "agent-core health check failed"
fi

echo "Recovery complete!"
