#!/bin/bash
# Master script for bootstrapping health checks in the Alfred Agent Platform

set -e

# Base directory
BASE_DIR="/home/locotoki/projects/alfred-agent-platform-v2"
SCRIPTS_DIR="${BASE_DIR}/scripts"

# Log file
LOG_FILE="${BASE_DIR}/health-check-bootstrap.log"

# Timestamp function for logging
timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

# Logging function
log() {
  echo "[$(timestamp)] $1" | tee -a "$LOG_FILE"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if cadvisor is defined in docker-compose-clean.yml
check_cadvisor() {
  if grep -q "cadvisor:" "${BASE_DIR}/docker-compose-clean.yml"; then
    log "cAdvisor service found in docker-compose-clean.yml"
    return 0
  else
    log "cAdvisor service not found in docker-compose-clean.yml. Adding it..."
    
    # Add cAdvisor service to docker-compose-clean.yml
    cat <<EOT >> "${BASE_DIR}/docker-compose-clean.yml"

  # Container Advisor - Container metrics exporter
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.0
    container_name: cadvisor
    privileged: true
    devices:
      - /dev/kmsg:/dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8081:8080"
    healthcheck:
      test: ["CMD", "healthcheck", "--http", "http://localhost:8080/healthz"]
      <<: *basic-health-check
    restart: unless-stopped
    deploy:
    networks:
      - alfred-network
    labels:
      <<: *monitoring-service-labels
      com.docker.compose.service: "cadvisor"
EOT
    
    log "Added cAdvisor service to docker-compose-clean.yml"
    return 0
  fi
}

# Main function
main() {
  log "Starting health check bootstrap process..."
  
  # 1. Update service Dockerfiles to include healthcheck binary
  log "Step 1: Updating Dockerfiles with healthcheck binary..."
  bash "${SCRIPTS_DIR}/update-healthcheck-binary.sh"
  log "Step 1 completed successfully"
  
  # 2. Check and add cAdvisor service
  log "Step 2: Checking cAdvisor service..."
  check_cadvisor
  log "Step 2 completed successfully"
  
  # 3. Set up Prometheus configuration for health checks
  log "Step 3: Setting up Prometheus configuration..."
  python3 "${SCRIPTS_DIR}/setup-prometheus-health-checks.py"
  log "Step 3 completed successfully"
  
  # 4. Build and start the updated services
  log "Step 4: Building and starting updated services..."
  log "Building services with updated Dockerfiles..."
  docker-compose -f "${BASE_DIR}/docker-compose-clean.yml" build
  
  log "Starting services with updated configurations..."
  cd "${BASE_DIR}" && echo y | ./start-platform.sh -a restart
  log "Step 4 completed successfully"
  
  # 5. Wait for Grafana to be ready
  log "Step 5: Waiting for Grafana to be ready..."
  log "Sleeping for 60 seconds to allow services to initialize..."
  sleep 60
  
  # 6. Seed Grafana health dashboards
  log "Step 6: Seeding Grafana health dashboards..."
  if command_exists python3; then
    GRAFANA_URL="http://localhost:3005" \
    GRAFANA_USER="admin" \
    GRAFANA_PASSWORD="${MONITORING_ADMIN_PASSWORD:-admin}" \
    python3 "${SCRIPTS_DIR}/seed-health-dashboard.py"
    log "Step 6 completed successfully"
  else
    log "ERROR: Python 3 not found. Skipping dashboard seeding."
    log "To manually seed the dashboards, run: python3 ${SCRIPTS_DIR}/seed-health-dashboard.py"
  fi
  
  # 7. Verify service health
  log "Step 7: Verifying service health..."
  bash "${SCRIPTS_DIR}/verify-service-health.sh" | tee -a "$LOG_FILE"
  log "Step 7 completed successfully"
  
  log "Health check bootstrap process completed successfully!"
  log "Grafana dashboards available at: http://localhost:3005"
  log "Default credentials: admin / ${MONITORING_ADMIN_PASSWORD:-admin}"
  log "Log file: $LOG_FILE"
  
  echo ""
  echo "================================================================================"
  echo "  Health Check Bootstrap Complete!"
  echo "================================================================================"
  echo ""
  echo "  Grafana dashboards: http://localhost:3005"
  echo "  Default credentials: admin / ${MONITORING_ADMIN_PASSWORD:-admin}"
  echo ""
  echo "  For detailed logs, see: $LOG_FILE"
  echo ""
}

# Execute main function
main