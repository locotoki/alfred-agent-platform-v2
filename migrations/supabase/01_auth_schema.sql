-- Create the auth schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS auth;

-- Set the search path to include auth schema
ALTER DATABASE postgres SET search_path TO "$user", public, auth;

-- Create a dedicated role for auth operations
DO
$$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    CREATE ROLE supabase_auth_admin WITH LOGIN PASSWORD 'your-super-secret-password';
  END IF;
END
$$;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA auth TO supabase_auth_admin;

-- Make sure the schema is accessible to the postgres user as well
GRANT ALL PRIVILEGES ON SCHEMA auth TO postgres;

-- Allow the auth service to create new tables in the auth schema
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL PRIVILEGES ON TABLES TO supabase_auth_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL PRIVILEGES ON SEQUENCES TO supabase_auth_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL PRIVILEGES ON FUNCTIONS TO supabase_auth_admin;

-- Create schema_migrations table in auth schema
CREATE TABLE IF NOT EXISTS auth.schema_migrations (
  version VARCHAR(14) NOT NULL,
  PRIMARY KEY(version)
);

CREATE UNIQUE INDEX IF NOT EXISTS schema_migrations_version_idx ON auth.schema_migrations (version);
EOF < /dev/null
