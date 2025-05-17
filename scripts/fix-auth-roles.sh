#!/bin/bash
# Script to fix authentication roles for storage service

set -e

echo "Creating authentication roles..."

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

# Fix the authentication roles
echo "Running authentication roles fix script..."
PGPASSWORD=postgres psql -h db-postgres -p 5432 -U postgres -d postgres -c "
-- Create auth roles if they don't exist
DO \$\$
BEGIN
    -- Create the 'anon' role if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN NOINHERIT;
    END IF;

    -- Create the 'authenticated' role if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN NOINHERIT;
    END IF;

    -- Create the 'service_role' role if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN NOINHERIT;
    END IF;

    -- Grant usage on storage schema
    GRANT USAGE ON SCHEMA storage TO anon;
    GRANT USAGE ON SCHEMA storage TO authenticated;
    GRANT USAGE ON SCHEMA storage TO service_role;

    -- Grant specific privileges to storage tables
    GRANT ALL ON ALL TABLES IN SCHEMA storage TO anon;
    GRANT ALL ON ALL TABLES IN SCHEMA storage TO authenticated;
    GRANT ALL ON ALL TABLES IN SCHEMA storage TO service_role;

    -- Grant specific privileges to storage sequences
    GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO anon;
    GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO authenticated;
    GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO service_role;
END \$\$;
"

echo "Authentication roles fix completed successfully!"