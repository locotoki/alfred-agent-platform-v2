#!/bin/bash

# Check if database is ready and storage schema exists
check_db_ready() {
    echo "Checking if database is ready..."
    
    # Check if we can connect to the database
    if ! docker exec supabase-db psql -U postgres -d postgres -c "\q" >/dev/null 2>&1; then
        echo "Database is not reachable yet"
        return 1
    fi
    
    # Check if storage schema exists
    if ! docker exec supabase-db psql -U postgres -d postgres -c "SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage'" | grep -q "1"; then
        echo "Storage schema does not exist yet"
        return 1
    fi
    
    # Check if storage.objects table exists
    if ! docker exec supabase-db psql -U postgres -d postgres -c "SELECT 1 FROM information_schema.tables WHERE table_schema = 'storage' AND table_name = 'objects'" | grep -q "1"; then
        echo "Storage objects table does not exist yet"
        return 1
    fi
    
    echo "Database is ready with storage schema!"
    return 0
}

# Wait for database to be ready
MAX_ATTEMPTS=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "Attempt $ATTEMPT of $MAX_ATTEMPTS..."
    
    if check_db_ready; then
        echo "Database is ready! You can now start the storage service."
        exit 0
    fi
    
    echo "Database not ready yet. Waiting 5 seconds..."
    sleep 5
    ATTEMPT=$((ATTEMPT + 1))
done

echo "Database did not become ready after $MAX_ATTEMPTS attempts"
exit 1
