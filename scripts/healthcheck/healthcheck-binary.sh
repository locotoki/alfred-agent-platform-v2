#!/bin/bash
# Simple healthcheck script that can be used as a binary

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --http)
      MODE="http"
      URL="$2"
      shift 2
      ;;
    --redis)
      MODE="redis"
      REDIS_URL="$2"
      shift 2
      ;;
    --tcp)
      MODE="tcp"
      HOST_PORT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# HTTP healthcheck
if [[ "$MODE" == "http" ]]; then
  if command -v curl &> /dev/null; then
    curl -s -f "$URL" > /dev/null
    exit $?
  elif command -v wget &> /dev/null; then
    wget -q -O /dev/null "$URL"
    exit $?
  else
    echo "No HTTP client available (curl or wget)"
    exit 1
  fi

# Redis healthcheck
elif [[ "$MODE" == "redis" ]]; then
  if command -v redis-cli &> /dev/null; then
    redis-cli -u "$REDIS_URL" PING | grep -q "PONG"
    exit $?
  else
    echo "redis-cli not available"
    exit 1
  fi

# TCP healthcheck
elif [[ "$MODE" == "tcp" ]]; then
  HOST=$(echo "$HOST_PORT" | cut -d':' -f1)
  PORT=$(echo "$HOST_PORT" | cut -d':' -f2)

  if command -v nc &> /dev/null; then
    nc -z "$HOST" "$PORT"
    exit $?
  else
    # Fallback using /dev/tcp if netcat is not available (works in bash)
    (echo > "/dev/tcp/$HOST/$PORT") >/dev/null 2>&1
    exit $?
  fi

else
  echo "Mode not specified or invalid. Use --http URL or --redis REDIS_URL or --tcp HOST:PORT"
  exit 1
fi
