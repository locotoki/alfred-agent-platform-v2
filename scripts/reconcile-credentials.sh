#!/bin/bash
# Credential Reconciliation Script for GA-Hardening
# Exit criteria: All containers healthy, 0 auth failures

set -euo pipefail

echo "=== Credential Reconciliation for Postgres/Redis ==="
echo "Starting at: $(date)"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists and source it
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo -e "${RED}ERROR: .env file not found${NC}"
    echo "Creating template .env file..."
    cat > .env <<EOF
# Database credentials
POSTGRES_PASSWORD=postgres
DB_PASSWORD=postgres
DB_USER=postgres
DATABASE_URL=postgresql://postgres:postgres@db-postgres:5432/postgres

# Redis credentials
REDIS_PASSWORD=change-me-in-production

# Supabase credentials
POSTGRES_DB=postgres
JWT_SECRET=super-secret-jwt-token
ANON_KEY=your-anon-key
SERVICE_ROLE_KEY=your-service-role-key
GOTRUE_JWT_SECRET=super-secret-jwt-token

# Service URLs
ALFRED_DATABASE_URL=postgresql://postgres:postgres@db-postgres:5432/postgres
ALFRED_REDIS_URL=redis://:change-me-in-production@redis:6379
EOF
    echo -e "${YELLOW}Created template .env file. Please update with secure passwords.${NC}"
    exit 1
fi

# Validate required environment variables
REQUIRED_VARS=(
    "POSTGRES_PASSWORD"
    "REDIS_PASSWORD"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}ERROR: Missing required environment variables:${NC}"
    printf '%s\n' "${MISSING_VARS[@]}"
    exit 1
fi

echo -e "${GREEN}✓ Environment variables loaded${NC}"

# Create Redis configuration with authentication
echo "Creating Redis configuration..."
mkdir -p config
cat > config/redis.conf <<EOF
# Redis Configuration for Alfred Platform
# Security hardening as per GA requirements

# Network binding
bind 0.0.0.0
protected-mode yes
port 6379

# Authentication
requirepass ${REDIS_PASSWORD}

# Disable dangerous commands
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""
rename-command SHUTDOWN ""
rename-command DEBUG ""
rename-command SLAVEOF ""
rename-command REPLICAOF ""
rename-command MODULE ""

# Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# Logging
loglevel notice
logfile ""

# Performance
maxmemory 256mb
maxmemory-policy allkeys-lru

# Security
timeout 300
tcp-keepalive 300
tcp-backlog 511
EOF

echo -e "${GREEN}✓ Redis configuration created${NC}"

# Create docker-compose override for consistent credentials
echo "Creating credential override file..."
cat > docker-compose.override.credentials.yml <<EOF
# Credential reconciliation override
# Ensures all services use consistent credentials

version: '3.8'

