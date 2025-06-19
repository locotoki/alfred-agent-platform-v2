#!/usr/bin/env bash
set -euo pipefail
NATS_URL=${NATS_URL:-nats://localhost:4222}
function add_stream() {
  local stream=$1 subjects=$2
  docker exec nats nats --server "$NATS_URL" stream info "$stream" 2>/dev/null \
    || docker exec nats nats --server "$NATS_URL" stream add "$stream" \
         --subjects "$subjects" --storage file --retention limits --max-msgs 0
}
add_stream EVENTS "events.*"
echo "✅ JetStream stream EVENTS ensured."