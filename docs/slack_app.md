# Slack App Integration for Alfred Platform

## Overview

The Slack App integration allows users to interact with the Alfred Agent Platform directly from Slack. This document provides instructions for setting up, configuring, and maintaining the Slack App integration.

## Environment Variables

The following environment variables are required for the Slack App to function:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `SLACK_BOT_TOKEN` | Bot token for the Slack app (starts with `xoxb-`) | Yes | None |
| `SLACK_APP_TOKEN` | App-level token for Socket Mode (starts with `xapp-`) | Yes | None |
| `SLACK_SIGNING_SECRET` | Signing secret for request verification | Yes | None |
| `SOCKET_MODE` | Enable Socket Mode for local development | No | "true" |
| `LOG_LEVEL` | Logging level (debug, info, warn, error) | No | "info" |
| `COMMAND_PREFIX` | Prefix for slash commands | No | "/alfred" |
| `DEFAULT_CHANNEL` | Default channel for notifications | No | "general" |
| `ALLOWED_COMMANDS` | Comma-separated list of allowed commands | No | "help,status,search,ask,agents" |

## Slack App Setup

To set up the Slack App in your workspace:

1. **Create a Slack App:**
   - Visit [api.slack.com/apps](https://api.slack.com/apps) and click "Create New App"
   - Choose "From scratch" and provide a name for your app
   - Select the workspace to install the app to

2. **Configure Basic Information:**
   - Under "Basic Information", add a description and icon
   - In the "App Credentials" section, note the Signing Secret for the `SLACK_SIGNING_SECRET` environment variable

3. **Add Required OAuth Scopes:**
   - Navigate to "OAuth & Permissions"
   - Add the following Bot Token Scopes:
     - `chat:write`
     - `commands`
     - `im:history`
     - `im:read`
     - `im:write`
     - `users:read`

4. **Enable Socket Mode:**
   - Go to "Socket Mode" and enable it
   - Generate a new app-level token with the `connections:write` scope
   - Save this token as the `SLACK_APP_TOKEN` environment variable

5. **Create Slash Commands:**
   - Navigate to "Slash Commands" and click "Create New Command"
   - Command: `/alfred`
   - Request URL: Not needed with Socket Mode
   - Short Description: "Interact with Alfred Agent Platform"
   - Usage Hint: "help | status | search <query> | ask <question> | agents"
   - Check "Escape channels, users, and links sent to your app"

6. **Install App to Workspace:**
   - Go to "Install App" and click "Install to Workspace"
   - Review permissions and click "Allow"
   - Copy the Bot User OAuth Token as the `SLACK_BOT_TOKEN` environment variable

## Slash Commands Registration

When adding new slash commands to the integration, follow these steps:

1. Add the command name to the `ALLOWED_COMMANDS` environment variable or the `config.ALLOWED_COMMANDS` value in the Helm chart
2. Update the usage hint in the Slack App configuration
3. Implement the command handler in the application code
4. Update the documentation to include the new command

## Kubernetes Deployment

The Slack App is deployed using Helm and can be configured through the following values:

```yaml
slackApp:
  enabled: true  # Enable/disable the Slack App deployment
  image:
    repository: ghcr.io/alfred/slack-app
    tag: v0.8.1
    pullPolicy: IfNotPresent
  env:
    SOCKET_MODE: "true"  # Socket Mode is the default and recommended approach
    LOG_LEVEL: "info"
  secrets:
    # These should be provided via CI/CD from GitHub Environments
    SLACK_BOT_TOKEN: ""
    SLACK_APP_TOKEN: ""  # Required for Socket Mode
    SLACK_SIGNING_SECRET: ""
  config:
    COMMAND_PREFIX: "/alfred"
    DEFAULT_CHANNEL: "general"
    ALLOWED_COMMANDS: "help,status,search,ask,agents"
  ingress:
    enabled: false  # Set to true only if HTTP mode is required instead of Socket Mode
```

### Socket Mode vs. HTTP Mode

The Slack App uses Socket Mode by default, which provides several advantages:
- Reduced attack surface (no public-facing endpoints)
- No need to configure request URL verification
- Simplified network setup (only outbound connections)
- Works in environments without public IPs

HTTP mode is supported as a fallback by setting `SOCKET_MODE=false` and enabling the ingress, but requires additional setup:
- Set `slackApp.ingress.enabled=true` in Helm
- Configure request URLs in the Slack app admin panel
- Ensure your cluster has proper ingress controller setup

## Token Rotation

Slack tokens should be rotated every 90 days as per security best practices. To rotate Slack tokens:

1. **Generate New Tokens:**
   - For Bot Token: Go to "OAuth & Permissions" and click "Regenerate Token"
   - For App Token: Go to "Socket Mode" and click "Rotate Token" (critical for Socket Mode functionality)
   - For Signing Secret: Go to "Basic Information" and click "Rotate" in the App Credentials section

2. **Update Tokens in Kubernetes Secrets:**
   - Update the GitHub Environment secrets with the new tokens (staging and production)
   - Navigate to GitHub ▸ Settings ▸ Environments ▸ staging/prod
   - Update the respective secrets: `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, and `SLACK_SIGNING_SECRET`
   - Redeploy the Slack App to apply the new tokens

3. **Verify Token Update:**
   - Confirm the Slack App reconnects successfully with Socket Mode
   - Test basic functionality with simple commands like `/alfred help`
   - Check logs to verify Socket Mode connection is active

4. **Update Calendar Reminder:**
   - Add a reminder in the team calendar for the next rotation (90 days from current rotation)
   - Include link to this documentation in the calendar event

## Known Issues & Fixes

- [x] **Socket Mode command registration fix (v0.8.1)**
  - Issue: Commands were registered with slash prefix (`@app.command("/alfred")`) causing dispatch failures
  - Fix: Register command without slash prefix (`@app.command("alfred")`)
  - Reference: See [SLACK-COMMAND-FIX-REPORT.md](../SLACK-COMMAND-FIX-REPORT.md) for details
  - Symptoms: `/alfred` commands failing with "dispatch_failed" and "dispatch_unknown_error" in Slack

## Troubleshooting

Common issues and their solutions:

1. **Connection Failures:**
   - Check that the `SLACK_APP_TOKEN` is valid and has the correct scope
   - Verify the app has Socket Mode enabled
   - Confirm logs show "Socket Mode client connected" message

2. **Authentication Failures:**
   - Confirm the `SLACK_BOT_TOKEN` is valid and not expired
   - Ensure the bot has been invited to the channels it needs to access

3. **Command Not Found:**
   - Check that the command is included in the `ALLOWED_COMMANDS` list
   - Verify the command handler is properly implemented
   - Ensure command is registered without slash prefix (`@app.command("alfred")`, not `@app.command("/alfred")`)

4. **Health Check Failures:**
   - The `/healthz` and `/readyz` endpoints should return 200 OK
   - Check the logs for any startup errors

5. **Command Dispatch Errors:**
   - If you see "dispatch_failed" or "dispatch_unknown_error" in Slack, check:
     - Command registration format (no slash prefix)
     - Exception handling in command processors
     - Verify `ack()` is called immediately at the start of the handler
