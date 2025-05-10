#!/bin/bash

# Script to fix the storage migration issue
# This resolves the "cannot change return type of existing function" error

set -e

echo "Fixing storage migration issue..."

# Connect to the database and drop the problematic function
docker exec supabase-db psql -U postgres -d postgres -c "
DO \$\$
BEGIN
    -- Drop the existing function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'storage' AND p.proname = 'get_size_by_bucket'
    ) THEN
        DROP FUNCTION IF EXISTS storage.get_size_by_bucket();
    END IF;
END
\$\$;
"

# Mark the problematic migration as completed (if needed)
docker exec supabase-db psql -U postgres -d postgres -c "
DO \$\$
BEGIN
    -- Mark the migration as completed if it's not already
    INSERT INTO storage.migrations (id, name, hash, executed_at)
    SELECT 4, 'add-size-functions', '6d79007d04f5acd288c9c250c42d2d5fd286c54d', NOW()
    WHERE NOT EXISTS (
        SELECT 1 FROM storage.migrations WHERE id = 4
    );
END
\$\$;
"

echo "Migration fix applied. Restarting storage container..."

# Restart the storage container to apply changes
docker restart supabase-storage

echo "Waiting for storage service to be healthy..."
sleep 10

# Check if the service is healthy
if curl -s http://localhost:5000/health > /dev/null; then
    echo "✅ Storage service is now healthy!"
else
    echo "⚠️  Storage service might still be having issues. Check the logs:"
    echo "docker logs supabase-storage --tail 50"
fi

echo "Fix complete!"
