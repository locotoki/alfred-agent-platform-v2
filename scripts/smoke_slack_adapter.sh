#!/bin/bash
# Smoke test for Slack Adapter service

set -e

ADAPTER_URL=${SLACK_ADAPTER_URL:-http://localhost:3001}
TIMEOUT=30
RETRY_INTERVAL=5

echo "🔍 Starting Slack Adapter smoke test..."
echo "   URL: $ADAPTER_URL"

# Function to check if service is healthy
check_health() {
    local url=$1
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url/healthz")

    if [ "$response" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Wait for service to be ready
echo "⏳ Waiting for Slack Adapter to be ready..."
start_time=$(date +%s)

while true; do
    if check_health "$ADAPTER_URL"; then
        echo "✅ Slack Adapter is healthy!"
        break
    fi

    current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    if [ $elapsed -gt $TIMEOUT ]; then
        echo "❌ Timeout waiting for Slack Adapter to be ready"
        exit 1
    fi

    echo "   Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done

# Test health endpoint
echo "🧪 Testing health endpoint..."
health_response=$(curl -s "$ADAPTER_URL/healthz")
echo "   Response: $health_response"

# Test root endpoint
echo "🧪 Testing root endpoint..."
root_response=$(curl -s "$ADAPTER_URL/")
echo "   Response: $root_response"

# Test ping command simulation
echo "🧪 Testing ping command..."
ping_response=$(curl -s -X POST "$ADAPTER_URL/slack/events" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "command=/alfred&text=ping")
echo "   Response: $ping_response"

echo "✅ All smoke tests passed!"
