#!/bin/bash

echo "Stopping and removing storage container..."
docker stop supabase-storage 2>/dev/null
docker rm supabase-storage 2>/dev/null

echo "Connecting to database to clean up storage completely..."
docker exec supabase-db psql -U postgres -d postgres << EOF
-- Terminate any existing connections to the database
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'postgres'
AND pid <> pg_backend_pid();

-- Drop storage schema and all objects
DROP SCHEMA IF EXISTS storage CASCADE;

-- Drop any storage-related functions from public schema
DROP FUNCTION IF EXISTS public.extension CASCADE;
DROP FUNCTION IF EXISTS public.get_size_by_bucket CASCADE;
DROP FUNCTION IF EXISTS public.search CASCADE;

-- Recreate a clean storage schema
CREATE SCHEMA storage;

-- Grant all privileges to supabase_storage_admin
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA storage TO supabase_storage_admin;

-- Ensure the storage admin has the necessary permissions
ALTER USER supabase_storage_admin WITH SUPERUSER;

-- List schemas to confirm
\dn
EOF

echo "Storage has been completely reset. Starting fresh storage container..."

# Start the storage container
cd /home/locotoki/projects/alfred-agent-platform-v2
docker-compose up -d supabase-storage

# Wait a bit and check status
echo "Waiting for storage to initialize..."
sleep 10

# Check if it's running
if docker ps | grep -q supabase-storage; then
    echo "✓ Storage container is running!"
    docker ps | grep supabase-storage
else
    echo "✗ Storage container failed to start. Checking logs..."
    docker logs --tail 50 supabase-storage
fi
