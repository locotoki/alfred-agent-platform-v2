#!/usr/bin/env bash
set -euo pipefail

# Create the message JSON
MSG='{"role":"architect","msg_type":"chat","content":"'"$1"'","metadata":{}}'
BASE64_MSG=$(echo -n "$MSG" | base64 | tr -d '\n')

# Using Pub/Sub emulator REST endpoint
curl -X POST "http://localhost:8085/v1/projects/atlas-dev/topics/architect_in:publish" \
  -H "Content-Type: application/json" \
  -d "{\"messages\":[{\"data\":\"$BASE64_MSG\"}]}"