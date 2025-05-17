# Slack MCP Gateway Deployment Guide

## Current Status
- PR #55 merged successfully ✅
- Main branch CI has completed (with expected failures) ✅
- Image built successfully but GHCR push failed due to authentication (expected) ❌

## Next Steps

### 1. Build and Push to GHCR Manually

Since the CI couldn't push to GHCR due to authentication restrictions on the main branch, you'll need to build and push manually:

```bash
# Build the image locally
cd services/slack_mcp_gateway
docker build -t ghcr.io/locotoki/alfred-platform/slack_mcp_gateway:0.1.0-rc3 .

# Log in to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push the image
docker push ghcr.io/locotoki/alfred-platform/slack_mcp_gateway:0.1.0-rc3
```

### 2. Create Kubernetes Secrets

```bash
kubectl -n alfred create secret generic slack-mcp-gateway-secrets \
  --from-literal=SLACK_APP_TOKEN="${STAGING_SLACK_APP_TOKEN}" \
  --from-literal=MCP_REDIS_PASSWORD="${STAGING_REDIS_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Deploy to Staging with Helm

```bash
helm upgrade alfred charts/alfred \
  --namespace alfred \
  -f charts/alfred/values-staging.yaml
```

### 4. Verify Deployment

```bash
# Check deployment status
kubectl -n alfred get deployments slack-mcp-gateway
kubectl -n alfred get pods -l app=slack-mcp-gateway

# Check logs
kubectl -n alfred logs -l app=slack-mcp-gateway --tail=50
```

### 5. Smoke Test

```bash
# Test the health endpoint from within the cluster
kubectl -n alfred run test-curl --rm -it --image=curlimages/curl -- \
  curl http://slack-mcp-gateway:3000/health
```

### 6. Test Slack Integration

In your Slack workspace, send a command to test:
```
/alfred ping
```

Expected response: `pong :tada:`

### 7. Monitor Canary

Monitor the service for 24 hours:
```bash
# Watch logs
kubectl -n alfred logs -f -l app=slack-mcp-gateway

# Check metrics
kubectl -n alfred port-forward service/slack-mcp-gateway 9127:9091
# Then visit http://localhost:9127/metrics
```

## Troubleshooting

### If GHCR Push Fails
1. Ensure you have proper authentication set up
2. Check if the repository/package already exists
3. Verify your GitHub token has `write:packages` scope

### If Deployment Fails
1. Check if the image exists in GHCR
2. Verify secrets are created correctly
3. Check Kubernetes events: `kubectl -n alfred describe pod <pod-name>`

### If Slack Commands Don't Work
1. Verify Socket Mode is enabled in your Slack app
2. Check the SLACK_APP_TOKEN is correct
3. Look for connection errors in logs
4. Ensure Redis is running and accessible

## Success Criteria
| Check | Status |
|-------|--------|
| Image pushed to GHCR | ⏳ |
| Deployment successful | ⏳ |
| Health check passing | ⏳ |
| Slack commands working | ⏳ |
| 24-hour canary clean | ⏳ |

🤖 Generated with [Claude Code](https://claude.ai/code)