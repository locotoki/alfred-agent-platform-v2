#!/bin/bash
# Script to test if metrics ports are open
# This script is used for CI verification of metrics exporter

set -e

echo "Testing if metrics ports are open..."

# Define expected ports for each service
declare -A SERVICE_PORTS=(
  ["agent-rag"]="9092"
  ["agent-atlas"]="9093"
  ["agent-social"]="9094"
  ["agent-financial"]="9095"
  ["agent-legal"]="9096"
  ["alfred-bot"]="9091"
)

# Function to check if a port is open
check_port() {
  local host="localhost"
  local port=$1
  local service=$2
  
  nc -z -w 5 $host $port
  if [ $? -eq 0 ]; then
    echo "✅ $service port $port is open"
    return 0
  else
    echo "❌ $service port $port is closed"
    return 1
  fi
}

# Check all service metrics ports
failures=0

for service in "${!SERVICE_PORTS[@]}"; do
  port=${SERVICE_PORTS[$service]}
  
  echo "Checking $service on port $port..."
  if ! check_port $port $service; then
    failures=$((failures + 1))
  fi
done

# Final summary
if [ $failures -eq 0 ]; then
  echo "🟢 All metrics ports are open"
  exit 0
else
  echo "🔴 $failures metrics ports are not open"
  exit 1
fi