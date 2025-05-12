#!/bin/bash
# Setup script for legal-compliance Supabase tables
# Creates necessary tables and sets up RLS policies

set -e

# Configuration
SUPABASE_URL=${SUPABASE_URL:-"http://localhost:3000"}
SUPABASE_KEY=${SUPABASE_SERVICE_ROLE_KEY:-"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvbWVrZXkiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjQ1NjQ4ODQ3LCJleHAiOjE2NjEyMDA4NDd9.secretkey"}

echo "Setting up legal-compliance Supabase tables at $SUPABASE_URL"

# Create legal_in table for incoming tasks
echo "Creating legal_in table..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_table_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_in",
    "columns": [
      {"name": "id", "type": "uuid", "is_primary": true},
      {"name": "data", "type": "jsonb"},
      {"name": "created_at", "type": "timestamptz", "default": "now()"},
      {"name": "tenant_id", "type": "text", "default": "null"}
    ]
  }'

# Create legal_out table for completed tasks
echo "Creating legal_out table..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_table_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_out",
    "columns": [
      {"name": "id", "type": "uuid", "is_primary": true},
      {"name": "data", "type": "jsonb"},
      {"name": "created_at", "type": "timestamptz", "default": "now()"},
      {"name": "tenant_id", "type": "text", "default": "null"}
    ]
  }'

# Create RLS policies for legal_in table
echo "Creating RLS policies for legal_in table..."

# Enable RLS for legal_in
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/enable_rls" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_in"
  }'

# Create service role policy for legal_in
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_policy_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_in",
    "policy_name": "Service role full access",
    "definition": "true",
    "check_type": "ALL",
    "for_role": "service_role"
  }'

# Create authenticated user policy with tenant isolation for legal_in
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_policy_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_in",
    "policy_name": "Tenant isolation for authenticated users",
    "definition": "tenant_id = auth.uid() OR (data->>\"tenant_id\")::text = auth.uid()::text",
    "check_type": "ALL"
  }'

# Create RLS policies for legal_out table
echo "Creating RLS policies for legal_out table..."

# Enable RLS for legal_out
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/enable_rls" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_out"
  }'

# Create service role policy for legal_out
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_policy_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_out",
    "policy_name": "Service role full access",
    "definition": "true",
    "check_type": "ALL",
    "for_role": "service_role"
  }'

# Create authenticated user policy with tenant isolation for legal_out
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_policy_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_out",
    "policy_name": "Tenant isolation for authenticated users",
    "definition": "tenant_id = auth.uid() OR (data->>\"tenant_id\")::text = auth.uid()::text",
    "check_type": "ALL"
  }'

# Add indexes for faster lookups
echo "Adding indexes..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_index_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_in",
    "index_name": "legal_in_tenant_id_idx",
    "column_name": "tenant_id"
  }'

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_index_if_not_exists" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "table_name": "legal_out",
    "index_name": "legal_out_tenant_id_idx",
    "column_name": "tenant_id"
  }'

echo "Setup completed successfully!"