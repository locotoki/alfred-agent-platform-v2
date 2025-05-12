#!/bin/bash
# standardize-health-checks.sh
# Script to standardize health checks across all services

set -e

echo "Standardizing health checks in docker-compose.unified.yml..."

# Backup the original file
cp ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-health

# Function to update health check for a service
update_health_check() {
  service=$1
  port_line=$(grep -A20 "^  $service:" ../docker-compose.unified.yml | grep -oP "ports:.*?:\K\d+" | head -1)
  
  if [ -z "$port_line" ]; then
    echo "⚠️ Could not extract port for $service"
    return
  fi
  
  # Determine appropriate health endpoint based on service type
  if [[ "$service" == *rag* ]]; then
    endpoint="/healthz"
  elif [[ "$service" == agent-* ]] || [[ "$service" == db-* ]]; then
    endpoint="/health"
  else
    endpoint="/health"
  fi
  
  # Update the health check configuration
  sed -i "/^  $service:/,/healthcheck:/!b;/healthcheck:/,/restart:/c\\
    healthcheck:\\
      test: [\"CMD-SHELL\", \"wget -q -O - http://localhost:$port_line$endpoint > /dev/null || exit 1\"]\\
      interval: 20s\\
      timeout: 5s\\
      retries: 3\\
      start_period: 30s\\
    restart: unless-stopped" ../docker-compose.unified.yml
  
  echo "✅ Updated health check for $service with port $port_line and endpoint $endpoint"
}

# Extract all service names
service_names=$(grep -oP "^  \K[a-zA-Z0-9-]+(?=:)" ../docker-compose.unified.yml)

# Update health checks for all services
for service in $service_names; do
  # Skip certain services that don't need HTTP health checks
  if [[ "$service" == "llm-service" ]] || [[ "$service" == "redis" ]] || [[ "$service" == "mail-server" ]]; then
    echo "ℹ️ Skipping $service (uses non-HTTP health check)"
    continue
  fi
  
  update_health_check "$service"
done

echo "Health checks standardized. Review changes with:"
echo "diff ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-health"
echo ""
echo "Apply changes with:"
echo "cd .. && docker-compose -f docker-compose.unified.yml up -d"