#!/usr/bin/env bash
# Bootstrap script for new developers
# Ensures a clean, reproducible core slice setup
#
# Usage: ./scripts/bootstrap-dev.sh [--profile extras]

set -euo pipefail

# Parse arguments
INCLUDE_EXTRAS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            if [ "$2" = "extras" ]; then
                INCLUDE_EXTRAS=true
            fi
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "🚀 Alfred Platform Bootstrap"
echo "==========================="
if [ "$INCLUDE_EXTRAS" = true ]; then
    echo "Mode: Core + Extras"
else
    echo "Mode: Core Only"
fi
echo

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not found. Please install Docker."; exit 1; }
command -v docker compose >/dev/null 2>&1 || { echo "❌ Docker Compose not found. Please install Docker Compose v2."; exit 1; }

# Ensure we're in the project root
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Not in project root. Please run from alfred-agent-platform-v2 directory."
    exit 1
fi

# Check for .env file
if [ ! -f ".env" ]; then
    echo "⚠️  No .env file found. Creating from template..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ Created .env from template. Please update with real credentials."
    else
        echo "❌ No .env.example found. Please create .env manually."
        exit 1
    fi
fi

# Create Docker network if it doesn't exist
echo "🌐 Setting up Docker network..."
docker network create alfred-network 2>/dev/null || echo "✅ Network 'alfred-network' already exists"

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker compose down --remove-orphans

# Define core services (13-service baseline)
CORE_SERVICES=(
    redis
    redis-exporter
    db-postgres
    db-api
    agent-core
    telegram-adapter
    pubsub-emulator
    pubsub-metrics
    monitoring-metrics
    monitoring-dashboard
    llm-service
    model-router
    model-registry
)

# For lean mode (9 services only)
LEAN_SERVICES=(
    redis
    redis-exporter
    db-postgres
    db-api
    telegram-adapter
    pubsub-emulator
    pubsub-metrics
    monitoring-metrics
    monitoring-dashboard
)

# Start services based on mode
if [ "${CORE_NO_LLM:-}" = "1" ]; then
    echo "🚀 Starting lean core services (9 services, no LLM)..."
    docker compose up -d "${LEAN_SERVICES[@]}"
elif [ "$INCLUDE_EXTRAS" = true ]; then
    echo "🚀 Starting all services (core + extras)..."
    docker compose up -d
else
    echo "🚀 Starting core services (13 services including LLM)..."
    docker compose up -d "${CORE_SERVICES[@]}"
fi

# Wait for services to initialize
echo "⏳ Waiting for services to initialize (60 seconds)..."
sleep 60

# Fix db-api by creating anon role
echo "🔧 Setting up PostgreSQL roles..."
cat > /tmp/create-anon.sql << 'EOF'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
END $$;
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon;
EOF

# Try to create the anon role
if docker exec -i db-postgres psql -U postgres -f - < /tmp/create-anon.sql 2>/dev/null; then
    echo "✅ PostgreSQL anon role created"
else
    echo "⚠️  Could not create anon role automatically. You may need to do this manually."
fi

rm -f /tmp/create-anon.sql

# Run health check
echo
echo "🏥 Running health check..."
./scripts/check-core-health.sh

# Run baseline audit
echo
echo "📊 Running baseline audit..."
./scripts/audit-core.sh > logs/baseline-audit-$(date +%Y%m%d-%H%M%S).txt

echo
echo "✅ Bootstrap complete!"
echo
echo "Next steps:"
echo "1. Check health status: ./scripts/check-core-health.sh"
echo "2. View logs: docker compose logs -f"
echo "3. Access services:"
echo "   - Redis: localhost:6379"
echo "   - PostgreSQL: localhost:5432"
echo "   - Grafana: http://localhost:3005 (admin/admin)"
echo "   - Prometheus: http://localhost:9090"
echo "   - Agent Core: http://localhost:8011/health"