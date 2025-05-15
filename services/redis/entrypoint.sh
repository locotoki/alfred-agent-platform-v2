#!/usr/bin/env bash
set -euo pipefail


# Standardized entrypoint script with health check integration for redis service

set -e

# Start healthcheck in background with standard configuration
: "${HEALTH_CHECK_PORT:=6379}"
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

# Start Redis server in the background
redis-server &
REDIS_PID=$!

# Wait for Redis to become ready
echo "Waiting for Redis to start..."
until redis-cli ping > /dev/null 2>&1; do
  sleep 1
done
echo "Redis started successfully"

# Start the health check wrapper using the virtual environment
echo "Starting health check wrapper on port 9091"
cd /app && /app/venv/bin/python health_wrapper.py &
WRAPPER_PID=$!

# Handle cleanup when container is stopped
cleanup() {
    echo "Stopping redis service and healthcheck..."
    
    # Kill the Redis server process
    if [ -n "${REDIS_PID}" ] && kill -0 ${REDIS_PID} 2>/dev/null; then
        kill -TERM ${REDIS_PID}
        wait ${REDIS_PID} || true
    fi
    
    # Kill the health wrapper process
    if [ -n "${WRAPPER_PID}" ] && kill -0 ${WRAPPER_PID} 2>/dev/null; then
        kill -TERM ${WRAPPER_PID}
        wait ${WRAPPER_PID} || true
    fi
    
    # Kill the healthcheck process
    if [ -n "${HEALTHCHECK_PID}" ] && kill -0 ${HEALTHCHECK_PID} 2>/dev/null; then
        kill -TERM ${HEALTHCHECK_PID}
        wait ${HEALTHCHECK_PID} || true
    fi
    
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Rather than exec $@, we need to wait for all background processes
# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
