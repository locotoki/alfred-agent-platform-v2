#!/usr/bin/env bash
set -euo pipefail

# Build and push all service images
# Usage: ./scripts/build_and_push_all_images.sh <tag>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <tag>"
    echo "Example: $0 v0.9.14-beta"
    exit 1
fi

TAG=$1
REGISTRY="ghcr.io"
IMAGE_PREFIX="locotoki"

echo "🚀 Building and pushing all service images with tag: ${TAG}"
echo "Registry: ${REGISTRY}/${IMAGE_PREFIX}"
echo ""

# Define services and their contexts
declare -A services=(
    ["alfred-core"]="./alfred/core/Dockerfile"
    ["alfred-slack-adapter"]="./alfred/adapters/slack/Dockerfile"
    ["agent-bizops"]="./services/agent_bizops/Dockerfile"
    ["contact-ingest"]="./services/contact-ingest/Dockerfile"
    ["crm-sync"]="./services/crm-sync/Dockerfile"
    ["model-registry"]="./services/model-registry/Dockerfile"
    ["model-router"]="./services/model-router/Dockerfile"
    ["social-intel"]="./services/social-intel/Dockerfile"
    ["pubsub"]="./services/pubsub/Dockerfile"
    ["redis"]="./services/redis/Dockerfile"
    ["hubspot-mock"]="./services/hubspot-mock/Dockerfile"
    ["db-metrics"]="./services/db-metrics/Dockerfile"
    ["rag-service"]="./services/rag-service/Dockerfile"
    ["slack-app"]="./services/slack_app/Dockerfile"
    ["slack-mcp-gateway"]="./services/slack_mcp_gateway/Dockerfile"
    ["diagnostics-bot"]="./docker/diagnostics-bot/Dockerfile"
    ["explainer-bot"]="./docker/explainer-bot/Dockerfile"
)

# Login to GitHub Container Registry
echo "🔐 Logging in to GitHub Container Registry..."
echo "$GITHUB_TOKEN" | docker login ${REGISTRY} -u ${GITHUB_ACTOR:-$USER} --password-stdin

# Build and push each service
for service in "${!services[@]}"; do
    dockerfile="${services[$service]}"
    image="${REGISTRY}/${IMAGE_PREFIX}/${service}"

    echo ""
    echo "📦 Building ${service}..."

    if [ ! -f "${dockerfile}" ]; then
        echo "⚠️  Warning: Dockerfile not found at ${dockerfile}, skipping..."
        continue
    fi

    # Build image
    docker build -t "${image}:${TAG}" -t "${image}:latest" -f "${dockerfile}" .

    # Push both tags
    echo "📤 Pushing ${service}:${TAG}..."
    docker push "${image}:${TAG}"
    docker push "${image}:latest"

    echo "✅ ${service} complete"
done

echo ""
echo "🎉 All images built and pushed successfully!"
echo ""
echo "Tagged images:"
for service in "${!services[@]}"; do
    echo "  - ${REGISTRY}/${IMAGE_PREFIX}/${service}:${TAG}"
done
