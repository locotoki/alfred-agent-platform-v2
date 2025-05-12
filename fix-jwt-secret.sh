#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing JWT secret in Supabase database...${NC}"

# Load environment variables
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo -e "${RED}Error: .env file not found${NC}"
  exit 1
fi

JWT_SECRET=${JWT_SECRET:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o}

# Update the JWT secret in the Postgres auth schema
echo -e "${YELLOW}Updating JWT secret in auth schema...${NC}"
docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "
-- Set the JWT secret directly
UPDATE auth.secrets SET secret = '$JWT_SECRET' WHERE type = 'jwt';

-- Check if the update was successful
SELECT type, secret FROM auth.secrets WHERE type = 'jwt';
"

# Generate a test JWT token
echo -e "${YELLOW}Generating test JWT token...${NC}"
docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "
-- Create a test function to generate a JWT token
CREATE OR REPLACE FUNCTION public.generate_test_token() RETURNS TEXT AS \$\$
DECLARE
  _token TEXT;
BEGIN
  -- This generates a token with service_role
  SELECT sign(
    json_build_object(
      'role', 'service_role',
      'iat', extract(epoch from now())::integer,
      'exp', extract(epoch from now() + interval '1 hour')::integer
    ),
    current_setting('app.settings.jwt_secret')
  ) INTO _token;
  
  RETURN _token;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set the JWT secret for the session
SET LOCAL app.settings.jwt_secret = '$JWT_SECRET';

-- Generate and display a test token
SELECT public.generate_test_token() AS test_token;
"

# Restart the Supabase services
echo -e "${YELLOW}Restarting Supabase services...${NC}"
docker restart alfred-agent-platform-v2-supabase-auth-1
docker restart alfred-agent-platform-v2-supabase-rest-1
docker restart alfred-agent-platform-v2-supabase-realtime-1

# Wait for services to restart
echo -e "${YELLOW}Waiting for services to restart...${NC}"
sleep 10

# Set the correct JWT secret in the auth config
echo -e "${YELLOW}Updating JWT secret in auth config...${NC}"
docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "
-- Verify the auth.config table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'auth' 
  AND table_name = 'config'
) AS config_table_exists;

-- Update the JWT config if the table exists
DO \$\$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'auth' 
    AND table_name = 'config'
  ) THEN
    UPDATE auth.config SET jwt_secret = '$JWT_SECRET';
    RAISE NOTICE 'Updated JWT secret in auth.config';
  ELSE
    RAISE NOTICE 'auth.config table does not exist';
  END IF;
END \$\$;
"

# Update all environment variables
echo -e "${YELLOW}Updating environment variables for all services...${NC}"
for service in "alfred-agent-platform-v2-supabase-auth-1" "alfred-agent-platform-v2-supabase-rest-1" "alfred-agent-platform-v2-supabase-realtime-1" "alfred-agent-platform-v2-atlas-1" "alfred-agent-platform-v2-alfred-bot-1" "alfred-agent-platform-v2-rag-gateway-1"; do
  docker exec $service /bin/sh -c "
    # Add environment variables if they don't exist
    export JWT_SECRET=$JWT_SECRET
    export ANON_KEY=$ANON_KEY
    export SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
    export SUPABASE_URL=$SUPABASE_URL
    export SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY

    # Try to persist them if possible
    if [ -d /etc/profile.d ]; then
      echo 'export JWT_SECRET=$JWT_SECRET' > /etc/profile.d/jwt.sh
      echo 'export ANON_KEY=$ANON_KEY' >> /etc/profile.d/jwt.sh
      echo 'export SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY' >> /etc/profile.d/jwt.sh
      echo 'export SUPABASE_URL=$SUPABASE_URL' >> /etc/profile.d/jwt.sh
      echo 'export SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY' >> /etc/profile.d/jwt.sh
      chmod +x /etc/profile.d/jwt.sh
    fi
  " || echo "Failed to update environment for $service"
done

echo -e "${GREEN}✅ JWT secret has been updated in the database.${NC}"
echo -e "${YELLOW}Run the test-auth.sh script again to verify the fix.${NC}"