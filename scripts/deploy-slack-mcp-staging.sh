#!/usr/bin/env bash
set -euo pipefail

echo "Deploying Slack MCP Gateway to Staging..."

# Get current commit SHA
COMMIT_SHA=$(git rev-parse HEAD)
IMAGE_TAG="ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:${COMMIT_SHA}"

echo "Using image: ${IMAGE_TAG}"

# Create or update Kubernetes secret for Slack tokens
echo "Creating/updating Kubernetes secrets..."
kubectl create secret generic slack-tokens \
  --from-literal=SLACK_APP_TOKEN="${SLACK_APP_TOKEN}" \
  --from-literal=SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy with Helm
echo "Deploying with Helm..."
helm upgrade --install alfred-slack-mcp charts/alfred \
  --set slack_mcp_gateway.enabled=true \
  --set slack_mcp_gateway.image.tag="${COMMIT_SHA}" \
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