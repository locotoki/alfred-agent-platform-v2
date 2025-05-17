#!/usr/bin/env bash
set -euo pipefail

echo "Deploying Slack MCP Gateway to Staging..."

# Parse command line arguments
IMAGE_TAG=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --image)
      IMAGE_TAG="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--image IMAGE_TAG]"
      exit 1
      ;;
  esac
done

# Use provided image tag or default to current commit SHA
if [ -z "$IMAGE_TAG" ]; then
  COMMIT_SHA=$(git rev-parse HEAD)
  IMAGE_TAG="ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:${COMMIT_SHA}"
fi

echo "Using image: ${IMAGE_TAG}"

# Create namespace if it doesn't exist
echo "Ensuring namespace exists..."
kubectl create namespace alfred-staging --dry-run=client -o yaml | kubectl apply -f -

# Create or update Kubernetes secret for Slack tokens
echo "Creating/updating Kubernetes secrets..."
kubectl create secret generic slack-tokens \
  --from-literal=SLACK_APP_TOKEN="${SLACK_APP_TOKEN}" \
  --from-literal=SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN}" \
  --namespace alfred-staging \
  --dry-run=client -o yaml | kubectl apply -f -

# Extract tag from image URL
IMAGE_REPO=$(echo $IMAGE_TAG | cut -d: -f1)
TAG=$(echo $IMAGE_TAG | cut -d: -f2)

# Deploy with Helm
echo "Deploying with Helm..."
helm upgrade --install alfred-slack-mcp charts/alfred \
  --set slack_mcp_gateway.enabled=true \
  --set slack_mcp_gateway.image.repository="${IMAGE_REPO}" \
  --set slack_mcp_gateway.image.tag="${TAG}" \
  --set slack_mcp_gateway.environmentSecrets.enabled=true \
  --values charts/alfred/values-staging.yaml \
  --create-namespace \
  --namespace alfred-staging

echo "Waiting for deployment to be ready..."
kubectl -n alfred-staging rollout status deployment/alfred-slack-mcp-slack-mcp-gateway

echo "Deployment complete!"
echo ""
echo "To verify the deployment:"
echo "  kubectl -n alfred-staging get pods | grep slack-mcp"
echo "  kubectl -n alfred-staging logs -l app=slack-mcp-gateway"
echo ""
echo "To test the deployment:"
echo "  1. Make sure your Slack app is configured for Socket Mode"
echo "  2. Try sending '/alfred ping' in a channel where the bot is present"
echo ""
echo "To monitor Redis:"
echo "  kubectl -n alfred-staging exec -it <redis-pod> -- redis-cli"
echo "  > XREAD BLOCK 0 STREAMS mcp.requests $"