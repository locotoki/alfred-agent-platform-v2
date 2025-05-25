-- Create auth schema for GoTrue (db-auth service)
CREATE SCHEMA IF NOT EXISTS auth;

-- Grant usage on auth schema to postgres user
GRANT ALL ON SCHEMA auth TO postgres;

-- Set search path to include auth schema
ALTER DATABASE postgres SET search_path TO public, auth;

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA auth;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA auth;
