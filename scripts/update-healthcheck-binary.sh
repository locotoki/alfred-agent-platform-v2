#!/bin/bash
# Script to update all service Dockerfiles and health check configurations
# to use the static health-checker binary

set -e

echo "Updating service Dockerfiles to include the healthcheck binary..."

# List of service directories with Dockerfiles
SERVICE_DIRS=$(find /home/locotoki/projects/alfred-agent-platform-v2/services -name "Dockerfile" -type f | xargs dirname)

# Process each Dockerfile
for SERVICE_DIR in $SERVICE_DIRS; do
  DOCKERFILE="$SERVICE_DIR/Dockerfile"
  SERVICE_NAME=$(basename "$SERVICE_DIR")
  
  echo "Processing $SERVICE_NAME Dockerfile..."
  
  # Skip if Dockerfile doesn't exist
  if [ ! -f "$DOCKERFILE" ]; then
    echo "  Skipping $SERVICE_NAME - Dockerfile not found"
    continue
  fi
  
  # Check if Dockerfile already has the healthcheck reference
  if grep -q "FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck" "$DOCKERFILE"; then
    echo "  Skipping $SERVICE_NAME - Healthcheck already added"
    continue
  fi
  
  # Create a backup of the original Dockerfile
  cp "$DOCKERFILE" "${DOCKERFILE}.bak"
  
  # Add healthcheck to Dockerfile
  # This handles both single FROM and multi-stage builds
  if grep -q "^FROM .* AS " "$DOCKERFILE"; then
    # Multi-stage build - Insert healthcheck stage at the top
    sed -i '1s/^/FROM ghcr.io\/alfred\/healthcheck:0.3.1 AS healthcheck\n\n/' "$DOCKERFILE"
    
    # Find the final FROM statement
    FINAL_FROM_LINE=$(grep -n "^FROM " "$DOCKERFILE" | tail -1 | cut -d: -f1)
    
    # Find a good place to insert the COPY command after the final FROM
    # Try to find a good place after RUN statements
    LAST_RUN_AFTER_FINAL_FROM=$(tail -n +$FINAL_FROM_LINE "$DOCKERFILE" | grep -n "^RUN " | tail -1 | cut -d: -f1)
    
    if [ -n "$LAST_RUN_AFTER_FINAL_FROM" ]; then
      # Insert after the last RUN command
      INSERTION_LINE=$((FINAL_FROM_LINE + LAST_RUN_AFTER_FINAL_FROM))
      sed -i "${INSERTION_LINE}a# Copy healthcheck binary\nCOPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck\n" "$DOCKERFILE"
    else
      # Insert after the final FROM statement
      sed -i "${FINAL_FROM_LINE}a\n# Copy healthcheck binary\nCOPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck\n" "$DOCKERFILE"
    fi
  else
    # Single-stage build
    # Insert healthcheck stage at the top
    sed -i '1s/^/FROM ghcr.io\/alfred\/healthcheck:0.3.1 AS healthcheck\n\n/' "$DOCKERFILE"
    
    # Find a good place to insert the COPY command
    # Try to find a good place after RUN statements
    LAST_RUN=$(grep -n "^RUN " "$DOCKERFILE" | tail -1 | cut -d: -f1)
    
    if [ -n "$LAST_RUN" ]; then
      # Insert after the last RUN command
      sed -i "${LAST_RUN}a\n# Copy healthcheck binary\nCOPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck\n" "$DOCKERFILE"
    else
      # Insert after the first FROM statement
      FIRST_FROM=$(grep -n "^FROM " "$DOCKERFILE" | head -1 | cut -d: -f1)
      INSERTION_LINE=$((FIRST_FROM + 2))
      sed -i "${INSERTION_LINE}i\n# Copy healthcheck binary\nCOPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck\n" "$DOCKERFILE"
    fi
  fi
  
  echo "  Updated $SERVICE_NAME Dockerfile"
done

echo "Updating Docker Compose health check configurations..."

# Docker Compose file path
COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"

# Make a backup of the Docker Compose file
cp "$COMPOSE_FILE" "${COMPOSE_FILE}.bak"

# Update health check configurations in Docker Compose file
# This is a simple example - in practice, you might need a more sophisticated approach
# for complex Docker Compose files

