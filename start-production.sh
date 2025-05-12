#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print banner
echo -e "${BLUE}
   █████╗ ██╗     ███████╗██████╗ ███████╗██████╗     ██████╗ ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
  ██╔══██╗██║     ██╔════╝██╔══██╗██╔════╝██╔══██╗    ██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║
  ███████║██║     █████╗  ██████╔╝█████╗  ██║  ██║    ██████╔╝██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║
  ██╔══██║██║     ██╔══╝  ██╔══██╗██╔══╝  ██║  ██║    ██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║
  ██║  ██║███████╗██║     ██║  ██║███████╗██████╔╝    ██║     ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚══════╝╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
${NC}"

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

function stop_containers {
  echo -e "${YELLOW}Stopping and removing existing containers...${NC}"
  docker-compose -f docker-compose.combined-fixed.yml down >/dev/null 2>&1 || true
  
  echo -e "${YELLOW}Pruning unused containers, networks, and volumes...${NC}"
  docker container prune -f
  docker volume prune -f
}

# Create configuration files needed by services
function create_config_files {
  echo -e "${YELLOW}Creating configuration files...${NC}"
  
  # Create the PostgREST configuration file
  cat > ./postgrest.conf << EOF
# PostgREST configuration file for development
db-uri = "postgres://postgres:your-super-secret-password@supabase-db:5432/postgres"
db-schema = "public"
db-anon-role = "postgres"
db-pool = 10
server-host = "0.0.0.0"
server-port = 3000
EOF
}

function start_services {
  local categories="$1"
  
  if [[ -z "$categories" ]]; then
    echo -e "${YELLOW}Starting all services...${NC}"
    docker-compose -f docker-compose.combined-fixed.yml -f docker-compose.supabase-config.yml -f docker-compose.atlas-fix.yml up -d
  else
    echo -e "${YELLOW}Starting services: $categories${NC}"
    docker-compose -f docker-compose.combined-fixed.yml -f docker-compose.supabase-config.yml -f docker-compose.atlas-fix.yml up -d $categories
  fi
}

function wait_for_services {
  echo -e "${YELLOW}Waiting for services to start...${NC}"
  sleep 10
  
  # Count running services
  local running_services=$(docker-compose -f docker-compose.combined-fixed.yml ps --services --filter "status=running" | wc -l)
  local total_services=$(docker-compose -f docker-compose.combined-fixed.yml ps --services | wc -l)
  
  echo -e "${GREEN}$running_services out of $total_services services running${NC}"
}

function setup_database {
  echo -e "${YELLOW}Setting up Supabase database...${NC}"
  
  # Create database tables and disable authentication
  ./disable-auth.sh >/dev/null 2>&1
  
  echo -e "${GREEN}Database configured for development.${NC}"
}

function print_access_info {
  echo -e "\n${BLUE}Service Access:${NC}"
  echo -e "${GREEN}Supabase REST:${NC} http://localhost:3000"
  echo -e "${GREEN}Supabase Auth:${NC} http://localhost:9999"
  echo -e "${GREEN}Supabase Studio:${NC} http://localhost:3001"
  echo -e "${GREEN}RAG Gateway:${NC} http://localhost:8501"
  echo -e "${GREEN}Atlas:${NC} http://localhost:8000"
  echo -e "${GREEN}Prometheus:${NC} http://localhost:9090"
  echo -e "${GREEN}Grafana:${NC} http://localhost:3005"
}

function main {
  create_network
  stop_containers
  create_config_files
  
  if [[ "$1" == "--core-only" ]]; then
    start_services "supabase-db supabase-rest supabase-auth redis qdrant pubsub-emulator"
  elif [[ "$1" == "--with-atlas" ]]; then
    start_services "supabase-db supabase-rest supabase-auth redis qdrant pubsub-emulator rag-gateway atlas"
  else
    start_services
  fi
  
  wait_for_services
  
  # Apply database setup after services are running
  setup_database
  
  print_access_info
}

# Check args
if [[ "$1" == "--help" ]]; then
  echo "Usage: $0 [OPTION]"
  echo "Start the Alfred Agent Platform v2 environment"
  echo
  echo "Options:"
  echo "  --core-only     Start only core infrastructure services"
  echo "  --with-atlas    Start core infrastructure and Atlas services"
  echo "  --help          Display this help message"
  exit 0
fi

# Execute main function with all arguments
main "$@"