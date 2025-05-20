#\!/bin/bash
# test-slack.sh - Test Slack commands with minimal setup

# Check if the Slack MCP Gateway and Redis are running
echo "Checking if Redis and Slack MCP Gateway are running..."
if \! docker ps  < /dev/null |  grep -q "slack_mcp_gateway" || \! docker ps | grep -q "redis"; then
  # Start the services if they're not running
  echo "Starting Redis and Slack MCP Gateway..."
  ./docker-compose-env.sh -f docker-compose.yml up -d redis slack_mcp_gateway
fi

echo "
The minimal Slack setup is now running.
You should be able to test these commands in your Slack workspace:

  /alfred help    - Should show available commands
  /alfred status  - Should show platform status

The full features requiring agent-core and other services won't work yet,
but the basic commands should respond to test connectivity.

To see logs from the Slack service:
  docker logs -f slack_mcp_gateway
"
