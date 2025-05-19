#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Testing Supabase authentication service...${NC}"

# Load environment variables
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo -e "${RED}Error: .env file not found${NC}"
  exit 1
fi

# Install curl in the agent containers
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "apk add --no-cache curl jq >/dev/null 2>&1 || true"

# Create a database function to verify JWT
echo -e "${YELLOW}Creating DB function to verify JWT...${NC}"
docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "
-- Create a simple function that requires authentication
CREATE OR REPLACE FUNCTION auth.test_auth() RETURNS TEXT AS \$\$
BEGIN
    RETURN 'JWT verification successful: ' || auth.uid()::TEXT;
EXCEPTION WHEN OTHERS THEN
    RETURN 'JWT verification failed: ' || SQLERRM;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create API endpoint
DROP FUNCTION IF EXISTS public.test_auth();
CREATE OR REPLACE FUNCTION public.test_auth() RETURNS TEXT AS \$\$
  SELECT auth.test_auth();
\$\$ LANGUAGE SQL;

-- Grant execute access
GRANT EXECUTE ON FUNCTION public.test_auth TO authenticated;
GRANT EXECUTE ON FUNCTION public.test_auth TO service_role;
GRANT EXECUTE ON FUNCTION public.test_auth TO anon;
"

# Create table for service role test
echo -e "${YELLOW}Creating test table with RLS...${NC}"
docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "
-- Create a test table with RLS
CREATE TABLE IF NOT EXISTS public.service_role_test (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.service_role_test ENABLE ROW LEVEL SECURITY;

-- Create service_role policy
DROP POLICY IF EXISTS service_role_policy ON public.service_role_test;
CREATE POLICY service_role_policy ON public.service_role_test
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Grant permissions
GRANT ALL ON public.service_role_test TO service_role;
"

echo -e "${YELLOW}Testing JWT token with Alfred Bot service...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
# Test the auth endpoint with the service role key
curl -s -X GET \
  -H \"apikey: ${SERVICE_ROLE_KEY}\" \
  -H \"Authorization: Bearer ${SERVICE_ROLE_KEY}\" \
  \"http://supabase-rest:3000/rest/v1/rpc/test_auth\" || echo 'Auth test failed'

# Test writing to the service role test table
echo '{\"data\":\"test data\"}' > /tmp/test_data.json
curl -s -X POST \
  -H \"apikey: ${SERVICE_ROLE_KEY}\" \
  -H \"Authorization: Bearer ${SERVICE_ROLE_KEY}\" \
  -H \"Content-Type: application/json\" \
  -d @/tmp/test_data.json \
  \"http://supabase-rest:3000/rest/v1/service_role_test\" || echo 'Write test failed'

# Test reading from the service role test table
curl -s -X GET \
  -H \"apikey: ${SERVICE_ROLE_KEY}\" \
  -H \"Authorization: Bearer ${SERVICE_ROLE_KEY}\" \
  \"http://supabase-rest:3000/rest/v1/service_role_test?select=*\" || echo 'Read test failed'
"

echo -e "${GREEN}✅ Authentication tests complete.${NC}"
