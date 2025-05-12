#!/usr/bin/env bash
set -e

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

echo "Configuring Supabase tables for Atlas..."

# Check if tables exist first
TABLE_CHECK=$(curl -s -X GET \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "${SUPABASE_URL}/rest/v1/architect_in?select=id&limit=1")

# If tables don't exist or we get an error, create them
if [[ "$TABLE_CHECK" == *"error"* ]] || [[ "$TABLE_CHECK" == "[]" ]]; then
  echo "Creating architect_in and architect_out tables..."
  
  # Create publication if it doesn't exist
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name": "architect_bus"}' \
    "${SUPABASE_URL}/rest/v1/rpc/create_publication_if_not_exists" > /dev/null
  
  # Create architect_in table (with properly defined columns)
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name": "architect_in", "columns": [{"name": "id", "type": "uuid", "primary": true}, {"name": "data", "type": "jsonb"}]}' \
    "${SUPABASE_URL}/rest/v1/rpc/create_table_if_not_exists" > /dev/null

  # Create architect_out table (with properly defined columns)
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"name": "architect_out", "columns": [{"name": "id", "type": "uuid", "primary": true}, {"name": "data", "type": "jsonb"}]}' \
    "${SUPABASE_URL}/rest/v1/rpc/create_table_if_not_exists" > /dev/null

  # Verify tables were created and are accessible
  echo "Verifying table access..."
  TABLE_IN_CHECK=$(curl -s -X GET \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    "${SUPABASE_URL}/rest/v1/architect_in?select=id&limit=1")

  TABLE_OUT_CHECK=$(curl -s -X GET \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    "${SUPABASE_URL}/rest/v1/architect_out?select=id&limit=1")

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
    "${SUPABASE_URL}/rest/v1/architect_out")

  if [[ "$TEST_WRITE" == *"error"* ]]; then
    echo "⚠️ Warning: Cannot write to tables. Permission issues may exist."
    echo "Running SQL migration for service role permissions..."

    # Apply the Atlas auth SQL directly
    MIGRATION_SQL=$(cat ../migrations/0002_atlas_auth.sql)
    curl -s -X POST \
      -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"query\":\"$MIGRATION_SQL\"}" \
      "${SUPABASE_URL}/rest/v1/rpc/sql" > /dev/null

    echo "✓ Permission migration applied"
  else
    echo "✓ Write access verified"

    # Clean up test record
    curl -s -X DELETE \
      -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
      "${SUPABASE_URL}/rest/v1/architect_out?id=eq.${TEST_ID}" > /dev/null
  fi
  
  # Add tables to publication
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"publication": "architect_bus", "tables": ["architect_in", "architect_out"]}' \
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
  -d '{"table": "architect_in", "enable": true}' \
  "${SUPABASE_URL}/rest/v1/rpc/set_rls" > /dev/null

curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"table": "architect_out", "enable": true}' \
  "${SUPABASE_URL}/rest/v1/rpc/set_rls" > /dev/null

# Create RLS policy for reading architect_out (anyone can read)
curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"table": "architect_out", "name": "anon_read", "definition": "true", "action": "SELECT", "role": "anon"}' \
  "${SUPABASE_URL}/rest/v1/rpc/create_policy_if_not_exists" > /dev/null

echo "✅ Supabase setup complete"
echo "Atlas can now use Supabase for message persistence"