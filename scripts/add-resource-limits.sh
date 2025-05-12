#!/bin/bash
set -e

# Add resource limits to key services in docker-compose.unified.yml

echo "Adding resource limits to key services..."

# Backup the original file
cp ../docker-compose.unified.yml ../docker-compose.unified.yml.bak

# Function to add resource limits to a service
add_resource_limits() {
  service=$1
  memory_limit=$2
  cpu_limit=$3
  memory_reservation=$4

  # Check if the service exists
  if grep -q "^  $service:" ../docker-compose.unified.yml; then
    # Check if deploy section already exists for this service
    if grep -A 20 "^  $service:" ../docker-compose.unified.yml | grep -q "    deploy:"; then
      echo "ℹ️ Service $service already has deploy section, skipping"
    else
      # Find the line number where the service definition starts
      start_line=$(grep -n "^  $service:" ../docker-compose.unified.yml | cut -d':' -f1)

      # Find a good spot to insert the deploy section (before networks, labels, or the next service)
      networks_line=$(tail -n +$start_line ../docker-compose.unified.yml | grep -n "^    networks:" | head -1 | cut -d':' -f1)
      labels_line=$(tail -n +$start_line ../docker-compose.unified.yml | grep -n "^    labels:" | head -1 | cut -d':' -f1)
      next_service_line=$(tail -n +$start_line ../docker-compose.unified.yml | grep -n "^  [a-z]" | head -2 | tail -1 | cut -d':' -f1)

      # Default to next service if no better anchor point is found
      if [ -z "$networks_line" ] && [ -z "$labels_line" ]; then
        insert_line=$((start_line + next_service_line - 1))
      elif [ -z "$networks_line" ]; then
        insert_line=$((start_line + labels_line - 1))
      elif [ -z "$labels_line" ]; then
        insert_line=$((start_line + networks_line - 1))
      else
        # Use the first one that appears
        if [ "$networks_line" -lt "$labels_line" ]; then
          insert_line=$((start_line + networks_line - 1))
        else
          insert_line=$((start_line + labels_line - 1))
        fi
      fi

      # Create the deploy section content
      if [ -n "$memory_reservation" ]; then
        deploy_content="    deploy:\n      resources:\n        limits:\n          memory: $memory_limit\n          cpus: '$cpu_limit'\n        reservations:\n          memory: $memory_reservation\n"
      else
        deploy_content="    deploy:\n      resources:\n        limits:\n          memory: $memory_limit\n          cpus: '$cpu_limit'\n"
      fi

      # Insert the deploy section
      sed -i "${insert_line}i\\${deploy_content}" ../docker-compose.unified.yml

      echo "✅ Added resource limits to $service"
    fi
  else
    echo "⚠️ Service $service not found in docker-compose.unified.yml"
  fi
}

# Add resource limits to key services
add_resource_limits "agent-rag" "700M" "0.5" "400M"
add_resource_limits "model-registry" "150M" "0.3" ""
add_resource_limits "db-postgres" "500M" "1.0" "200M"
add_resource_limits "agent-social" "150M" "0.3" ""
add_resource_limits "agent-financial" "150M" "0.3" ""
add_resource_limits "agent-legal" "150M" "0.3" ""
add_resource_limits "pubsub-emulator" "400M" "1.5" "300M"
add_resource_limits "model-router" "150M" "0.3" ""
add_resource_limits "db-realtime" "250M" "0.8" "150M"
add_resource_limits "vector-db" "250M" "0.5" "150M"
add_resource_limits "ui-chat" "150M" "0.3" ""
add_resource_limits "ui-admin" "200M" "0.3" ""
add_resource_limits "monitoring-metrics" "150M" "0.2" ""
add_resource_limits "monitoring-dashboard" "200M" "0.2" ""

echo "Resource limits added. Verify changes with:"
echo "diff ../docker-compose.unified.yml ../docker-compose.unified.yml.bak"
echo ""
echo "Apply changes with:"
echo "cd .. && docker-compose -f docker-compose.unified.yml up -d"