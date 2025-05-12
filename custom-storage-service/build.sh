#!/bin/bash
set -e

echo "Building custom storage service..."
docker build -t custom-storage-api:latest .

echo "Ensuring storage schema exists in database..."
cat > ./ensure-storage-schema.sql << EOL
-- Create storage schema
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

-- Create default bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('default', 'default', FALSE)
ON CONFLICT (id) DO NOTHING;

-- Set up indexes
CREATE INDEX IF NOT EXISTS objects_bucket_id_name_idx ON storage.objects (bucket_id, name);
CREATE INDEX IF NOT EXISTS buckets_owner_idx ON storage.buckets (owner);
CREATE INDEX IF NOT EXISTS objects_owner_idx ON storage.objects (owner);
EOL

echo "Applying schema to database..."
docker cp ensure-storage-schema.sql db-postgres:/docker-entrypoint-initdb.d/
docker exec db-postgres psql -U postgres -d postgres -f /docker-entrypoint-initdb.d/ensure-storage-schema.sql

echo "Done! Now update docker-compose.unified.yml to use custom-storage-api:latest"