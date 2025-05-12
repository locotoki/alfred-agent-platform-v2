#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "   █████╗ ██╗     ███████╗██████╗ ███████╗██████╗     ██████╗ ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗"
echo "  ██╔══██╗██║     ██╔════╝██╔══██╗██╔════╝██╔══██╗    ██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║"
echo "  ███████║██║     █████╗  ██████╔╝█████╗  ██║  ██║    ██████╔╝██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║"
echo "  ██╔══██║██║     ██╔══╝  ██╔══██╗██╔══╝  ██║  ██║    ██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║"
echo "  ██║  ██║███████╗██║     ██║  ██║███████╗██████╔╝    ██║     ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║"
echo "  ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚══════╝╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝"
echo -e "${NC}"

# Function to display usage information
function show_help {
    echo -e "${YELLOW}Alfred Platform Environment Starter${NC}"
    echo ""
    echo "Usage: ./start-clean.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all              Start all services (default if no options provided)"
    echo "  --core             Start core services (Redis, Qdrant, PubSub)"
    echo "  --supabase         Start Supabase services"
    echo "  --monitoring       Start monitoring services (Prometheus, Grafana)"
    echo "  --agents           Start agent services (Alfred Bot, Social Intel, etc.)"
    echo "  --rag              Start RAG Gateway and Atlas services"
    echo "  --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./start-clean.sh --all                 # Start all services"
    echo "  ./start-clean.sh --core --supabase     # Start only core and supabase services"
    echo ""
}

# Function to create the alfred network if it doesn't exist
function create_network {
    # Remove the network if it exists
    if docker network inspect alfred-network >/dev/null 2>&1; then
        echo -e "${YELLOW}Removing existing alfred-network...${NC}"
        docker network rm alfred-network >/dev/null 2>&1
    fi

    # Create the network
    echo -e "${YELLOW}Creating alfred-network...${NC}"
    docker network create alfred-network
}

# Function to stop and remove existing containers
function clean_environment {
    echo -e "${YELLOW}Stopping and removing existing containers...${NC}"
    docker-compose -f docker-compose.combined-fixed.yml down --remove-orphans
    
    echo -e "${YELLOW}Pruning unused containers, networks, and volumes...${NC}"
    docker container prune -f
    docker network prune -f
    docker volume prune -f
}

# Function to start all services
function start_all {
    echo -e "${YELLOW}Starting all services...${NC}"
    docker-compose -f docker-compose.combined-fixed.yml up -d
    
    # Wait for all services to start up
    echo -e "${YELLOW}Waiting for services to start...${NC}"
    sleep 10
    
    # Check if services are running
    SERVICE_COUNT=$(docker-compose -f docker-compose.combined-fixed.yml ps --services | wc -l)
    RUNNING_COUNT=$(docker ps --filter "network=alfred-network" --format "{{.Names}}" | wc -l)
    
    echo -e "${GREEN}${RUNNING_COUNT} out of ${SERVICE_COUNT} services running${NC}"
    
    # Show services URLs
    echo -e "\n${BLUE}Service Access:${NC}"
    echo -e "${GREEN}Supabase REST:${NC} http://localhost:3000"
    echo -e "${GREEN}Supabase Auth:${NC} http://localhost:9999"
    echo -e "${GREEN}Supabase Studio:${NC} http://localhost:3001"
    echo -e "${GREEN}RAG Gateway:${NC} http://localhost:8501"
    echo -e "${GREEN}Atlas:${NC} http://localhost:8000"
    echo -e "${GREEN}Prometheus:${NC} http://localhost:9090"
    echo -e "${GREEN}Grafana:${NC} http://localhost:3005"
}

# Function to start core services
function start_core {
    echo -e "${YELLOW}Starting core services...${NC}"
    docker-compose -f docker-compose.combined-fixed.yml up -d redis qdrant pubsub-emulator
}

# Function to start Supabase services
function start_supabase {
    echo -e "${YELLOW}Starting Supabase services...${NC}"
    docker-compose -f docker-compose.combined-fixed.yml up -d supabase-db supabase-rest supabase-auth supabase-realtime supabase-storage supabase-studio
}

# Function to start monitoring services
function start_monitoring {
    echo -e "${YELLOW}Starting monitoring services...${NC}"
    docker-compose -f docker-compose.combined-fixed.yml up -d prometheus grafana node-exporter postgres-exporter
}

# Function to start agent services
function start_agents {
    echo -e "${YELLOW}Starting agent services...${NC}"
    docker-compose -f docker-compose.combined-fixed.yml up -d alfred-bot social-intel financial-tax legal-compliance mission-control ollama
}

# Function to start RAG services
function start_rag {
    echo -e "${YELLOW}Starting RAG Gateway and Atlas services...${NC}"
    docker-compose -f docker-compose.combined-fixed.yml up -d rag-gateway atlas
}

# Check if the script needs to display help
if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Create network and clean environment
create_network
clean_environment

# Parse command line arguments
if [ $# -eq 0 ]; then
    # No arguments provided, start all services
    start_all
    exit 0
fi

# Process options
start_components=()
while [ $# -gt 0 ]; do
    case "$1" in
        --all)
            start_all
            exit 0
            ;;
        --core)
            start_components+=("core")
            ;;
        --supabase)
            start_components+=("supabase")
            ;;
        --monitoring)
            start_components+=("monitoring")
            ;;
        --agents)
            start_components+=("agents")
            ;;
        --rag)
            start_components+=("rag")
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Start selected components
for component in "${start_components[@]}"; do
    case $component in
        core)
            start_core
            ;;
        supabase)
            start_supabase
            ;;
        monitoring)
            start_monitoring
            ;;
        agents)
            start_agents
            ;;
        rag)
            start_rag
            ;;
    esac
done

echo -e "${GREEN}Selected services started successfully!${NC}"