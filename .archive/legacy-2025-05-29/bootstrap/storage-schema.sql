-- Storage Schema Initialization SQL
-- This file is used to initialize the storage schema without requiring migrations

-- Create extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create storage schema
CREATE SCHEMA IF NOT EXISTS storage;

-- Create roles if not exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE ROLE supabase_storage_admin;
    END IF;
END
$$;

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

-- Create objects table
CREATE TABLE IF NOT EXISTS storage.objects (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- Create empty migrations table (to be ignored during startup)
CREATE TABLE IF NOT EXISTS storage.migrations (
    id integer PRIMARY KEY,
    name text NOT NULL,
    hash text,
    executed_at timestamptz DEFAULT now()
);

-- IMPORTANT: We leave the migrations table empty to bypass hash validation

-- Create necessary indexes
CREATE INDEX IF NOT EXISTS idx_objects_bucket_id_name ON storage.objects(bucket_id, name);
CREATE INDEX IF NOT EXISTS idx_objects_created_at ON storage.objects(created_at);
CREATE INDEX IF NOT EXISTS objects_path_tokens_idx ON storage.objects USING gin(path_tokens);

-- Enable Row Level Security
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create default policies
-- Buckets select policy
CREATE POLICY "Buckets are public" ON storage.buckets
    FOR SELECT USING (true);

-- Buckets insert policy
CREATE POLICY "Users can create buckets" ON storage.buckets
    FOR INSERT TO authenticated WITH CHECK (owner = auth.uid());

-- Buckets update policy
CREATE POLICY "Owner can update buckets" ON storage.buckets
    FOR UPDATE TO authenticated USING (owner = auth.uid()) WITH CHECK (owner = auth.uid());

-- Buckets delete policy
CREATE POLICY "Owner can delete buckets" ON storage.buckets
    FOR DELETE TO authenticated USING (owner = auth.uid());

-- Objects select policy
CREATE POLICY "Objects are public" ON storage.objects
    FOR SELECT USING (
        bucket_id IN (
            SELECT id FROM storage.buckets WHERE public = true
        )
        OR owner = auth.uid()
    );

-- Objects insert policy
CREATE POLICY "Users can upload objects" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (
        bucket_id IN (
            SELECT id FROM storage.buckets
        )
        AND owner = auth.uid()
    );

-- Objects update policy
CREATE POLICY "Owner can update objects" ON storage.objects
    FOR UPDATE TO authenticated USING (owner = auth.uid()) WITH CHECK (owner = auth.uid());

-- Objects delete policy
CREATE POLICY "Owner can delete objects" ON storage.objects
    FOR DELETE TO authenticated USING (owner = auth.uid());

-- Storage functions
CREATE OR REPLACE FUNCTION storage.search(prefix text, search text, config text DEFAULT 'english'::text)
 RETURNS SETOF storage.objects
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    IF prefix IS NULL THEN
        RETURN QUERY
        SELECT objects.* FROM storage.objects as objects
        WHERE objects.name ILIKE '%' || search || '%';
    ELSE
        RETURN QUERY
        SELECT objects.* FROM storage.objects as objects
        WHERE objects.name ILIKE prefix || '%' || search || '%';
    END IF;
END
$function$;

CREATE OR REPLACE FUNCTION storage.get_size_by_bucket()
 RETURNS TABLE(size bigint, bucket_id text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT SUM((metadata->>'size')::bigint) as size, objects.bucket_id
    FROM storage.objects as objects
    GROUP BY objects.bucket_id;
END
$function$;

-- Set table ownership
ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;
ALTER TABLE storage.objects OWNER TO supabase_storage_admin;
ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;

-- Grant permissions to roles
GRANT USAGE ON SCHEMA storage TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO postgres, supabase_storage_admin, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO postgres, supabase_storage_admin, service_role;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;

-- Create default bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('default', 'default', false)
ON CONFLICT (id) DO NOTHING;
