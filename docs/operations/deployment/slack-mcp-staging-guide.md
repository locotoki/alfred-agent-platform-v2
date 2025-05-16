# Slack MCP Gateway Staging Deployment Guide

This guide covers the deployment process for the Slack MCP Gateway to the staging environment.

## Prerequisites

- Access to GKE staging cluster
- GitHub token with container registry access
- Helm CLI installed
- kubectl configured for staging namespace

## Deployment Steps

### 1. Build and Push Container Image

```bash
# Authenticate to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

# Build the image
docker build -t ghcr.io/org/slack-mcp-gateway:0.1.0-rc3 services/slack_mcp_gateway

# Push to registry
docker push ghcr.io/org/slack-mcp-gateway:0.1.0-rc3
```

### 2. Configure Kubernetes Secrets

The Slack MCP Gateway requires the following secrets:
- `SLACK_APP_TOKEN`: Slack application token for authentication
- `MCP_REDIS_PASSWORD`: Redis password for stream access

Create or update the secrets in the staging namespace:

```bash
kubectl -n alfred create secret generic slack-mcp-gateway-secrets \
  --from-literal=SLACK_APP_TOKEN="${STAGING_SLACK_APP_TOKEN}" \
  --from-literal=MCP_REDIS_PASSWORD="${STAGING_REDIS_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Deploy with Helm

Update the staging values file (`charts/alfred/values-staging.yaml`) to enable the Slack MCP Gateway:

```yaml
slackMcpGateway:
  enabled: true
  image:
    tag: 0.1.0-rc3
  envFromSecret: slack-mcp-gateway-secrets
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"
```

Deploy using Helm:

```bash
helm upgrade alfred charts/alfred \
  --namespace alfred \
  -f charts/alfred/values-staging.yaml
```

### 4. Verify Deployment

#### Check rollout status
```bash
kubectl rollout status deploy/slack-mcp-gateway -n alfred
```

#### Test health endpoint
```bash
kubectl exec deploy/slack-mcp-gateway -n alfred -- curl -sf http://localhost:3000/health
```

#### Verify Redis connectivity
```bash
# Check stream existence
kubectl exec deploy/redis -n alfred -- \
  redis-cli -a "${STAGING_REDIS_PASSWORD}" \
    XINFO STREAM mcp.requests

# Verify consumer group
kubectl exec deploy/redis -n alfred -- \
  redis-cli -a "${STAGING_REDIS_PASSWORD}" \
    XINFO GROUPS mcp.responses | grep slack-gw
```

#### Monitor resource usage
```bash
kubectl top pod -n alfred | grep slack-mcp-gateway
```

## Smoke Testing

### Basic functionality test
1. Send a test message in Slack: `/alfred ping test`
2. Expect echo response from the echo-agent within 5 seconds

### Port forward for local testing
```bash
kubectl port-forward deploy/slack-mcp-gateway 3000:3000 -n alfred
# Then test locally with curl or browser
```

## Troubleshooting

### Common issues

1. **Pod not starting**: Check logs with `kubectl logs deploy/slack-mcp-gateway -n alfred`
2. **Connection errors**: Verify secrets are mounted correctly
3. **High memory usage**: Check resource limits and adjust if needed

### Debug commands
```bash
# Describe pod for events
kubectl describe pod -l app=slack-mcp-gateway -n alfred

# Check secret mounting
kubectl exec deploy/slack-mcp-gateway -n alfred -- env | grep -E "(SLACK|REDIS)"

# Redis connection test
kubectl exec deploy/slack-mcp-gateway -n alfred -- nc -zv redis 6379
```

## Rollback

If issues occur, rollback to the previous release:

```bash
helm rollback alfred -n alfred
```

## Success Criteria

✓ Gateway pod is running and healthy  
✓ Health endpoint returns 200 OK  
✓ Redis streams and consumer groups are created  
✓ Slack commands receive responses within 5 seconds  
✓ Resource usage within defined limits  

## References

- [Slack MCP Gateway README](../../../services/slack_mcp_gateway/README.md)
- [Alfred Platform Helm Chart](../../../charts/alfred/README.md)
- [Redis Streams Documentation](https://redis.io/docs/data-types/streams/)