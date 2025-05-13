#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Creating new JWT tokens for Supabase...${NC}"

# Generate a new JWT secret
echo -e "${YELLOW}Generating new JWT secret...${NC}"
JWT_SECRET=$(docker exec alfred-agent-platform-v2-supabase-db-1 openssl rand -base64 32)
echo "New JWT_SECRET: $JWT_SECRET"

# Save the new secret to .env
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env

# Create anon and service role tokens with the new secret
echo -e "${YELLOW}Creating anon and service role tokens...${NC}"

# Create the tokens with the new secret
docker exec alfred-agent-platform-v2-supabase-db-1 bash -c "
  # Install necessary tools
  apt-get update >/dev/null 2>&1
  apt-get install -y python3 python3-pip >/dev/null 2>&1
  pip3 install pyjwt >/dev/null 2>&1
  
  python3 -c \"
import jwt
import time
import sys

# Set the secret
secret = '$JWT_SECRET'

# Create the payload for anon token
anon_payload = {
    'role': 'anon',
    'iat': int(time.time()),
    'exp': int(time.time()) + 100 * 365 * 24 * 60 * 60  # 100 years
}

# Create the payload for service role token
service_payload = {
    'role': 'service_role',
    'iat': int(time.time()),
    'exp': int(time.time()) + 100 * 365 * 24 * 60 * 60  # 100 years
}

# Create the tokens
anon_token = jwt.encode(anon_payload, secret, algorithm='HS256')
service_token = jwt.encode(service_payload, secret, algorithm='HS256')

# Write the tokens
print('ANON_KEY=' + anon_token)
print('SERVICE_ROLE_KEY=' + service_token)
  \"
" > jwt_tokens.txt

# Update .env with the new tokens
ANON_KEY=$(grep "ANON_KEY=" jwt_tokens.txt | cut -d= -f2)
SERVICE_ROLE_KEY=$(grep "SERVICE_ROLE_KEY=" jwt_tokens.txt | cut -d= -f2)

echo "New ANON_KEY: $ANON_KEY"
echo "New SERVICE_ROLE_KEY: $SERVICE_ROLE_KEY"

sed -i "s|^ANON_KEY=.*|ANON_KEY=$ANON_KEY|" .env
sed -i "s|^SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|" .env

echo -e "${YELLOW}Updating PostgREST configuration...${NC}"
cat > ./postgrest.conf << EOF
# PostgREST configuration file
db-uri = "postgres://authenticator:authenticatorpass@supabase-db:5432/postgres"
db-schema = "public, auth"
db-anon-role = "anon"
db-pool = 10
server-host = "0.0.0.0"
server-port = 3000
jwt-secret = "${JWT_SECRET}"
secret-is-base64 = false
EOF

# Copy the configuration to the PostgREST container
docker cp ./postgrest.conf alfred-agent-platform-v2-supabase-rest-1:/etc/postgrest.conf || true

# Update authentification config in the database
echo -e "${YELLOW}Updating authentication config in database...${NC}"
cat > ./update_auth.sql << EOF
-- Update auth.config with the new JWT secret if the table exists
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

-- Set the database parameter
ALTER DATABASE postgres SET "app.jwt_secret" TO '$JWT_SECRET';
EOF

cat ./update_auth.sql | docker exec -i alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres

# Restart the auth and REST services
echo -e "${YELLOW}Restarting Supabase services...${NC}"
docker restart alfred-agent-platform-v2-supabase-auth-1
docker restart alfred-agent-platform-v2-supabase-rest-1

# Wait for services to restart
sleep 5

# Test the new token
echo -e "${YELLOW}Testing with new service role token...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  apk add --no-cache curl jq >/dev/null 2>&1 || true
  
  # Set environment variables
  export SUPABASE_SERVICE_ROLE_KEY='$SERVICE_ROLE_KEY'
  
  # Test writing to architect_in table
  echo 'Testing write to architect_in table...'
  echo '{\"data\":{\"message\":\"test message with new token\"}}' > /tmp/test_data.json
  curl -s -X POST \
    -H \"apikey: \$SUPABASE_SERVICE_ROLE_KEY\" \
    -H \"Authorization: Bearer \$SUPABASE_SERVICE_ROLE_KEY\" \
    -H \"Content-Type: application/json\" \
    -d @/tmp/test_data.json \
    \"http://supabase-rest:3000/rest/v1/architect_in\" | jq . || echo 'Write to architect_in failed'
"

echo -e "${GREEN}✅ New JWT tokens created and tested.${NC}"