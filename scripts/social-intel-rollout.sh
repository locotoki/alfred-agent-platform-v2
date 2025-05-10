#!/bin/bash
# Social-Intel Service Rollout Script
# This script implements the canary deployment plan for Social-Intel v1.0.0

set -e  # Exit on error

echo "===== Social-Intel Service Rollout ====="
echo "Starting rollout process..."

# Step 1: Deploy the database schema first
echo -e "\n[1/7] Deploying database schema..."
cd /home/locotoki/projects/alfred-agent-platform-v2/services/social-intel
export DATABASE_URL=$(grep DATABASE_URL /home/locotoki/projects/alfred-agent-platform-v2/.env | cut -d= -f2-)
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL environment variable not set"
  exit 1
fi
echo "Using DATABASE_URL: $DATABASE_URL"

# Check if PostgreSQL client is installed
if command -v psql &> /dev/null; then
  echo "Using local psql client"
  npm run migrate
else
  echo "PostgreSQL client not found, using Docker"
  cd /home/locotoki/projects/alfred-agent-platform-v2
  
  # Verify if supabase-db container is running
  if docker ps | grep -q supabase-db; then
    echo "Applying database schema via Docker..."
    cat services/social-intel/db/schema.sql | docker exec -i $(docker ps -q --filter name=supabase-db) psql -U postgres -d postgres
    echo "Schema applied successfully"
  else
    echo "WARNING: Database container not running, trying to start..."
    docker compose up -d supabase-db
    echo "Waiting for database to start..."
    sleep 10
    cat services/social-intel/db/schema.sql | docker exec -i $(docker ps -q --filter name=supabase-db) psql -U postgres -d postgres
  fi
  cd /home/locotoki/projects/alfred-agent-platform-v2/services/social-intel
fi

echo "✅ Database schema deployed"

# Step 2: Check existing data and seed if needed
echo -e "\n[2/7] Checking data and seeding if needed..."
# Check if data exists and when it was last updated
cd /home/locotoki/projects/alfred-agent-platform-v2

# Query max updated timestamp from database
max_updated=$(docker exec -i $(docker ps -q --filter name=supabase-db) psql -U postgres -d postgres -t -c 'select max(updated_at) from features' 2>/dev/null || echo "")

cd /home/locotoki/projects/alfred-agent-platform-v2/services/social-intel

if [ -z "$max_updated" ] || [ "$max_updated" = " " ]; then
  echo "No existing data found. Seeding initial data..."
  if command -v node &> /dev/null; then
    echo "Using local Node"
    npm run db:seed
  else
    echo "Using Docker for seeding"
    cd /home/locotoki/projects/alfred-agent-platform-v2
    docker compose exec social-intel npm run db:seed
    cd /home/locotoki/projects/alfred-agent-platform-v2/services/social-intel
  fi
  echo "✅ Initial data seeded"
else
  current_time=$(date +%s)
  last_update=$(date -d "$max_updated" +%s 2>/dev/null || echo 0)
  time_diff=$((current_time - last_update))
  
  if [ $time_diff -gt 86400 ]; then
    echo "⚠️ Data has not been updated in more than 24 hours (last update: $max_updated)"
    echo "Running nightly scorer to update data..."
    if command -v node &> /dev/null; then
      echo "Using local Node"
      npm run score:nightly
    else
      echo "Using Docker for scoring"
      cd /home/locotoki/projects/alfred-agent-platform-v2
      docker compose exec social-intel npm run score:nightly
      cd /home/locotoki/projects/alfred-agent-platform-v2/services/social-intel
    fi
    echo "✅ Data updated with latest scores"
  else
    echo "✅ Data is current (last update: $max_updated)"
  fi
fi

# Step 3: Deploy services with Docker Compose
echo -e "\n[3/7] Deploying services..."
cd /home/locotoki/projects/alfred-agent-platform-v2
docker compose up -d social-intel
echo "✅ Social-Intel service deployed"

# Step 4: Wait for service to be healthy
echo -e "\n[4/7] Waiting for Social-Intel service to be healthy..."

# First, check if the container is running
if ! docker compose ps social-intel | grep -q "Up"; then
  echo "Social-Intel container not running, attempting to start it..."
  docker compose up -d social-intel
  # Wait for container to start
  sleep 10
fi

# If using custom image, tag it for use with docker-compose
if docker images | grep -q "social-intel:v1.0.0"; then
  echo "Tagging custom image for use with docker-compose"
  docker tag social-intel:v1.0.0 alfred-agent-platform-v2-social-intel:latest
  docker compose up -d social-intel
  # Wait for container to start
  sleep 10
fi

# Now check health
attempt=0
max_attempts=30
until curl -s http://localhost:9000/health/ | grep -q "healthy" || [ $attempt -eq $max_attempts ]; do
  echo "Waiting for Social-Intel to be ready... ($((attempt+1))/$max_attempts)"
  sleep 2
  attempt=$((attempt+1))
done

if [ $attempt -eq $max_attempts ]; then
  echo "WARNING: Social-Intel service health check timed out"
  echo "Checking logs for errors:"
  docker compose logs --tail=20 social-intel
  read -p "Continue despite health check failure? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollout aborted."
    exit 1
  fi
  echo "Continuing rollout despite health check failure..."
else
  echo "✅ Social-Intel service is healthy"
fi

# Step 5: Deploy proxy with 10% canary
echo -e "\n[5/7] Deploying proxy with 10% canary traffic..."
docker compose up -d mission-control
echo "✅ Mission Control deployed with FEATURE_PROXY_ENABLED=0.1"

# Step 6: Setup monitoring and install k6
echo -e "\n[6/7] Setting up monitoring and installing k6..."
echo "Installing k6..."
if ! command -v k6 &> /dev/null; then
  curl -s https://packagecloud.io/install/repositories/loadimpact/k6/script.deb.sh | sudo bash
  sudo apt-get install k6 -y
  echo "✅ k6 installed"
else
  echo "✅ k6 already installed"
fi
if [ -d "monitoring" ]; then
  docker compose -f monitoring/prometheus/docker-compose.yml up -d || echo "WARNING: Could not start monitoring stack"
  echo "✅ Monitoring deployed"
else
  echo "⚠️ Monitoring directory not found, skipping"
fi

# Step 7: Final checks
echo -e "\n[7/7] Running final checks..."
echo "Testing Social-Intel API..."
curl -s http://localhost:9000/health/ready | grep -q "ready" && echo "✅ Health check passed" || echo "⚠️ Health check failed"
curl -s http://localhost:9000/docs | grep -q "Swagger" && echo "✅ Swagger UI available" || echo "⚠️ Swagger UI not available"

echo -e "\n===== Rollout Complete ====="
echo "Social-Intel service has been deployed with canary settings."
echo "Monitor for 24 hours before proceeding to 100% traffic."
echo ""
echo "Run the following command to promote to 100% traffic:"
echo "  sed -i 's/FEATURE_PROXY_ENABLED=0.1/FEATURE_PROXY_ENABLED=1/' .env && docker compose restart mission-control"
echo ""
echo "Monitoring dashboards:"
echo "  - Grafana: http://localhost:3002 (admin/admin)"
echo "  - Prometheus: http://localhost:9090"
echo "  - Social-Intel API: http://localhost:9000/docs"
echo ""
echo "SECURITY REMINDER: Have you rotated any exposed secrets?"
echo "Run the secrets check tool if you haven't already:"
echo "  ./scripts/rotate-secrets.sh"pg_dump -Fc social_intel > pre-rollout.dump
