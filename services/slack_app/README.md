# Alfred Platform Slack App

This service integrates the Alfred Agent Platform with Slack, providing a conversational interface to Alfred directly within Slack workspaces.

## Features

- Slash commands for interacting with Alfred
- Real-time responses and notifications
- Status and health monitoring
- Agent-specific commands

## Quick Start

1. Create a `.env` file from `.env.template` and add your Slack API tokens
2. Install dependencies: `pip install -r requirements.txt`
3. Start the app: `python run.py`

## Usage

After inviting the bot to a channel, you can use the following commands:

- `/alfred help` - Show help message
- `/alfred status` - Show platform status
- `/alfred health` - Check service health
- `/alfred search <query>` - Search for information
- `/alfred ask <question>` - Ask a question to Alfred agents
- `/alfred agents` - List available agents

## Development

See the [Slack App documentation](../../docs/slack_app.md) for complete setup and configuration details.

## Deployment

The app is deployed as part of the Alfred Platform using Helm charts. Configuration is managed through values in `charts/alfred/values.yaml`.
