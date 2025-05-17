# Slack MCP Gateway Staging Deployment Checklist

## Prerequisites

### 1. Kubernetes Configuration
```bash
# Check kubectl context
kubectl config current-context

# For EKS (staging environment):
aws eks update-kubeconfig --region eu-west-1 --name alfred-staging-cluster
kubectl config use-context arn:aws:eks:eu-west-1:123456789012:cluster/alfred-staging-cluster
kubectl get nodes -o wide  # sanity check connectivity

# Alternative for GKE:
# gcloud container clusters get-credentials alfred-staging --zone europe-west1-b --project alfred-prod
```

### 2. Environment Variables
```bash
# Verify tokens are available
source .env.local
echo "SLACK_APP_TOKEN: ${SLACK_APP_TOKEN:0:10}..."
echo "SLACK_BOT_TOKEN: ${SLACK_BOT_TOKEN:0:10}..."
```

### 3. Helm Installation
```bash
# Check Helm is installed
helm version --short

# Install Helm v3:
# macOS (Homebrew)
brew install helm

# Linux (Debian/Ubuntu)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Deployment Steps

### 1. Deploy with Script
```bash
# Source environment variables
source .env.local

# Run deployment
./scripts/deploy-slack-mcp-staging.sh \
  --image ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:17482304b0fb9a802bf6a58ae89ea2751afc0b7e
```

### 2. Manual Deployment (if script fails)
```bash
# Create namespace
kubectl create namespace alfred-staging

# Create secrets
kubectl create secret generic slack-tokens \
  --from-literal=SLACK_APP_TOKEN="${SLACK_APP_TOKEN}" \
  --from-literal=SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN}" \
  --namespace alfred-staging

# Deploy with Helm
helm upgrade --install alfred-slack-mcp charts/alfred \
  --set slack_mcp_gateway.enabled=true \
  --set slack_mcp_gateway.image.repository=ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway \
  --set slack_mcp_gateway.image.tag=17482304b0fb9a802bf6a58ae89ea2751afc0b7e \
  --set slack_mcp_gateway.environmentSecrets.enabled=true \
  --values charts/alfred/values-staging.yaml \
  --namespace alfred-staging
```

## Post-Deployment Verification

### 1. Check Deployment Status
```bash
kubectl -n alfred-staging get deployments
kubectl -n alfred-staging get pods
kubectl -n alfred-staging describe deployment alfred-slack-mcp-slack-mcp-gateway
```

### 2. View Logs
```bash
kubectl -n alfred-staging logs -l app=slack-mcp-gateway --tail=50 --follow
```

### 3. Test Connection
- Send `/alfred ping` in Slack channel where bot is present
- Expected response: "pong 🎉" within 5 seconds

### 4. Monitor Redis Streams
```bash
# Find Redis pod
kubectl -n alfred-staging get pods | grep redis

# Access Redis CLI
kubectl -n alfred-staging exec -it <redis-pod-name> -- redis-cli

# Monitor requests stream
> XREAD BLOCK 0 STREAMS mcp.requests $
```

## Troubleshooting

### Issue: kubectl not configured
- Ensure you have access to your Kubernetes cluster
- Configure kubectl with your cloud provider's instructions

### Issue: Helm not found
- Install Helm v3 using the commands above

### Issue: Deployment not starting
- Check secrets are created: `kubectl -n alfred-staging get secrets`
- Verify image is accessible: `docker pull ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:17482304b0fb9a802bf6a58ae89ea2751afc0b7e`

### Issue: Bot not responding
- Verify Socket Mode is enabled in Slack app settings
- Check logs for authentication errors
- Ensure bot is in the channel where you're testing