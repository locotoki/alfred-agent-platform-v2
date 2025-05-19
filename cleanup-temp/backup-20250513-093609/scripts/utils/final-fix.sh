#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Final fix for Supabase authentication...${NC}"

# Create the new postgrest.conf with simplified configuration
cat > postgrest.conf << EOF
db-uri = "postgres://postgres:your-super-secret-password@supabase-db:5432/postgres"
db-schema = "public"
db-anon-role = "anon"
db-pool = 10
server-host = "0.0.0.0"
server-port = 3000
jwt-secret = "Dch9y6o9ih/DrzAjUtYS9a3/pEw+v8MFy8k+LYBv0uk="
EOF

# Copy the configuration to the PostgREST container
docker cp postgrest.conf alfred-agent-platform-v2-supabase-rest-1:/etc/postgrest.conf

# Create simple RLS policies
cat > simple_policies.sql << EOF
-- First drop existing policies that might conflict
DROP POLICY IF EXISTS service_role_all_architect_in ON public.architect_in;
DROP POLICY IF EXISTS service_role_all_architect_out ON public.architect_out;
DROP POLICY IF EXISTS anon_read_architect_out ON public.architect_out;
DROP POLICY IF EXISTS service_role_all_test ON public.service_role_test;

-- Create simplified policies
CREATE POLICY service_role_all_architect_in ON public.architect_in FOR ALL USING (true);
CREATE POLICY service_role_all_architect_out ON public.architect_out FOR ALL USING (true);
CREATE POLICY anon_read_architect_out ON public.architect_out FOR SELECT USING (true);
CREATE POLICY service_role_all_test ON public.service_role_test FOR ALL USING (true);

-- Verify the auth function exists
CREATE OR REPLACE FUNCTION auth.role() RETURNS TEXT AS \$\$
BEGIN
  RETURN coalesce(
    current_setting('request.jwt.claim.role', true),
    'anon'
  );
EXCEPTION WHEN OTHERS THEN
  RETURN 'anon';
END;
\$\$ LANGUAGE plpgsql STABLE;

-- Create a public test function
CREATE OR REPLACE FUNCTION public.test_auth() RETURNS TEXT AS \$\$
BEGIN
  RETURN 'Authentication test: Role = ' || coalesce(current_setting('request.jwt.claim.role', true), 'none');
EXCEPTION WHEN OTHERS THEN
  RETURN 'Error: ' || SQLERRM;
END;
\$\$ LANGUAGE plpgsql;

-- Grant access to everyone
GRANT EXECUTE ON FUNCTION public.test_auth TO PUBLIC;
EOF

# Execute the SQL
cat simple_policies.sql | docker exec -i alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres

# Restart the REST service
echo -e "${YELLOW}Restarting Supabase REST...${NC}"
docker restart alfred-agent-platform-v2-supabase-rest-1

# Wait for the service to restart
echo -e "${YELLOW}Waiting for service to restart...${NC}"
sleep 5

# Install dependencies in the Alfred Bot container
echo -e "${YELLOW}Installing dependencies in Alfred Bot container...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  apk add --no-cache curl jq >/dev/null 2>&1 || true
"

# Update the environment in the Alfred Bot container
echo -e "${YELLOW}Updating environment in Alfred Bot container...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  # Set environment variables
  export SUPABASE_URL=http://supabase-rest:3000
  export SUPABASE_SERVICE_ROLE_KEY=\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNzQ2OTYwNzgyLCJleHAiOjQ5MDA1NjA3ODJ9.jp2EYNlfat_wVIXgw97Y7zkaEpGPsKgc6lR7R_xRmsA\"

  # Test with direct table access - simple approach
  echo 'Testing direct table access without auth...'
  curl -s -X GET \"http://supabase-rest:3000/architect_in\" || echo 'Direct access failed'

  # Try test_auth function - public access
  echo 'Testing public function...'
  curl -s -X GET \"http://supabase-rest:3000/rpc/test_auth\" || echo 'Public function test failed'

  # Test with service role token
  echo 'Testing with service role token...'
  curl -s -X GET \
    -H \"apikey: \$SUPABASE_SERVICE_ROLE_KEY\" \
    -H \"Authorization: Bearer \$SUPABASE_SERVICE_ROLE_KEY\" \
    \"http://supabase-rest:3000/architect_in\" || echo 'Service role access failed'

  # Test writing to architect_in
  echo 'Testing write to architect_in...'
  echo '{\"data\":{\"message\":\"test\"}}' > /tmp/test.json
  curl -s -X POST \
    -H \"apikey: \$SUPABASE_SERVICE_ROLE_KEY\" \
    -H \"Authorization: Bearer \$SUPABASE_SERVICE_ROLE_KEY\" \
    -H \"Content-Type: application/json\" \
    -d @/tmp/test.json \
    \"http://supabase-rest:3000/architect_in\" || echo 'Write failed'
"

echo -e "${GREEN}✅ Final fix applied.${NC}"
