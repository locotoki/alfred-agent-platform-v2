# Alfred Platform - Environment Quick Start

This quick start guide explains how to get your local development environment working with Slack commands.

## Prerequisites

1. Docker Engine installed
2. Valid Slack API tokens (Bot Token, App Token, and Signing Secret)

## Step 1: Configure Environment

1. Run the setup script to create your local environment file:
   ```bash
   ./setup-dev-env.sh
   ```

   If you already have a `.env.local` file, either:
   - Continue with your existing file, or
   - Run `./setup-dev-env.sh` and choose to create a new one (it will back up the existing file)

2. Ensure your `.env.local` contains the following Slack-related variables:
   ```
   SLACK_BOT_TOKEN=xoxb-your-token       # Bot User OAuth Token
   SLACK_APP_TOKEN=xapp-your-token       # App-Level Token
   SLACK_SIGNING_SECRET=your-secret      # Signing Secret
   ALFRED_ENABLE_SLACK=true              # Enable Slack integration
   ```

## Step 2: Start Required Services

1. Start the Docker daemon:
   ```bash
   sudo service docker start
   ```

2. Start only the services required for Slack:
   ```bash
   ./start-slack.sh
   ```

   This script will start:
   - redis
   - db-postgres
   - agent-core
   - slack_mcp_gateway
   - slack-adapter

## Step 3: Test Slack Commands

In your Slack workspace, try the following commands:

1. `/alfred help` - Should show available commands
2. `/alfred status` - Should show platform status
3. `/diag health` - Should show detailed health status

## Troubleshooting

If commands aren't working:

1. Check service logs:
   ```bash
   ./docker-compose-env.sh -f docker-compose.yml logs -f slack_mcp_gateway slack-adapter
   ```

2. Verify Slack app configuration:
   - Ensure Socket Mode is enabled
   - Verify the slash commands are registered
   - Confirm the bot has appropriate permissions

3. Validate environment variables:
   ```bash
   ./docker-compose-env.sh -f docker-compose.yml exec slack_mcp_gateway env | grep SLACK
   ```

4. Check service health:
   ```bash
   ./docker-compose-env.sh -f docker-compose.yml ps
   ```

## Stopping Services

To stop the services:
```bash
./docker-compose-env.sh -f docker-compose.yml stop
```

Or to stop and remove containers:
```bash
./docker-compose-env.sh -f docker-compose.yml down
```
