#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Alfred Platform Controlled Restart Script    ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Function to show progress
show_progress() {
  local msg="$1"
  echo -e "${YELLOW}$msg${NC}"
}

# Function to check if containers are healthy
check_container_health() {
  local unhealthy_count=$(docker ps --filter health=unhealthy | grep -v CONTAINER | wc -l)
  if [ "$unhealthy_count" -gt 0 ]; then
    echo -e "${RED}Warning: $unhealthy_count containers are still unhealthy:${NC}"
    docker ps --filter health=unhealthy --format "{{.Names}}: {{.Status}}"
    return 1
  else
    echo -e "${GREEN}All running containers are healthy!${NC}"
    return 0
  fi
}

# Function to verify critical services
verify_critical_services() {
  local missing=0

  # Check if critical services are running
  critical_services=("alfred-postgres" "redis" "vector-db" "pubsub-emulator" "agent-core" "agent-rag" "mail-server")

  for service in "${critical_services[@]}"; do
    if ! docker ps --format "{{.Names}}" | grep -q "$service"; then
      echo -e "${RED}Critical service $service is not running${NC}"
      missing=$((missing+1))
    fi
  done

  if [ "$missing" -eq 0 ]; then
    echo -e "${GREEN}All critical services are running!${NC}"
    return 0
  else
    echo -e "${RED}$missing critical services are missing${NC}"
    return 1
  fi
}

# Function to check service connectivity
check_service_connectivity() {
  local failed=0

  # Check if PostgreSQL is reachable
  if ! docker exec alfred-postgres pg_isready -U postgres; then
    echo -e "${RED}Cannot connect to PostgreSQL${NC}"
    failed=$((failed+1))
  fi

  # Check if Redis is reachable
  if ! docker exec redis redis-cli ping | grep -q "PONG"; then
    echo -e "${RED}Cannot connect to Redis${NC}"
    failed=$((failed+1))
  fi

  # Check if vector-db is reachable
  if ! curl -s http://localhost:6333/healthz > /dev/null; then
    echo -e "${RED}Cannot connect to vector-db${NC}"
    failed=$((failed+1))
  fi

  # Check if agent-core is reachable
  if ! curl -s http://localhost:8011/health > /dev/null; then
    echo -e "${RED}Cannot connect to agent-core${NC}"
    failed=$((failed+1))
  fi

  if [ "$failed" -eq 0 ]; then
    echo -e "${GREEN}All service connectivity checks passed!${NC}"
    return 0
  else
    echo -e "${RED}$failed service connectivity checks failed${NC}"
    return 1
  fi
}

# Backup any critical container configuration
backup_container_config() {
  show_progress "Creating a backup of critical container configurations..."

  # Create a backup directory
  backup_dir="container-config-backup-$(date +%Y%m%d%H%M%S)"
  mkdir -p "$backup_dir"

  # Backup postgres data directory if needed
  # Note: This would require stopping postgres first, which might not be feasible
  # docker exec alfred-postgres pg_dumpall -U postgres > "$backup_dir/postgres-backup.sql"

  # Backup container configs
  docker inspect alfred-postgres > "$backup_dir/alfred-postgres-config.json"
  docker inspect agent-core > "$backup_dir/agent-core-config.json"
  docker inspect agent-rag > "$backup_dir/agent-rag-config.json"
  docker inspect agent-atlas > "$backup_dir/agent-atlas-config.json"
  docker inspect ui-admin > "$backup_dir/ui-admin-config.json"
  docker inspect vector-db > "$backup_dir/vector-db-config.json"
  docker inspect monitoring-db > "$backup_dir/monitoring-db-config.json" 2>/dev/null || true

  echo -e "${GREEN}Backup created in $backup_dir${NC}"
}

# Controlled shutdown
controlled_shutdown() {
  show_progress "Starting controlled shutdown..."

  # Step 1: Stop UI services first (they depend on backend services)
  show_progress "Stopping UI services..."
  docker stop ui-admin ui-chat auth-ui || true

  # Step 2: Stop agent services
  show_progress "Stopping agent services..."
  docker stop agent-atlas agent-social agent-financial agent-legal || true

  # Step 3: Stop core services
  show_progress "Stopping core services..."
  docker stop agent-core agent-rag || true

  # Step 4: Stop model services
  show_progress "Stopping model services..."
  docker stop alfred-model-router alfred-model-registry alfred-ollama || true

  # Step 5: Stop monitoring services
  show_progress "Stopping monitoring services..."
  docker stop monitoring-dashboard monitoring-metrics monitoring-node monitoring-db || true

  # Step 6: Stop database services
  show_progress "Stopping database services..."
  docker stop db-auth db-api db-admin db-realtime db-storage || true

  # Step 7: Stop mail service
  show_progress "Stopping mail service..."
  docker stop mail-server || true

  # Step 8: Stop core infrastructure last
  show_progress "Stopping core infrastructure..."
  docker stop vector-db pubsub-emulator redis alfred-postgres || true

  show_progress "All services stopped"
}

