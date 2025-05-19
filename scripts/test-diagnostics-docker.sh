#!/bin/bash
# Test diagnostics bot in Docker

set -e

echo "🧪 Testing Diagnostics Bot in Docker"
echo
echo "Prerequisites:"
echo "  - SLACK_BOT_TOKEN must be set (xoxb-...)"
echo "  - SLACK_APP_TOKEN must be set (xapp-...)"
echo "  - /diag slash command configured in Slack"
echo

# Check for required tokens
if [ -z "$SLACK_BOT_TOKEN" ] || [ -z "$SLACK_APP_TOKEN" ]; then
    echo "❌ Error: SLACK_BOT_TOKEN and SLACK_APP_TOKEN must be set"
    echo
    echo "Export them with:"
    echo "  export SLACK_BOT_TOKEN=xoxb-your-bot-token"
    echo "  export SLACK_APP_TOKEN=xapp-your-app-token"
    exit 1
fi

echo "✅ Tokens configured"
echo
echo "🚀 Starting diagnostics bot..."
echo

# Run docker-compose
cd "$(dirname "$0")/.."
docker-compose -f deploy/docker-compose.diagnostics.yml up

echo
echo "🎯 Test in Slack with:"
echo "  /diag health"
echo "  /diag metrics"
