#!/bin/bash

# Startup script for the Alfred Core service

# Set default environment variables
export ALFRED_MODE=${ALFRED_MODE:-"default"}
export ENABLE_SLACK=${ENABLE_SLACK:-"true"}
export LOG_LEVEL=${LOG_LEVEL:-"INFO"}

# Check if running in demo mode
if [ "$1" == "demo" ]; then
  echo "Starting Alfred Core in DEMO mode..."
  export ALFRED_MODE="demo"
fi

# Check if running with Slack disabled
if [ "$1" == "no-slack" ] || [ "$2" == "no-slack" ]; then
  echo "Starting Alfred Core with Slack interface DISABLED..."
  export ENABLE_SLACK="false"
fi

# Start the services using Docker Compose
echo "Starting Alfred Core with mode: $ALFRED_MODE and Slack enabled: $ENABLE_SLACK"
docker-compose up -d

# Show status
echo "Alfred Core is starting up..."
echo "API will be available at: http://localhost:8011"
echo "Streamlit UI will be available at: http://localhost:8501"
echo ""
echo "To check logs, run:"
echo "docker-compose logs -f"
echo ""
echo "To stop services, run:"
echo "docker-compose down"