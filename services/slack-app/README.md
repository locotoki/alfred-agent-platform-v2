# Slack App Integration

This directory contains the Slack app implementation for the Alfred Agent Platform v2, enabling interactive commands and notifications.

## Features

- Socket Mode integration for secure connections without public URLs
- Slash commands (`/alfred`) for direct interaction with the platform
- Interactive components (buttons, menus) for remediation workflows
- Real-time notifications for alerts and system events

## Setup

1. Create a Slack app in the [Slack API Console](https://api.slack.com/apps)
2. Enable Socket Mode in the app settings
3. Generate an App-Level Token with `connections:write` scope
4. Create a slash command `/alfred` with the request URL (placeholder during Socket Mode setup)
5. Add the following OAuth scopes:
   - `chat:write`
   - `commands`
   - `channels:history`
   - `channels:read`
6. Add the required environment variables to GitHub Secrets:
   ```
   SLACK_BOT_TOKEN
   SLACK_APP_TOKEN
   SLACK_SIGNING_SECRET
   ```

## Usage

The `/alfred` command supports the following subcommands:

- `/alfred help` - Shows available commands
- `/alfred health [service]` - Checks health of a service (or all services)
- `/alfred remediate <service>` - Initiates remediation for a service

## Development

### Local Testing

1. Install dependencies: `pip install -r requirements.txt`
2. Set required environment variables
3. Run the app: `python -m slack_app.server`

### Testing

Run the tests with:
```
pytest tests/slack
```

### CI/CD

The CI pipeline includes a `slack-smoke` job that verifies the Slack integration works correctly before deployment.

## Implementation Details

- `slack_app/` - Main package containing the Slack app implementation
- `slack_app/server.py` - FastAPI server for HTTP endpoints and health checks
- `slack_app/commands.py` - Slash command handlers
- `slack_app/interactive.py` - Interactive component handlers
- `slack_app/notifications.py` - Notification utilities

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Slack App   │<───>│ Socket Mode │<───>│ Alfred Core │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              v
                                        ┌─────────────┐
                                        │ Remediation │
                                        │ Workflows   │
                                        └─────────────┘
```

The Slack app connects to the Alfred platform via Socket Mode, which eliminates the need for public endpoints. Commands are routed to the appropriate services, and interactive components allow for complex workflows like health checks and remediation.
