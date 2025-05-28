#!/bin/bash
# Start local services without GHCR dependencies
set -euo pipefail

echo "Starting local services..."

# 1 — Source the .env file
export $(grep -v '^#' .env | xargs)

# 2 — Start core infrastructure services
echo "Starting core infrastructure..."
docker compose up -d redis db-postgres

# 3 — Wait for services to be ready
echo "Waiting for infrastructure to initialize..."
sleep 5

# 4 — Start Slack integration services
echo "Starting Slack integration services..."
docker compose up -d slack_mcp_gateway echo-agent || true

# 5 — List running services
echo -e "\nRunning services:"
docker compose ps

# 6 — Check Redis connectivity
echo -e "\nChecking Redis connectivity:"
docker compose exec redis redis-cli -a ${REDIS_PASSWORD} ping || echo "Redis auth failed"

# 7 — Check Postgres connectivity
echo -e "\nChecking Postgres connectivity:"
docker compose exec db-postgres pg_isready || echo "Postgres not ready"

echo -e "\nLocal services started. To use GHCR images, please add your GitHub PAT to .env:"
echo "GHCR_PAT=ghp_your_token_here"
echo ""
echo "Then run: docker login ghcr.io -u YOUR_GITHUB_USERNAME -p \$GHCR_PAT"
