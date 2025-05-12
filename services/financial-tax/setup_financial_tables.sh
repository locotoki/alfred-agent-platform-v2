#!/bin/bash
# Setup script for financial-tax Supabase tables
# Creates necessary tables and sets up RLS policies

set -e

# Configuration
SUPABASE_URL=${SUPABASE_URL:-"http://localhost:3000"}
SUPABASE_KEY=${SUPABASE_SERVICE_ROLE_KEY:-"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvbWVrZXkiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjQ1NjQ4ODQ3LCJleHAiOjE2NjEyMDA4NDd9.secretkey"}

echo "Setting up financial-tax Supabase tables at $SUPABASE_URL"

# Create financial_in table for incoming tasks
echo "Creating financial_in table..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_table_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_in",
    "columns": [
      {"name": "id", "type": "uuid", "is_primary": true},
      {"name": "data", "type": "jsonb"},
      {"name": "created_at", "type": "timestamptz", "default": "now()"}
    ]
  }'

# Create financial_out table for completed tasks
echo "Creating financial_out table..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_table_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_out",
    "columns": [
      {"name": "id", "type": "uuid", "is_primary": true},
      {"name": "data", "type": "jsonb"},
      {"name": "created_at", "type": "timestamptz", "default": "now()"},
      {"name": "tenant_id", "type": "text", "default": "null"}
    ]
  }'

# Create RLS policies for financial_in table
echo "Creating RLS policies for financial_in table..."

# Enable RLS for financial_in
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/enable_rls" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_in"
  }'

# Create service role policy for financial_in
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_policy_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_in",
    "policy_name": "Service role full access",
    "definition": "true",
    "check_type": "ALL",
    "for_role": "service_role"
  }'

# Create authenticated user policy with tenant isolation for financial_in
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_policy_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_in",
    "policy_name": "Tenant isolation for authenticated users",
    "definition": "(data->>\"tenant_id\")::text = auth.uid()::text",
    "check_type": "ALL"
  }'

# Create RLS policies for financial_out table
echo "Creating RLS policies for financial_out table..."

# Enable RLS for financial_out
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/enable_rls" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_out"
  }'

# Create service role policy for financial_out
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_policy_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_out",
    "policy_name": "Service role full access",
    "definition": "true",
    "check_type": "ALL",
    "for_role": "service_role"
  }'

# Create authenticated user policy with tenant isolation for financial_out
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_policy_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_out",
    "policy_name": "Tenant isolation for authenticated users",
    "definition": "tenant_id = auth.uid() OR (data->>\"tenant_id\")::text = auth.uid()::text",
    "check_type": "ALL"
  }'

# Add index for faster lookups by tenant_id
echo "Adding index for tenant_id..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_index_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "financial_out",
    "index_name": "financial_out_tenant_id_idx",
    "column_name": "tenant_id"
  }'

echo "Setup completed successfully!"