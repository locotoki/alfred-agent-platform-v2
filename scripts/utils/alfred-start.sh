#!/bin/bash
#
# Alfred Agent Platform v2 - Unified Startup Script
# This script provides a centralized way to start the platform with the new unified docker-compose file
#

# Color configuration
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Progress indicator
function show_progress() {
  echo -e "${BLUE}==>${NC} $1"
}

# Success indicator
function show_success() {
  echo -e "${GREEN}✓${NC} $1"
}

# Error indicator
function show_error() {
  echo -e "${RED}✗${NC} $1"
}

# Warning indicator
function show_warning() {
  echo -e "${YELLOW}!${NC} $1"
}

# Default configuration
COMPOSE_FILE="docker-compose.unified.yml"
MODE="all"
ENV="dev"
COMMAND="up"
DETACHED="-d"

# Show usage instructions
function show_usage() {
  echo -e "${BLUE}Alfred Agent Platform v2 - Unified Startup Script${NC}"
  echo ""
  echo "Usage: $0 [options] [command]"
  echo ""
  echo "Commands:"
  echo "  setup     Initialize the unified setup (stops/removes old containers)"
  echo "  up        Start all services (default)"
  echo "  down      Stop all services"
  echo "  restart   Restart all services"
  echo "  status    Show service status"
  echo "  logs      Show service logs"
  echo "  health    Check service health"
  echo ""
  echo "Options:"
  echo "  -m, --mode MODE    Specify which components to run:"
  echo "                     'all' - All services (default)"
  echo "                     'core' - Core infrastructure only"
  echo "                     'agents' - Core + Agent services"
  echo "                     'ui' - UI services only" 
  echo "                     'llm' - LLM services only"
  echo "  -e, --env ENV      Specify environment:"
  echo "                     'dev' - Development environment (default)"
  echo "                     'prod' - Production environment"
  echo "  -f, --foreground   Run in foreground (don't detach)"
  echo "  -h, --help         Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                    # Start all services in detached mode (development)"
  echo "  $0 -m core -f         # Start core services in foreground"
  echo "  $0 -m llm             # Start LLM services only"
  echo "  $0 -m agents -e prod  # Start agents in production mode"
  echo "  $0 logs               # Show logs for all services"
  echo "  $0 -m ui logs         # Show logs for UI services only"
  echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -m|--mode)
      MODE="$2"
      shift 2
      ;;
    -e|--env)
      ENV="$2"
      shift 2
      ;;
    -f|--foreground)
      DETACHED=""
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    up|down|restart|status|logs|health|setup)
      COMMAND="$1"
      shift
      ;;
    *)
      show_error "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

# Validate mode
if [[ ! "$MODE" =~ ^(all|core|agents|ui|llm)$ ]]; then
  show_error "Invalid mode: $MODE"
  show_usage
  exit 1
fi

# Validate environment
if [[ ! "$ENV" =~ ^(dev|prod)$ ]]; then
  show_error "Invalid environment: $ENV"
  show_usage
  exit 1
fi

# Determine services based on mode
case $MODE in
  all)
    SERVICES=""
    ;;
  core)
    SERVICES="redis vector-db pubsub-emulator db-postgres db-api db-auth"
    ;;
  agents)
    SERVICES="redis vector-db pubsub-emulator db-postgres db-api db-auth agent-core agent-rag agent-atlas agent-social agent-financial agent-legal"
    ;;
  ui)
    SERVICES="ui-chat ui-admin auth-ui"
    ;;
  llm)
    SERVICES="llm-service model-registry model-router"
    ;;
esac

# Determine environment overrides
if [[ "$ENV" == "dev" ]]; then
  ENV_FILE=".env.dev"
  ENV_OVERRIDE="-f docker-compose.dev.override.yml"
else
  ENV_FILE=".env.prod"
  ENV_OVERRIDE="-f docker-compose.prod.override.yml"
fi

# Ensure environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f ".env" ]]; then
    show_warning "Environment file $ENV_FILE not found, using .env"
    ENV_FILE=".env"
  else
    show_warning "No environment file found, using default values"
  fi
fi

