#!/bin/bash
# E2E health check smoke test for Alfred Platform
# This script starts all services and verifies they report healthy status

set -e

echo "Starting E2E health check smoke test for Alfred Platform"
echo "------------------------------------------------------"

# Create a test directory
TEST_DIR="$(mktemp -d)"
cd "$TEST_DIR"
echo "Created temporary test directory: $TEST_DIR"

# Create a docker-compose file that starts services and includes a healthcheck service
cat > docker-compose.test.yml << 'EOF'
version: '3.8'

x-health-check-settings: &basic-health-check
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s

services:
  healthcheck-provider:
    image: ghcr.io/alfred-health/healthcheck:latest
    container_name: healthcheck-provider
    volumes:
      - healthcheck-binary:/healthcheck-binary
    entrypoint: 
      - sh
      - -c
      - |
        mkdir -p /healthcheck-binary
        cp /usr/local/bin/healthcheck /healthcheck-binary/
        chmod +x /healthcheck-binary/healthcheck
        echo "Healthcheck binary installed to volume"
        sleep 10
        exit 0

  # Add health validation service
  health-validator:
    image: ghcr.io/alfred-health/healthcheck:latest
    container_name: health-validator
    depends_on:
      healthcheck-provider:
        condition: service_completed_successfully
      # Add dependencies for core services
      db-postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      model-registry:
        condition: service_healthy
      model-router:
        condition: service_healthy
    entrypoint:
      - sh
      - -c
      - |
        echo "Checking health of all services..."
        
        # Wait for services to be ready
        sleep 30
        
        # Check core services
        echo "Checking db-postgres health..."
        healthcheck --postgres "postgres://postgres:postgres@db-postgres:5432/postgres" || exit 1
        
        echo "Checking redis health..."
        healthcheck --redis "redis://redis:6379" || exit 1
        
        echo "Checking model-registry health..."
        healthcheck --http "http://model-registry:8079/health" || exit 1
        
        echo "Checking model-router health..."
        healthcheck --http "http://model-router:8080/health" || exit 1
        
        echo "All core services are healthy!"
        exit 0

  # Required services for testing
  db-postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  model-registry:
    image: localhost/alfred/model-registry:latest
    volumes:
      - healthcheck-binary:/usr/local/bin
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db-postgres:5432/postgres
      HEALTH_CHECK_PORT: 8079
      HEALTH_CHECK_PATH: /health
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:8079/health"]
      <<: *basic-health-check
    depends_on:
      db-postgres:
        condition: service_healthy
      healthcheck-provider:
        condition: service_completed_successfully

  model-router:
    image: localhost/alfred/model-router:latest
    volumes:
      - healthcheck-binary:/usr/local/bin
    environment:
      MODEL_REGISTRY_URL: http://model-registry:8079
      HEALTH_CHECK_PORT: 8080
      HEALTH_CHECK_PATH: /health
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:8080/health"]
      <<: *basic-health-check
    depends_on:
      model-registry:
        condition: service_started
      healthcheck-provider:
        condition: service_completed_successfully

volumes:
  postgres-data:
  healthcheck-binary:
EOF

echo "Created test docker-compose file"

# Build necessary services
echo "Building core services..."
cd /home/locotoki/projects/alfred-agent-platform-v2
docker-compose -f docker-compose-clean.yml build model-registry model-router

echo "Starting test environment..."
cd "$TEST_DIR"
docker-compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from health-validator

RESULT=$?

echo "------------------------------------------------------"
if [ $RESULT -eq 0 ]; then
  echo "✅ E2E health check smoke test PASSED"
  
  # Capture Grafana dashboard screenshot if Grafana is available
  echo "Checking if Grafana is running..."
  if curl -s http://localhost:3000 > /dev/null; then
    echo "Grafana detected, capturing dashboard screenshot..."
    # Use a simple script to capture screenshot using headless browser
    # or simply output the Grafana URL for manual capture
    echo "Grafana dashboard available at: http://localhost:3000/d/platform-health/platform-health-overview"
    echo "Please capture a screenshot manually for the tracking issue"
  else
    echo "Grafana not detected. Skipping dashboard screenshot."
  fi
else
  echo "❌ E2E health check smoke test FAILED"
fi

echo "Cleaning up test environment..."
docker-compose -f docker-compose.test.yml down -v

echo "Removing temporary test directory..."
rm -rf "$TEST_DIR"

echo "E2E test completed with exit code: $RESULT"
exit $RESULT