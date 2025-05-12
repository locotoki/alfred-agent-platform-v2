#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Updating service configurations with new JWT tokens...${NC}"

# Load environment variables
source .env

echo -e "${YELLOW}Stopping all services to update configurations...${NC}"
docker-compose -f docker-compose.combined-fixed.yml down

echo -e "${YELLOW}Creating Docker network...${NC}"
docker network create alfred-network 2>/dev/null || true

echo -e "${YELLOW}Updating environment variables in all services...${NC}"
# Create a temporary .env file for docker-compose
cat > .env.updated << EOF
# Environment
ENVIRONMENT=development
DEBUG=true

# Database
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_DB=${POSTGRES_DB}
DATABASE_URL=${DATABASE_URL}

# Supabase
JWT_SECRET=${JWT_SECRET}
ANON_KEY=${ANON_KEY}
SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_PUBLIC_URL=${SUPABASE_PUBLIC_URL}

# Authentication
SITE_URL=${SITE_URL}
ADDITIONAL_REDIRECT_URLS=${ADDITIONAL_REDIRECT_URLS}
DISABLE_SIGNUP=${DISABLE_SIGNUP}
JWT_EXPIRY=${JWT_EXPIRY}

# OpenAI
OPENAI_API_KEY=${OPENAI_API_KEY}

# Monitoring
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
PROMETHEUS_RETENTION_TIME=${PROMETHEUS_RETENTION_TIME}

# Security
API_KEY_SALT=${API_KEY_SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}

# Supabase Realtime
SECRET_KEY_BASE=${SECRET_KEY_BASE}
APP_NAME=${APP_NAME}
EOF

# Replace the current .env file
mv .env.updated .env

echo -e "${YELLOW}Starting core services first...${NC}"
docker-compose -f docker-compose.combined-fixed.yml up -d supabase-db supabase-rest

# Wait for the database to be ready
echo -e "${YELLOW}Waiting for database to be ready...${NC}"
sleep 10

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

# Restart the REST service
echo -e "${YELLOW}Restarting Supabase REST...${NC}"
docker restart alfred-agent-platform-v2-supabase-rest-1

# Wait for REST service to restart
sleep 5

echo -e "${YELLOW}Starting other services...${NC}"
docker-compose -f docker-compose.combined-fixed.yml up -d

# Wait for services to stabilize
sleep 15

echo -e "${YELLOW}Testing connection with new tokens...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  apk add --no-cache curl jq >/dev/null 2>&1 || true
  
  # Test with the token from the environment
  echo 'Testing connection to Supabase REST API...'
  curl -s -X GET \
    -H \"apikey: ${SERVICE_ROLE_KEY}\" \
    -H \"Authorization: Bearer ${SERVICE_ROLE_KEY}\" \
    \"http://supabase-rest:3000/rest/v1/service_role_test?select=*\" | jq . || echo 'Connection test failed'
    
  # Test writing to a table
  echo 'Testing write to architect_in table...'
  echo '{\"data\":{\"message\":\"test from update script\"}}' > /tmp/test.json
  curl -s -X POST \
    -H \"apikey: ${SERVICE_ROLE_KEY}\" \
    -H \"Authorization: Bearer ${SERVICE_ROLE_KEY}\" \
    -H \"Content-Type: application/json\" \
    -d @/tmp/test.json \
    \"http://supabase-rest:3000/rest/v1/architect_in\" | jq . || echo 'Write test failed'
"

echo -e "${GREEN}✅ Services updated with new JWT tokens.${NC}"
echo -e "${YELLOW}Note: If still seeing authentication issues, you may need to completely restart all services.${NC}"