# Check if override file exists
if [[ ! -f "${ENV_OVERRIDE#-f }" ]]; then
  ENV_OVERRIDE=""
fi

# Function to initialize required infrastructure
function initialize_infrastructure() {
  show_progress "Performing essential initialization before startup..."

  # Create docker network if it doesn't exist
  NETWORK_EXISTS=$(docker network ls --format "{{.Name}}" | grep -x "alfred-network" || true)
  if [[ -z "$NETWORK_EXISTS" ]]; then
    show_progress "Creating alfred-network..."
    docker network create alfred-network
    show_success "Network created successfully"
  fi

  # Create required volumes if they don't exist
  VOLUMES_TO_CREATE=(
    "redis-data"
    "vector-db-data"
    "llm-service-data"
    "db-postgres-data"
    "db-storage-data"
    "monitoring-metrics-data"
    "monitoring-dashboard-data"
  )

  for volume in "${VOLUMES_TO_CREATE[@]}"; do
    VOLUME_EXISTS=$(docker volume ls --format "{{.Name}}" | grep -x "$volume" || true)
    if [[ -z "$VOLUME_EXISTS" ]]; then
      docker volume create "$volume"
      show_success "Volume $volume created"
    fi
  done

  # Ensure environment file exists
  if [[ ! -f "$ENV_FILE" && ! -f ".env" ]]; then
    if [[ -f ".env.example" ]]; then
      show_progress "Creating .env file from .env.example..."
      cp .env.example .env
      show_success "Created .env file"
    else
      show_warning "No environment file found. Creating a minimal .env file."
      echo "# Alfred Agent Platform v2 - Environment Variables" > .env
      echo "DB_USER=postgres" >> .env
      echo "DB_PASSWORD=your-super-secret-password" >> .env
      echo "DB_NAME=postgres" >> .env
      echo "DB_JWT_SECRET=your-super-secret-jwt-token" >> .env
      echo "ALFRED_PROJECT_ID=alfred-agent-platform" >> .env
      echo "ALFRED_ENVIRONMENT=development" >> .env
    fi
  fi
}

# Determine command to run
DOCKER_COMMAND="docker-compose -f $COMPOSE_FILE $ENV_OVERRIDE --env-file $ENV_FILE"

# Initialize infrastructure for commands that require it
if [[ "$COMMAND" == "up" || "$COMMAND" == "setup" || "$COMMAND" == "restart" ]]; then
  initialize_infrastructure
fi

# Check for conflicts on startup
function check_for_conflicts() {
  # Check for ALL running containers using a more comprehensive pattern
  CONFLICTING_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -E "agent-|db-|monitoring-|ui-|redis|vector-db|pubsub-|llm-|mail-|auth-|rag-|atlas-|storage-|model-|alfred-" || true)

  if [[ -n "$CONFLICTING_CONTAINERS" ]]; then
    show_warning "Found existing containers that may conflict with the unified setup:"
    echo "$CONFLICTING_CONTAINERS"
    echo ""
    show_warning "To safely resolve conflicts, run: ./alfred-start.sh setup"
    echo ""
    read -p "Continue anyway? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
      show_warning "Startup cancelled. Run './alfred-start.sh setup' to resolve conflicts."
      exit 0
    fi
  fi
}

# Check for conflicts on regular startup
if [[ "$COMMAND" == "up" && "$MODE" == "all" ]]; then
  check_for_conflicts
fi