services:
  redis:
    environment:
      - REDIS_PASSWORD=\${REDIS_PASSWORD}
    command: redis-server /usr/local/etc/redis/redis.conf
    volumes:
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf:ro

  redis-exporter:
    environment:
      - REDIS_ADDR=redis://:\${REDIS_PASSWORD}@redis:6379

  db-postgres:
    environment:
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_USER=\${DB_USER:-postgres}
      - POSTGRES_DB=\${POSTGRES_DB:-postgres}

  postgres-exporter:
    environment:
      - DATA_SOURCE_NAME=postgresql://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres?sslmode=disable

  # Core services with database access
  agent-core:
    environment:
      - DATABASE_URL=postgresql://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres
      - REDIS_URL=redis://:\${REDIS_PASSWORD}@redis:6379
      - ALFRED_DATABASE_URL=postgresql://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres
      - ALFRED_REDIS_URL=redis://:\${REDIS_PASSWORD}@redis:6379

  model-registry:
    environment:
      - DATABASE_URL=postgresql://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres

  # Supabase services
  db-auth:
    environment:
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - DATABASE_URL=postgres://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres
      - GOTRUE_DB_DATABASE_URL=postgres://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres?search_path=auth

  db-api:
    environment:
      - PGRST_DB_URI=postgres://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres

  db-realtime:
    environment:
      - DB_HOST=db-postgres
      - DB_NAME=postgres
      - DB_USER=\${DB_USER:-postgres}
      - DB_PASSWORD=\${POSTGRES_PASSWORD}
      - DB_PORT=5432

  db-storage:
    environment:
      - DATABASE_URL=postgres://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres

  # Services using Redis
  slack_mcp_gateway:
    environment:
      - REDIS_URL=redis://:\${REDIS_PASSWORD}@redis:6379
      - REDIS_PASSWORD=\${REDIS_PASSWORD}

  echo-agent:
    environment:
      - REDIS_URL=redis://:\${REDIS_PASSWORD}@redis:6379
      - REDIS_PASSWORD=\${REDIS_PASSWORD}

  alfred-bot:
    environment:
      - REDIS_URL=redis://:\${REDIS_PASSWORD}@redis:6379
      - DATABASE_URL=postgresql://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres

  agent_bizops:
    environment:
      - BIZOPS_DATABASE_URL=postgresql://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres
      - BIZOPS_REDIS_URL=redis://:\${REDIS_PASSWORD}@redis:6379
      - ALFRED_DATABASE_URL=postgresql://\${DB_USER:-postgres}:\${POSTGRES_PASSWORD}@db-postgres:5432/postgres
      - ALFRED_REDIS_URL=redis://:\${REDIS_PASSWORD}@redis:6379
EOF

echo -e "${GREEN}✓ Credential override file created${NC}"

# Test credential connectivity
echo ""
echo "Testing credential connectivity..."

# Function to check service health
check_service() {
    local service=$1
    local check_cmd=$2
    local max_attempts=30
    local attempt=1

    echo -n "Checking $service... "

    while [ $attempt -le $max_attempts ]; do
        if eval "$check_cmd" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
            return 0
        fi
        sleep 1
        ((attempt++))
    done

    echo -e "${RED}✗ Failed after $max_attempts attempts${NC}"
    return 1
}

# Start services with reconciled credentials
echo ""
echo "Starting services with reconciled credentials..."
docker-compose -f docker-compose.yml -f docker-compose.override.credentials.yml up -d redis db-postgres

# Wait for services to be ready
sleep 5

# Test Redis authentication
REDIS_OK=false
if check_service "Redis authentication" "docker exec redis redis-cli -a ${REDIS_PASSWORD} ping"; then
    REDIS_OK=true
fi

# Test PostgreSQL authentication
POSTGRES_OK=false
if check_service "PostgreSQL authentication" "docker exec db-postgres pg_isready -U ${DB_USER:-postgres}"; then
    # Test actual authentication
    if docker exec db-postgres psql -U ${DB_USER:-postgres} -c "SELECT 1" >/dev/null 2>&1; then
        POSTGRES_OK=true
    fi
fi

# Summary
echo ""
echo "=== Credential Reconciliation Summary ==="
echo "Completed at: $(date)"
echo ""
echo "Redis authentication: $([ "$REDIS_OK" = true ] && echo -e "${GREEN}✓ PASS${NC}" || echo -e "${RED}✗ FAIL${NC}")"
echo "PostgreSQL authentication: $([ "$POSTGRES_OK" = true ] && echo -e "${GREEN}✓ PASS${NC}" || echo -e "${RED}✗ FAIL${NC}")"
echo ""

if [ "$REDIS_OK" = true ] && [ "$POSTGRES_OK" = true ]; then
    echo -e "${GREEN}✓ All credential checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Use 'docker-compose -f docker-compose.yml -f docker-compose.override.credentials.yml up -d' to start all services"
    echo "2. Monitor logs with 'docker-compose logs -f' for any auth failures"
    echo "3. Run './scripts/verify-no-auth-failures.sh' to verify 0 auth failures"
    exit 0
else
    echo -e "${RED}✗ Some credential checks failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check .env file has correct passwords"
    echo "2. Ensure no conflicting environment variables"
    echo "3. Check Docker logs: docker-compose logs redis db-postgres"
    exit 1
fi
