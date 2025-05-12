#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Updating JWT configuration for Supabase REST...${NC}"

# Get the current directory
DIR=$(pwd)
JWT_SECRET=$(grep JWT_SECRET .env | cut -d= -f2)
SERVICE_ROLE_KEY=$(grep SERVICE_ROLE_KEY .env | cut -d= -f2)
ANON_KEY=$(grep ANON_KEY .env | cut -d= -f2)

# Create a configuration file for PostgREST
cat > ${DIR}/postgrest.conf << EOF
# PostgREST configuration file
db-uri = "postgres://authenticator:authenticatorpass@supabase-db:5432/postgres"
db-schema = "public"
db-anon-role = "anon"
db-pool = 10
server-host = "0.0.0.0"
server-port = 3000
jwt-secret = "${JWT_SECRET}"
secret-is-base64 = false
EOF

# Copy the configuration to the PostgREST container
echo -e "${YELLOW}Copying configuration to Supabase REST...${NC}"
docker cp ${DIR}/postgrest.conf alfred-agent-platform-v2-supabase-rest-1:/etc/postgrest.conf || echo "Failed to copy postgrest.conf"

# Restart the REST service
echo -e "${YELLOW}Restarting Supabase REST...${NC}"
docker restart alfred-agent-platform-v2-supabase-rest-1

# Wait for REST service to restart
echo -e "${YELLOW}Waiting for REST service to restart...${NC}"
sleep 5

# Update GoTrue JWT configuration
echo -e "${YELLOW}Updating GoTrue JWT configuration...${NC}"

# Get a new token from the database
echo -e "${YELLOW}Generating new token from database...${NC}"
NEW_TOKEN=$(docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -t -c "SELECT public.generate_service_token();")
NEW_TOKEN=$(echo $NEW_TOKEN | tr -d '[:space:]')

if [ -n "$NEW_TOKEN" ]; then
  echo -e "${GREEN}Generated new token: ${NEW_TOKEN}${NC}"
  
  # Update token in environment
  echo -e "${YELLOW}Updating token in environment...${NC}"
  sed -i "s|^SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=${NEW_TOKEN}|" .env
  
  echo -e "${YELLOW}Updating agent service environment variables...${NC}"
  
  # Update environment variables in all agent containers
  for container in $(docker ps --format '{{.Names}}' | grep alfred-agent-platform-v2 | grep -v supabase-db); do
    echo -e "${YELLOW}Updating ${container}...${NC}"
    docker exec $container /bin/sh -c "export SUPABASE_SERVICE_ROLE_KEY='${NEW_TOKEN}'" || echo "Failed to update ${container}"
  done
else
  echo -e "${RED}Failed to generate new token${NC}"
fi

# Test the authentication with the new token
echo -e "${YELLOW}Testing authentication with new token...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  apk add --no-cache curl jq >/dev/null 2>&1 || true
  
  # Test accessing a table with service role
  curl -s -X GET \
    -H \"apikey: ${NEW_TOKEN}\" \
    -H \"Authorization: Bearer ${NEW_TOKEN}\" \
    \"http://supabase-rest:3000/rest/v1/service_role_test?select=*\" | jq . || echo 'Auth test failed'
"

echo -e "${GREEN}✅ JWT configuration has been updated.${NC}"