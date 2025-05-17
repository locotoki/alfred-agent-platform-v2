#!/bin/sh
# Simple healthcheck script that can be used in Docker containers
# Usage: healthcheck.sh [--export-prom PORT] [--http URL] [--] COMMAND [ARGS...]

set -e

usage() {
  echo "Usage: healthcheck.sh [--export-prom PORT] [--http URL] [--] COMMAND [ARGS...]"
  echo "  --export-prom PORT  Export metrics on the specified port (e.g. 9091)"
  echo "  --http URL          Check if HTTP endpoint is healthy"
  echo "  -- COMMAND [ARGS...]  Run the command with arguments"
  exit 1
}

EXPORT_PROM=""
CHECK_HTTP=""
CMD_START=0

# Parse arguments
i=1
while [ $i -le $# ]; do
  arg=$(eval echo \${$i})
  if [ "$arg" = "--export-prom" ]; then
    i=$((i+1))
    EXPORT_PROM=$(eval echo \${$i})
  elif [ "$arg" = "--http" ]; then
    i=$((i+1))
    CHECK_HTTP=$(eval echo \${$i})
  elif [ "$arg" = "--" ]; then
    CMD_START=$((i+1))
    break
  fi
  i=$((i+1))
done

# If we need to export metrics, start a simple HTTP server
if [ -n "$EXPORT_PROM" ]; then
  # Extract port number from PORT format (:9091 -> 9091)
  PORT=$(echo $EXPORT_PROM | sed 's/^://')
  
  # Create a simple metrics response
  mkdir -p /tmp/metrics
  cat > /tmp/metrics/index.html << EOF
# HELP up Service up status
# TYPE up gauge
up 1
EOF

  # Start a background HTTP server with busybox httpd
  (cd /tmp/metrics && busybox httpd -f -p $PORT) &
  echo "Started metrics server on port $PORT"
fi

# If checking HTTP endpoint
if [ -n "$CHECK_HTTP" ]; then
  if command -v curl >/dev/null 2>&1; then
    curl -s -f "$CHECK_HTTP" > /dev/null
    exit $?
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O - "$CHECK_HTTP" > /dev/null
    exit $?
  else
    echo "Error: Neither curl nor wget available for health checks"
    exit 1
  fi
fi

# Execute the command if specified
if [ $CMD_START -gt 0 ]; then
  shift $((CMD_START-1))
  exec "$@"
fi