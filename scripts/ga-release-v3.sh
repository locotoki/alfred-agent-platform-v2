#!/bin/bash
# GA Release Script for v3.0.0
set -euo pipefail

repo="Digital-Native-Ventures/alfred-agent-platform-v2"
version="v3.0.0"

echo "🚀 GA Release Process for $version"
echo "=================================="

# Since the tag already exists, we'll skip tagging
echo "✅ Tag $version already exists"

# Build and push images will need the docker-release fix to be merged first
echo ""
echo "⚠️  Note: Docker image builds require PR #587 to be merged first"
echo "   PR: https://github.com/$repo/pull/587"
echo ""

# The release already exists
echo "✅ GitHub release already exists at:"
echo "   https://github.com/$repo/releases/tag/$version"

# Package Helm chart
echo ""
echo "📦 Packaging Helm chart..."
cd /home/locotoki/projects/alfred-agent-platform-v2

# Create helm-releases directory if it doesn't exist
mkdir -p helm-releases

# Package the chart
helm package charts/alfred --version "${version#v}" --destination ./helm-releases/

echo "✅ Helm chart packaged: helm-releases/alfred-${version#v}.tgz"

# Show next steps
echo ""
echo "📋 Next Steps:"
echo "=============="
echo "1. Merge PR #587 to fix Docker image builds"
echo "2. Trigger docker-release workflow manually for v3.0.0"
echo "3. Push Helm chart to OCI registry:"
echo "   helm push helm-releases/alfred-${version#v}.tgz oci://ghcr.io/digital-native-ventures/charts"
echo ""
echo "Note: Helm push requires HELM_EXPERIMENTAL_OCI=1 and proper authentication"
