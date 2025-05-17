#!/bin/bash
# Standardize health endpoint implementations for all services
#
# This script:
# 1. Checks all services for compliance with the health endpoint standard
# 2. Verifies that each service implements all three required endpoints
# 3. Rebuilds and restarts only the affected services
#
# See docs/HEALTH_CHECK_STANDARD.md for details on the framework

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure the script is run from the project root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

echo -e "${BLUE}Standardizing service health endpoints${NC}"
echo "================================================"
echo "Enforcing the three-endpoint health check framework"
echo "For details, see docs/HEALTH_CHECK_STANDARD.md"
echo

# List of services to check (service_name:port:service_directory)
SERVICES=(
  "agent-rag:8501:./services/rag-service"
  "agent-core:8011:./alfred/core"
  "agent-social:9000:./services/social-intel"
  "agent-financial:9003:./services/financial-tax"
  "agent-legal:9002:./services/legal-compliance"
  "ui-chat:8502:./services/streamlit-chat"
  "model-router:8080:./alfred/model/router"
)

# Function to check if an endpoint exists
check_endpoint() {
    local url="$1"
    local pattern="$2"
    local timeout=2  # Short timeout to avoid hanging on unreachable services

    if curl -s --max-time "$timeout" "$url" 2>/dev/null | grep -q "$pattern"; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# Function to check if a service implements all required endpoints
validate_service() {
    local service="$1"
    local port="$2"
    local passed=true

    echo -e "${CYAN}Validating ${service} (port ${port})${NC}"

    # Check /health endpoint
    if check_endpoint "http://localhost:${port}/health" "status"; then
        echo -e "  /health endpoint: ${GREEN}OK${NC}"
    else
        echo -e "  /health endpoint: ${RED}MISSING${NC}"
        passed=false
    fi

    # Check /healthz endpoint
    if check_endpoint "http://localhost:${port}/healthz" "ok"; then
        echo -e "  /healthz endpoint: ${GREEN}OK${NC}"
    else
        echo -e "  /healthz endpoint: ${RED}MISSING${NC}"
        passed=false
    fi

    # Check /metrics endpoint
    if check_endpoint "http://localhost:${port}/metrics" "_up"; then
        echo -e "  /metrics endpoint: ${GREEN}OK${NC}"
    else
        echo -e "  /metrics endpoint: ${RED}MISSING${NC}"
        passed=false
    fi

    if [ "$passed" = true ]; then
        echo -e "  Overall: ${GREEN}Compliant with framework${NC}"
        return 0
    else
        echo -e "  Overall: ${RED}Non-compliant with framework${NC}"
        return 1
    fi
}

# Function to fix a specific service
fix_service() {
    local service="$1"
    local port="$2"
    local service_dir="$3"

    echo -e "${YELLOW}Fixing health endpoints for ${service}${NC}"

    # Rebuild and restart only this service
    echo "Rebuilding ${service}..."
    docker-compose -f docker-compose-clean.yml build "${service}"

    echo "Restarting ${service}..."
    docker-compose -f docker-compose-clean.yml stop "${service}"
    docker-compose -f docker-compose-clean.yml rm -f "${service}"
    docker-compose -f docker-compose-clean.yml up -d --no-deps --force-recreate "${service}"

    echo "Waiting for service to start..."
    sleep 15

    # Re-validate the service
    if validate_service "$service" "$port"; then
        echo -e "${GREEN}✅ ${service} service now complies with the framework!${NC}"
    else
        echo -e "${RED}❌ ${service} is still non-compliant.${NC}"
        echo "Checking container logs:"
        docker-compose -f docker-compose-clean.yml logs --tail=20 "${service}"
    fi

    echo
}

# Process all services
for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r service port dir <<< "$service_info"

    # Try to validate the service
    echo
    if ! validate_service "$service" "$port"; then
        echo
        read -p "Would you like to fix $service? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            fix_service "$service" "$port" "$dir"
        else
            echo -e "${YELLOW}Skipping $service fix${NC}"
        fi
    fi
done

echo
echo -e "${BLUE}Service health standardization completed${NC}"
echo "For details on the health check framework, see:"
echo "  docs/HEALTH_CHECK_STANDARD.md"