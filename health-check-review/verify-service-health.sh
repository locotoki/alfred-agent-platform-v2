#!/bin/bash
# Script to verify the health of all services after health check standardization

echo "Verifying health of all services..."
echo "===================================="
echo ""

# Array of service names and ports to check
declare -a services=(
  "redis:6379"
  "vector-db:6333"
  "pubsub-emulator:8085"
  "llm-service:11434"
  "model-registry:8079"
  "model-router:8080"
  "db-postgres:5432"
  "db-auth:9999"
  "db-api:3000"
  "db-admin:3001" 
  "db-realtime:4000"
  "db-storage:5000"
  "agent-core:8011"
  "agent-rag:8501"
  "agent-atlas:8000"
  "agent-social:9000"
  "agent-financial:9003"
  "agent-legal:9002"
  "ui-chat:8501"
  "ui-admin:3000"
  "auth-ui:80"
  "monitoring-metrics:9090"
  "monitoring-dashboard:3000"
  "monitoring-node:9100"
  "monitoring-db:9187"
  "mail-server:1025"
)

# Check each service
for service in "${services[@]}"; do
  # Split service:port
  IFS=":" read -r container_name port <<< "$service"
  
  echo "Checking $container_name (port $port)..."
  
  # Get container status
  container_status=$(docker inspect --format="{{.State.Status}}" $container_name 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo "  ❌ Container not found"
    continue
  fi
  
  if [ "$container_status" != "running" ]; then
    echo "  ❌ Container is not running (status: $container_status)"
    continue
  fi
  
  # Get health status if available
  health_status=$(docker inspect --format="{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}" $container_name 2>/dev/null)
  
  if [ "$health_status" == "healthy" ]; then
    echo "  ✅ Container is running and healthy"
  elif [ "$health_status" == "N/A" ]; then
    echo "  ⚠️ Container is running but has no health check"
  else
    echo "  ❌ Container is not healthy (status: $health_status)"
    
    # Get health check logs for unhealthy containers
    echo "  Health check logs:"
    docker inspect --format="{{if .State.Health}}{{range .State.Health.Log}}{{.Output}}{{end}}{{else}}No health logs available{{end}}" $container_name | tail -n 5
  fi
  
  echo ""
done

echo "Health check verification complete"
echo "=================================="