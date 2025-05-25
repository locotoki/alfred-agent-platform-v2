-- Create auth schema and tables with correct types to prevent migration issues
CREATE SCHEMA IF NOT EXISTS auth;

-- Create identities table with proper UUID types
CREATE TABLE IF NOT EXISTS auth.identities (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (provider, id)
);

-- Create schema_migrations table to track applied migrations
CREATE TABLE IF NOT EXISTS auth.schema_migrations (
    version varchar(255) PRIMARY KEY
);

-- Mark the problematic migration as already applied to skip it
INSERT INTO auth.schema_migrations (version)
VALUES ('20221208132122_backfill_email_last_sign_in_at.up.sql')
ON CONFLICT (version) DO NOTHING;

-- Grant permissions
GRANT USAGE ON SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO postgres;
