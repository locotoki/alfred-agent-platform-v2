#!/bin/bash
# Script to update all Dockerfiles to use healthcheck binary v0.4.0
# and enable metrics exporters on port 9091

set -e

echo "Updating Dockerfiles to use healthcheck binary v0.4.0..."

# List of services to update
SERVICES=(
  "services/rag-service"
  "services/financial-tax"
  "services/legal-compliance"
  "services/social-intel"
  "services/alfred-bot"
  "rag-gateway"
)

# Update each service Dockerfile
for SERVICE in "${SERVICES[@]}"; do
  if [ -f "$SERVICE/Dockerfile.new" ]; then
    echo "Updating $SERVICE/Dockerfile"
    mv "$SERVICE/Dockerfile.new" "$SERVICE/Dockerfile"
  else
    echo "WARNING: $SERVICE/Dockerfile.new not found"
  fi
done

# Update Prometheus configuration
if [ -f "monitoring/prometheus/prometheus.yml.new" ]; then
  echo "Updating Prometheus configuration"
  mv "monitoring/prometheus/prometheus.yml.new" "monitoring/prometheus/prometheus.yml"
else
  echo "WARNING: monitoring/prometheus/prometheus.yml.new not found"
fi

# Update Grafana dashboard
if [ -f "monitoring/grafana/dashboards/platform/health-dashboard.json.new" ]; then
  echo "Updating Grafana health dashboard"
  mv "monitoring/grafana/dashboards/platform/health-dashboard.json.new" "monitoring/grafana/dashboards/platform/health-dashboard.json"
else
  echo "WARNING: monitoring/grafana/dashboards/platform/health-dashboard.json.new not found"
fi

# Update Docker Compose file with tightened health check timings
if [ -f "docker-compose-clean.yml.new" ]; then
  echo "Updating Docker Compose configuration with tightened health check timings"
  mv "docker-compose-clean.yml.new" "docker-compose-clean.yml"
else
  echo "WARNING: docker-compose-clean.yml.new not found"
fi

echo "All updates completed."
echo "To apply these changes, you need to rebuild the affected services:"
echo "  docker-compose -f docker-compose-clean.yml build ${SERVICES[@]}"
echo "  docker-compose -f docker-compose-clean.yml up -d"