# Execute the command
case $COMMAND in
  setup)
    show_progress "Setting up Alfred Agent Platform with unified Docker Compose..."

    # Check for running containers from the old setup - comprehensive pattern
    OLD_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -E "agent-|db-|monitoring-|ui-|redis|vector-db|pubsub-|llm-|mail-|auth-|rag-|atlas-|storage-|model-|alfred-")

    if [[ -n "$OLD_CONTAINERS" ]]; then
      show_warning "Found existing containers that may conflict with the unified setup:"
      echo "$OLD_CONTAINERS"

      echo ""
      read -p "Do you want to stop and remove these containers? (y/n): " CONFIRM
      if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        # Stop all matching containers
        show_progress "Stopping containers..."
        docker ps -a --format "{{.Names}}" | grep -E "agent-|db-|monitoring-|ui-|redis|vector-db|pubsub-|llm-|mail-|auth-|rag-|atlas-|storage-|model-|alfred-" | xargs -r docker stop

        # Remove all matching containers
        show_progress "Removing containers..."
        docker ps -a --format "{{.Names}}" | grep -E "agent-|db-|monitoring-|ui-|redis|vector-db|pubsub-|llm-|mail-|auth-|rag-|atlas-|storage-|model-|alfred-" | xargs -r docker rm

        show_success "Old containers removed successfully"
      else
        show_warning "Setup cancelled. Existing containers were not removed."
        exit 0
      fi
    else
      show_success "No conflicting containers found"
    fi

    # Check for existing networks
    NETWORK_EXISTS=$(docker network ls --format "{{.Name}}" | grep -x "alfred-network" || true)
    if [[ -z "$NETWORK_EXISTS" ]]; then
      show_progress "Creating alfred-network..."
      docker network create alfred-network
      show_success "Network created successfully"
    else
      show_success "Network alfred-network already exists"
    fi

    # Check for existing volumes
    show_progress "Checking for existing volumes..."
    VOLUMES_TO_CREATE=(
      "redis-data"
      "vector-db-data"
      "llm-service-data"
      "db-postgres-data"
      "db-storage-data"
      "monitoring-metrics-data"
      "monitoring-dashboard-data"
    )

    for volume in "${VOLUMES_TO_CREATE[@]}"; do
      VOLUME_EXISTS=$(docker volume ls --format "{{.Name}}" | grep -x "$volume" || true)
      if [[ -z "$VOLUME_EXISTS" ]]; then
        docker volume create "$volume"
        show_success "Volume $volume created"
      else
        show_success "Volume $volume already exists"
      fi
    done

    # Optional: Copy environment file if it doesn't exist
    if [[ ! -f ".env" ]]; then
      if [[ -f ".env.example" ]]; then
        show_progress "Creating .env file from .env.example..."
        cp .env.example .env
        show_success "Created .env file"
      else
        show_warning "No .env.example file found. You may need to create a .env file manually."
      fi
    else
      show_success ".env file already exists"
    fi

    # Start core services with the unified setup
    show_progress "Starting core services with unified setup..."
    $DOCKER_COMMAND -f $COMPOSE_FILE up -d redis db-postgres vector-db pubsub-emulator

    if [[ $? -eq 0 ]]; then
      show_success "Setup completed successfully"
      show_progress "Wait for core services to initialize, then start the remaining services with:"
      echo -e "  ${BLUE}./alfred-start.sh up${NC}"

      # Show service status
      echo ""
      show_progress "Core service status:"
      $DOCKER_COMMAND -f $COMPOSE_FILE ps
    else
      show_error "Failed to start core services"
      exit 1
    fi
    ;;

  up)
    # Check if containers are already running
    RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -E "agent-|db-|monitoring-|ui-|redis|vector-db|pubsub-|llm-|mail-" || true)

    # If starting for the first time, show reminder about orderly startup
    if [[ -z "$RUNNING_CONTAINERS" && "$MODE" == "all" ]]; then
      show_warning "Starting all services at once may lead to startup timing issues."
      show_progress "For best results on first startup, consider starting in this order:"
      echo "  1. ./alfred-start.sh --mode core"
      echo "  2. ./alfred-start.sh --mode agents"
      echo "  3. ./alfred-start.sh --mode ui"
      echo ""
      read -p "Continue with starting all services at once? (y/n): " CONFIRM
      if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        show_warning "Startup cancelled."
        exit 0
      fi
    fi

    show_progress "Starting Alfred Agent Platform services (Mode: $MODE, Env: $ENV)..."

    # If starting core services, do it one by one in order
    if [[ "$MODE" == "core" ]]; then
      show_progress "Starting core infrastructure in the correct order..."
      $DOCKER_COMMAND up $DETACHED redis
      sleep 3
      $DOCKER_COMMAND up $DETACHED vector-db
      sleep 3
      $DOCKER_COMMAND up $DETACHED pubsub-emulator
      sleep 3
      $DOCKER_COMMAND up $DETACHED db-postgres
      sleep 5
      $DOCKER_COMMAND up $DETACHED db-api db-auth db-realtime db-storage
      $DOCKER_COMMAND up $DETACHED mail-server
      $DOCKER_COMMAND up $DETACHED llm-service

      if [[ "$ENV" == "dev" ]]; then
        show_success "Core services started successfully (development mode)"
      else
        show_success "Core services started successfully (production mode)"
      fi
    else
      # Start services normally
      if [[ -n "$SERVICES" ]]; then
        $DOCKER_COMMAND up $DETACHED $SERVICES
      else
        $DOCKER_COMMAND up $DETACHED
      fi
    fi

    if [[ $? -eq 0 ]]; then
      show_success "Services started successfully"
      # Show service status
      if [[ -n "$DETACHED" ]]; then
        echo ""
        show_progress "Service status:"
        $DOCKER_COMMAND ps
      fi
    else
      show_error "Failed to start services"
      exit 1
    fi
    ;;

  down)
    show_progress "Stopping Alfred Agent Platform services..."
    if [[ -n "$SERVICES" ]]; then
      $DOCKER_COMMAND stop $SERVICES
    else
      $DOCKER_COMMAND down
    fi

    if [[ $? -eq 0 ]]; then
      show_success "Services stopped successfully"
    else
      show_error "Failed to stop services"
      exit 1
    fi
    ;;

  restart)
    show_progress "Restarting Alfred Agent Platform services (Mode: $MODE, Env: $ENV)..."
    if [[ -n "$SERVICES" ]]; then
      $DOCKER_COMMAND restart $SERVICES
    else
      $DOCKER_COMMAND restart
    fi

    if [[ $? -eq 0 ]]; then
      show_success "Services restarted successfully"
      # Show service status
      echo ""
      show_progress "Service status:"
      $DOCKER_COMMAND ps
    else
      show_error "Failed to restart services"
      exit 1
    fi
    ;;

  status)
    show_progress "Alfred Agent Platform service status (Mode: $MODE, Env: $ENV):"
    if [[ -n "$SERVICES" ]]; then
      $DOCKER_COMMAND ps $SERVICES
    else
      $DOCKER_COMMAND ps
    fi
    ;;

  logs)
    show_progress "Showing logs for Alfred Agent Platform services (Mode: $MODE, Env: $ENV)..."
    if [[ -n "$SERVICES" ]]; then
      $DOCKER_COMMAND logs --tail=100 -f $SERVICES
    else
      $DOCKER_COMMAND logs --tail=100 -f
    fi
    ;;

  health)
    show_progress "Checking health of Alfred Agent Platform services (Mode: $MODE, Env: $ENV)..."

    # Get container IDs and names
    if [[ -n "$SERVICES" ]]; then
      CONTAINERS=$($DOCKER_COMMAND ps -q $SERVICES)
    else
      CONTAINERS=$($DOCKER_COMMAND ps -q)
    fi

    # Check health status for each container
    echo -e "CONTAINER ID\tNAME\t\t\tHEALTH STATUS"
    echo -e "------------------------------------------------"
    for container in $CONTAINERS; do
      HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null || echo "N/A")
      NAME=$(docker inspect --format='{{.Name}}' $container | sed 's/\///')
      ID=$(docker inspect --format='{{.Id}}' $container | cut -c1-12)

      # Color the health status
      if [[ "$HEALTH" == "healthy" ]]; then
        HEALTH_COLORED="${GREEN}$HEALTH${NC}"
      elif [[ "$HEALTH" == "unhealthy" ]]; then
        HEALTH_COLORED="${RED}$HEALTH${NC}"
      elif [[ "$HEALTH" == "starting" ]]; then
        HEALTH_COLORED="${YELLOW}$HEALTH${NC}"
      else
        HEALTH_COLORED="$HEALTH"
      fi

      echo -e "$ID\t$NAME\t\t$HEALTH_COLORED"
    done
    ;;
esac

exit 0