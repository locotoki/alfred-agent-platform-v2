-- Create storage schema
CREATE SCHEMA IF NOT EXISTS storage;

-- Create migrations table
CREATE TABLE IF NOT EXISTS storage.migrations (
  id bigint NOT NULL,
  name character varying(100) NOT NULL,
  hash character varying(40) NOT NULL,
  executed_at timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT migrations_pkey PRIMARY KEY (id)
);

-- Insert migrations data
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES 
  (1, 'pathtoken-column', 'e7862023a1ae7afe7b69f991e0530b15c4ef7d39', NOW()),
  (2, 'add-public-to-buckets', '83455c984ffbe3feca3411b5591f68b8a4260ba9', NOW()),
  (3, 'add-migration-versions', '99b7ef8119e1f495163c0a1e13559878d4eb1156', NOW());

-- Create objects table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS storage.objects (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    bucket_id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_accessed_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED,
    version text,
    CONSTRAINT objects_pkey PRIMARY KEY (id),
    CONSTRAINT objects_bucketid_name_owner_key UNIQUE (bucket_id, name, owner),
    CONSTRAINT objects_version_key UNIQUE (version)
);

-- Create buckets table
CREATE TABLE IF NOT EXISTS storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    public boolean DEFAULT false NOT NULL,
    avif_autodetection boolean DEFAULT false NOT NULL,
    file_size_limit bigint DEFAULT 0,
    allowed_mime_types text[],
    CONSTRAINT buckets_pkey PRIMARY KEY (id),
    CONSTRAINT buckets_name_key UNIQUE (name)
);

-- Add default bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('supabase-storage', 'supabase-storage', false)
ON CONFLICT DO NOTHING;

-- Add indexes
CREATE INDEX IF NOT EXISTS objects_created_at_idx ON storage.objects USING btree (created_at);
CREATE INDEX IF NOT EXISTS objects_bucketid_name_idx ON storage.objects USING btree (bucket_id, name);

-- Create owner policy
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Give users access to own objects" ON storage.objects
    USING (owner = auth.uid());

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Give users access to own buckets" ON storage.buckets
    USING (owner = auth.uid());

-- Grant permissions
GRANT ALL ON SCHEMA storage TO postgres;
GRANT ALL ON SCHEMA storage TO anon;
GRANT ALL ON SCHEMA storage TO authenticated;
GRANT ALL ON SCHEMA storage TO service_role;

GRANT ALL ON ALL TABLES IN SCHEMA storage TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO service_role;

GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO service_role;