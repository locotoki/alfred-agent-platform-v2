#!/usr/bin/env bash
# Updates the Prometheus configuration to include all services with
# metrics endpoints exposed on port 9091

set -euo pipefail

# Define paths using absolute references to avoid permission issues
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROMETHEUS_DIR="${PROJECT_ROOT}/monitoring/prometheus"
PROMETHEUS_CONFIG="${PROMETHEUS_DIR}/prometheus.yml"
NEW_CONFIG="${PROMETHEUS_DIR}/prometheus.yml.new"

# Ensure we're in the project root
cd "${PROJECT_ROOT}"

echo "Updating Prometheus configuration to include all metrics endpoints..."

# Create a fresh configuration file based on the existing one
echo "Creating new config based on ${PROMETHEUS_CONFIG}..."
cp "$PROMETHEUS_CONFIG" "$NEW_CONFIG"

# Find all services that expose metrics on port 9091
echo "Finding services that expose metrics on port 9091..."
SERVICES_WITH_METRICS=(
  "agent-core"
  "alfred-bot"
  "model-registry"
  "model-router"
  "agent-financial"
  "agent-legal"
  "agent-rag"
  "agent-social"
  "ui-chat"
  "ui-admin"
)

# Add more services by scanning docker-compose.yml for port 9091
echo "Scanning docker-compose.yml for services with port 9091..."
COMPOSE_SERVICES=$(grep -B5 "9091:9091" "${PROJECT_ROOT}/docker-compose.yml" | grep -o '[a-z0-9_-]\+:$' | tr -d ':' || true)
for service in $COMPOSE_SERVICES; do
  if [[ ! " ${SERVICES_WITH_METRICS[*]} " =~ " $service " ]]; then
    SERVICES_WITH_METRICS+=("$service")
  fi
done

# Add more services by looking at Dockerfiles
echo "Scanning Dockerfiles for EXPOSE 9091..."
ADDITIONAL_SERVICES=$(grep -l "EXPOSE.*9091" "${PROJECT_ROOT}"/services/*/Dockerfile 2>/dev/null | xargs dirname 2>/dev/null | xargs basename 2>/dev/null | sort -u || true)
for service in $ADDITIONAL_SERVICES; do
  # Check if service is already in the list
  if [[ ! " ${SERVICES_WITH_METRICS[*]} " =~ " $service " ]]; then
    SERVICES_WITH_METRICS+=("$service")
  fi
done

# Also scan override files
echo "Scanning override compose files..."
for OVERRIDE_FILE in "${PROJECT_ROOT}"/docker-compose.*.yml; do
  if [[ -f "$OVERRIDE_FILE" ]]; then
    OVERRIDE_SERVICES=$(grep -B5 "9091:9091" "$OVERRIDE_FILE" | grep -o '[a-z0-9_-]\+:$' | tr -d ':' || true)
    for service in $OVERRIDE_SERVICES; do
      if [[ ! " ${SERVICES_WITH_METRICS[*]} " =~ " $service " ]]; then
        SERVICES_WITH_METRICS+=("$service")
      fi
    done
  fi
done

echo "Found ${#SERVICES_WITH_METRICS[@]} services that expose metrics on port 9091: ${SERVICES_WITH_METRICS[*]}"

# Create the targets array for the service_health job
TARGETS=""
for service in "${SERVICES_WITH_METRICS[@]}"; do
  if [ -z "$TARGETS" ]; then
    TARGETS="          '$service:9091'"
  else
    TARGETS="$TARGETS,\n          '$service:9091'"
  fi
done

# Check if the service_health job already exists
if grep -q "job_name: 'service_health'" "$NEW_CONFIG"; then
  # Update the existing job
  echo "Updating existing service_health job..."
  # Use perl for more robust regex replacement with multiline support
  perl -i -0pe "s|(job_name: 'service_health'.*?targets: \[).*?(\])|\\1\n$TARGETS\n        \\2|s" "$NEW_CONFIG"
else
  # Add a new job
  echo "Adding new service_health job..."
  cat << EOF >> "$NEW_CONFIG"

  # New job for service health metrics from v0.4.0 healthcheck binary
  - job_name: 'service_health'
    static_configs:
      - targets: [
$TARGETS
        ]
    metrics_path: '/metrics'
EOF
fi

# Add or update the alfred_health_dashboard job
if grep -q "job_name: 'alfred_health_dashboard'" "$NEW_CONFIG"; then
  # Update the existing job
  echo "Updating existing alfred_health_dashboard job..."
  perl -i -0pe "s|(job_name: 'alfred_health_dashboard'.*?targets: \[).*?(\])|\\1\n          'localhost:9091', 'localhost:9093', 'localhost:9094', 'localhost:9095', 'localhost:9096', 'localhost:9097', 'localhost:9098', 'localhost:9099', 'localhost:9100'\n        \\2|s" "$NEW_CONFIG"
else
  # Add a new job
  echo "Adding new alfred_health_dashboard job..."
  cat << EOF >> "$NEW_CONFIG"

  # Unified Health Dashboard Job (for Grafana)
  - job_name: 'alfred_health_dashboard'
    honor_labels: true
    metrics_path: '/metrics'
    static_configs:
      - targets: ['localhost:9091', 'localhost:9093', 'localhost:9094', 'localhost:9095', 'localhost:9096', 'localhost:9097', 'localhost:9098', 'localhost:9099', 'localhost:9100']
        labels:
          instance: 'alfred-platform'
          environment: 'development'
EOF
fi

# Validate the new config
if ! grep -q "job_name: 'service_health'" "$NEW_CONFIG"; then
  echo "❌ Error: service_health job not found in $NEW_CONFIG after update."
  exit 1
fi

if ! grep -q "job_name: 'alfred_health_dashboard'" "$NEW_CONFIG"; then
  echo "❌ Error: alfred_health_dashboard job not found in $NEW_CONFIG after update."
  exit 1
fi

echo ""
echo "✅ Prometheus configuration updated successfully!"
echo "New config file: $NEW_CONFIG"
echo ""
echo "To apply the changes, run:"
echo "  mv \"$NEW_CONFIG\" \"$PROMETHEUS_CONFIG\""
echo "  docker-compose restart prometheus"

# Offer to automatically apply the changes
read -p "Would you like to automatically apply these changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Applying changes..."
  mv "$NEW_CONFIG" "$PROMETHEUS_CONFIG"
  echo "Restarting Prometheus service..."
  docker-compose restart prometheus
  echo "✅ Changes applied and Prometheus restarted!"
fi
