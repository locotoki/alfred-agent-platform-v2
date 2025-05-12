#!/usr/bin/env bash
set -euo pipefail

MSG=$(jq -n --arg c "$1" '{role:"architect",msg_type:"chat",content:$c,metadata:{}}')
# Using Pub/Sub emulator REST endpoint
curl -s -X POST "http://localhost:8681/v1/projects/atlas-dev/topics/architect_in:publish" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"data":"'$(echo -n "$MSG" | base64)'"}]}' | jq .