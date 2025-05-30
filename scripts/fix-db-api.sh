#!/usr/bin/env bash
# Attempt to fix db-api by creating anon role

set -euo pipefail

echo "🔧 Attempting to fix db-api..."

# Method 1: Try with PGPASSWORD environment variable
echo "Method 1: Using PGPASSWORD..."
PGPASSWORD=postgres docker exec db-postgres psql -h localhost -U postgres -d postgres -c "CREATE ROLE anon NOLOGIN;" 2>/dev/null || echo "Role may already exist"
PGPASSWORD=postgres docker exec db-postgres psql -h localhost -U postgres -d postgres -c "GRANT USAGE ON SCHEMA public TO anon;" 2>/dev/null || true
PGPASSWORD=postgres docker exec db-postgres psql -h localhost -U postgres -d postgres -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;" 2>/dev/null || true

# Give db-api time to pick up the change
echo "⏳ Waiting for db-api to restart..."
docker compose restart db-api
sleep 30

# Check if it worked
echo "🏥 Checking db-api health..."
docker compose ps db-api