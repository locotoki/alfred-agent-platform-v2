#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Setting up Supabase for Alfred Agent Platform...${NC}"

# Ensure we're using the latest .env values
JWT_SECRET=$(grep JWT_SECRET .env | cut -d= -f2)
ANON_KEY=$(grep ANON_KEY .env | cut -d= -f2)
SERVICE_ROLE_KEY=$(grep SERVICE_ROLE_KEY .env | cut -d= -f2)

echo -e "${YELLOW}Configuring authentication...${NC}"

# Create PostgreSQL functions and tables for authentication
docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "
-- Set the JWT secret as a database parameter
ALTER DATABASE postgres SET pgrst.jwt_secret TO '$JWT_SECRET';

-- Create tables needed for authentication if they don't exist
CREATE SCHEMA IF NOT EXISTS auth;

-- Create basic users table if it doesn't exist
CREATE TABLE IF NOT EXISTS auth.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  role TEXT DEFAULT 'authenticated',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create a function to get the current authenticated user
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
BEGIN
  RETURN nullif(current_setting('request.jwt.claim.sub', true), '')::UUID;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- Create a function to get the current user's role
CREATE OR REPLACE FUNCTION auth.role() RETURNS TEXT AS $$
BEGIN
  RETURN coalesce(
    current_setting('request.jwt.claim.role', true),
    'anon'
  );
EXCEPTION WHEN OTHERS THEN
  RETURN 'anon';
END;
$$ LANGUAGE plpgsql STABLE;

-- Create tables for our application
CREATE TABLE IF NOT EXISTS public.architect_in (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.architect_out (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.service_role_test (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.architect_in ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.architect_out ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_role_test ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for service_role
CREATE POLICY IF NOT EXISTS service_role_all_architect_in 
  ON public.architect_in FOR ALL TO service_role USING (true);

CREATE POLICY IF NOT EXISTS service_role_all_architect_out 
  ON public.architect_out FOR ALL TO service_role USING (true);

CREATE POLICY IF NOT EXISTS anon_read_architect_out 
  ON public.architect_out FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS service_role_all_test 
  ON public.service_role_test FOR ALL TO service_role USING (true);

-- Grant permissions
GRANT ALL ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- Create a function to test authentication
CREATE OR REPLACE FUNCTION public.test_auth() RETURNS TEXT AS $$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN 'Authentication successful as service_role';
  ELSIF auth.role() = 'anon' THEN
    RETURN 'Authentication successful as anon';
  ELSIF auth.role() = 'authenticated' THEN
    RETURN 'Authentication successful as authenticated user';
  ELSE
    RETURN 'Authentication failed. Current role: ' || auth.role();
  END IF;
EXCEPTION WHEN OTHERS THEN
  RETURN 'Authentication error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to all roles
GRANT EXECUTE ON FUNCTION public.test_auth TO anon, authenticated, service_role;
"

# Configure PostgREST
echo -e "${YELLOW}Configuring PostgREST...${NC}"

# Create a configuration file for PostgREST
cat > postgrest.conf << EOF
# PostgREST configuration file
db-uri = "postgres://postgres:your-super-secret-password@supabase-db:5432/postgres"
db-schemas = "public, auth"
db-anon-role = "anon"
db-pool = 10
server-host = "0.0.0.0"
server-port = 3000
jwt-secret = "$JWT_SECRET"
max-rows = 1000
EOF

# Copy the configuration to the PostgREST container
docker cp postgrest.conf alfred-agent-platform-v2-supabase-rest-1:/etc/postgrest.conf

# Restart the REST service
echo -e "${YELLOW}Restarting Supabase services...${NC}"
docker restart alfred-agent-platform-v2-supabase-rest-1

# Wait for services to restart
echo -e "${YELLOW}Waiting for services to restart...${NC}"
sleep 10

# Test the configuration
echo -e "${YELLOW}Testing Supabase authentication...${NC}"

# Install curl and jq in the Alfred bot container
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  apk add --no-cache curl jq >/dev/null 2>&1 || true
  
  # Test authentication
  echo 'Testing authentication function...'
  curl -s -X GET \
    -H \"apikey: $SERVICE_ROLE_KEY\" \
    -H \"Authorization: Bearer $SERVICE_ROLE_KEY\" \
    \"http://supabase-rest:3000/rest/v1/rpc/test_auth\" || echo 'Authentication test failed'
  
  # Test writing to architect_in table
  echo 'Testing write to architect_in table...'
  echo '{\"data\":{\"message\":\"Test from setup script\"}}' > /tmp/test.json
  curl -s -X POST \
    -H \"apikey: $SERVICE_ROLE_KEY\" \
    -H \"Authorization: Bearer $SERVICE_ROLE_KEY\" \
    -H \"Content-Type: application/json\" \
    -d @/tmp/test.json \
    \"http://supabase-rest:3000/rest/v1/architect_in\" || echo 'Write test failed'
  
  # Test reading from architect_in table
  echo 'Testing read from architect_in table...'
  curl -s -X GET \
    -H \"apikey: $SERVICE_ROLE_KEY\" \
    -H \"Authorization: Bearer $SERVICE_ROLE_KEY\" \
    \"http://supabase-rest:3000/rest/v1/architect_in?select=*\" || echo 'Read test failed'
"

echo -e "${GREEN}✅ Supabase setup complete.${NC}"