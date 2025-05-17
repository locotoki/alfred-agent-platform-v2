#!/bin/bash
# Slack deployment announcement with proper webhook support

set -euo pipefail

MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Error: Message parameter required"
    echo "Usage: $0 \"Your message here\""
    exit 1
fi

# Check for webhook URL
WEBHOOK_URL="${SLACK_RELEASE_WEBHOOK:-}"

if [ -z "$WEBHOOK_URL" ]; then
    echo "Warning: SLACK_RELEASE_WEBHOOK not set. Running in dry-run mode."
    echo "Would send to Slack: $MESSAGE"
    echo "$MESSAGE" >> /tmp/slack-announcements.log
    exit 0
fi

# Send to Slack via webhook
echo "Sending to Slack: $MESSAGE"

RESPONSE=$(curl -s -w '\n%{http_code}' -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$MESSAGE\"}" \
    "$WEBHOOK_URL")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Slack notification sent successfully"
    exit 0
else
    echo "Error: Failed to send Slack notification (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
    exit 1
fi