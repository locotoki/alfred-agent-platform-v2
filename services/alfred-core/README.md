# Alfred Core Service

This is the unified core service for the Alfred Agent Platform. It provides a modular architecture with a shared core implementation and multiple interface adapters.

## Features

- **Unified Core Logic**: Shared business logic used by all interfaces
- **Multiple Interfaces**: Support for Slack, API, and Streamlit
- **Modular Design**: Easy to add new interfaces or extend functionality
- **Configuration Options**: Different operating modes for various use cases

## Architecture

The Alfred Core service consists of:

1. **Core API** (`core.py`): Implements the shared business logic and API endpoints
2. **Interface Adapters**:
   - **Slack Interface** (`slack_interface.py`): Handles Slack events and commands
   - More interfaces can be added easily
3. **Main Application** (`main.py`): Combines the core with enabled interfaces

## Operating Modes

The service supports different operating modes:

- **Default Mode**: Regular operation with full functionality
- **Demo Mode**: Simplified responses for demonstration purposes
- **Development Mode**: Additional logging and debugging features

## Usage

### Starting the Service

To start the service:

```bash
./start.sh
```

To start in demo mode:

```bash
./start.sh demo
```

To start without Slack integration:

```bash
./start.sh no-slack
```

### API Endpoints

The service exposes the following API endpoints:

- `GET /`: API information
- `GET /health`: Health check
- `POST /api/chat`: Send a chat message
- `GET /api/task/{task_id}`: Get task information

When Slack is enabled, additional endpoints are available:

- `POST /slack/events`: Handle Slack events
- `POST /slack/install`: Handle Slack app installation (future)

### Environment Variables

The service can be configured using the following environment variables:

- `ALFRED_MODE`: Operating mode (default, demo, development)
- `ENABLE_SLACK`: Whether to enable Slack integration (true/false)
- `SLACK_BOT_TOKEN`: Slack Bot token for authentication
- `SLACK_SIGNING_SECRET`: Slack signing secret for request verification
- `REDIS_URL`: URL for Redis connection
- `DATABASE_URL`: URL for database connection
- `LOG_LEVEL`: Logging level (INFO, DEBUG, etc.)

## Development

### Prerequisites

- Python 3.11+
- Docker and Docker Compose
- Redis server

### Setup

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run locally:
   ```bash
   uvicorn app.main:app --reload
   ```

### Adding a New Interface

To add a new interface (e.g., Microsoft Teams):

1. Create a new file `teams_interface.py` in the `app` directory
2. Implement the Teams-specific functionality
3. Update `main.py` to include the new interface when enabled

## Deployment

The service can be deployed using Docker:

```bash
docker build -t alfred-core:latest .
docker run -p 8011:8011 alfred-core:latest
```

Or with Docker Compose:

```bash
docker-compose up -d
```

## Integration with Streamlit

The service includes integration with the Streamlit chat interface. When started with Docker Compose, the Streamlit UI will be available at http://localhost:8501.