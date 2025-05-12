#!/usr/bin/env bash
# Script for setting up social-intel agent tables in Supabase
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/.."

echo "🔍 Setting up Social Intelligence tables in Supabase"

# Run the generic setup script with the right agent name
./scripts/setup_agent_tables.sh social

# Add specialized tables for social-intel specific data

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

# Create specialized tables for social intelligence
echo "Creating specialized tables for social intelligence..."

# Create features table if it doesn't exist
FEATURES_CHECK=$(curl -s -X GET \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "${SUPABASE_URL}/rest/v1/features?select=niche_id&limit=1")

if [[ "$FEATURES_CHECK" == *"error"* ]] || [[ "$FEATURES_CHECK" == "[]" ]]; then
  echo "Creating features table..."
  
  # Execute schema SQL
  FEATURES_SQL="
  CREATE TABLE IF NOT EXISTS features (
    niche_id       BIGSERIAL PRIMARY KEY,
    phrase         TEXT UNIQUE,
    demand_score   NUMERIC(5,4),
    monetise_score NUMERIC(5,4),
    supply_score   NUMERIC(5,4),
    opportunity    NUMERIC(6,5),
    updated_at     TIMESTAMPTZ DEFAULT now()
  );
  
  CREATE INDEX IF NOT EXISTS features_phrase_idx ON features(phrase);
  CREATE INDEX IF NOT EXISTS features_opportunity_idx ON features(opportunity DESC);
  
  CREATE MATERIALIZED VIEW IF NOT EXISTS hot_niches_today AS
  SELECT *
  FROM   features
  WHERE  updated_at > now() - interval '24 hours'
  ORDER  BY opportunity DESC
  LIMIT  50;
  
  CREATE INDEX IF NOT EXISTS hot_niches_today_opportunity_idx ON hot_niches_today(opportunity DESC);
  "
  
  # Execute SQL
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$FEATURES_SQL\"}" \
    "${SUPABASE_URL}/rest/v1/rpc/sql" > /dev/null
  
  echo "✅ Features table created"
  
  # Add sample data
  echo "Adding sample data..."
  curl -s -X POST \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d '[{"phrase":"Financial Literacy Shorts","demand_score":0.8750,"monetise_score":0.9200,"supply_score":0.6500,"opportunity":1.2346},{"phrase":"DIY Home Improvement","demand_score":0.6230,"monetise_score":0.7800,"supply_score":0.5500,"opportunity":0.8829}]' \
    "${SUPABASE_URL}/rest/v1/features" > /dev/null
    
  echo "✅ Sample data added"
else
  echo "✅ Features table already exists"
fi

echo "✅ Social Intelligence tables set up successfully!"
echo "The social-intel agent can now use Supabase for persistence"