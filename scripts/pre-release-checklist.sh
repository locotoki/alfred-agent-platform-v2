#!/usr/bin/env bash
# Pre-release Checklist Script for GA v3.0.0 Staging Validation (Week of July 7)
# Usage: ./scripts/pre-release-checklist.sh
# Requirements:
#   - Docker CLI authenticated to your registry
#   - kubectl configured for your staging cluster (optional)
#   - Helm installed
#
# Environment variables are loaded from .env.dev or can be overridden

set -euo pipefail

# Load environment variables from .env files if they exist
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
fi

if [[ -f .env.dev ]]; then
  export $(grep -v '^#' .env.dev | xargs)
fi

# Override with staging-specific values if needed
export SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-$STAGING_SLACK_BOT_TOKEN}"
export SLACK_APP_TOKEN="${SLACK_APP_TOKEN:-$STAGING_SLACK_APP_TOKEN}"
export REDIS_PASSWORD="${REDIS_PASSWORD:-$STAGING_REDIS_PASSWORD}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Alfred Agent Platform v3.0.0 Pre-Release Checklist${NC}"
echo -e "Target GA Date: July 11, 2025"
echo -e "==================================================="

echo -e "\n${YELLOW}1. Verify Environment Variables${NC}"
MISSING_VARS=0
for var in SLACK_BOT_TOKEN SLACK_SIGNING_SECRET SLACK_APP_TOKEN REDIS_PASSWORD OPENAI_API_KEY ANTHROPIC_API_KEY GRAFANA_PASSWORD POSTGRES_PASSWORD; do
  if [[ -z "${!var:-}" ]]; then
    echo -e "${RED}ERROR: $var is not set${NC}"
    MISSING_VARS=$((MISSING_VARS + 1))
  else
    echo -e "${GREEN}✓ $var is set${NC}"
  fi
done

if [[ $MISSING_VARS -gt 0 ]]; then
  echo -e "${RED}Missing $MISSING_VARS required environment variables${NC}"
  exit 1
fi

echo -e "${GREEN}All required environment variables are set.${NC}"

