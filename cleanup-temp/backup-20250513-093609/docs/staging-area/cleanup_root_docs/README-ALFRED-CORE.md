# Alfred Agent Platform v2 - Core Service

This document provides an overview of the new unified Alfred Core service that integrates all interfaces into a single, cohesive platform.

## Overview

The Alfred Core service unifies the previously separate interfaces (Slack, API, Streamlit) into a single service with a common core implementation. This approach offers several advantages:

- **Unified Business Logic**: All interfaces share the same core logic, ensuring consistent behavior
- **Simplified Deployment**: Easier to deploy and manage as a single service
- **Improved Maintainability**: Changes to core logic only need to be made in one place
- **Extensibility**: Easy to add new interfaces without duplicating code

## Architecture

```
┌───────────────────────────────────────────────┐
│                Alfred Core                    │
├───────────────┬────────────────┬──────────────┤
│ Slack         │ API            │ Streamlit    │
│ Interface     │ Interface      │ Interface    │
└───────┬───────┴───────┬────────┴───────┬──────┘
        │               │                │
        ▼               ▼                ▼
┌───────────────┬───────────────┬────────────────┐
│ Slack         │ HTTP API      │ Streamlit      │
│ Workspace     │ Clients       │ UI             │
└───────────────┴───────────────┴────────────────┘
```

### Components

1. **Core API** (`core.py`):
   - Implements the shared business logic
   - Handles command parsing and processing
   - Manages tasks and state

2. **Interface Adapters**:
   - **Slack Interface** (`slack_interface.py`): Handles Slack-specific events
   - **API Interface**: Exposes RESTful API endpoints
   - **More interfaces can be added easily**

3. **Main Application** (`main.py`):
   - Combines all components
   - Configures enabled interfaces based on environment

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Slack API credentials (for Slack integration)

### Quick Start

1. Navigate to the Alfred Core directory:
   ```bash
   cd services/alfred-core
   ```

2. Start the service:
   ```bash
   ./start.sh
   ```

3. Access the interfaces:
   - API: http://localhost:8011
   - Streamlit UI: http://localhost:8501
   - Slack: Use your Slack workspace

### Configuration

The service can be configured using environment variables:

```bash
# Start with demo responses
ALFRED_MODE=demo ./start.sh

# Disable Slack integration
ENABLE_SLACK=false ./start.sh

# Configure Redis connection
REDIS_URL=redis://custom-redis:6379 ./start.sh
```

## Available Commands

The following commands are available across all interfaces:

- `help`: Display available commands
- `ping`: Test if the service is responsive
- `trend <topic>`: Analyze trends for a specified topic
- `status <task_id>`: Check the status of a task
- `cancel <task_id>`: Cancel a running task

## Interface-Specific Features

### Slack Interface

- Supports slash commands (`/alfred`)
- Handles direct messages
- Processes @mentions in channels
- Supports threaded conversations

### API Interface

- RESTful API endpoints
- JSON request/response format
- Swagger documentation at `/docs`

### Streamlit Interface

- Web-based chat UI
- Configuration options in sidebar
- Debug mode for API inspection
- Mobile-friendly design

## Next Steps

The following enhancements are planned:

1. **Authentication and Authorization**:
   - Add user authentication via Supabase
   - Implement role-based access control

2. **Advanced NLU**:
   - Integrate with NLU services for better language understanding
   - Support more complex conversations

3. **Additional Interfaces**:
   - Microsoft Teams integration
   - Discord bot
   - Native mobile app

4. **Enhanced Analytics**:
   - Detailed trend analysis with visualization
   - Historical data tracking and comparison

## Contributing

Contributions to the Alfred Core service are welcome! Please refer to the [contribution guidelines](CONTRIBUTING.md) for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
