#!/bin/sh
set -e

echo "DB-AUTH: Starting wrapper script..."
echo "DB-AUTH: Environment check - POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:+SET}"

# Wait for database to be ready
echo "DB-AUTH: Waiting for database..."
until PGPASSWORD=${POSTGRES_PASSWORD:-postgres} psql -h db-postgres -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-auth_db} -c "SELECT 1" > /dev/null 2>&1; do
  echo "DB-AUTH: Database not ready, waiting..."
  sleep 1
done

# Initialize auth schema with correct types
echo "DB-AUTH: Initializing auth schema..."
PGPASSWORD=${POSTGRES_PASSWORD:-postgres} psql -h db-postgres -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-auth_db} -f /tmp/init-auth-schema.sql || true

# Run the original auth binary
echo "DB-AUTH: Starting GoTrue..."
exec /usr/local/bin/auth
