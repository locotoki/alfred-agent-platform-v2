#!/bin/bash
# Unified Health Check Script for Alfred Agent Platform
# This script can be used consistently across all services 
# to provide standardized health checks.

# Set default values
PORT=${1:-8080}
ENDPOINT=${2:-health}
CHECK_TYPE=${3:-endpoint}
MAX_RETRIES=${4:-1}
TIMEOUT=${5:-5}

# Function to display usage information
usage() {
  echo "Usage: $0 [PORT] [ENDPOINT] [CHECK_TYPE] [MAX_RETRIES] [TIMEOUT]"
  echo ""
  echo "Arguments:"
  echo "  PORT       Service port (default: 8080)"
  echo "  ENDPOINT   Health endpoint without leading slash (default: health)"
  echo "  CHECK_TYPE Type of check: process, port, endpoint, deep (default: endpoint)"
  echo "  MAX_RETRIES Number of retries if check fails (default: 1)"
  echo "  TIMEOUT    Timeout in seconds (default: 5)"
  echo ""
  echo "Example:"
  echo "  $0 8080 health endpoint 3 10"
  echo ""
  exit 1
}

# Parse help flag
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  usage
fi

# Get the container ID (useful for logging)
CONTAINER_ID=$(hostname)

# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Detect the best available tool for HTTP checks
detect_health_tool() {
  if command_exists wget; then
    echo "wget"
  elif command_exists curl; then
    echo "curl"
  elif command_exists nc; then
    echo "nc"
  else
    echo "none"
  fi
}

# Process check - always works if the container process is running
process_check() {
  if [ -f /proc/1/status ]; then
    return 0
  else
    return 1
  fi
}

# Port check - verifies if the port is open
port_check() {
  local retries=$MAX_RETRIES
  
  while [ $retries -ge 0 ]; do
    if command_exists nc; then
      if nc -z -w$TIMEOUT localhost $PORT 2>/dev/null; then
        return 0
      fi
    elif command_exists bash; then
      if bash -c "echo > /dev/tcp/localhost/$PORT" 2>/dev/null; then
        return 0
      fi
    elif command_exists timeout; then
      if timeout $TIMEOUT bash -c "echo > /dev/tcp/localhost/$PORT" 2>/dev/null; then
        return 0
      fi
    else
      # If we can't check the port directly, assume it's ok if process is running
      return 0
    fi
    
    retries=$((retries-1))
    [ $retries -ge 0 ] && sleep 1
  done
  
  return 1
}

# HTTP endpoint check - verifies if the health endpoint responds correctly
endpoint_check() {
  local retries=$MAX_RETRIES
  local tool=$(detect_health_tool)
  
  while [ $retries -ge 0 ]; do
    if [ "$tool" == "wget" ]; then
      if wget -q -O- -T $TIMEOUT http://localhost:$PORT/$ENDPOINT >/dev/null 2>&1; then
        return 0
      fi
    elif [ "$tool" == "curl" ]; then
      if curl -s -f -m $TIMEOUT http://localhost:$PORT/$ENDPOINT >/dev/null 2>&1; then
        return 0
      fi
    else
      # If we can't check the endpoint directly, fall back to port check
      if port_check; then
        return 0
      fi
    fi
    
    retries=$((retries-1))
    [ $retries -ge 0 ] && sleep 1
  done
  
  return 1
}

# Deep check - verifies detailed health status including dependencies
deep_check() {
  local retries=$MAX_RETRIES
  local tool=$(detect_health_tool)
  
  while [ $retries -ge 0 ]; do
    if [ "$tool" == "wget" ]; then
      response=$(wget -q -O- -T $TIMEOUT http://localhost:$PORT/$ENDPOINT/deep 2>/dev/null)
      status=$?
      
      if [ $status -eq 0 ]; then
        # Check if the response contains "status": "unhealthy"
        if ! echo "$response" | grep -q '"status"[[:space:]]*:[[:space:]]*"unhealthy"'; then
          return 0
        fi
      fi
    elif [ "$tool" == "curl" ]; then
      response=$(curl -s -m $TIMEOUT http://localhost:$PORT/$ENDPOINT/deep 2>/dev/null)
      status=$?
      
      if [ $status -eq 0 ]; then
        # Check if the response contains "status": "unhealthy"
        if ! echo "$response" | grep -q '"status"[[:space:]]*:[[:space:]]*"unhealthy"'; then
          return 0
        fi
      fi
    else
      # If we can't do a deep check, fall back to regular endpoint check
      if endpoint_check; then
        return 0
      fi
    fi
    
    retries=$((retries-1))
    [ $retries -ge 0 ] && sleep 1
  done
  
  return 1
}

# Main function that runs the appropriate check
main() {
  # Always do a process check first - if this fails, the container is definitely unhealthy
  if ! process_check; then
    echo "Process check failed - container is not running properly"
    exit 1
  fi
  
  # Run the appropriate check based on CHECK_TYPE
  case "$CHECK_TYPE" in
    process)
      # Process check already passed, just return success
      exit 0
      ;;
    port)
      if port_check; then
        exit 0
      else
        echo "Port check failed - $PORT is not accessible"
        exit 1
      fi
      ;;
    endpoint)
      if endpoint_check; then
        exit 0
      else
        echo "Endpoint check failed - http://localhost:$PORT/$ENDPOINT is not responding"
        exit 1
      fi
      ;;
    deep)
      if deep_check; then
        exit 0
      else
        echo "Deep health check failed - service has dependency issues"
        exit 1
      fi
      ;;
    *)
      echo "Unknown check type: $CHECK_TYPE"
      usage
      ;;
  esac
}

# Run the main function
main