echo -e "\n${YELLOW}2. Check Docker and Kubernetes Tools${NC}"
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker not found. Please install Docker.${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl not found. Please install kubectl.${NC}"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo -e "${RED}Helm not found. Please install Helm.${NC}"; exit 1; }

echo -e "${GREEN}✓ Docker version:${NC} $(docker --version)"
echo -e "${GREEN}✓ kubectl version:${NC} $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo -e "${GREEN}✓ Helm version:${NC} $(helm version --short)"

echo -e "\n${YELLOW}3. Run Health Checks on Current Services${NC}"
if [[ -f ./scripts/run_quick_health_check.sh ]]; then
  ./scripts/run_quick_health_check.sh || echo -e "${YELLOW}Warning: Some health checks failed${NC}"
else
  echo -e "${YELLOW}Health check script not found, skipping...${NC}"
fi

echo -e "\n${YELLOW}4. Build & Push Docker Images${NC}"
echo "Building images with production configuration..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

echo -e "\n${YELLOW}Push images to registry? (y/n)${NC}"
read -r PUSH_CONFIRM
if [[ "$PUSH_CONFIRM" == "y" ]]; then
  echo "Pushing images to registry..."
  docker-compose -f docker-compose.yml -f docker-compose.prod.yml push
  echo -e "${GREEN}Docker images built and pushed successfully.${NC}"
else
  echo -e "${YELLOW}Skipping image push. Remember to push before deployment!${NC}"
fi

echo -e "\n${YELLOW}5. Validate Docker Compose Configuration${NC}"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.tls.yml config > /dev/null
echo -e "${GREEN}✓ Docker Compose configuration is valid${NC}"

echo -e "\n${YELLOW}6. Helm Template Validation${NC}"
echo "Generating Helm templates..."
helm template alfred-staging ./charts/alfred \
  --values charts/alfred/values-prod-complete.yaml \
  --set global.domain=staging.alfred.local > /tmp/helm-staging-manifest.yaml

if [[ -s /tmp/helm-staging-manifest.yaml ]]; then
  echo -e "${GREEN}✓ Helm templates generated successfully${NC}"
  echo "  Manifest size: $(wc -l /tmp/helm-staging-manifest.yaml | awk '{print $1}') lines"
else
  echo -e "${RED}ERROR: Helm template generation failed${NC}"
  exit 1
fi

echo -e "\n${YELLOW}7. Kubernetes Cluster Check${NC}"
if kubectl cluster-info >/dev/null 2>&1; then
  echo -e "${GREEN}✓ Kubernetes cluster is reachable${NC}"
  kubectl cluster-info | head -2

  echo -e "\n${YELLOW}8. Helm Dry-Run Deployment to Staging${NC}"
  helm upgrade --install alfred-staging ./charts/alfred \
    --values charts/alfred/values-prod-complete.yaml \
    --set global.domain=staging.alfred.local \
    --namespace staging \
    --create-namespace \
    --dry-run --debug > /tmp/helm-dry-run.log 2>&1

  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Helm dry-run completed successfully${NC}"
  else
    echo -e "${RED}Helm dry-run failed. Check /tmp/helm-dry-run.log for details${NC}"
    tail -20 /tmp/helm-dry-run.log
  fi

  echo -e "\n${YELLOW}Deploy to staging cluster? (y/n)${NC}"
  read -r DEPLOY_CONFIRM
  if [[ "$DEPLOY_CONFIRM" == "y" ]]; then
    echo -e "\n${YELLOW}9. Deploying to Staging${NC}"
    helm upgrade --install alfred-staging ./charts/alfred \
      --values charts/alfred/values-prod-complete.yaml \
      --set global.domain=staging.alfred.local \
      --namespace staging \
      --create-namespace \
      --wait --timeout 10m

    echo -e "\n${YELLOW}10. Kubernetes Pod Readiness Check${NC}"
    # Wait up to 5 minutes for all pods to be ready
    kubectl wait --for=condition=ready pod \
      -l app.kubernetes.io/instance=alfred-staging \
      --timeout=300s -n staging || true

    kubectl get pods -n staging
    echo -e "${GREEN}Staging deployment complete.${NC}"
  fi
else
  echo -e "${YELLOW}WARNING: No Kubernetes cluster configured${NC}"
  echo "To test Kubernetes deployment, configure kubectl with your staging cluster"
fi

echo -e "\n${YELLOW}11. Generate Deployment Checklist${NC}"
cat > pre-release-summary-$(date +%Y%m%d).md << EOF
# Pre-Release Validation Summary

Date: $(date)
Version: v3.0.0
Target GA: July 11, 2025

## Environment Check
$(for var in SLACK_BOT_TOKEN SLACK_SIGNING_SECRET SLACK_APP_TOKEN REDIS_PASSWORD; do
  if [[ -n "${!var:-}" ]]; then
    echo "- [x] $var configured"
  else
    echo "- [ ] $var missing"
  fi
done)

## Docker Images
- [ ] All images built successfully
- [ ] Images pushed to registry
- [ ] Images tagged with v3.0.0

## Helm Deployment
- [ ] Templates generated without errors
- [ ] Dry-run completed successfully
- [ ] No missing values in configuration

## Health Checks
- [ ] All services report healthy
- [ ] No critical errors in logs
- [ ] Metrics endpoints accessible

## Next Steps
1. Fix any issues identified above
2. Schedule final review before July 11
3. Prepare release announcement
4. Ensure backups are configured

## Sign-offs
- [ ] Engineering Lead
- [ ] DevOps Lead
- [ ] QA Lead
- [ ] Product Manager
EOF

echo -e "${GREEN}✓ Summary saved to pre-release-summary-$(date +%Y%m%d).md${NC}"

echo -e "\n${GREEN}==================================================="
echo -e "Pre-release staging validation complete!"
echo -e "===================================================${NC}"
echo -e "\n${YELLOW}Remaining items before GA (July 11, 2025):${NC}"
echo "1. Review pre-release-summary-$(date +%Y%m%d).md"
echo "2. Fix any identified issues"
echo "3. Get sign-offs from stakeholders"
echo "4. Prepare production secrets"
echo "5. Schedule maintenance window"
echo -e "\n${GREEN}Ready for GA on July 11, 2025! 🚀${NC}"
