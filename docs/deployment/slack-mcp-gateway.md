# Slack MCP Gateway Deployment Guide

## Overview

The Slack MCP Gateway provides a bridge between Slack Socket Mode and the Redis Streams-based MCP protocol.

## Prerequisites

1. Kubernetes cluster access
2. Helm installed
3. Environment variables configured:
   ```bash
   export SLACK_APP_TOKEN="xapp-1-..."
   export SLACK_BOT_TOKEN="xoxb-..."
   ```

## Deployment Steps

### 1. Manual Deployment

Run the deployment script:
```bash
./scripts/deploy-slack-mcp-staging.sh
```

### 2. CI/CD Deployment

The deploy workflow automatically runs when PRs are merged to main:
- Builds and pushes Docker image to GHCR
- Image tag is based on commit SHA
- Staging uses `:latest` tag

### 3. Verification

Check deployment status:
```bash
kubectl -n alfred-staging get pods | grep slack-mcp
kubectl -n alfred-staging describe deployment alfred-slack-mcp-slack-mcp-gateway
```

View logs:
```bash
kubectl -n alfred-staging logs -l app=slack-mcp-gateway --tail=100
```

### 4. Smoke Testing

Send a test command in Slack:
```
/alfred ping
```

Monitor Redis Streams:
```bash
kubectl -n alfred-staging exec -it <redis-pod> -- redis-cli
> XREAD BLOCK 0 STREAMS mcp.requests $
```

## Configuration

### Helm Values

Key configuration in `charts/alfred/values-staging.yaml`:
```yaml
slack_mcp_gateway:
  enabled: true
  image:
    repository: ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway
    tag: latest
  replicaCount: 1
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

### Environment Variables

Required secrets:
- `SLACK_APP_TOKEN`: Socket Mode token
- `SLACK_BOT_TOKEN`: Bot OAuth token

Configured via Kubernetes secret `slack-tokens`.

## Troubleshooting

### Connection Issues

1. Check Socket Mode is enabled in Slack app settings
2. Verify tokens are correct:
   ```bash
   kubectl -n alfred-staging get secret slack-tokens -o yaml
   ```

### Redis Communication

1. Test Redis connectivity:
   ```bash
   kubectl -n alfred-staging exec -it <slack-mcp-pod> -- redis-cli -h redis ping
   ```

2. Monitor streams:
   ```bash
   kubectl -n alfred-staging exec -it <redis-pod> -- redis-cli monitor
   ```

### Health Checks

Service includes health endpoint at `/health`:
```bash
kubectl -n alfred-staging port-forward svc/alfred-slack-mcp-gateway 3000:3000
curl http://localhost:3000/health
```

## Rollback

To rollback to previous version:
```bash
helm rollback alfred-slack-mcp -n alfred-staging
```

## Security Considerations

1. Tokens stored in Kubernetes secrets
2. Service runs as non-root user (uid 1001)
3. No sensitive data logged
4. TLS enabled for external communications

## Monitoring

Prometheus metrics available at `:9091/metrics`:
- `slack_mcp_messages_processed_total`
- `slack_mcp_errors_total`
- `slack_mcp_redis_operations_total`

Grafana dashboard available at: `[staging-grafana-url]/d/slack-mcp`