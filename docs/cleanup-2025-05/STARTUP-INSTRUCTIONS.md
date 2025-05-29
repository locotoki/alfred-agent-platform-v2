# Alfred Platform Startup Instructions

This document provides step-by-step instructions for starting the Alfred Agent Platform according to the repository's standard practices.

## Prerequisites

1. **Docker Engine** must be running:
   ```bash
   sudo service docker start
   ```

2. **Environment Configuration**:
   - Ensure your `.env.local` file contains the necessary variables
   - At minimum for Slack functionality, you need:
     ```
     SLACK_APP_TOKEN=xapp-1-...
     SLACK_BOT_TOKEN=xoxb-...
     SLACK_SIGNING_SECRET=...
     ALFRED_ENABLE_SLACK=true
     ```

## Method 1: Using Docker Compose Directly (Recommended for Slack Testing)

For testing just the Slack functionality:

```bash
# Start only the services required for Slack
./docker-compose-env.sh -f docker-compose.yml up -d redis slack_mcp_gateway

# Check that the services are running
docker ps

# Check the logs
docker logs -f slack_mcp_gateway
```

## Method 2: Using the Platform Startup Script

For starting the entire platform or specific services:

```bash
# Start the entire platform in detached mode
./start-platform.sh -d

# Or start specific services
./start-platform.sh redis slack_mcp_gateway agent-core
```

## Method 3: Using Makefile Targets

For a standardized approach with generated compose files:

```bash
# Generate the docker-compose file
make compose-generate

# Start the platform
make up
```

## Verifying Slack Commands

1. Check that your Slack app is properly configured with:
   - Bot token with appropriate scopes
   - Socket Mode enabled
   - Slash commands registered

2. Try the following commands in your Slack workspace:
   - `/alfred help` - Shows available commands
   - `/alfred status` - Shows platform status
   - `/diag health` - If the full platform is running

3. Monitor logs to ensure commands are being processed:
   ```bash
   docker logs -f slack_mcp_gateway
   ```

## Troubleshooting

If commands aren't working:

1. **Check service status**: Ensure all required services are running and healthy
   ```bash
   docker ps
   ```

2. **Verify Slack connection**: Check the logs to ensure the gateway is connected to Slack
   ```bash
   docker logs slack_mcp_gateway | grep "Connected to Slack"
   ```

3. **Environment variables**: Make sure your `.env.local` has the correct Slack tokens

4. **Slack app settings**: Verify Socket Mode is enabled and slash commands are registered

5. **Docker status**: Ensure Docker is running with `sudo service docker status`
