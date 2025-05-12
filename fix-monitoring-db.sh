#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing monitoring-db authentication issue...${NC}"

# Check if the container is running
if ! docker ps | grep -q monitoring-db; then
  echo -e "${RED}Container monitoring-db is not running.${NC}"
  exit 1
fi

# Get the current PostgreSQL password from alfred-postgres container
PG_PASSWORD=$(docker inspect --format='{{range .Config.Env}}{{if eq (index (split . "=") 0) "POSTGRES_PASSWORD"}}{{index (split . "=") 1}}{{end}}{{end}}' alfred-postgres)

if [ -z "$PG_PASSWORD" ]; then
  echo -e "${RED}Could not determine PostgreSQL password from container.${NC}"
  echo -e "${YELLOW}Using 'postgres' as default password.${NC}"
  PG_PASSWORD="postgres"
fi

echo -e "${YELLOW}Using PostgreSQL password: $PG_PASSWORD${NC}"

# Update the monitoring-db container with the correct connection string
echo -e "${YELLOW}Updating monitoring-db container with correct credentials...${NC}"
docker stop monitoring-db

# Start the container with the correct environment variable
docker run -d --rm \
  --name monitoring-db \
  --network alfred-network \
  -p 9187:9187 \
  -e "DATA_SOURCE_NAME=postgresql://postgres:${PG_PASSWORD}@alfred-postgres:5432/postgres?sslmode=disable" \
  --health-cmd "curl -f http://localhost:9187/metrics" \
  --health-interval 30s \
  --health-timeout 10s \
  --health-retries 3 \
  --health-start-period 10s \
  prometheuscommunity/postgres-exporter:v0.15.0

# Wait for the container to start
echo -e "${YELLOW}Waiting for monitoring-db to restart...${NC}"
sleep 5

# Check the health status
if curl -s http://localhost:9187/metrics > /dev/null; then
  echo -e "${GREEN}✅ monitoring-db is now connected to PostgreSQL correctly.${NC}"
else
  echo -e "${RED}❌ monitoring-db is still having issues. Please check the logs:${NC}"
  docker logs monitoring-db
fi