#!/bin/bash
# Script to fix the storage migrations hash issue

set -e

echo "Fixing storage migrations hash..."

# Wait for PostgreSQL to become ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to become ready..."

    while ! pg_isready -h db-postgres -p 5432 -U postgres; do
        echo "PostgreSQL is not ready yet. Waiting..."
        sleep 2
    done

    echo "PostgreSQL is ready"
}

# Wait for PostgreSQL to be ready
wait_for_postgres

# Fix the migrations
echo "Running migration fix script..."
PGPASSWORD=postgres psql -h db-postgres -p 5432 -U postgres -d postgres -c "
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

-- Set a known working hash value for the pathtoken-column migration
UPDATE storage.migrations
SET hash = 'e2c8d16e824f5ed948b4760efd0d88d5'
WHERE name = 'pathtoken-column';
"

echo "Storage migrations hash fix completed successfully!"
