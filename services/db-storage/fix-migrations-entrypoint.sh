#!/bin/bash
set -e

echo "Starting storage-api service with migration fix..."

# Check if PostgreSQL is ready
is_postgres_ready() {
    PGPASSWORD="${DB_PASSWORD:-postgres}" psql -h "${DB_HOST:-db-postgres}" -p "${DB_PORT:-5432}" -U "${DB_USER:-postgres}" -d "${DB_NAME:-postgres}" -c "SELECT 1" > /dev/null 2>&1
}

# Wait for PostgreSQL to become ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL at ${DB_HOST:-db-postgres}:${DB_PORT:-5432} to become ready..."
    
    local retries=30
    while ! is_postgres_ready && [ $retries -gt 0 ]; do
        echo "PostgreSQL is not ready yet. Waiting... ($retries attempts left)"
        sleep 2
        retries=$((retries-1))
    done
    
    if [ $retries -eq 0 ]; then
        echo "Error: Failed to connect to PostgreSQL"
        exit 1
    fi
    
    echo "PostgreSQL is ready"
}

# Initialize the storage schema if needed
initialize_storage_schema() {
    echo "Initializing storage schema..."
    
    # Check if schema is already initialized
    if PGPASSWORD="${DB_PASSWORD:-postgres}" psql -h "${DB_HOST:-db-postgres}" -p "${DB_PORT:-5432}" -U "${DB_USER:-postgres}" -d "${DB_NAME:-postgres}" -c "SELECT 1 FROM storage.migrations LIMIT 1" > /dev/null 2>&1; then
        echo "Storage schema is already initialized"
    else
        echo "Running storage schema initialization..."
        
        # Execute the schema initialization script
        PGPASSWORD="${DB_PASSWORD:-postgres}" psql -h "${DB_HOST:-db-postgres}" -p "${DB_PORT:-5432}" -U "${DB_USER:-postgres}" -d "${DB_NAME:-postgres}" -f /app/fix-storage-migrations.sql
        
        echo "Storage schema initialization completed"
    fi
}

# Main execution
echo "Starting initialization process..."

# Wait for PostgreSQL to be ready
wait_for_postgres

# Initialize storage schema and migrations
initialize_storage_schema

# Set environment variables for storage-api
export SKIP_MIGRATIONS=true
export PGRST_JWT_SECRET=${JWT_SECRET:-super-secret-jwt-token}

# Start the storage-api service
echo "Starting storage-api service..."
exec node dist/server.js