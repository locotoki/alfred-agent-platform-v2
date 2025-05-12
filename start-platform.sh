#!/bin/bash
# Alfred Agent Platform v2 - Startup Script
# This script helps manage the platform with optimized Docker Compose configurations

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default environment
ENV="dev"
ACTION="up"
CLEAN=false
DETACH=false
SERVICES=""

# Help function
function show_help {
    echo -e "${BLUE}Alfred Agent Platform v2 - Startup Script${NC}"
    echo ""
    echo "Usage: $0 [options] [services]"
    echo ""
    echo "Options:"
    echo "  -e, --env ENV       Environment to use (dev, prod, local, test) [default: dev]"
    echo "  -a, --action ACTION Action to perform (up, down, restart, logs) [default: up]"
    echo "  -c, --clean         Clean volumes when performing down action"
    echo "  -d, --detach        Run containers in detached mode"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Services:"
    echo "  Specify one or more services to act upon (e.g., redis db-postgres agent-core)"
    echo "  If no services are specified, all services will be affected"
    echo ""
    echo "Examples:"
    echo "  $0                  # Start all services in development mode"
    echo "  $0 -e prod          # Start all services in production mode"
    echo "  $0 -a down -c       # Stop all services and clean volumes"
    echo "  $0 agent-core ui-chat # Start only the core agent and chat UI"
    echo "  $0 -a logs agent-core # Show logs for the core agent"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENV="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -d|--detach)
            DETACH=true
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

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "prod" && "$ENV" != "local" && "$ENV" != "test" ]]; then
    echo -e "${RED}Error: Invalid environment '$ENV'. Must be one of: dev, prod, local, test${NC}"
    exit 1
fi

# Validate action
if [[ "$ACTION" != "up" && "$ACTION" != "down" && "$ACTION" != "restart" && "$ACTION" != "logs" ]]; then
    echo -e "${RED}Error: Invalid action '$ACTION'. Must be one of: up, down, restart, logs${NC}"
    exit 1
fi

# Base compose file
COMPOSE_FILES="-f docker-compose-clean.yml"

# Add environment-specific override
if [[ -f "docker-compose/docker-compose.$ENV.yml" ]]; then
    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose/docker-compose.$ENV.yml"
fi

# Action-specific options
ACTION_OPTS=""
if [[ "$ACTION" == "up" || "$ACTION" == "restart" ]]; then
    if [[ "$DETACH" == true ]]; then
        ACTION_OPTS="$ACTION_OPTS -d"
    fi
elif [[ "$ACTION" == "down" && "$CLEAN" == true ]]; then
    ACTION_OPTS="$ACTION_OPTS -v"
elif [[ "$ACTION" == "logs" ]]; then
    ACTION_OPTS="$ACTION_OPTS -f"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check environment variables before starting services
if [[ "$ACTION" == "up" || "$ACTION" == "restart" ]]; then
    echo -e "${YELLOW}Checking environment variables...${NC}"

    # Make check-env-vars.sh executable if it's not already
    if [[ ! -x "./check-env-vars.sh" ]]; then
        chmod +x ./check-env-vars.sh
    fi

    # Run the environment check script
    if ! ./check-env-vars.sh; then
        echo -e "${RED}Environment variable check failed. Please fix the issues and try again.${NC}"
        echo -e "${YELLOW}Would you like to continue anyway? (y/N)${NC}"
        read -n 1 -r CONTINUE_ANYWAY
        echo ""
        if [[ ! $CONTINUE_ANYWAY =~ ^[Yy]$ ]]; then
            exit 1
        else
            echo -e "${YELLOW}Continuing despite environment variable issues...${NC}"
        fi
    fi
fi

echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}Alfred Agent Platform v2 - $ENV Environment${NC}"
echo -e "${BLUE}==========================================================${NC}"
echo ""
echo -e "${YELLOW}Action:${NC} $ACTION"
echo -e "${YELLOW}Environment:${NC} $ENV"
if [[ -n "$SERVICES" ]]; then
    echo -e "${YELLOW}Services:${NC}$SERVICES"
else
    echo -e "${YELLOW}Services:${NC} all"
fi
echo ""

# Prepare command
CMD="docker-compose $COMPOSE_FILES $ACTION $ACTION_OPTS $SERVICES"
echo -e "${YELLOW}Executing:${NC} $CMD"
echo ""

# Check for network
if [[ "$ACTION" == "up" || "$ACTION" == "restart" ]]; then
    if ! docker network ls | grep -q alfred-network; then
        echo -e "${YELLOW}Creating alfred-network...${NC}"
        docker network create alfred-network
    fi
fi

# Execute command
eval "$CMD"

# Post-action information
if [[ "$ACTION" == "up" && "$DETACH" == true ]]; then
    echo ""
    echo -e "${GREEN}Services are starting in the background.${NC}"
    echo -e "${GREEN}Run '$0 -a logs' to view logs.${NC}"
    echo ""
    
    echo -e "${BLUE}Checking service health (initial check)...${NC}"
    sleep 5
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E '(alfred|agent|db-|ui-|monitor|redis|vector-db)'
    
    echo ""
    echo -e "${YELLOW}Access the platform:${NC}"
    echo "  Chat UI:              http://localhost:8502"
    echo "  Admin Dashboard:      http://localhost:3007"
    echo "  Monitoring Dashboard: http://localhost:3005 (admin/admin)"
    echo "  Mail Interface:       http://localhost:8025 (in development)"
    echo ""
elif [[ "$ACTION" == "down" ]]; then
    echo ""
    echo -e "${GREEN}Services have been stopped.${NC}"
    if [[ "$CLEAN" == true ]]; then
        echo -e "${YELLOW}Volumes have been removed.${NC}"
    fi
fi