#!/bin/bash
# Test staging webhook after adding SLACK_ALERT_WEBHOOK secret

# Use the example alert JSON
curl -X POST https://staging.alfred.example.com/alerts \
     -d @examples/alerts/critical.json \
     -H "Content-Type: application/json"

# Expected: Slack message with 🚨 emoji + runbook link
echo "Check Slack for critical alert with 🚨 emoji and runbook link"
