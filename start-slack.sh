#!/bin/bash
# start-slack.sh - Start only services required for Slack integration
# Created by Claude Code

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "[ERROR] Docker daemon is not running!"
  echo "Please start Docker manually with: sudo service docker start"
  echo "Then run this script again."
  exit 1
fi

echo "Starting essential services for Slack integration..."
./docker-compose-env.sh -f docker-compose.yml up -d redis db-postgres agent-core slack_mcp_gateway slack-adapter

echo "Checking service status..."
./docker-compose-env.sh -f docker-compose.yml ps

echo "
To test Slack commands, use:
  /alfred help  - Shows available commands
  /diag health  - Shows detailed health status

If commands are not working, check logs with:
  ./docker-compose-env.sh -f docker-compose.yml logs -f slack_mcp_gateway slack-adapter
"
