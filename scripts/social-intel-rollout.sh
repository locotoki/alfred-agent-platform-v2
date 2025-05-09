#!/bin/bash
# Social-Intel Service Rollout Script
# This script implements the canary deployment plan for Social-Intel v1.0.0

set -e  # Exit on error

echo "===== Social-Intel Service Rollout ====="
echo "Starting rollout process..."

# Step 1: Deploy the database schema first
echo -e "\n[1/7] Deploying database schema..."
cd /home/locotoki/projects/alfred-agent-platform-v2/services/social-intel
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL environment variable not set"
  exit 1
fi
npm run migrate
echo "✅ Database schema deployed"

# Step 2: Check existing data and seed if needed
echo -e "\n[2/7] Checking data and seeding if needed..."
# Check if data exists and when it was last updated
max_updated=$(docker compose exec social-intel psql -t -c 'select max(updated_at) from features')
if [ -z "$max_updated" ] || [ "$max_updated" = " " ]; then
  echo "No existing data found. Seeding initial data..."
  npm run db:seed
  echo "✅ Initial data seeded"
else
  current_time=$(date +%s)
  last_update=$(date -d "$max_updated" +%s 2>/dev/null || echo 0)
  time_diff=$((current_time - last_update))
  
  if [ $time_diff -gt 86400 ]; then
    echo "⚠️ Data has not been updated in more than 24 hours (last update: $max_updated)"
    echo "Running nightly scorer to update data..."
    npm run score:nightly
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
attempt=0
max_attempts=30
until docker compose exec social-intel curl -s http://localhost:9000/health/ | grep -q "ok" || [ $attempt -eq $max_attempts ]; do
  echo "Waiting for Social-Intel to be ready... ($((attempt+1))/$max_attempts)"
  sleep 2
  attempt=$((attempt+1))
done

if [ $attempt -eq $max_attempts ]; then
  echo "ERROR: Social-Intel service failed to become healthy"
  exit 1
fi
echo "✅ Social-Intel service is healthy"

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
echo "  ./scripts/rotate-secrets.sh"