# Controlled startup
controlled_startup() {
  show_progress "Starting controlled startup..."

  # Step 1: Start core infrastructure first
  show_progress "Starting core infrastructure..."
  docker start redis vector-db pubsub-emulator alfred-postgres || true
  show_progress "Waiting for core infrastructure to initialize..."
  sleep 20

  # Step 2: Start database services
  show_progress "Starting database services..."
  docker start db-auth db-api db-realtime db-storage db-admin || true
  show_progress "Waiting for database services to initialize..."
  sleep 15

  # Step 3: Start mail service
  show_progress "Starting mail service..."
  docker start mail-server || true

  # Step 4: Start model services
  show_progress "Starting model services..."
  docker start alfred-ollama alfred-model-registry alfred-model-router || true
  show_progress "Waiting for model services to initialize..."
  sleep 10

  # Step 5: Start core services
  show_progress "Starting core services..."
  docker start agent-rag agent-core || true
  show_progress "Waiting for core services to initialize..."
  sleep 10

  # Step 6: Start agent services
  show_progress "Starting agent services..."
  docker start agent-atlas agent-social agent-financial agent-legal || true
  show_progress "Waiting for agent services to initialize..."
  sleep 10

  # Step 7: Start UI services
  show_progress "Starting UI services..."
  docker start ui-admin ui-chat auth-ui || true

  # Step 8: Start monitoring services
  show_progress "Starting monitoring services..."
  docker start monitoring-metrics monitoring-dashboard monitoring-node || true
  # Try to start monitoring-db if it exists
  docker start monitoring-db 2>/dev/null || echo -e "${YELLOW}monitoring-db not found, skipping...${NC}"

  show_progress "All services started"
}

# Apply fixes if needed
apply_fixes_if_needed() {
  # Check if any containers are unhealthy
  unhealthy_containers=$(docker ps --filter health=unhealthy --format "{{.Names}}")

  if [ -z "$unhealthy_containers" ]; then
    echo -e "${GREEN}No unhealthy containers detected. No fixes needed.${NC}"
    return 0
  fi

  echo -e "${YELLOW}Detected unhealthy containers: $unhealthy_containers${NC}"
  echo -e "${YELLOW}Applying fixes...${NC}"

  # Apply fixes
  if [ -f "./fix-all-directly.sh" ]; then
    ./fix-all-directly.sh
  else
    # Apply individual fixes if available
    for container in $unhealthy_containers; do
      if [ -f "./fix-$container.sh" ]; then
        echo -e "${YELLOW}Applying fix for $container...${NC}"
        "./fix-$container.sh"
      elif [ "$container" = "agent-atlas" ] && [ -f "./fix-atlas-direct.sh" ]; then
        echo -e "${YELLOW}Applying fix for $container...${NC}"
        "./fix-atlas-direct.sh"
      elif [ "$container" = "agent-core" ] && [ -f "./fix-agent-core.sh" ]; then
        echo -e "${YELLOW}Applying fix for $container...${NC}"
        "./fix-agent-core.sh"
      elif [ "$container" = "agent-rag" ] && [ -f "./fix-agent-rag.sh" ]; then
        echo -e "${YELLOW}Applying fix for $container...${NC}"
        "./fix-agent-rag.sh"
      elif [ "$container" = "monitoring-db" ] && [ -f "./fix-monitoring-db-direct.sh" ]; then
        echo -e "${YELLOW}Applying fix for $container...${NC}"
        "./fix-monitoring-db-direct.sh"
      elif [ "$container" = "vector-db" ] && [ -f "./fix-vector-db.sh" ]; then
        echo -e "${YELLOW}Applying fix for $container...${NC}"
        "./fix-vector-db.sh"
      else
        echo -e "${RED}No fix script available for $container${NC}"
      fi
    done
  fi
}

# Main execution

# Show current status
show_progress "Current container status:"
docker ps
echo

# Ask for confirmation
read -p "Do you want to proceed with the controlled restart? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Operation canceled.${NC}"
  exit 0
fi

# Backup container configurations
backup_container_config

# Perform controlled shutdown
controlled_shutdown

# Simplify the startup confirmation
echo -e "${YELLOW}Shutdown complete. Do you want to proceed with startup? (y/n) ${NC}"
read -r STARTUP_REPLY
if [[ ! $STARTUP_REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Startup canceled. System remains in shutdown state.${NC}"
  exit 0
fi

# Perform controlled startup
controlled_startup

# Wait for things to settle
show_progress "Waiting for all services to initialize and settle..."
sleep 30

# Verify services
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Verifying Service Status After Restart    ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check container health
if ! check_container_health; then
  # Apply fixes if needed
  echo -e "${YELLOW}Attempting to fix unhealthy containers...${NC}"
  apply_fixes_if_needed

  # Check again after fixes
  echo -e "${BLUE}Checking container health after applying fixes...${NC}"
  if ! check_container_health; then
    echo -e "${RED}Warning: Some containers are still unhealthy after applying fixes${NC}"
  fi
fi

# Verify critical services
if ! verify_critical_services; then
  echo -e "${RED}Warning: Some critical services are missing${NC}"
fi

# Check service connectivity
if ! check_service_connectivity; then
  echo -e "${RED}Warning: Some service connectivity checks failed${NC}"
fi

# Final status
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Final System Status    ${NC}"
echo -e "${BLUE}===============================================${NC}"
docker ps

echo
if check_container_health && verify_critical_services && check_service_connectivity; then
  echo -e "${GREEN}✅ Restart completed successfully. System is fully operational.${NC}"
else
  echo -e "${YELLOW}⚠️ Restart completed with some issues. Additional troubleshooting may be needed.${NC}"
  echo -e "${YELLOW}You can check HEALTH_FIX_GUIDE.md for troubleshooting steps.${NC}"
fi
