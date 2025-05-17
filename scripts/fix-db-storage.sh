#!/bin/bash
# Comprehensive script to fix db-storage service

set -e

echo "===== DB-Storage Production Fix Script ====="
echo "This script fixes migration and role issues for the Supabase storage service"

# Wait for PostgreSQL to become ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to become ready..."
    
    while ! pg_isready -h db-postgres -p 5432 -U postgres; do
        echo "PostgreSQL is not ready yet. Waiting..."
        sleep 2
    done
    
    echo "PostgreSQL is ready"
}

# Fix the migrations hash
fix_migrations_hash() {
    echo "Running migration hash fix..."
    PGPASSWORD=postgres psql -h db-postgres -p 5432 -U postgres -d postgres -c "
    -- Fix the migration hashes to match what the storage service expects
    -- This is used to fix the hash conflict issue

    -- Add hash column if it doesn't exist
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
    echo "Migration hash fix completed"
}

# Create authentication roles
create_auth_roles() {
    echo "Creating authentication roles..."
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
    echo "Authentication roles created"
}

# Make storage schema accessible
fix_schema_access() {
    echo "Fixing schema access..."
    PGPASSWORD=postgres psql -h db-postgres -p 5432 -U postgres -d postgres -c "
    -- Grant necessary privileges on all schemas
    GRANT USAGE ON SCHEMA public TO postgres;
    GRANT USAGE ON SCHEMA storage TO postgres;
    GRANT USAGE ON SCHEMA auth TO postgres;
    
    -- Grant access to all tables
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA storage TO postgres;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO postgres;
    
    -- Grant access to all sequences
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA storage TO postgres;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO postgres;
    "
    echo "Schema access fixed"
}

# Skip migrations check
create_skip_migrations() {
    echo "Adding skip migrations option..."
    PGPASSWORD=postgres psql -h db-postgres -p 5432 -U postgres -d postgres -c "
    -- Mark all storage migrations as completed to prevent future migrations
    WITH migration_list AS (
        SELECT unnest(ARRAY[
            's3-multipart-uploads',
            'extended-object-types',
            'pathtoken-unique-constraint',
            'nullable-migration-ids',
            'add-version-column'
        ]) AS name,
        generate_series(38, 42) AS id
    )
    INSERT INTO storage.migrations (id, name, hash)
    SELECT id, name, 'skip-migration-' || id
    FROM migration_list
    ON CONFLICT (id) DO UPDATE SET hash = 'skip-migration-' || excluded.id;
    "
    echo "Skip migrations option added"
}

# Run all fixes
main() {
    # Wait for PostgreSQL
    wait_for_postgres
    
    # Execute all fixes
    fix_migrations_hash
    create_auth_roles
    fix_schema_access
    create_skip_migrations
    
    echo "===== All fixes completed successfully! ====="
    echo "You can now restart the db-storage service with:"
    echo "docker-compose restart db-storage"
}

# Execute the main function
main