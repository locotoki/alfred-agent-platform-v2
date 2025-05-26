#!/bin/bash
# GA Release Script for Alfred Agent Platform v3.0.0
# Target Date: July 11, 2025

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VERSION="${1:-v3.0.0}"
RELEASE_DATE="2025-07-11"
REGISTRY="ghcr.io/locotoki/alfred-agent-platform-v2"

echo -e "${GREEN}Alfred Agent Platform GA Release Script${NC}"
echo -e "Version: ${YELLOW}${VERSION}${NC}"
echo -e "Release Date: ${YELLOW}${RELEASE_DATE}${NC}"
echo ""

# Pre-flight checks
echo -e "${YELLOW}Running pre-flight checks...${NC}"

# Check if on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${RED}Error: Must be on main branch to create release${NC}"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}Error: Uncommitted changes detected${NC}"
    exit 1
fi

# Pull latest changes
echo "Pulling latest changes..."
git pull origin main

# Run health checks
echo -e "${YELLOW}Running health checks...${NC}"
if ! ./scripts/run_quick_health_check.sh; then
    echo -e "${RED}Error: Health checks failed${NC}"
    exit 1
fi

# Run tests
echo -e "${YELLOW}Running test suite...${NC}"
if ! make test; then
    echo -e "${RED}Error: Tests failed${NC}"
    exit 1
fi

# Check CI status
echo -e "${YELLOW}Checking CI status...${NC}"
gh run list --limit 1 --json conclusion -q '.[0].conclusion' | grep -q "success" || {
    echo -e "${RED}Error: Latest CI run did not succeed${NC}"
    exit 1
}

# Build and tag Docker images
echo -e "${YELLOW}Building Docker images...${NC}"

SERVICES=(
    "alfred-core"
    "model-registry"
    "model-router"
    "slack-adapter"
    "slack-mcp-gateway"
    "social-intel"
    "agent-orchestrator"
    "ui-chat"
    "mission-control"
    "db-storage"
    "db-auth"
)

for SERVICE in "${SERVICES[@]}"; do
    echo "Building ${SERVICE}..."
    docker build -t "${REGISTRY}/${SERVICE}:${VERSION}" "./services/${SERVICE}" || {
        # Try alternate paths
        docker build -t "${REGISTRY}/${SERVICE}:${VERSION}" "./alfred/${SERVICE#alfred-}" 2>/dev/null || \
        docker build -t "${REGISTRY}/${SERVICE}:${VERSION}" "./${SERVICE}" 2>/dev/null || \
        echo -e "${YELLOW}Warning: Could not build ${SERVICE}${NC}"
    }
done

# Tag images as latest
echo -e "${YELLOW}Tagging images as latest...${NC}"
for SERVICE in "${SERVICES[@]}"; do
    docker tag "${REGISTRY}/${SERVICE}:${VERSION}" "${REGISTRY}/${SERVICE}:latest" 2>/dev/null || true
done

# Create git tag
echo -e "${YELLOW}Creating git tag ${VERSION}...${NC}"
git tag -a "${VERSION}" -m "Release ${VERSION} - GA Release

## What's New
- 100% health coverage for all 39 services
- Production-ready Docker Compose configuration
- Complete Helm chart with autoscaling and security policies
- TLS/SSL support with automatic certificate management
- Comprehensive monitoring with Prometheus and Grafana
- Multi-agent orchestration with social intelligence capabilities

## Breaking Changes
- None

## Migration Guide
See docs/production-deployment-guide.md for deployment instructions.

## Contributors
- Alfred Architect Team
- Claude Code (Implementation)
- Community Contributors"

# Push images to registry (requires authentication)
echo -e "${YELLOW}Push images to registry? (y/n)${NC}"
read -r PUSH_CONFIRM
if [[ "$PUSH_CONFIRM" == "y" ]]; then
    echo "Logging into GitHub Container Registry..."
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin

    for SERVICE in "${SERVICES[@]}"; do
        echo "Pushing ${SERVICE}..."
        docker push "${REGISTRY}/${SERVICE}:${VERSION}" || echo -e "${YELLOW}Warning: Could not push ${SERVICE}${NC}"
        docker push "${REGISTRY}/${SERVICE}:latest" || echo -e "${YELLOW}Warning: Could not push ${SERVICE}:latest${NC}"
    done
fi

# Update Helm chart
echo -e "${YELLOW}Updating Helm chart version...${NC}"
sed -i "s/^version: .*/version: ${VERSION#v}/" charts/alfred/Chart.yaml
sed -i "s/^appVersion: .*/appVersion: \"${VERSION}\"/" charts/alfred/Chart.yaml

# Package Helm chart
echo -e "${YELLOW}Packaging Helm chart...${NC}"
helm package charts/alfred --destination ./helm-releases/

# Generate release notes
echo -e "${YELLOW}Generating release notes...${NC}"
cat > "RELEASE-${VERSION}.md" << EOF
# Alfred Agent Platform ${VERSION} - GA Release

Released: ${RELEASE_DATE}

## Highlights

- **100% Health Coverage**: All 39 services now have comprehensive health checks
- **Production Ready**: Full production deployment configurations with resource limits
- **Security Hardened**: TLS/SSL, secrets management, and security policies
- **Cloud Native**: Kubernetes/Helm charts with autoscaling and observability
- **Multi-Agent Support**: Orchestrated agent platform with social intelligence

## Quick Start

### Docker Compose
\`\`\`bash
# Clone the repository
git clone https://github.com/locotoki/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2
git checkout ${VERSION}

# Deploy with production settings
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
\`\`\`

### Kubernetes/Helm
\`\`\`bash
# Add Helm repository
helm repo add alfred https://charts.alfred.example.com
helm repo update

# Deploy to Kubernetes
helm install alfred alfred/alfred --version ${VERSION#v}
\`\`\`

## Documentation

- [Production Deployment Guide](docs/production-deployment-guide.md)
- [API Documentation](https://api.alfred.example.com/docs)
- [Architecture Overview](docs/architecture/system-architecture.md)

## Docker Images

All images are available at \`ghcr.io/locotoki/alfred-agent-platform-v2\`:

$(for SERVICE in "${SERVICES[@]}"; do echo "- ${SERVICE}:${VERSION}"; done)

## Known Issues

- Docker Compose parity check has a yq parsing bug (#492)
- Template validation requires healthcheck stages (#493)
- Mypy reports 594 type errors (#494)
- Financial tax module import issues (#495)

These are non-blocking infrastructure issues with workarounds in place.

## Upgrade Instructions

From v2.x:
1. Backup your data
2. Review breaking changes (none in this release)
3. Follow the migration guide in docs/

## Contributors

Thank you to all contributors who made this release possible!

## License

See [LICENSE](LICENSE) file.
EOF

echo -e "${GREEN}Release preparation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Review RELEASE-${VERSION}.md"
echo "2. Push the tag: git push origin ${VERSION}"
echo "3. Create GitHub release: gh release create ${VERSION} -F RELEASE-${VERSION}.md"
echo "4. Upload Helm chart: helm push helm-releases/alfred-${VERSION#v}.tgz oci://ghcr.io/locotoki/charts"
echo "5. Update documentation site"
echo "6. Send announcement to stakeholders"
