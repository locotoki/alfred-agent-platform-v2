#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Testing Supabase authentication with updated token...${NC}"

# Get the token from the database
echo -e "${YELLOW}Getting token from database...${NC}"
TOKEN=$(docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -t -c "SELECT public.generate_service_token();")
TOKEN=$(echo $TOKEN | tr -d '[:space:]')

echo -e "${YELLOW}New token: ${TOKEN}${NC}"

# Update the postgrest.conf file
echo -e "${YELLOW}Updating PostgREST configuration...${NC}"
cat > ./postgrest.conf << EOF
# PostgREST configuration file
db-uri = "postgres://authenticator:authenticatorpass@supabase-db:5432/postgres"
db-schema = "public"
db-anon-role = "anon"
db-pool = 10
server-host = "0.0.0.0"
server-port = 3000
jwt-secret = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o"
secret-is-base64 = false
EOF

# Copy the configuration to the PostgREST container
docker cp ./postgrest.conf alfred-agent-platform-v2-supabase-rest-1:/etc/postgrest.conf || true

# Restart the REST service
echo -e "${YELLOW}Restarting Supabase REST...${NC}"
docker restart alfred-agent-platform-v2-supabase-rest-1

# Wait for REST service to restart
sleep 5

# Install curl in the alpine containers
echo -e "${YELLOW}Installing curl in Alfred Bot container...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "apk add --no-cache curl jq >/dev/null 2>&1 || true"

# Test with the service role token
echo -e "${YELLOW}Testing with service role token...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  # Test the auth endpoint with the service role token
  echo 'Testing authentication...'
  curl -s -X GET \
    -H \"apikey: $TOKEN\" \
    -H \"Authorization: Bearer $TOKEN\" \
    \"http://supabase-rest:3000/rest/v1/rpc/test_auth\" || echo 'Auth test failed'

  # Test creating a record
  echo 'Testing writing to database...'
  echo '{\"data\":\"test data\"}' > /tmp/test_data.json
  curl -s -X POST \
    -H \"apikey: $TOKEN\" \
    -H \"Authorization: Bearer $TOKEN\" \
    -H \"Content-Type: application/json\" \
    -d @/tmp/test_data.json \
    \"http://supabase-rest:3000/rest/v1/service_role_test\" || echo 'Write test failed'
"

echo -e "${GREEN}✅ Authentication tests complete.${NC}"
