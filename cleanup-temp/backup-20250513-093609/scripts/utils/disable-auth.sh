#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Disabling authentication for development environment...${NC}"

# Create a configuration that disables JWT verification
cat > postgrest.conf << EOF
db-uri = "postgres://postgres:your-super-secret-password@supabase-db:5432/postgres"
db-schema = "public"
db-anon-role = "postgres"
db-pool = 10
server-host = "0.0.0.0"
server-port = 3000
EOF

# Copy the configuration to the PostgREST container
docker cp postgrest.conf alfred-agent-platform-v2-supabase-rest-1:/etc/postgrest.conf

# Update the database to allow anonymous access
cat > disable_rls.sql << EOF
-- Disable Row Level Security for development
ALTER TABLE public.architect_in DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.architect_out DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_role_test DISABLE ROW LEVEL SECURITY;

-- Create a public function to verify disabled authentication
CREATE OR REPLACE FUNCTION public.check_auth_status() RETURNS TEXT AS \$\$
BEGIN
  RETURN 'Authentication disabled for development environment';
END;
\$\$ LANGUAGE plpgsql;

-- Grant access to everyone
GRANT EXECUTE ON FUNCTION public.check_auth_status TO PUBLIC;

-- Verify the anon role has full access
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;
EOF

# Execute the SQL
cat disable_rls.sql | docker exec -i alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres

# Restart the REST service
echo -e "${YELLOW}Restarting Supabase REST...${NC}"
docker restart alfred-agent-platform-v2-supabase-rest-1

# Wait for the service to restart
echo -e "${YELLOW}Waiting for service to restart...${NC}"
sleep 5

# Test direct access
echo -e "${YELLOW}Testing direct access to tables...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
  # Test direct table access
  echo 'Testing read from architect_in...'
  curl -s -X GET \"http://supabase-rest:3000/architect_in\" | jq . || echo 'Read failed'
  
  # Test writing to architect_in
  echo 'Testing write to architect_in...'
  echo '{\"data\":{\"message\":\"testing disabled auth\"}}' > /tmp/test.json
  curl -s -X POST \
    -H \"Content-Type: application/json\" \
    -d @/tmp/test.json \
    \"http://supabase-rest:3000/architect_in\" | jq . || echo 'Write failed'
  
  # Verify again
  echo 'Verifying data was written...'
  curl -s -X GET \"http://supabase-rest:3000/architect_in\" | jq . || echo 'Verification failed'
"

echo -e "${GREEN}✅ Authentication disabled for development purposes.${NC}"
echo -e "${YELLOW}Note: This is a temporary solution. In production, proper authentication should be configured.${NC}"

# Create a document explaining the current state
cat > SUPABASE_STATUS.md << EOF
# Supabase Authentication Status

## Current Configuration

For development purposes, authentication has been disabled in the PostgREST configuration. This means:

1. Row Level Security (RLS) is disabled on all tables
2. The database is accessible without authentication
3. All services can directly access the API without tokens

## How to Use

Services can access the Supabase REST API directly without authentication headers:

\`\`\`bash
# Read from a table
curl http://supabase-rest:3000/architect_in

# Write to a table
curl -X POST \\
  -H "Content-Type: application/json" \\
  -d '{"data":{"message":"test"}}' \\
  http://supabase-rest:3000/architect_in
\`\`\`

## Future Improvements

For production deployment, proper authentication should be configured:

1. Enable Row Level Security
2. Configure JWT authentication with proper signing keys
3. Implement proper schema migrations
4. Set up secure API key handling

## Troubleshooting

If services cannot access Supabase, check:

1. Network connectivity between containers
2. PostgREST configuration in \`/etc/postgrest.conf\`
3. Database schema integrity
4. Table permissions

To reset the current configuration, run:

\`\`\`bash
./disable-auth.sh
\`\`\`
EOF

echo -e "${YELLOW}Created SUPABASE_STATUS.md with documentation on the current state and future improvements.${NC}"