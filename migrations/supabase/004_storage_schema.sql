-- Create storage schema
CREATE SCHEMA IF NOT EXISTS storage;

-- Create objects table
CREATE TABLE IF NOT EXISTS storage.objects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bucket_id TEXT NOT NULL,
    name TEXT NOT NULL,
    owner UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB,
    path_tokens TEXT[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED,
    version UUID
);

-- Create buckets table
CREATE TABLE IF NOT EXISTS storage.buckets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    owner UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    public BOOLEAN DEFAULT FALSE,
    avif_autodetection BOOLEAN DEFAULT FALSE,
    file_size_limit BIGINT DEFAULT 0,
    allowed_mime_types TEXT[]
);

-- Create default bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('supabase-storage', 'supabase-storage', false)
ON CONFLICT (id) DO NOTHING;

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_objects_bucket_id_name 
ON storage.objects(bucket_id, name);

CREATE INDEX IF NOT EXISTS idx_objects_created_at
ON storage.objects(created_at);

-- Grant permissions to supabase_storage_admin
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
