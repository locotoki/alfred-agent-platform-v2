# Alfred Streamlit Chat Interface

This directory contains the implementation of the Streamlit-based chat interface for the Alfred Agent Platform. It provides a simple, intuitive web-based UI for interacting with Alfred, either for development/testing purposes or as a lightweight alternative to the Slack interface.

## Production Deployment Status

**[✅ DEPLOYED]** The Streamlit Chat Interface has been successfully deployed in production mode and is available at:
- **Streamlit UI**: http://localhost:8502
- **Alfred API**: http://localhost:8012

## Features

- **Web-based Chat Interface**: Communicate with Alfred through a clean, modern chat UI
- **Command Support**: Use all the same commands available in Slack
- **Real-time Responses**: Get immediate feedback for commands like help and ping
- **Task Tracking**: Track tasks created by complex commands like trend analysis
- **Configuration Options**: Customize the interface through the sidebar settings
- **Debug Mode**: Troubleshoot API communication with request/response inspection
- **Connection Testing**: Verify connectivity to Alfred Bot API
- **Clear UI**: Simple, intuitive design focused on the chat experience

## Prerequisites

- Python 3.11+
- pip package manager
- Access to the Alfred Bot API

## Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set environment variables:
```bash
export ALFRED_API_URL="http://localhost:8011"  # Point to Alfred Bot API
```

## Usage

### Development Mode

Use the provided script to start the application in development mode:

```bash
./start-dev.sh
```

This will start Streamlit on the default port (8501) and connect to the configured Alfred Bot API.

### Using with Docker

A Docker Compose configuration is provided to start both the Streamlit Chat UI and the Alfred Bot services:

```bash
docker-compose up
```

This will start:
- Streamlit Chat UI on port 8501
- Alfred Bot API on port 8011
- Redis on port 6379

### Starting the Full Development Stack

To start both the Alfred Bot and Streamlit Chat UI in development mode with proper configuration:

```bash
./start-dev-stack.sh
```

This script will:
1. Start Redis in a Docker container if not already running
2. Start the Alfred Bot service with proper configuration
3. Start the Streamlit Chat UI connected to the Alfred Bot

## Integration with Alfred Bot

The Streamlit Chat UI communicates with Alfred through the `/api/chat` endpoint implemented in the Alfred Bot service. This endpoint accepts and processes messages similar to how Slack messages are handled, allowing for a consistent experience across interfaces.

### Key Integration Points

- **Chat API**: Uses the `/api/chat` endpoint for sending messages and receiving responses
- **Command Processing**: Handles commands like `help`, `ping`, and `trend` through the API
- **Task Tracking**: Supports tracking long-running tasks via task IDs
- **Health Checking**: Verifies connectivity to the Alfred Bot API

## Configuration Options

The following configuration options are available through the sidebar:

- **Alfred API URL**: The URL of the Alfred Bot API (default: http://localhost:8011)
- **Chat History Size**: Maximum number of messages to display (default: 100)
- **Debug Mode**: Enables request/response logging for troubleshooting

## Extending the Interface

To add new features to the Streamlit Chat UI:

1. Edit the `streamlit_chat_ui.py` file
2. Add new UI components using Streamlit's API
3. Add new API calls to support additional functionality
4. Test changes by running `./start-dev.sh`

## Known Limitations

- No authentication system (use network controls for access restriction)
- Limited natural language understanding (primarily command-based)
- No persistent memory across browser sessions
- Does not support file uploads/downloads

## Related Documentation

- [Alfred Bot API](../alfred-bot/README.md)
- [Slack Bot Interface](../../docs/agents/interfaces/alfred-slack-bot.md)
- [Chat UI Implementation Spec](../../docs/interfaces/chat-ui-implementation.md)