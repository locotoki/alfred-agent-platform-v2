#!/bin/bash

# Script to test the Alfred Core API endpoints

# Configuration
API_URL=${API_URL:-"http://localhost:8011"}
USER_ID=${USER_ID:-"test_user"}
CHANNEL_ID=${CHANNEL_ID:-"test_channel"}

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to make API calls
call_api() {
  local endpoint=$1
  local method=${2:-"GET"}
  local data=$3
  
  if [ "$method" == "GET" ]; then
    curl -s "$API_URL$endpoint"
  else
    curl -s -X "$method" "$API_URL$endpoint" \
      -H "Content-Type: application/json" \
      -d "$data"
  fi
}

# Test health endpoint
echo -e "${YELLOW}Testing health endpoint...${NC}"
RESPONSE=$(call_api "/health")
if echo "$RESPONSE" | grep -q "healthy"; then
  echo -e "${GREEN}✓ Health endpoint is working${NC}"
  echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${RED}✗ Health endpoint failed${NC}"
  echo "$RESPONSE"
fi
echo ""

# Test root endpoint
echo -e "${YELLOW}Testing root endpoint...${NC}"
RESPONSE=$(call_api "/")
if echo "$RESPONSE" | grep -q "Alfred API"; then
  echo -e "${GREEN}✓ Root endpoint is working${NC}"
  echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${RED}✗ Root endpoint failed${NC}"
  echo "$RESPONSE"
fi
echo ""

# Test chat endpoint with help command
echo -e "${YELLOW}Testing chat endpoint with 'help' command...${NC}"
RESPONSE=$(call_api "/api/chat" "POST" "{\"message\":\"help\",\"user_id\":\"$USER_ID\",\"channel_id\":\"$CHANNEL_ID\"}")
if echo "$RESPONSE" | grep -q "success"; then
  echo -e "${GREEN}✓ Chat endpoint with 'help' command is working${NC}"
  echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${RED}✗ Chat endpoint with 'help' command failed${NC}"
  echo "$RESPONSE"
fi
echo ""

# Test chat endpoint with ping command
echo -e "${YELLOW}Testing chat endpoint with 'ping' command...${NC}"
RESPONSE=$(call_api "/api/chat" "POST" "{\"message\":\"ping\",\"user_id\":\"$USER_ID\",\"channel_id\":\"$CHANNEL_ID\"}")
if echo "$RESPONSE" | grep -q "Pong"; then
  echo -e "${GREEN}✓ Chat endpoint with 'ping' command is working${NC}"
  echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${RED}✗ Chat endpoint with 'ping' command failed${NC}"
  echo "$RESPONSE"
fi
echo ""

# Test chat endpoint with trend command
echo -e "${YELLOW}Testing chat endpoint with 'trend' command...${NC}"
RESPONSE=$(call_api "/api/chat" "POST" "{\"message\":\"trend artificial intelligence\",\"user_id\":\"$USER_ID\",\"channel_id\":\"$CHANNEL_ID\"}")
if echo "$RESPONSE" | grep -q "Analyzing trends"; then
  echo -e "${GREEN}✓ Chat endpoint with 'trend' command is working${NC}"
  echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
else
  echo -e "${RED}✗ Chat endpoint with 'trend' command failed${NC}"
  echo "$RESPONSE"
fi
echo ""

# Extract task ID from the response
TASK_ID=$(echo "$RESPONSE" | grep -o "Task ID: [^ ]*" | sed 's/Task ID: //')

if [ -n "$TASK_ID" ]; then
  # Test task status endpoint
  echo -e "${YELLOW}Testing task status endpoint for task ID: $TASK_ID...${NC}"
  RESPONSE=$(call_api "/api/task/$TASK_ID")
  if echo "$RESPONSE" | grep -q "status"; then
    echo -e "${GREEN}✓ Task status endpoint is working${NC}"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
  else
    echo -e "${RED}✗ Task status endpoint failed${NC}"
    echo "$RESPONSE"
  fi
  echo ""
fi

echo -e "${GREEN}All tests completed!${NC}"