#!/bin/bash

echo "Checking Alfred - Streamlit Integration..."

# Set default URLs based on environment
ALFRED_API_URL=${ALFRED_API_URL:-"http://localhost:8012"}
STREAMLIT_URL=${STREAMLIT_URL:-"http://localhost:8502"}
REDIS_HOST=${REDIS_HOST:-"localhost"}
REDIS_PORT=${REDIS_PORT:-"6379"}
# Check 1: Verify Alfred Bot API health
echo "Checking Alfred Bot API health..."
if curl -s "$ALFRED_API_URL/health" | grep -q "status"; then
  echo "✅ Alfred Bot API is healthy"
else
  echo "❌ Alfred Bot API is not reachable at $ALFRED_API_URL"
  exit 1
fi

# Check 2: Verify Streamlit is running
echo "Checking Streamlit UI health..."
response=$(curl -s "$STREAMLIT_URL")
if [[ $response == *"streamlit"* ]] || [[ $response == *"Streamlit"* ]] || [[ $response == *"<!DOCTYPE html>"* ]]; then
  echo "✅ Streamlit UI is running"
else
  echo "❌ Streamlit UI is not reachable at $STREAMLIT_URL"
  echo "Response was: ${response:0:100}..."  # Show first 100 chars of response
  exit 1
fi

# Check 3: Test simple API command to Alfred
echo "Testing API communication..."
RESPONSE=$(curl -s -X POST \
  "$ALFRED_API_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"ping","user_id":"test_user","channel_id":"test_channel"}')

if echo "$RESPONSE" | grep -q "Pong"; then
  echo "✅ Alfred Bot API communication successful"
else
  echo "❌ Alfred Bot API communication failed:"
  echo "$RESPONSE"
  exit 1
fi

# Check 4: Verify Redis is accessible to the platform
echo "Checking Redis connection..."
if nc -z $REDIS_HOST $REDIS_PORT 2>/dev/null; then
  echo "✅ Redis is running and accessible"
else
  echo "❌ Redis is not accessible at $REDIS_HOST:$REDIS_PORT"
  echo "This may not be critical if Redis is running in a container network"
fi

echo "All checks passed! The Alfred - Streamlit integration is working correctly."
echo "You can now access the Streamlit Chat UI at: $STREAMLIT_URL"