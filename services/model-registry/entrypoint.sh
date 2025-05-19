#!/usr/bin/env bash
set -euo pipefail


# Standardized entrypoint script with health check integration for model-registry service

set -e

# Start healthcheck in background with standard configuration
: "${HEALTH_CHECK_PORT:=8079}"
: "${HEALTH_CHECK_PATH:=/health}"
: "${HEALTH_CHECK_INTERVAL:=30s}"
: "${METRICS_EXPORTER_PORT:=9091}"

# Start the healthcheck binary in the background
/usr/local/bin/healthcheck \
    --export-prom ":${METRICS_EXPORTER_PORT}" \
    --interval "${HEALTH_CHECK_INTERVAL}" \
    --port "${HEALTH_CHECK_PORT}" \
    --path "${HEALTH_CHECK_PATH}" &

# Store the healthcheck process ID
HEALTHCHECK_PID=$!

# model-registry specific initialization
if [ "$DATABASE_URL" ]; then
  echo "Initializing database..."
  # Connect to PostgreSQL database to initialize
  psql "postgresql://postgres:postgres@db-postgres:5432/postgres" -f /app/init-db.sql
fi

# Handle cleanup when container is stopped
cleanup() {
    echo "Stopping model-registry service and healthcheck..."

    # Kill any running service processes if needed

    # Kill the healthcheck process
    if [ -n "${HEALTHCHECK_PID}" ] && kill -0 ${HEALTHCHECK_PID} 2>/dev/null; then
        kill -TERM ${HEALTHCHECK_PID}
        wait ${HEALTHCHECK_PID}
    fi

    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start the service using the CMD provided in the Dockerfile
exec "$@"
