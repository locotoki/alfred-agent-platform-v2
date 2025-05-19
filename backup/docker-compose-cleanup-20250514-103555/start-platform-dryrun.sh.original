#!/bin/bash
# Dry Run Version of Platform Startup Script
# This version only prints commands without executing them

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
${BOLD}[DRY RUN] How to Use the Start Platform Script${NORM}

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
  echo -e "${RED}[DRY RUN] Error: $COMPOSE_FILE not found. Please check your configuration.${NORM}"
  exit 1
fi

# Function to simulate command execution
simulate_command() {
  echo -e "${YELLOW}[DRY RUN] Would execute: ${NORM}$@"
}

# Check for current running containers
echo -e "${BLUE}[DRY RUN] Currently running containers:${NORM}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -v "CONTAINER ID"

# Execute the command (simulated)
case "$ACTION" in
  up)
    echo -e "${BLUE}[DRY RUN] Starting platform services (ENV: $ENV)...${NORM}"
    if [ -z "$DETACH" ]; then
      echo -e "${YELLOW}[DRY RUN] Would start in foreground mode. Press Ctrl+C to stop.${NORM}"
    else
      echo -e "${YELLOW}[DRY RUN] Would start in detached mode.${NORM}"
    fi

    # Simulate creating network if it doesn't exist
    echo -e "${BLUE}[DRY RUN] Checking if network exists:${NORM}"
    docker network ls | grep alfred-network || echo -e "${YELLOW}[DRY RUN] Would create network: docker network create alfred-network${NORM}"

    # Simulate starting the services
    if [ -z "$SERVICES" ]; then
      simulate_command "docker-compose -f $COMPOSE_FILE up $DETACH"
      echo -e "${GREEN}[DRY RUN] This would start ALL services defined in $COMPOSE_FILE${NORM}"
    else
      simulate_command "docker-compose -f $COMPOSE_FILE up $DETACH $SERVICES"
      echo -e "${GREEN}[DRY RUN] This would start the following services: $SERVICES${NORM}"
    fi
    ;;

  down)
    echo -e "${BLUE}[DRY RUN] Stopping platform services...${NORM}"
    if [ -n "$CLEAN" ]; then
      echo -e "${YELLOW}[DRY RUN] Warning: This would also remove volumes!${NORM}"
    fi

    # Simulate stopping the services
    if [ -z "$SERVICES" ]; then
      simulate_command "docker-compose -f $COMPOSE_FILE down $CLEAN"
      echo -e "${GREEN}[DRY RUN] This would stop ALL services defined in $COMPOSE_FILE${NORM}"
    else
      simulate_command "docker-compose -f $COMPOSE_FILE stop $SERVICES"
      echo -e "${GREEN}[DRY RUN] This would stop the following services: $SERVICES${NORM}"
    fi
    ;;

  restart)
    echo -e "${BLUE}[DRY RUN] Restarting platform services...${NORM}"

    # Simulate restarting the services
    if [ -z "$SERVICES" ]; then
      simulate_command "docker-compose -f $COMPOSE_FILE restart"
      echo -e "${GREEN}[DRY RUN] This would restart ALL services defined in $COMPOSE_FILE${NORM}"
    else
      simulate_command "docker-compose -f $COMPOSE_FILE restart $SERVICES"
      echo -e "${GREEN}[DRY RUN] This would restart the following services: $SERVICES${NORM}"
    fi
    ;;

  logs)
    echo -e "${BLUE}[DRY RUN] Would show logs for platform services...${NORM}"

    # Simulate showing logs
    if [ -z "$SERVICES" ]; then
      simulate_command "docker-compose -f $COMPOSE_FILE logs -f"
      echo -e "${GREEN}[DRY RUN] This would show logs for ALL services defined in $COMPOSE_FILE${NORM}"
    else
      simulate_command "docker-compose -f $COMPOSE_FILE logs -f $SERVICES"
      echo -e "${GREEN}[DRY RUN] This would show logs for the following services: $SERVICES${NORM}"
    fi
    ;;

  *)
    echo -e "${RED}[DRY RUN] Error: Unknown action '$ACTION'${NORM}"
    show_help
    exit 1
    ;;
esac

# Simulate showing status after up or restart
if [ "$ACTION" = "up" ] || [ "$ACTION" = "restart" ]; then
  echo -e "${GREEN}[DRY RUN] After operation, would show service status:${NORM}"
  simulate_command "docker-compose -f $COMPOSE_FILE ps"
fi

# Print services that would be affected
echo -e "${BLUE}\n[DRY RUN] Services defined in $COMPOSE_FILE that would be affected:${NORM}"
grep -E "^  [a-zA-Z0-9_-]+:" $COMPOSE_FILE | sed 's/://' | sort

echo -e "${GREEN}\n[DRY RUN] Dry run completed. No containers were affected.${NORM}"

exit 0
