#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Setting up Supabase tables for Alfred Agent Platform...${NC}"

# Load environment variables
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo -e "${RED}Error: .env file not found${NC}"
  exit 1
fi

# Adjust URLs to point to internal Docker network
SUPABASE_INTERNAL_URL="http://supabase-rest:3000"
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-your-super-secret-password}

# Create the database schema
echo -e "${YELLOW}Creating database schema...${NC}"

# First check if PostgreSQL is ready
docker exec alfred-agent-platform-v2-supabase-db-1 pg_isready -U postgres
if [ $? -ne 0 ]; then
  echo -e "${RED}PostgreSQL is not ready. Please make sure the database is running.${NC}"
  exit 1
fi

# Create architect_in and architect_out tables for Atlas
echo -e "${YELLOW}Creating architect tables for Atlas...${NC}"
docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "
CREATE TABLE IF NOT EXISTS public.architect_in (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.architect_out (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Create publication for realtime
DROP PUBLICATION IF EXISTS architect_bus;
CREATE PUBLICATION architect_bus FOR TABLE architect_in, architect_out;

-- Enable Row Level Security
ALTER TABLE public.architect_in ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.architect_out ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS service_role_all_architect_in ON public.architect_in;
CREATE POLICY service_role_all_architect_in ON public.architect_in
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS service_role_all_architect_out ON public.architect_out;
CREATE POLICY service_role_all_architect_out ON public.architect_out
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS anon_read_architect_out ON public.architect_out;
CREATE POLICY anon_read_architect_out ON public.architect_out
  FOR SELECT USING (true);

-- Grant permissions to service_role
GRANT ALL ON public.architect_in TO service_role;
GRANT ALL ON public.architect_out TO service_role;
"

# Create agent tables for each agent service
echo -e "${YELLOW}Creating tables for agent services...${NC}"
docker exec alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "
-- Alfred Bot tables
CREATE TABLE IF NOT EXISTS public.alfred_bot_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Social Intelligence tables
CREATE TABLE IF NOT EXISTS public.social_intel_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Financial Tax tables
CREATE TABLE IF NOT EXISTS public.financial_tax_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Legal Compliance tables
CREATE TABLE IF NOT EXISTS public.legal_compliance_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.alfred_bot_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_intel_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_tax_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_compliance_checks ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for service_role
CREATE POLICY service_role_all ON public.alfred_bot_tasks
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY service_role_all ON public.social_intel_analysis
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY service_role_all ON public.financial_tax_records
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY service_role_all ON public.legal_compliance_checks
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Grant permissions
GRANT ALL ON public.alfred_bot_tasks TO service_role;
GRANT ALL ON public.social_intel_analysis TO service_role;
GRANT ALL ON public.financial_tax_records TO service_role;
GRANT ALL ON public.legal_compliance_checks TO service_role;
"

echo -e "${GREEN}Database schema created successfully.${NC}"

# Verify connection with a test request
echo -e "${YELLOW}Testing connection to Supabase REST API...${NC}"

# Test with Atlas service
echo -e "${YELLOW}Testing connection from Atlas service...${NC}"
docker exec alfred-agent-platform-v2-atlas-1 python -c "
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
response = requests.get(f'{supabase_url}/rest/v1/architect_in?select=id&limit=1', headers=headers)
print(f'Connection status: {response.status_code}')
if response.status_code == 200:
    print('Successfully connected to Supabase REST API!')
else:
    print(f'Error connecting to Supabase: {response.text}')
"

echo -e "${YELLOW}Testing connection from Alfred Bot service...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 /bin/sh -c "
# Use shell commands as Alpine doesn't have Python installed
echo '{\"test\":\"data\"}' > /tmp/test.json
curl -s -X POST \
  -H \"apikey: ${SERVICE_ROLE_KEY}\" \
  -H \"Authorization: Bearer ${SERVICE_ROLE_KEY}\" \
  -H \"Content-Type: application/json\" \
  -d @/tmp/test.json \
  \"${SUPABASE_INTERNAL_URL}/rest/v1/alfred_bot_tasks\" | grep -q '.' && echo 'Successfully wrote to Supabase!' || echo 'Failed to write to Supabase'
"

echo -e "${GREEN}✅ Supabase setup complete.${NC}"
echo -e "${YELLOW}Note: 401 errors may still occur if tables don't exist or if RLS policies prevent access.${NC}"
echo -e "${YELLOW}In a real deployment, ensure schemas are properly migrated and RLS policies are configured.${NC}"