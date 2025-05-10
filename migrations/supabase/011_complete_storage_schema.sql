-- Create auth schema if it doesn't exist (needed for references)
CREATE SCHEMA IF NOT EXISTS auth;

-- Create minimal auth.users table if not exists (for references)
CREATE TABLE IF NOT EXISTS auth.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid()
);

-- Create storage schema
CREATE SCHEMA IF NOT EXISTS storage;

-- Grant permissions
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA storage TO supabase_storage_admin;

-- Create migrations table as per Supabase storage requirements
CREATE TABLE IF NOT EXISTS storage.migrations (
    id integer PRIMARY KEY,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;

-- Create buckets table
CREATE TABLE IF NOT EXISTS storage.buckets (
    id text PRIMARY KEY,
    name text NOT NULL UNIQUE,
    owner uuid REFERENCES auth.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[]
);

ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;

-- Create objects table
CREATE TABLE IF NOT EXISTS storage.objects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    bucket_id text REFERENCES storage.buckets(id),
    name text,
    owner uuid REFERENCES auth.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    last_accessed_at timestamptz DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED,
    version text
);

ALTER TABLE storage.objects OWNER TO supabase_storage_admin;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_objects_bucket_id_name ON storage.objects(bucket_id, name);
CREATE INDEX IF NOT EXISTS idx_objects_created_at ON storage.objects(created_at);

-- Ensure RLS is enabled (Supabase storage expects this)
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create default policies 
CREATE POLICY "Enable read access for all users" ON storage.objects
FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users" ON storage.objects
FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- Grant final permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON TABLES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON SEQUENCES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON FUNCTIONS TO supabase_storage_admin;

-- Ensure supabase_storage_admin has necessary privileges
ALTER ROLE supabase_storage_admin WITH SUPERUSER;
