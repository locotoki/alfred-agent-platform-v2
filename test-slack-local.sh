#!/bin/bash
# Test script for local Slack bot

echo "🔍 Testing Slack Bot Locally"
echo "=========================="

# Check if slack-bot is running
echo -e "\n1. Checking if slack-bot container is running..."
if docker ps | grep -q slack-bot; then
    echo "✅ slack-bot is running"
    docker ps | grep slack-bot
else
    echo "❌ slack-bot is not running"
    echo "Run: TAG=local-fixed-v2 docker-compose up -d slack-bot"
    exit 1
fi

# Test health endpoint
echo -e "\n2. Testing health endpoint..."
HEALTH=$(curl -s http://localhost:3011/health)
if echo "$HEALTH" | jq -e '.ok == true' > /dev/null 2>&1; then
    echo "✅ Health check passed"
    echo "$HEALTH" | jq
else
    echo "❌ Health check failed"
    echo "$HEALTH"
fi

# Check logs for errors
echo -e "\n3. Recent logs (excluding health checks)..."
docker logs slack-bot --tail 20 2>&1 | grep -v "GET /health" | tail -10

# Provide instructions
echo -e "\n📋 Next Steps:"
echo "============="
echo "1. Install ngrok: wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
echo "2. Extract: tar xvzf ngrok-v3-stable-linux-amd64.tgz"
echo "3. Run: ./ngrok http 3011"
echo "4. Copy the HTTPS URL (e.g., https://abc123.ngrok.io)"
echo "5. Update Slack app at https://api.slack.com/apps"
echo "   - Go to Slash Commands > /alfred > Edit"
echo "   - Set Request URL to: https://abc123.ngrok.io/slack/events"
echo "6. Save and test with: /alfred help"
echo ""
echo "🔗 Your slack-bot is ready at http://localhost:3011"
echo "It just needs to be accessible from the internet for Slack to reach it."