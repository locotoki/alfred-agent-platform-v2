-- Create necessary roles for Supabase
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticator') THEN
    CREATE ROLE authenticator NOLOGIN;
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN;
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin LOGIN CREATEROLE CREATEDB REPLICATION BYPASSRLS;
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
    CREATE ROLE supabase_storage_admin LOGIN;
  END IF;
END$$;

-- Grant necessary permissions
GRANT ALL ON DATABASE postgres TO supabase_admin;
GRANT USAGE ON SCHEMA public TO authenticator, anon, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticator, anon, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticator, anon, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticator, anon, service_role;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS extensions;

-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS "vector" SCHEMA extensions;
