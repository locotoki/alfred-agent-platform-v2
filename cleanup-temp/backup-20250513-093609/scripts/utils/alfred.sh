#!/bin/bash
#
# Alfred Agent Platform v2 - Unified Management Script
# This script provides a single interface for managing the Alfred platform
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configurable variables
ALFRED_NETWORK="alfred-network"
DEFAULT_ENV="dev"
DEFAULT_COMPONENTS="all"
DOCKER_COMPOSE_COMMAND="docker-compose"

# Configuration variables initialized based on options
COMPOSE_FILES="-f docker-compose.yml"
ENV_CONFIG=""
COMPONENTS=()
OPERATION=""
SERVICE=""
BUILD=false
CLEAN=false
FOLLOW=false
FORCE=false

# Display ASCII art banner
function print_banner() {
  echo -e "${BLUE}"
  echo "    _    _  __               _   "
  echo "   / \  | |/ _|_ __ ___  __| |  "
  echo "  / _ \ | | |_| '__/ _ \/ _\` |  "
  echo " / ___ \| |  _| | |  __/ (_| |  "
  echo "/_/   \_\_|_| |_|  \___|\__,_|  "
  echo "                               "
  echo " Agent Platform v2"
  echo -e "${NC}"
}

# Display help text
function print_help() {
  echo -e "\nUsage: ./alfred.sh <command> [options]"
  echo -e "\nCommands:"
  echo "  start         Start services"
  echo "  stop          Stop services"
  echo "  restart       Restart services"
  echo "  status        Show status of services"
  echo "  logs          View logs of services"
  echo "  exec          Execute a command in a container"
  echo "  build         Build services"
  echo "  clean         Clean up resources"
  echo "  help          Show this help message"
  echo -e "\nOptions:"
  echo "  --env=dev|prod                         Environment (default: dev)"
  echo "  --components=core,agents,ui,monitoring Components to include (default: all)"
  echo "  --service=name                         Service name for logs/exec"
  echo "  --build                                Build before starting"
  echo "  --clean                                Clean before starting"
  echo "  --follow                               Follow logs"
  echo "  --force                                Force operation"
  echo -e "\nExamples:"
  echo "  ./alfred.sh start                      Start all services in dev mode"
  echo "  ./alfred.sh start --env=prod           Start all services in production mode"
  echo "  ./alfred.sh start --components=core,agents  Start only core and agent components"
  echo "  ./alfred.sh logs --service=agent-core  View logs for the agent-core service"
  echo "  ./alfred.sh exec --service=redis redis-cli  Run redis-cli in the redis container"
  echo -e "\nNotes:"
  echo "  - All services use the 'alfred-network' Docker network for communication"
  echo "  - The 'clean' command removes the Docker network and containers"
  echo "  - Use --clean to create a fresh Docker network when starting services"
}

# Create Docker network if it doesn't exist
function create_network() {
  if ! docker network inspect $ALFRED_NETWORK > /dev/null 2>&1; then
    echo -e "${YELLOW}Creating $ALFRED_NETWORK network...${NC}"
    docker network create $ALFRED_NETWORK
  else
    echo -e "${GREEN}Using existing $ALFRED_NETWORK network${NC}"
  fi
}

# Remove Docker network if it exists
function remove_network() {
  if docker network inspect $ALFRED_NETWORK > /dev/null 2>&1; then
    echo -e "${YELLOW}Removing $ALFRED_NETWORK network...${NC}"
    docker network rm $ALFRED_NETWORK
  fi
}

# Select and configure environment
function select_environment() {
  local env=$1

  if [[ "$env" == "prod" ]]; then
    echo -e "${YELLOW}Using production environment${NC}"
    ENV_CONFIG="-f docker-compose.prod.yml"
  else
    echo -e "${YELLOW}Using development environment${NC}"
    ENV_CONFIG="-f docker-compose.dev.yml"

    # Use docker-compose.override.yml if it exists
    if [[ -f "docker-compose.override.yml" ]]; then
      echo -e "${YELLOW}Including docker-compose.override.yml${NC}"
      ENV_CONFIG="$ENV_CONFIG -f docker-compose.override.yml"
    fi
  fi
}

# Select and configure components
function select_components() {
  local components=$1
  local component_config=""

  if [[ "$components" == "all" ]]; then
    echo -e "${YELLOW}Including all components${NC}"
    # No additional files needed for 'all' as base docker-compose.yml includes everything
  else
    echo -e "${YELLOW}Including components: $components${NC}"

    # Split components string into array
    IFS=',' read -r -a COMPONENTS <<< "$components"

    # Add component-specific docker-compose files
    for component in "${COMPONENTS[@]}"; do
      if [[ -f "docker-compose.${component}.yml" ]]; then
        component_config="$component_config -f docker-compose.${component}.yml"
      else
        echo -e "${RED}Warning: docker-compose.${component}.yml not found${NC}"
      fi
    done
  fi

  # Update compose files
  COMPOSE_FILES="$COMPOSE_FILES $component_config"
}

