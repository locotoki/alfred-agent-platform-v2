#!/bin/bash
set -e

echo "Applying storage schema fix..."
docker exec db-postgres psql -U postgres -d postgres -f /docker-entrypoint-initdb.d/fix-storage-schema.sql

echo "Recreating the supabase_storage_admin role with proper permissions..."
docker exec db-postgres psql -U postgres -d postgres -c "
DROP ROLE IF EXISTS supabase_storage_admin;
CREATE ROLE supabase_storage_admin WITH LOGIN PASSWORD 'your-super-secret-password';
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
"

echo "Restarting db-storage service..."
docker-compose -f docker-compose.unified.yml restart db-storage

echo "Done! Check the status with: docker ps | grep db-storage"