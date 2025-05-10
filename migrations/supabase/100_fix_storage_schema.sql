-- Drop the existing tables to fix schema conflicts
DROP TABLE IF EXISTS storage.objects;
DROP TABLE IF EXISTS storage.buckets;
DROP TABLE IF EXISTS storage.migrations;

-- Create tables with the exact schema the storage API expects
CREATE TABLE storage.buckets (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    owner UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE storage.objects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bucket_id TEXT REFERENCES storage.buckets (id),
    name TEXT,
    owner UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB,
    version TEXT
);

CREATE TABLE storage.migrations (
    id INTEGER PRIMARY KEY,
    name VARCHAR NOT NULL,
    hash VARCHAR,
    executed_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create basic indexes
CREATE INDEX idx_objects_bucket_id_name ON storage.objects(bucket_id, name);
CREATE INDEX idx_objects_created_at ON storage.objects(created_at);
CREATE INDEX idx_objects_name ON storage.objects(name);
CREATE INDEX idx_objects_bucket_id ON storage.objects(bucket_id);

-- Grant all privileges to supabase_storage_admin
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;

-- Set ownership
ALTER TABLE storage.objects OWNER TO supabase_storage_admin;
ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;
ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;

-- Create the default bucket
INSERT INTO storage.buckets (id, name, owner)
VALUES ('supabase-storage', 'supabase-storage', NULL)
ON CONFLICT (id) DO NOTHING;
