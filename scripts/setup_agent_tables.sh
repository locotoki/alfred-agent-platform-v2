#!/usr/bin/env bash
# Generic script template for setting up agent tables in Supabase
# Usage: ./setup_agent_tables.sh [agent_name]
set -e

# Get agent name from command line or default to "agent"
AGENT=${1:-agent}
echo "Setting up tables for $AGENT agent..."

# Load environment variables
if [ -f ".env.dev" ]; then
  export $(grep -v '^#' .env.dev | xargs)
elif [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Check for required environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo "Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set"
  echo "Please create a .env or .env.dev file with these values"
  exit 1
fi

echo "Configuring Supabase tables for $AGENT..."

# Table names based on agent name
IN_TABLE="${AGENT}_in"
OUT_TABLE="${AGENT}_out" 

# Check if tables exist first
TABLE_CHECK=$(curl -s -X GET \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "${SUPABASE_URL}/rest/v1/$IN_TABLE?select=id&limit=1")

# If tables don't exist or we get an error, create them
if [[ "$TABLE_CHECK" == *"error"* ]] || [[ "$TABLE_CHECK" == "[]" ]]; then
  echo "Creating $IN_TABLE and $OUT_TABLE tables..."
  
  # Create publication if it doesn't exist
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"${AGENT}_publication\"}" \
    "${SUPABASE_URL}/rest/v1/rpc/create_publication_if_not_exists" > /dev/null
  
  # Create input table
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$IN_TABLE\", \"columns\": [{\"name\": \"id\", \"type\": \"uuid\", \"primary\": true}, {\"name\": \"data\", \"type\": \"jsonb\"}]}" \
    "${SUPABASE_URL}/rest/v1/rpc/create_table_if_not_exists" > /dev/null

  # Create output table
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$OUT_TABLE\", \"columns\": [{\"name\": \"id\", \"type\": \"uuid\", \"primary\": true}, {\"name\": \"data\", \"type\": \"jsonb\"}]}" \
    "${SUPABASE_URL}/rest/v1/rpc/create_table_if_not_exists" > /dev/null

  # Verify tables were created successfully
  echo "Verifying table access..."
  TABLE_IN_CHECK=$(curl -s -X GET \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    "${SUPABASE_URL}/rest/v1/$IN_TABLE?select=id&limit=1")

  TABLE_OUT_CHECK=$(curl -s -X GET \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    "${SUPABASE_URL}/rest/v1/$OUT_TABLE?select=id&limit=1")

  if [[ "$TABLE_IN_CHECK" == *"error"* ]] || [[ "$TABLE_OUT_CHECK" == *"error"* ]]; then
    echo "⚠️ Warning: Tables were created but there might be an issue accessing them."
    echo "Please check your Supabase configuration and service role key."
  else
    echo "✓ Tables verified and accessible"
  fi
  
  # Verify write access with a test record
  echo "Verifying write access..."
  TEST_ID=$(uuidgen || echo "test-$(date +%s)")
  TEST_WRITE=$(curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{\"id\":\"${TEST_ID}\",\"data\":{\"test\":\"setup-verification\"}}" \
    "${SUPABASE_URL}/rest/v1/$OUT_TABLE")
    
  if [[ "$TEST_WRITE" == *"error"* ]]; then
    echo "⚠️ Warning: Cannot write to tables. Permission issues may exist."
    echo "Creating RLS policies..."
  else
    echo "✓ Write access verified"
    
    # Clean up test record
    curl -s -X DELETE \
      -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
      "${SUPABASE_URL}/rest/v1/$OUT_TABLE?id=eq.${TEST_ID}" > /dev/null
  fi
  
  # Add tables to publication
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"publication\": \"${AGENT}_publication\", \"tables\": [\"$IN_TABLE\", \"$OUT_TABLE\"]}" \
    "${SUPABASE_URL}/rest/v1/rpc/add_tables_to_publication" > /dev/null
  
  echo "✅ Tables created successfully"
else
  echo "✅ Tables already exist"
fi

# Create appropriate RLS policies (read-only for anon, full access for service role)
echo "Setting up RLS policies..."

# Enable RLS on tables
curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"table\": \"$IN_TABLE\", \"enable\": true}" \
  "${SUPABASE_URL}/rest/v1/rpc/set_rls" > /dev/null

curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"table\": \"$OUT_TABLE\", \"enable\": true}" \
  "${SUPABASE_URL}/rest/v1/rpc/set_rls" > /dev/null

# Create RLS policy for service_role (all permissions)
curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"table\": \"$IN_TABLE\", \"name\": \"service_role_all\", \"definition\": \"true\", \"action\": \"ALL\", \"role\": \"service_role\"}" \
  "${SUPABASE_URL}/rest/v1/rpc/create_policy_if_not_exists" > /dev/null

curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"table\": \"$OUT_TABLE\", \"name\": \"service_role_all\", \"definition\": \"true\", \"action\": \"ALL\", \"role\": \"service_role\"}" \
  "${SUPABASE_URL}/rest/v1/rpc/create_policy_if_not_exists" > /dev/null

# Create RLS policy for reading output (anyone can read)
curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"table\": \"$OUT_TABLE\", \"name\": \"anon_read\", \"definition\": \"true\", \"action\": \"SELECT\", \"role\": \"anon\"}" \
  "${SUPABASE_URL}/rest/v1/rpc/create_policy_if_not_exists" > /dev/null

echo "✅ RLS policies configured"
echo "✅ Supabase setup complete for $AGENT agent"
echo "$AGENT agent can now use Supabase for message persistence"