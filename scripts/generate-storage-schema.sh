#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Storage Schema Bootstrap Generator ===${NC}"
echo "This script will generate a clean storage schema for use with Supabase storage-api"
echo "It will create a temporary database, run migrations, and export the schema"

# Create directory for bootstrap files
BOOTSTRAP_DIR="./bootstrap"
mkdir -p "$BOOTSTRAP_DIR"

# Step 1: Clean up any existing temporary containers and network
echo -e "${BLUE}[Step 1]${NC} Cleaning up any existing temporary resources..."
NETWORK_NAME="temp-storage-bootstrap-network"
PG_CONTAINER="temp-storage-postgres"
STORAGE_CONTAINER="temp-storage-api"

docker rm -f "$PG_CONTAINER" "$STORAGE_CONTAINER" 2>/dev/null || true
docker network rm "$NETWORK_NAME" 2>/dev/null || true

# Create a temporary network for isolation
echo -e "${BLUE}[Step 1a]${NC} Creating temporary Docker network..."
docker network create "$NETWORK_NAME" || true

# Step 2: Start a clean Postgres instance
echo -e "${BLUE}[Step 2]${NC} Starting temporary PostgreSQL container..."
PG_CONTAINER="temp-storage-postgres"
docker run --rm -d \
  --name "$PG_CONTAINER" \
  --network "$NETWORK_NAME" \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=postgres \
  postgres:15-alpine

# Wait for Postgres to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 5
MAX_RETRIES=30
RETRIES=0

until docker exec "$PG_CONTAINER" pg_isready -U postgres -h localhost || [ $RETRIES -eq $MAX_RETRIES ]; do
  echo "Waiting for PostgreSQL to be ready... ($((MAX_RETRIES - RETRIES)) attempts left)"
  sleep 2
  RETRIES=$((RETRIES + 1))
done

if [ $RETRIES -eq $MAX_RETRIES ]; then
  echo -e "${RED}Error: PostgreSQL did not become ready in time${NC}"
  docker stop "$PG_CONTAINER"
  docker network rm "$NETWORK_NAME"
  exit 1
fi

echo -e "${GREEN}PostgreSQL is ready${NC}"

# Step 3: Create the auth schema and required tables
echo -e "${BLUE}[Step 3]${NC} Creating auth schema and required tables..."
docker exec "$PG_CONTAINER" psql -U postgres -d postgres -c "
CREATE SCHEMA IF NOT EXISTS auth;
CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";

-- Create supabase_admin role if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE ROLE supabase_storage_admin;
    END IF;
END
\$\$;

CREATE TABLE IF NOT EXISTS auth.users (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    email text,
    created_at timestamptz DEFAULT now()
);"

# Step 4: Start the storage-api container
echo -e "${BLUE}[Step 4]${NC} Starting storage-api container to run migrations..."
STORAGE_CONTAINER="temp-storage-api"
docker run --rm -d \
  --name "$STORAGE_CONTAINER" \
  --network "$NETWORK_NAME" \
  -e ANON_KEY="${SUPABASE_ANON_KEY:-development-anon-key-placeholder}" \
  -e SERVICE_KEY="${SUPABASE_SERVICE_KEY:-development-service-key-placeholder}" \
  -e PGRST_URL=http://localhost:3000 \
  -e PGRST_JWT_SECRET=jwt-secret-for-development-only \
  -e DATABASE_URL=postgresql://postgres:postgres@"$PG_CONTAINER":5432/postgres \
  -e REGION=local \
  -e GLOBAL_S3_BUCKET=supabase-storage \
  -e FILE_SIZE_LIMIT=52428800 \
  -e FILE_STORAGE_BACKEND_PATH=/var/lib/storage \
  -e TENANT_ID=stub \
  -e STORAGE_BACKEND=file \
  -e JWT_SECRET=jwt-secret-for-development-only \
  -e ENABLE_IMAGE_TRANSFORMATION=true \
  supabase/storage-api:v0.40.4

# Immediately check logs to see if there are startup issues
echo "Checking initial storage-api logs..."
docker logs "$STORAGE_CONTAINER" || true

# Wait for the migrations to complete
echo "Waiting for storage-api to complete migrations..."
sleep 10

# Check if storage-api is running properly
if ! docker ps | grep -q "$STORAGE_CONTAINER"; then
  echo -e "${RED}Error: storage-api container is not running${NC}"
  echo "Checking container logs:"
  docker logs "$STORAGE_CONTAINER"
  docker stop "$PG_CONTAINER"
  docker network rm "$NETWORK_NAME"
  exit 1
fi

echo -e "${GREEN}Storage-api is running with migrations applied${NC}"

# Step 5: Export the schema without the migrations table data
echo -e "${BLUE}[Step 5]${NC} Exporting the storage schema..."
SCHEMA_SQL="$BOOTSTRAP_DIR/storage-schema.sql"
docker exec "$PG_CONTAINER" pg_dump -U postgres -d postgres \
  --schema=storage \
  --no-owner \
  --no-acl \
  --exclude-table-data=storage.migrations \
  -f /tmp/storage-schema.sql

# Copy the schema SQL file from the container
docker cp "$PG_CONTAINER:/tmp/storage-schema.sql" "$SCHEMA_SQL"

# Step 6: Create the initialization SQL script
echo -e "${BLUE}[Step 6]${NC} Creating bootstrap initialization script..."
INIT_SQL="$BOOTSTRAP_DIR/storage-bootstrap.sql"

# Create the bootstrap SQL file that will be used in Postgres initialization
cat > "$INIT_SQL" << 'EOF'
-- Storage Bootstrap SQL
-- This file is auto-generated - DO NOT EDIT MANUALLY

-- Create extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Check if storage schema already exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage') THEN
    -- Include the generated schema SQL here
EOF

# Append the schema SQL file content
cat "$SCHEMA_SQL" >> "$INIT_SQL"

# Close the conditional check
cat >> "$INIT_SQL" << 'EOF'
  ELSE
    RAISE NOTICE 'Storage schema already exists, skipping bootstrap';
  END IF;
END
$$;

-- Ensure migrations table is empty to prevent hash validation
TRUNCATE storage.migrations;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA storage TO postgres;
GRANT USAGE ON SCHEMA storage TO anon;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT USAGE ON SCHEMA storage TO service_role;

GRANT ALL ON ALL TABLES IN SCHEMA storage TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO service_role;

-- Create default storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('default', 'default', false)
ON CONFLICT (id) DO NOTHING;
EOF

# Step 7: Clean up
echo -e "${BLUE}[Step 7]${NC} Cleaning up temporary containers and network..."
docker stop "$STORAGE_CONTAINER" "$PG_CONTAINER"
docker network rm "$NETWORK_NAME"

echo -e "${GREEN}Success!${NC} Bootstrap files generated:"
echo "- Schema SQL: $SCHEMA_SQL"
echo "- Bootstrap SQL: $INIT_SQL"
echo ""
echo "Next steps:"
echo "1. Add the bootstrap SQL to your PostgreSQL initialization"
echo "2. Update your docker-compose.yml to use the real storage-api without migrations"
echo "3. Test the storage functionality"
