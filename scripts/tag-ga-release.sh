#!/bin/bash
# GA Release Tagging Script
# Usage: ./scripts/tag-ga-release.sh v3.0.0

set -euo pipefail

VERSION=${1:-v3.0.0}
RELEASE_DATE=$(date +%Y-%m-%d)

echo "🚀 Preparing GA Release ${VERSION}"
echo "📅 Release Date: ${RELEASE_DATE}"

# Ensure we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "❌ Error: Must be on main branch to tag release"
    echo "Current branch: $CURRENT_BRANCH"
    exit 1
fi

# Ensure working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Error: Working directory has uncommitted changes"
    git status --short
    exit 1
fi

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Create release notes
RELEASE_NOTES=$(cat <<EOF
Alfred Agent Platform v3.0.0 - General Availability

## Highlights
- Production-ready with 94.4% service health coverage
- Full Docker Compose and Kubernetes (Helm) support
- TLS/HTTPS termination with automated certificates
- Comprehensive monitoring and alerting
- Fixed db-auth GoTrue migration issue

## Key Metrics
- Health Coverage: 94.4% (34/36 services)
- Docker Images: 6 core services
- Resource Limits: All services configured
- Security: TLS, secrets management, network policies

## Deployment Options
- Docker Compose (single-node)
- Docker Swarm (multi-node)
- Kubernetes via Helm Chart

## Documentation
- Production Deployment Checklist
- GA Release Notes
- Health Check Exceptions

See docs/ga-release-v3.0.0.md for full details.

Released: ${RELEASE_DATE}
EOF
)

# Create annotated tag
echo "🏷️  Creating annotated tag ${VERSION}..."
git tag -a "$VERSION" -m "$RELEASE_NOTES"

echo "✅ Tag created successfully!"
echo ""
echo "📋 Release Notes:"
echo "----------------------------------------"
echo "$RELEASE_NOTES"
echo "----------------------------------------"
echo ""
echo "📤 To push the tag to remote:"
echo "   git push origin $VERSION"
echo ""
echo "🐳 To build and push Docker images:"
echo "   make build-prod TAG=$VERSION"
echo "   make push-prod TAG=$VERSION"
echo ""
echo "☸️  To deploy with Helm:"
echo "   helm upgrade --install alfred ./charts/alfred \\"
echo "     --values ./charts/alfred/values-prod.yaml \\"
echo "     --set image.tag=$VERSION"
echo ""
echo "🎉 Ready for GA release!"
