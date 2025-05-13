#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Final Supabase authentication test...${NC}"

# Use the token from .env
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o"

echo -e "${YELLOW}Using token from .env: ${TOKEN}${NC}"

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
jwt-secret = "${TOKEN}"
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
  # Add testing for architect_in table
  echo 'Testing write to architect_in table...'
  echo '{\"data\":{\"message\":\"test message from alfred-bot\"}}' > /tmp/test_data.json
  curl -s -X POST \
    -H \"apikey: $TOKEN\" \
    -H \"Authorization: Bearer $TOKEN\" \
    -H \"Content-Type: application/json\" \
    -d @/tmp/test_data.json \
    \"http://supabase-rest:3000/rest/v1/architect_in\" | jq . || echo 'Write to architect_in failed'
  
  # Test reading from architect_in table
  echo 'Testing read from architect_in table...'
  curl -s -X GET \
    -H \"apikey: $TOKEN\" \
    -H \"Authorization: Bearer $TOKEN\" \
    \"http://supabase-rest:3000/rest/v1/architect_in?select=*\" | jq . || echo 'Read from architect_in failed'
  
  # Test alfred_bot_tasks table
  echo 'Testing write to alfred_bot_tasks table...'
  echo '{\"data\":{\"task\":\"test task\",\"status\":\"pending\"}}' > /tmp/bot_task.json
  curl -s -X POST \
    -H \"apikey: $TOKEN\" \
    -H \"Authorization: Bearer $TOKEN\" \
    -H \"Content-Type: application/json\" \
    -d @/tmp/bot_task.json \
    \"http://supabase-rest:3000/rest/v1/alfred_bot_tasks\" | jq . || echo 'Write to alfred_bot_tasks failed'
  
  # Test reading from alfred_bot_tasks table
  echo 'Testing read from alfred_bot_tasks table...'
  curl -s -X GET \
    -H \"apikey: $TOKEN\" \
    -H \"Authorization: Bearer $TOKEN\" \
    \"http://supabase-rest:3000/rest/v1/alfred_bot_tasks?select=*\" | jq . || echo 'Read from alfred_bot_tasks failed'
"

echo -e "${GREEN}✅ Final authentication tests complete.${NC}"