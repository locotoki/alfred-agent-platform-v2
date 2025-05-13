#!/bin/bash
# Example health check script for Docker containers
# This script provides a flexible health check implementation that can be used
# across different service types with consistent behavior.

# Configuration with defaults
SERVICE_PORT=${SERVICE_PORT:-8080}
HEALTH_ENDPOINT=${HEALTH_ENDPOINT:-health}
CHECK_TYPE=${CHECK_TYPE:-basic}  # basic, process, endpoint, deep
CHECK_TOOL=${CHECK_TOOL:-auto}   # auto, wget, curl, nc, process
PROCESS_NAME=${PROCESS_NAME:-""}
TIMEOUT=${TIMEOUT:-5}
HTTP_HOST=${HTTP_HOST:-localhost}
VERBOSE=${VERBOSE:-false}

# Log function that only outputs if VERBOSE is true
log() {
  if [ "$VERBOSE" = "true" ]; then
    echo "[HEALTH] $1"
  fi
}

# Detect available tools
detect_tools() {
  if [ "$CHECK_TOOL" = "auto" ]; then
    if command -v wget >/dev/null 2>&1; then
      CHECK_TOOL="wget"
    elif command -v curl >/dev/null 2>&1; then
      CHECK_TOOL="curl"
    elif command -v nc >/dev/null 2>&1; then
      CHECK_TOOL="nc"
    else
      CHECK_TOOL="process"
      log "No HTTP tools found, falling back to process check"
    fi
  fi
  
  log "Using tool: $CHECK_TOOL"
}

# Basic process check - always works if container is running
check_process_exists() {
  if [ -z "$PROCESS_NAME" ]; then
    # If no process name specified, just check PID 1
    if [ -e /proc/1/status ]; then
      log "Process check: OK (PID 1 exists)"
      return 0
    else
      log "Process check: FAIL (PID 1 not found)"
      return 1
    fi
  else
    # Check for specified process
    if pidof "$PROCESS_NAME" >/dev/null; then
      log "Process check: OK ($PROCESS_NAME running)"
      return 0
    else
      log "Process check: FAIL ($PROCESS_NAME not running)"
      return 1
    fi
  fi
}

# Port check - verifies a port is open
check_port() {
  if [ "$CHECK_TOOL" = "nc" ]; then
    if nc -z -w"$TIMEOUT" "$HTTP_HOST" "$SERVICE_PORT"; then
      log "Port check: OK (port $SERVICE_PORT is open)"
      return 0
    else
      log "Port check: FAIL (port $SERVICE_PORT is not open)"
      return 1
    fi
  else
    # Fallback using /dev/tcp
    (echo > /dev/tcp/"$HTTP_HOST"/"$SERVICE_PORT") >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      log "Port check: OK (port $SERVICE_PORT is open)"
      return 0
    else
      log "Port check: FAIL (port $SERVICE_PORT is not open)"
      return 1
    fi
  fi
}

# HTTP endpoint check - verifies an HTTP endpoint responds correctly
check_endpoint() {
  if [ "$CHECK_TOOL" = "wget" ]; then
    if wget -q -T "$TIMEOUT" -O - "http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT" >/dev/null 2>&1; then
      log "Endpoint check: OK (http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT)"
      return 0
    else
      log "Endpoint check: FAIL (http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT)"
      return 1
    fi
  elif [ "$CHECK_TOOL" = "curl" ]; then
    if curl -s -f -m "$TIMEOUT" "http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT" >/dev/null 2>&1; then
      log "Endpoint check: OK (http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT)"
      return 0
    else
      log "Endpoint check: FAIL (http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT)"
      return 1
    fi
  else
    log "Endpoint check: SKIP (no suitable HTTP tools available)"
    # Fall back to port check
    check_port
  fi
}

# Deep health check - checks a deep health endpoint for comprehensive status
check_deep() {
  if [ "$CHECK_TOOL" = "wget" ]; then
    RESPONSE=$(wget -q -T "$TIMEOUT" -O - "http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT/deep" 2>/dev/null)
    RC=$?
  elif [ "$CHECK_TOOL" = "curl" ]; then
    RESPONSE=$(curl -s -m "$TIMEOUT" "http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT/deep" 2>/dev/null)
    RC=$?
  else
    log "Deep check: SKIP (no suitable HTTP tools available)"
    # Fall back to endpoint check
    check_endpoint
    return $?
  fi
  
  if [ $RC -eq 0 ]; then
    # Check for "status": "unhealthy" in response
    if echo "$RESPONSE" | grep -q '"status"[[:space:]]*:[[:space:]]*"unhealthy"'; then
      log "Deep check: FAIL (unhealthy status detected)"
      return 1
    else
      log "Deep check: OK"
      return 0
    fi
  else
    log "Deep check: FAIL (HTTP request failed)"
    return 1
  fi
}

# Readiness check - specific check for readiness
check_readiness() {
  if [ "$CHECK_TOOL" = "wget" ]; then
    if wget -q -T "$TIMEOUT" -O - "http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT/readiness" >/dev/null 2>&1; then
      log "Readiness check: OK"
      return 0
    else
      log "Readiness check: FAIL"
      return 1
    fi
  elif [ "$CHECK_TOOL" = "curl" ]; then
    if curl -s -f -m "$TIMEOUT" "http://$HTTP_HOST:$SERVICE_PORT/$HEALTH_ENDPOINT/readiness" >/dev/null 2>&1; then
      log "Readiness check: OK"
      return 0
    else
      log "Readiness check: FAIL"
      return 1
    fi
  else
    log "Readiness check: SKIP (no suitable HTTP tools available)"
    # Fall back to endpoint check
    check_endpoint
  fi
}

# Main health check logic
main() {
  # Detect available tools
  detect_tools
  
  # Simple process check first - if this fails, container is dead
  if ! check_process_exists; then
    exit 1
  fi
  
  # Then perform check based on specified type
  case "$CHECK_TYPE" in
    process)
      # Already done, just exit with success
      exit 0
      ;;
    port)
      check_port
      exit $?
      ;;
    endpoint)
      check_endpoint
      exit $?
      ;;
    readiness)
      check_readiness
      exit $?
      ;;
    deep)
      check_deep
      exit $?
      ;;
    basic|*)
      # Default - if process check passed, container is alive
      exit 0
      ;;
  esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  
  case $key in
    --port|-p)
      SERVICE_PORT="$2"
      shift
      shift
      ;;
    --endpoint|-e)
      HEALTH_ENDPOINT="$2"
      shift
      shift
      ;;
    --type|-t)
      CHECK_TYPE="$2"
      shift
      shift
      ;;
    --tool|-T)
      CHECK_TOOL="$2"
      shift
      shift
      ;;
    --process|-P)
      PROCESS_NAME="$2"
      shift
      shift
      ;;
    --timeout|-s)
      TIMEOUT="$2"
      shift
      shift
      ;;
    --host|-H)
      HTTP_HOST="$2"
      shift
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Run the main function
main