# List of services and their health check endpoints
declare -A SERVICE_PORTS=(
  ["redis"]="6379 REDIS_PING"
  ["vector-db"]="6333 /health"
  ["pubsub-emulator"]="8085 /v1/projects/alfred-agent-platform/topics"
  ["llm-service"]="11434 /api/tags"
  ["model-registry"]="8079 /health"
  ["model-router"]="8080 /health"
  ["db-postgres"]="5432 PG_ISREADY"
  ["db-api"]="3000 /"
  ["db-admin"]="3001 /api/health"
  ["db-realtime"]="4000 NETCAT"
  ["db-storage"]="5000 /health"
  ["agent-core"]="8011 /health"
  ["agent-rag"]="8501 /health"
  ["agent-atlas"]="8000 /health"
  ["agent-social"]="9000 /health"
  ["agent-financial"]="9003 /health"
  ["agent-legal"]="9002 /health"
  ["ui-chat"]="8501 /health"
  ["ui-admin"]="3000 PROCESS"
  ["auth-ui"]="80 /health"
  ["monitoring-metrics"]="9090 /-/healthy"
  ["monitoring-dashboard"]="3000 /api/health"
  ["monitoring-node"]="9100 /metrics"
  ["monitoring-db"]="9187 /metrics"
  ["monitoring-redis"]="9122 /metrics"
  ["mail-server"]="1025 NETCAT"
)

# Function to update health check configuration for a service
update_healthcheck() {
  local service_name="$1"
  local service_port="$2"
  local endpoint="$3"
  
  # Skip if service, port, or endpoint is empty
  if [ -z "$service_name" ] || [ -z "$service_port" ]; then
    return
  fi
  
  # Find the service in the Docker Compose file
  local service_line=$(grep -n "^  $service_name:" "$COMPOSE_FILE" | cut -d: -f1)
  if [ -z "$service_line" ]; then
    echo "  Service $service_name not found in Docker Compose file"
    return
  fi
  
  # Find the healthcheck section for this service
  local healthcheck_line=$(tail -n +$service_line "$COMPOSE_FILE" | grep -n "^    healthcheck:" | head -1 | cut -d: -f1)
  if [ -z "$healthcheck_line" ]; then
    echo "  Healthcheck section not found for $service_name"
    return
  fi
  
  # Calculate the actual line number of the healthcheck section
  healthcheck_line=$((service_line + healthcheck_line - 1))
  
  # Find the test line in the healthcheck section
  local test_line=$(tail -n +$healthcheck_line "$COMPOSE_FILE" | grep -n '      test:' | head -1 | cut -d: -f1)
  if [ -z "$test_line" ]; then
    echo "  Test command not found in healthcheck section for $service_name"
    return
  fi
  
  # Calculate the actual line number of the test line
  test_line=$((healthcheck_line + test_line - 1))
  
  # Determine the appropriate health check command based on the endpoint
  local health_command=""
  
  case "$endpoint" in
    "REDIS_PING")
      health_command='["CMD", "healthcheck", "--redis", "redis://localhost:'$service_port'"]'
      ;;
    "PG_ISREADY")
      health_command='["CMD", "healthcheck", "--postgres", "postgres://postgres:your-super-secret-password@localhost:'$service_port'/postgres"]'
      ;;
    "NETCAT")
      health_command='["CMD", "healthcheck", "--tcp", "localhost:'$service_port'"]'
      ;;
    "PROCESS")
      health_command='["CMD", "healthcheck", "--process", "node"]'
      ;;
    *)
      # Default HTTP check
      health_command='["CMD", "healthcheck", "--http", "http://localhost:'$service_port''$endpoint'"]'
      ;;
  esac
  
  # Update the test line with the new health check command
  if [ -n "$health_command" ]; then
    sed -i "${test_line}s|test: .*|test: $health_command|" "$COMPOSE_FILE"
    echo "  Updated health check for $service_name to use healthcheck binary"
  fi
}

# Update health check configurations for all services
for service in "${!SERVICE_PORTS[@]}"; do
  port_and_endpoint=(${SERVICE_PORTS[$service]})
  port=${port_and_endpoint[0]}
  endpoint=${port_and_endpoint[1]}
  
  echo "Updating health check for $service (port $port, endpoint $endpoint)..."
  update_healthcheck "$service" "$port" "$endpoint"
done

echo "All updates complete!"
echo ""
echo "Next steps:"
echo "1. Review the changes to Dockerfiles and docker-compose-clean.yml"
echo "2. Build the updated services: docker-compose -f docker-compose-clean.yml build"
echo "3. Restart the platform: ./start-platform.sh -a restart"