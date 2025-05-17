#!/bin/bash
# Run script for the Echo Agent
# This script starts the echo agent that responds to /alfred ping commands

set -e

# Environment check
if [ -z "$SLACK_BOT_TOKEN" ]; then
  echo "Error: SLACK_BOT_TOKEN environment variable is required"
  exit 1
fi

# Change to the project root directory
cd "$(dirname "$0")/../.."

# Activate virtual environment if it exists
if [ -d "venv" ]; then
  echo "Activating virtual environment..."
  source venv/bin/activate
fi

# Set default environment variables
export REDIS_HOST=${REDIS_HOST:-"localhost"}
export REDIS_PORT=${REDIS_PORT:-6379}
export REDIS_DB=${REDIS_DB:-0}
export LOG_LEVEL=${LOG_LEVEL:-"INFO"}

echo "Starting Slack MCP Gateway Echo Agent..."
echo "Redis: $REDIS_HOST:$REDIS_PORT/$REDIS_DB"

# Run the echo agent
python -m services.slack_mcp_gateway.echo_agent