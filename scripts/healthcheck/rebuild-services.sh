#!/usr/bin/env bash
# Script to rebuild services with healthcheck binary and metrics export

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Preparing to rebuild services with healthcheck updates ===${NC}"
echo ""

# Ensure proper working directory
cd "$(dirname "$0")/../.."
PROJECT_ROOT=$(pwd)

# List of services to rebuild
SERVICES=(
  "ui-chat"
  "model-registry"
  "model-router"
  "agent-rag"
  "agent-social"
  "agent-financial"
  "agent-legal"
  "pubsub-emulator"
)

# Check if services exist
echo -e "${YELLOW}Checking services to rebuild...${NC}"
for service in "${SERVICES[@]}"; do
  if grep -q "^  $service:" docker-compose.yml; then
    echo -e "  ${GREEN}✅ $service found in docker-compose.yml${NC}"
  else
    echo -e "  ${RED}❌ $service not found in docker-compose.yml${NC}"
    # Try to find the actual service name
    possible_match=$(grep -o "^  [a-z-]*$service[a-z-]*:" docker-compose.yml | tr -d ' :')
    if [ -n "$possible_match" ]; then
      echo -e "  ${YELLOW}   Possible match: $possible_match${NC}"
    fi
  fi
done

echo ""
echo -e "${GREEN}=== Instructions to rebuild services ===${NC}"
echo ""
echo -e "To complete the health check standardization, there are two approaches:"
echo ""
echo -e "1. ${YELLOW}Using the healthcheck binary (if available):${NC}"
echo -e "   docker-compose build --no-cache ui-chat"
echo -e "   docker-compose up -d ui-chat"
echo ""
echo -e "2. ${YELLOW}Implementing health endpoints directly in service code:${NC}"
echo -e "   docker-compose build --no-cache model-registry"
echo -e "   docker-compose up -d model-registry"
echo ""
echo -e "The model-registry service demonstrates the direct implementation approach:"
echo -e "- Exposes standard /health, /healthz, and /metrics endpoints"
echo -e "- Returns standardized responses in the required format"
echo -e "- Exposes port 9091 for metrics scraping by Prometheus"
echo ""
echo -e "${GREEN}=== Health check verification commands ===${NC}"
echo ""
echo -e "After rebuilding, verify implementation with:"
echo -e "${YELLOW}./scripts/healthcheck/run-full-healthcheck.sh${NC}"
echo -e "${YELLOW}./scripts/healthcheck/ensure-metrics-exported.sh${NC}"
echo ""
echo -e "${GREEN}=== Monitoring ===${NC}"
echo ""
echo -e "Access Prometheus at http://localhost:9090 to verify metrics collection"
echo -e "Check target status at http://localhost:9090/targets"
echo ""