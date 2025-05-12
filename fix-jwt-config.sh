#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing JWT configuration for Supabase...${NC}"

# Install Alpine packages if in Alpine container
install_curl() {
  if [ -f /etc/alpine-release ]; then
    apk add --no-cache curl jq 2>/dev/null || true
  fi
}

# Get the JWT secret from the .env file
JWT_SECRET=$(grep JWT_SECRET .env | cut -d= -f2)
ANON_KEY=$(grep ANON_KEY .env | cut -d= -f2)
SERVICE_ROLE_KEY=$(grep SERVICE_ROLE_KEY .env | cut -d= -f2)

echo -e "${YELLOW}Updating JWT configuration in Supabase containers...${NC}"

# Update the JWT secret in the Supabase Auth container
docker exec alfred-agent-platform-v2-supabase-auth-1 /bin/sh -c "
  sed -i 's|JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET}|g' /app/.env
  sed -i 's|ANON_KEY=.*|ANON_KEY=${ANON_KEY}|g' /app/.env
  sed -i 's|SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}|g' /app/.env
"

# Update the JWT secret in the Supabase REST container
docker exec alfred-agent-platform-v2-supabase-rest-1 /bin/sh -c "
  sed -i 's|JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET}|g' /app/.env
  sed -i 's|ANON_KEY=.*|ANON_KEY=${ANON_KEY}|g' /app/.env
  sed -i 's|SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}|g' /app/.env
"

# Update the JWT secret in the Supabase Realtime container
docker exec alfred-agent-platform-v2-supabase-realtime-1 /bin/sh -c "
  sed -i 's|JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET}|g' /app/.env
  sed -i 's|ANON_KEY=.*|ANON_KEY=${ANON_KEY}|g' /app/.env
  sed -i 's|SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}|g' /app/.env
"

echo -e "${YELLOW}Restarting Supabase services...${NC}"
docker restart alfred-agent-platform-v2-supabase-auth-1
docker restart alfred-agent-platform-v2-supabase-rest-1
docker restart alfred-agent-platform-v2-supabase-realtime-1

echo -e "${YELLOW}Waiting for Supabase services to restart...${NC}"
sleep 10

echo -e "${YELLOW}Installing curl for API testing...${NC}"
# Install curl in the alpine containers for testing
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "apk add --no-cache curl jq 2>/dev/null || true"

echo -e "${YELLOW}Testing Supabase connection from Alfred Bot service...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  # Test connection to Supabase REST API
  curl -s -X GET \
    -H \"apikey: ${SERVICE_ROLE_KEY}\" \
    -H \"Authorization: Bearer ${SERVICE_ROLE_KEY}\" \
    \"http://supabase-rest:3000/rest/v1/alfred_bot_tasks?select=id&limit=1\" | jq . || echo 'Error connecting to Supabase'
  
  # Test writing to Supabase
  echo '{\"data\":{\"test\":\"data\"}}' > /tmp/test.json
  curl -s -X POST \
    -H \"apikey: ${SERVICE_ROLE_KEY}\" \
    -H \"Authorization: Bearer ${SERVICE_ROLE_KEY}\" \
    -H \"Content-Type: application/json\" \
    -d @/tmp/test.json \
    \"http://supabase-rest:3000/rest/v1/alfred_bot_tasks\" | jq . || echo 'Error writing to Supabase'
"

# Test the Atlas service as well
echo -e "${YELLOW}Testing Supabase connection from Atlas service...${NC}"
docker exec alfred-agent-platform-v2-atlas-1 /bin/sh -c "
  if command -v python3 >/dev/null 2>&1; then
    python3 -c \"
import requests
import os
import json

# Get environment variables
supabase_url = os.environ.get('SUPABASE_URL')
supabase_key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')

# Try to connect to Supabase
headers = {
    'apikey': supabase_key,
    'Authorization': f'Bearer {supabase_key}',
    'Content-Type': 'application/json'
}

# Try to query the architect_in table
try:
    response = requests.get(f'{supabase_url}/rest/v1/architect_in?select=id&limit=1', headers=headers)
    print(f'Connection status: {response.status_code}')
    print(f'Response: {response.text}')
except Exception as e:
    print(f'Error: {str(e)}')

# Try to insert data
try:
    data = {'data': {'message': 'test'}}
    response = requests.post(f'{supabase_url}/rest/v1/architect_in', headers=headers, json=data)
    print(f'Insert status: {response.status_code}')
    print(f'Insert response: {response.text}')
except Exception as e:
    print(f'Insert error: {str(e)}')
    \"
  else
    echo 'Python not available in Atlas container'
  fi
"

echo -e "${GREEN}✅ JWT configuration fixes applied.${NC}"
echo -e "${YELLOW}Note: If you are still seeing 401 errors, you may need to verify your tables and RLS policies.${NC}"