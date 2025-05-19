#!/usr/bin/env bash
set -euo pipefail

exec "$@"

set -e

echo "Starting storage-api service with migration fix..."

# Check if PostgreSQL is ready
is_postgres_ready() {
    pg_isready -h ${DB_HOST:-db-postgres} -p ${DB_PORT:-5432} -U ${DB_USER:-postgres}
}

# Wait for PostgreSQL to become ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL at ${DB_HOST:-db-postgres}:${DB_PORT:-5432} to become ready..."

    while ! is_postgres_ready; do
        echo "PostgreSQL is not ready yet. Waiting..."
        sleep 2
    done

    echo "PostgreSQL is ready"
}

# Wait for PostgreSQL to be ready
wait_for_postgres

# Fix the migrations
echo "Running migration fix script..."
PGPASSWORD=${DB_PASSWORD:-postgres} psql -h ${DB_HOST:-db-postgres} -p ${DB_PORT:-5432} -U ${DB_USER:-postgres} -d ${DB_NAME:-postgres} -c "
-- Fix the migration hashes to match what the storage service expects
-- This is used to fix the hash conflict issue

-- Drop the hash column if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'storage'
        AND table_name = 'migrations'
        AND column_name = 'hash'
    ) THEN
        ALTER TABLE storage.migrations ADD COLUMN hash text;
    END IF;
END \$\$;

-- Update the hash for pathtoken-column migration to match what the storage service expects
-- This removes the hash to let the service recreate the proper hash
UPDATE storage.migrations
SET hash = NULL
WHERE name = 'pathtoken-column';
"

# Start the original entry point
echo "Starting storage-api service..."
exec node dist/server.js
