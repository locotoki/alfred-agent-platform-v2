#!/bin/bash
set -e

# Create a more complete storage schema
cat > ./complete-storage-schema.sql << EOL
-- Create storage schema and tables
CREATE SCHEMA IF NOT EXISTS storage;

-- Create storage.migrations table
CREATE TABLE IF NOT EXISTS storage.migrations (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    hash VARCHAR(100) NOT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create storage.objects table
CREATE TABLE IF NOT EXISTS storage.objects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bucket_id TEXT,
    name TEXT,
    owner UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    metadata JSONB,
    path_tokens TEXT[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED,
    version TEXT,
    owner_id UUID,
    size BIGINT
);

-- Create storage.buckets table
CREATE TABLE IF NOT EXISTS storage.buckets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    owner UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    public BOOLEAN DEFAULT FALSE,
    avif_autodetection BOOLEAN DEFAULT FALSE,
    file_size_limit BIGINT,
    allowed_mime_types TEXT[],
    owner_id UUID
);

-- Create storage.webhooks
CREATE TABLE IF NOT EXISTS storage.webhooks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    bucket_id TEXT REFERENCES storage.buckets(id),
    endpoint TEXT NOT NULL,
    events TEXT[],
    headers JSONB,
    signing_key TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create default bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('default', 'default', FALSE)
ON CONFLICT (id) DO NOTHING;

-- Create indexes
CREATE INDEX IF NOT EXISTS objects_bucket_id_name_idx ON storage.objects (bucket_id, name);
CREATE INDEX IF NOT EXISTS buckets_owner_idx ON storage.buckets (owner);
CREATE INDEX IF NOT EXISTS objects_owner_idx ON storage.objects (owner);

-- Mark all migrations as already applied
DELETE FROM storage.migrations;
INSERT INTO storage.migrations (id, name, hash) VALUES
(0, '0_create-migrations-table.sql', '5f200a7d9df9cf47384789b041638a44c6c2cdb5'),
(1, '0001-initialmigration.sql', '32471475d8d657a63f78256ef3efc937cf5deb6b'),
(2, '0002-pathtoken-column.sql', 'a7ef485ce4a9b4e6034bc4459a30a85f0c2401ed'),
(3, '0003-add-migrations-rls.sql', 'cdb051d37bf23bcc12f6b7e6636fbae6cd160a10'),
(4, '0004-add-size-functions.sql', 'fe7ec31db84473ba5ab4f7a8d3d0e4c04633ec81'),
(5, '0005-create-webhooks-table.sql', '0100b885c67ff98dfc1266dadf58a0ae8f9ec850'),
(6, '0006-search-function.sql', '6c4365fe3aa64fb1a4bc38721ebda3bb08634807');

-- Create or recreate the storage_admin role
DROP ROLE IF EXISTS supabase_storage_admin;
CREATE ROLE supabase_storage_admin WITH LOGIN PASSWORD 'storage-admin-password';
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA storage TO supabase_storage_admin;
EOL

echo "Copying SQL to database container..."
docker cp complete-storage-schema.sql db-postgres:/docker-entrypoint-initdb.d/

echo "Applying complete storage schema fix..."
docker exec db-postgres psql -U postgres -d postgres -f /docker-entrypoint-initdb.d/complete-storage-schema.sql

echo "Restarting db-storage service..."
docker-compose -f docker-compose.unified.yml restart db-storage

echo "Done! Check the status with: docker ps | grep db-storage"