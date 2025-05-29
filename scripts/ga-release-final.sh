#!/usr/bin/env bash
set -euo pipefail

repo="Digital-Native-Ventures/alfred-agent-platform-v2"
version="v3.0.0"

echo "🚀 GA Release Process for $version"
echo "=================================="

# 1️⃣  Tag already exists
echo "✅ Step 1: Tag $version already exists"

# 2️⃣  Build and push container images to GHCR
echo ""
echo "📦 Step 2: Build and push container images"
echo "⚠️  Note: This requires PR #587 to be merged first"
echo "   PR: https://github.com/$repo/pull/587"
echo ""
echo "Once PR is merged, run:"
echo "  gh workflow run docker-release.yml --repo $repo --ref $version"

# 3️⃣  GitHub release already exists
echo ""
echo "✅ Step 3: GitHub release already exists at:"
echo "   https://github.com/$repo/releases/tag/$version"

# 4️⃣  Helm chart
echo ""
echo "📊 Step 4: Helm chart"

# Check if already packaged
if [ -f "helm-releases/alfred-3.0.0.tgz" ]; then
    echo "✅ Helm chart already packaged: helm-releases/alfred-3.0.0.tgz"
else
    echo "Packaging Helm chart..."
    mkdir -p helm-releases
    helm package charts/alfred --version "${version#v}" --destination ./helm-releases/
    echo "✅ Helm chart packaged: helm-releases/alfred-${version#v}.tgz"
fi

echo ""
echo "To push Helm chart to OCI registry:"
echo "  export HELM_EXPERIMENTAL_OCI=1"
echo "  helm push helm-releases/alfred-${version#v}.tgz oci://ghcr.io/digital-native-ventures/charts"
echo ""
echo "Note: Requires authentication with GitHub Container Registry"

# Summary
echo ""
echo "📋 Summary"
echo "=========="
echo "✅ Git tag: $version"
echo "✅ GitHub release: Published"
echo "✅ Helm chart: Packaged (3.0.0)"
echo "⏳ Docker images: Waiting for PR #587"
echo "⏳ Helm OCI push: Requires manual execution with auth"