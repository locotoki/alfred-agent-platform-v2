#!/bin/bash
# Alfred Agent Platform - Platform Startup Script
# 
# This script handles the startup, shutdown, and management
# of all platform services in a controlled way.

# Default settings
ENV="dev"
ACTION="up"
CLEAN=""
DETACH=""
SERVICES=""

# Text formatting
BOLD=$(tput bold)
NORM=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)

# Display help message
show_help() {
  cat << EOF
${BOLD}How to Use the Start Platform Script${NORM}

${BOLD}Basic Usage${NORM}

./start-platform.sh [options] [services]

${BOLD}Common Commands${NORM}

1. Start all services in development mode:
./start-platform.sh
2. Start all services in production mode:
./start-platform.sh -e prod
3. Start specific services only:
./start-platform.sh agent-core ui-chat
4. Stop all services:
./start-platform.sh -a down
5. Stop and remove volumes (cleanup):
./start-platform.sh -a down -c
6. View logs for all services:
./start-platform.sh -a logs
7. View logs for specific services:
./start-platform.sh -a logs agent-core
8. Restart services:
./start-platform.sh -a restart
9. Run in detached mode (background):
./start-platform.sh -d

${BOLD}Options${NORM}

- e, --env ENV - Environment to use (dev, prod, local, test)
- a, --action ACTION - Action to perform (up, down, restart, logs)
- c, --clean - Clean volumes when performing down action
- d, --detach - Run containers in detached mode
- h, --help - Show help message

${BOLD}For More Information${NORM}

Run the help command:
./start-platform.sh --help
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--env)
      ENV="$2"
      shift 2
      ;;
    -a|--action)
      ACTION="$2"
      shift 2
      ;;
    -c|--clean)
      CLEAN="--volumes"
      shift
      ;;
    -d|--detach)
      DETACH="-d"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      SERVICES="$SERVICES $1"
      shift
      ;;
  esac
done

# Determine which docker-compose file to use
COMPOSE_FILE="docker-compose-clean.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
  echo -e "${RED}Error: $COMPOSE_FILE not found. Please check your configuration.${NORM}"
  exit 1
fi

# Execute the command
case "$ACTION" in
  up)
    echo -e "${BLUE}Starting platform services (ENV: $ENV)...${NORM}"
    if [ -z "$DETACH" ]; then
      echo -e "${YELLOW}Starting in foreground mode. Press Ctrl+C to stop.${NORM}"
    else
      echo -e "${YELLOW}Starting in detached mode.${NORM}"
    fi
    
    # Create network if it doesn't exist
    docker network inspect alfred-network >/dev/null 2>&1 || docker network create alfred-network
    
    # Start the services
    if [ -z "$SERVICES" ]; then
      docker-compose -f $COMPOSE_FILE up $DETACH
    else
      docker-compose -f $COMPOSE_FILE up $DETACH $SERVICES
    fi
    ;;
    
  down)
    echo -e "${BLUE}Stopping platform services...${NORM}"
    if [ -n "$CLEAN" ]; then
      echo -e "${YELLOW}Warning: Also removing volumes!${NORM}"
    fi
    
    # Stop the services
    if [ -z "$SERVICES" ]; then
      docker-compose -f $COMPOSE_FILE down $CLEAN
    else
      docker-compose -f $COMPOSE_FILE stop $SERVICES
    fi
    ;;
    
  restart)
    echo -e "${BLUE}Restarting platform services...${NORM}"
    
    # Restart the services
    if [ -z "$SERVICES" ]; then
      docker-compose -f $COMPOSE_FILE restart
    else
      docker-compose -f $COMPOSE_FILE restart $SERVICES
    fi
    ;;
    
  logs)
    echo -e "${BLUE}Showing logs for platform services...${NORM}"
    
    # Show logs
    if [ -z "$SERVICES" ]; then
      docker-compose -f $COMPOSE_FILE logs -f
    else
      docker-compose -f $COMPOSE_FILE logs -f $SERVICES
    fi
    ;;
    
  *)
    echo -e "${RED}Error: Unknown action '$ACTION'${NORM}"
    show_help
    exit 1
    ;;
esac

# Show status after up or restart
if [ "$ACTION" = "up" ] || [ "$ACTION" = "restart" ]; then
  echo -e "${GREEN}Service status:${NORM}"
  docker-compose -f $COMPOSE_FILE ps
fi

exit 0