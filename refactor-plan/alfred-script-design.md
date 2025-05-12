# Alfred Agent Platform v2 - Unified Script Design

## alfred.sh Script

The `alfred.sh` script will provide a unified interface for managing the platform. It will:

1. Accept commands and options for different operations
2. Handle environment and component selection
3. Manage the Docker network and containers
4. Provide helpful feedback and documentation

## Usage

```
./alfred.sh <command> [options]
```

### Commands

| Command | Description |
|---------|-------------|
| start | Start services |
| stop | Stop services |
| restart | Restart services |
| status | Show status of services |
| logs | View logs |
| exec | Execute a command in a container |
| build | Build services |
| clean | Clean up resources |
| help | Show help |

### Options

| Option | Description | Default |
|--------|-------------|---------|
| --env=dev\|prod | Environment | dev |
| --components=core,agents,ui,monitoring | Components to include | all |
| --build | Build before starting | false |
| --clean | Clean before starting | false |
| --service=name | Service name for logs/exec | |
| --follow | Follow logs | false |
| --force | Force operation | false |

## Script Structure

```bash
#!/bin/bash

# Configurable variables
COMPOSE_FILES="-f docker-compose.yml"
ALFRED_NETWORK="alfred-network"
DEFAULT_ENV="dev"
DEFAULT_COMPONENTS="all"

# ASCII Art and colors
function print_banner() {
  # Display ASCII art banner
}

function print_help() {
  # Display help text
}

function create_network() {
  # Create Docker network if it doesn't exist
}

function select_environment() {
  # Select and configure environment files
}

function select_components() {
  # Select and configure component files
}

function start_services() {
  # Start services with selected configuration
}

function stop_services() {
  # Stop services
}

function restart_services() {
  # Restart services
}

function show_status() {
  # Show status of services
}

function view_logs() {
  # View logs for services
}

function exec_command() {
  # Execute command in container
}

function build_services() {
  # Build service images
}

function clean_resources() {
  # Clean up resources
}

# Parse command line arguments
function parse_args() {
  # Parse command and options
}

# Main function
function main() {
  # Main script logic
}

# Execute main function
main "$@"
```

## Example Usage Scenarios

### Starting the full platform for development

```bash
./alfred.sh start
```

### Starting only core and agents for development

```bash
./alfred.sh start --components=core,agents
```

### Starting the platform for production

```bash
./alfred.sh start --env=prod
```

### Viewing logs for a specific service

```bash
./alfred.sh logs --service=alfred --follow
```

### Executing a command in a container

```bash
./alfred.sh exec --service=alfred "python -m alembic upgrade head"
```

### Cleaning up and starting fresh

```bash
./alfred.sh start --clean
```

## Implementation Details

### Environment Selection

The script will:
1. Always use the base `docker-compose.yml`
2. Add `-f docker-compose.ENV.yml` based on `--env` option
3. Detect and use `docker-compose.override.yml` if present for development

### Component Selection

The script will:
1. Parse the `--components` option into an array
2. For each component, add `-f docker-compose.COMPONENT.yml`
3. Handle the special case "all" to include everything

### Network Management

The script will:
1. Check if the network exists before creating it
2. Recreate the network on `--clean` option
3. Use the existing network otherwise

### Container Management

The script will:
1. Use `docker-compose` commands with the appropriate files
2. Check container status and provide feedback
3. Handle errors and provide helpful messages

## Integration with Existing Tools

The script will:
1. Support integration with the Makefile
2. Maintain backward compatibility where possible
3. Allow gradual migration from existing scripts