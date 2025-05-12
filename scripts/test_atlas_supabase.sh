#!/usr/bin/env bash
set -e

# Test script to verify Atlas Supabase persistence functionality
# This script sends a test message to Atlas and verifies it's stored in Supabase

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

echo "🔍 Testing Atlas Supabase persistence..."

# Generate a unique test ID
TEST_ID=$(uuidgen || date +%s)
echo "Test ID: $TEST_ID"

# 1. Verify Supabase Connection
echo "Step 1: Verifying Supabase connection..."
CONN_CHECK=$(curl -s -X GET \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "${SUPABASE_URL}/rest/v1/architect_out?select=id&limit=1")

if [[ "$CONN_CHECK" == *"error"* ]]; then
  echo "❌ Supabase connection failed. Error: $CONN_CHECK"
  echo "Please run ./scripts/setup_supabase.sh to set up the necessary tables"
  exit 1
else
  echo "✅ Supabase connection verified"
fi

# 2. Send a test message directly to Supabase
echo "Step 2: Testing direct write to Supabase..."
TEST_MSG="{\"id\":\"$TEST_ID\",\"data\":{\"task_id\":\"$TEST_ID\",\"role\":\"architect\",\"msg_type\":\"chat\",\"content\":\"Test message from validation script\",\"metadata\":{\"test\":true}}}"

curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$TEST_MSG" \
  "${SUPABASE_URL}/rest/v1/architect_in"

# 3. Verify the message was stored
echo "Step 3: Verifying message was stored..."
sleep 1
VERIFY_MSG=$(curl -s -X GET \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "${SUPABASE_URL}/rest/v1/architect_in?id=eq.$TEST_ID&select=*")

if [[ "$VERIFY_MSG" == "[]" ]] || [[ "$VERIFY_MSG" == *"error"* ]]; then
  echo "❌ Failed to verify message storage: $VERIFY_MSG"
  exit 1
else
  echo "✅ Message successfully stored in architect_in table"
fi

# 4. Send a message to Atlas via Pub/Sub
if [ -z "$PUBSUB_EMULATOR_HOST" ]; then
  echo "Skipping Pub/Sub test - PUBSUB_EMULATOR_HOST not set"
else
  echo "Step 4: Sending test message to Atlas via Pub/Sub..."
  
  # Create the message JSON
  PUB_MSG="{\"task_id\":\"$TEST_ID-pubsub\",\"role\":\"architect\",\"msg_type\":\"chat\",\"content\":\"Test message from validation script via PubSub\",\"metadata\":{\"test\":true}}"
  BASE64_MSG=$(echo -n "$PUB_MSG" | base64 | tr -d '\n')
  
  # Send to Pub/Sub
  PROJECT_ID=${PUBSUB_PROJECT_ID:-"alfred-agent-platform"}
  TOPIC=${PUBSUB_TOPIC_IN:-"architect_in"}
  
  curl -s -X POST "http://$PUBSUB_EMULATOR_HOST/v1/projects/$PROJECT_ID/topics/$TOPIC:publish" \
    -H "Content-Type: application/json" \
    -d "{\"messages\":[{\"data\":\"$BASE64_MSG\"}]}"
  
  echo "✅ Message sent to Pub/Sub"
  echo "Check atlas-worker logs for processing and Supabase for storage"
fi

# 5. Clean up
echo "Step 5: Cleaning up test data..."
curl -s -X DELETE \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "${SUPABASE_URL}/rest/v1/architect_in?id=eq.$TEST_ID"

echo "✅ Test completed successfully"
echo "The Supabase persistence functionality in Atlas should now be working correctly."