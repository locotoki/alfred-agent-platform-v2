#!/bin/bash
# Setup script for db-metrics service

set -e

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up db-metrics exporter service...${NC}"

# Ensure the directory structure exists
if [ ! -d "services/db-metrics" ]; then
  echo -e "${GREEN}Creating db-metrics directory...${NC}"
  mkdir -p services/db-metrics
fi

# Update Prometheus configuration
echo -e "${GREEN}Updating Prometheus configuration...${NC}"
if [ -f "monitoring/prometheus/prometheus.yml.new" ]; then
  cp monitoring/prometheus/prometheus.yml.new monitoring/prometheus/prometheus.yml
  echo -e "${GREEN}Prometheus configuration updated successfully.${NC}"
else
  echo -e "${RED}Error: New Prometheus configuration file not found.${NC}"
  exit 1
fi

# Update docker-compose.yml to include db-metrics
echo -e "${GREEN}Adding db-metrics service to docker-compose-clean.yml...${NC}"

# Check if service already exists
if grep -q "db-metrics:" docker-compose-clean.yml; then
  echo -e "${BLUE}db-metrics service already exists in docker-compose-clean.yml.${NC}"
else
  # Create a temporary file with the service definition
  cat << EOF > /tmp/db-metrics-service.yml
  # Database Metrics Exporter
  db-metrics:
    build:
      context: ./services/db-metrics
      dockerfile: Dockerfile
    image: db-metrics:latest
    container_name: db-metrics
    ports:
      - "9120:8000"  # API port
      - "9121:9091"  # Metrics port
    environment:
      - ALFRED_ENVIRONMENT=\${ALFRED_ENVIRONMENT:-development}
      - ALFRED_DEBUG=\${ALFRED_DEBUG:-true}
      - DB_USER=\${DB_USER:-postgres}
      - DB_PASSWORD=\${DB_PASSWORD:-your-super-secret-password}
      - DB_NAME=\${DB_NAME:-postgres}
    depends_on:
      db-postgres:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 45s
    restart: unless-stopped
    deploy:
    networks:
      - alfred-network
    labels:
      com.docker.compose.project: "alfred"
      com.docker.compose.group: "monitoring"
      com.docker.compose.service: "db-metrics"
EOF

  # Find the last monitoring service and insert db-metrics after it
  last_monitoring_line=$(grep -n "com.docker.compose.group: \"monitoring\"" docker-compose-clean.yml | tail -1 | cut -d: -f1)

  if [ -n "$last_monitoring_line" ]; then
    # Find the next service after the last monitoring service
    next_service_line=$((last_monitoring_line + 1))
    while ! grep -q "^  [a-zA-Z0-9_-]\+:$" <(sed -n "${next_service_line}p" docker-compose-clean.yml) && [ "$next_service_line" -lt "$(wc -l < docker-compose-clean.yml)" ]; do
      next_service_line=$((next_service_line + 1))
    done

    # Insert the db-metrics service before the next service
    sed -i "${next_service_line}r /tmp/db-metrics-service.yml" docker-compose-clean.yml
    echo -e "${GREEN}db-metrics service added to docker-compose-clean.yml.${NC}"
  else
    echo -e "${RED}Could not find a suitable position to insert db-metrics service.${NC}"
    echo -e "${BLUE}Please add the db-metrics service to docker-compose-clean.yml manually.${NC}"
    cat /tmp/db-metrics-service.yml
  fi

  # Clean up temporary file
  rm /tmp/db-metrics-service.yml
fi

# Build and start the service
echo -e "${GREEN}Building and starting db-metrics service...${NC}"
docker-compose -f docker-compose-clean.yml build db-metrics
docker-compose -f docker-compose-clean.yml up -d db-metrics

# Restart Prometheus to pick up the new configuration
echo -e "${GREEN}Restarting Prometheus to apply new configuration...${NC}"
docker-compose -f docker-compose-clean.yml restart monitoring-metrics

echo -e "${GREEN}Done! The db-metrics service is now set up.${NC}"
echo -e "${BLUE}You can access the metrics at http://localhost:9121/metrics${NC}"
echo -e "${BLUE}You can access the API at http://localhost:9120/health${NC}"
echo -e "${BLUE}View the metrics in Grafana at http://localhost:3005/dashboards${NC}"
