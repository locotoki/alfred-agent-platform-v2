#\!/bin/sh
# Simple healthcheck script
usage() {
  echo "Usage: healthcheck [--export-prom :PORT] [--] COMMAND [ARGS...]"
  echo "  --export-prom :PORT  Export metrics on the specified port"
  echo "  --http URL           Check if HTTP endpoint is healthy"
  echo "  -- COMMAND [ARGS...] Run the command with arguments"
  exit 1
}

EXPORT_PROM=""
CHECK_HTTP=""
CMD_START=0

for i in $(seq 1 $#); do
  arg=$(eval echo \${$i})
  if [ "$arg" = "--export-prom" ]; then
    next=$((i+1))
    EXPORT_PROM=$(eval echo \${$next})
    i=$next
  elif [ "$arg" = "--http" ]; then
    next=$((i+1))
    CHECK_HTTP=$(eval echo \${$next})
    i=$next
  elif [ "$arg" = "--" ]; then
    CMD_START=$((i+1))
    break
  fi
done

# If we need to export metrics, start a simple HTTP server
if [ -n "$EXPORT_PROM" ]; then
  # Simple HTTP server simulation using netcat
  (while true; do
    echo -e "HTTP/1.1 200 OK\nContent-Type: text/plain\n\n# HELP up Service up status\n# TYPE up gauge\nup 1"  < /dev/null |  nc -l -p ${EXPORT_PROM#:} || true
    sleep 1
  done) &
  echo "Started metrics server on $EXPORT_PROM"
fi

# If checking HTTP endpoint
if [ -n "$CHECK_HTTP" ]; then
  curl -s -f "$CHECK_HTTP" > /dev/null
  exit $?
fi

# Execute the command if specified
if [ $CMD_START -gt 0 ]; then
  shift $((CMD_START-1))
  exec "$@"
fi
