# Slack MCP Gateway - Deployment Quick Start

## Overview
Deploy the Slack MCP Gateway to AWS EKS staging cluster.

## Prerequisites Setup

### 1. Install Required Tools
Run the setup script with sudo access:
```bash
bash scripts/setup-deployment-tools.sh
```

This installs:
- AWS CLI v2
- kubectl
- Helm v3
- System dependencies (unzip, curl, wget)

### 2. Configure AWS Access
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: eu-west-1
# Default output format: json
```

### 3. Configure kubectl for EKS
```bash
aws eks update-kubeconfig --region eu-west-1 --name alfred-staging-cluster
kubectl config use-context arn:aws:eks:eu-west-1:123456789012:cluster/alfred-staging-cluster
kubectl get nodes  # Verify connectivity
```

## Deployment

### 1. Set Environment Variables
```bash
source .env.local
# Verify tokens are loaded:
echo "SLACK_APP_TOKEN: ${SLACK_APP_TOKEN:0:10}..."
echo "SLACK_BOT_TOKEN: ${SLACK_BOT_TOKEN:0:10}..."
```

### 2. Deploy to Staging
```bash
./scripts/deploy-slack-mcp-staging.sh \
  --image ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:17482304b0fb9a802bf6a58ae89ea2751afc0b7e
```

### 3. Verify Deployment
```bash
# Check pods
kubectl -n alfred-staging get pods | grep slack-mcp

# View logs
kubectl -n alfred-staging logs -l app=slack-mcp-gateway --tail=50

# Check deployment status
kubectl -n alfred-staging describe deployment alfred-slack-mcp-slack-mcp-gateway
```

## Testing

### 1. Smoke Test
In Slack channel where bot is present:
```
/alfred ping
```
Expected response: "pong 🎉" within 5 seconds

### 2. Monitor Redis Streams
```bash
# Find Redis pod
kubectl -n alfred-staging get pods | grep redis

# Connect to Redis
kubectl -n alfred-staging exec -it <redis-pod-name> -- redis-cli

# Monitor requests
> XREAD BLOCK 0 STREAMS mcp.requests $
```

## Troubleshooting

### Cannot connect to cluster
1. Verify AWS credentials: `aws sts get-caller-identity`
2. Check cluster exists: `aws eks describe-cluster --name alfred-staging-cluster --region eu-west-1`
3. Update kubeconfig: `aws eks update-kubeconfig --region eu-west-1 --name alfred-staging-cluster`

### Deployment fails
1. Check namespace exists: `kubectl get namespace alfred-staging`
2. Verify secrets: `kubectl -n alfred-staging get secrets`
3. Check image pull: `docker pull ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:17482304b0fb9a802bf6a58ae89ea2751afc0b7e`

### Bot not responding
1. Check Socket Mode is enabled in Slack app settings
2. Verify tokens in deployment: `kubectl -n alfred-staging describe deployment alfred-slack-mcp-slack-mcp-gateway`
3. Check logs for errors: `kubectl -n alfred-staging logs -l app=slack-mcp-gateway --tail=100`

## Production Deployment
After successful 24-hour canary:
```bash
# Tag for production
docker tag ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:17482304b0fb9a802bf6a58ae89ea2751afc0b7e \
           ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:v0.1.0
docker push ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:v0.1.0

# Deploy to production
helm upgrade -f charts/alfred/values-prod.yaml ...
```
