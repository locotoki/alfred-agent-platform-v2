#!/bin/bash
# optimize-startup-sequence.sh
# Script to optimize service startup sequence through proper dependency ordering

set -e

echo "Optimizing startup sequence in docker-compose.unified.yml..."

# Backup the original file
cp ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-sequence

# Function to update dependencies for a service
update_dependencies() {
  service=$1
  deps=$2
  
  # Check if service exists
  if ! grep -q "^  $service:" ../docker-compose.unified.yml; then
    echo "⚠️ Service $service not found"
    return
  fi
  
  # Find the depends_on section or add it if it doesn't exist
  if grep -q "^    depends_on:" ../docker-compose.unified.yml; then
    # Remove existing depends_on section
    sed -i "/^  $service:/,/^  [a-z]/ { /depends_on:/,/    [a-z]/d }" ../docker-compose.unified.yml
  fi
  
  # Find where to insert the depends_on section (before networks, volumes, or the next service)
  line_num=$(grep -n "^  $service:" ../docker-compose.unified.yml | cut -d: -f1)
  insert_line=$line_num
  
  # Find the next key we want to insert before
  for key in "networks:" "labels:" "restart:"; do
    key_line=$(tail -n +$line_num ../docker-compose.unified.yml | grep -n "^    $key" | head -1 | cut -d: -f1)
    if [ -n "$key_line" ]; then
      possible_line=$((line_num + key_line - 1))
      if [ $possible_line -gt $insert_line ]; then
        insert_line=$possible_line
      fi
    fi
  done
  
  # Now create and insert the depends_on block
  depends_block="    depends_on:"
  for dep in $deps; do
    IFS=':' read -r dep_name dep_condition <<< "$dep"
    if [ -z "$dep_condition" ]; then
      dep_condition="service_started"
    fi
    depends_block="$depends_block\n      $dep_name:\n        condition: $dep_condition"
  done
  
  # Insert the depends_on block
  sed -i "${insert_line}i\\${depends_block}" ../docker-compose.unified.yml
  
  echo "✅ Updated dependencies for $service"
}

# Update dependencies for core services
update_dependencies "model-registry" "db-postgres:service_healthy llm-service"
update_dependencies "model-router" "model-registry:service_healthy"
update_dependencies "db-api" "db-postgres:service_healthy"
update_dependencies "db-realtime" "db-postgres:service_healthy"
update_dependencies "db-storage" "db-postgres:service_healthy db-api"

# Update dependencies for agent services
update_dependencies "agent-core" "db-postgres:service_healthy redis:service_healthy pubsub-emulator model-router"
update_dependencies "agent-rag" "vector-db redis:service_healthy model-router"
update_dependencies "agent-atlas" "agent-rag:service_started redis:service_healthy pubsub-emulator model-router"
update_dependencies "agent-social" "db-postgres:service_healthy redis:service_healthy pubsub-emulator agent-rag:service_started model-router"
update_dependencies "agent-financial" "db-postgres:service_healthy redis:service_healthy pubsub-emulator agent-rag:service_started model-router"
update_dependencies "agent-legal" "db-postgres:service_healthy redis:service_healthy pubsub-emulator agent-rag:service_started model-router"

# Update dependencies for UI services
update_dependencies "ui-chat" "agent-core:service_started model-router:service_started"
update_dependencies "ui-admin" "agent-core:service_started agent-rag:service_started"
update_dependencies "auth-ui" "db-auth:service_started"

# Update dependencies for monitoring services
update_dependencies "monitoring-db" "db-postgres:service_healthy"
update_dependencies "monitoring-redis" "redis:service_started"

echo "Startup sequence optimized. Review changes with:"
echo "diff ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-sequence"
echo ""
echo "Apply changes with:"
echo "cd .. && docker-compose -f docker-compose.unified.yml up -d"