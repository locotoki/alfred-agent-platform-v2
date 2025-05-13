#!/bin/bash

# Stop the storage container
docker stop supabase-storage
docker rm supabase-storage

# Clean up storage schema completely
docker exec supabase-db psql -U postgres -d postgres << EOF
-- Drop existing storage schema completely
DROP SCHEMA IF EXISTS storage CASCADE;

-- Create a clean storage schema
CREATE SCHEMA storage;

-- Grant all privileges to supabase_storage_admin
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;

-- Ensure the storage admin has the necessary permissions
ALTER USER supabase_storage_admin WITH CREATEDB CREATEROLE;
EOF

echo "Storage schema has been reset. You can now start the storage service."