# Start services with selected configuration
function start_services() {
  echo -e "${YELLOW}Starting services...${NC}"

  # Create network if it doesn't exist
  create_network

  # Build if requested
  if [[ "$BUILD" == true ]]; then
    echo -e "${YELLOW}Building services...${NC}"
    $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG build
  fi

  # Start services
  $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG up -d

  echo -e "${GREEN}Services started${NC}"
}

# Stop services
function stop_services() {
  echo -e "${YELLOW}Stopping services...${NC}"

  if [[ "$FORCE" == true ]]; then
    $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG down --remove-orphans
  else
    $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG stop
  fi

  echo -e "${GREEN}Services stopped${NC}"
}

# Restart services
function restart_services() {
  echo -e "${YELLOW}Restarting services...${NC}"

  if [[ "$FORCE" == true ]]; then
    stop_services
    start_services
  else
    $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG restart
  fi

  echo -e "${GREEN}Services restarted${NC}"
}

# Show status of services
function show_status() {
  echo -e "${YELLOW}Service status:${NC}"
  $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG ps
}

# View logs for services
function view_logs() {
  if [[ -n "$SERVICE" ]]; then
    echo -e "${YELLOW}Viewing logs for $SERVICE...${NC}"

    if [[ "$FOLLOW" == true ]]; then
      $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG logs -f "$SERVICE"
    else
      $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG logs "$SERVICE"
    fi
  else
    echo -e "${YELLOW}Viewing logs for all services...${NC}"

    if [[ "$FOLLOW" == true ]]; then
      $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG logs -f
    else
      $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG logs
    fi
  fi
}

# Execute command in container
function exec_command() {
  if [[ -z "$SERVICE" ]]; then
    echo -e "${RED}Error: --service is required for exec command${NC}"
    exit 1
  fi

  # Shift past all the options to get the command
  local cmd=""
  for arg in "${EXTRA_ARGS[@]}"; do
    cmd="$cmd $arg"
  done

  echo -e "${YELLOW}Executing in $SERVICE:${NC} $cmd"
  $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG exec "$SERVICE" $cmd
}

# Build service images
function build_services() {
  echo -e "${YELLOW}Building services...${NC}"

  if [[ -n "$SERVICE" ]]; then
    $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG build "$SERVICE"
  else
    $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG build
  fi

  echo -e "${GREEN}Services built${NC}"
}

# Clean up resources
function clean_resources() {
  echo -e "${YELLOW}Cleaning up resources...${NC}"

  # Stop all containers
  $DOCKER_COMPOSE_COMMAND $COMPOSE_FILES $ENV_CONFIG down --remove-orphans

  # Remove network
  remove_network

  # Prune resources
  if [[ "$FORCE" == true ]]; then
    echo -e "${YELLOW}Pruning containers, networks, and volumes...${NC}"
    docker container prune -f
    docker network prune -f
    docker volume prune -f
  fi

  echo -e "${GREEN}Resources cleaned${NC}"
}

# Parse command line arguments
function parse_args() {
  # Default values
  ENV="$DEFAULT_ENV"
  COMPONENTS_LIST="$DEFAULT_COMPONENTS"
  EXTRA_ARGS=()

  # First argument is the command
  OPERATION="$1"
  shift

  # Process remaining arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --env=*)
        ENV="${1#*=}"
        ;;
      --components=*)
        COMPONENTS_LIST="${1#*=}"
        ;;
      --service=*)
        SERVICE="${1#*=}"
        ;;
      --build)
        BUILD=true
        ;;
      --clean)
        CLEAN=true
        ;;
      --follow)
        FOLLOW=true
        ;;
      --force)
        FORCE=true
        ;;
      *)
        EXTRA_ARGS+=("$1")
        ;;
    esac
    shift
  done

  # Configure based on options
  select_environment "$ENV"
  select_components "$COMPONENTS_LIST"
}

# Main function
function main() {
  print_banner

  if [[ $# -eq 0 || "$1" == "help" ]]; then
    print_help
    exit 0
  fi

  # Parse arguments
  parse_args "$@"

  # Clean if requested
  if [[ "$CLEAN" == true ]]; then
    clean_resources
  fi

  # Execute the requested operation
  case "$OPERATION" in
    start)
      start_services
      ;;
    stop)
      stop_services
      ;;
    restart)
      restart_services
      ;;
    status)
      show_status
      ;;
    logs)
      view_logs
      ;;
    exec)
      exec_command
      ;;
    build)
      build_services
      ;;
    clean)
      clean_resources
      ;;
    *)
      echo -e "${RED}Error: Unknown command: $OPERATION${NC}"
      print_help
      exit 1
      ;;
  esac
}

# Execute main function with all arguments
main "$@"
