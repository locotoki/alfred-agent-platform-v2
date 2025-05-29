# Slack Integration Deployment Guide

## Why Issues Keep Recurring

1. **No Single Deployment Command**: Services are scattered across multiple docker-compose files
2. **Manual Steps Required**: Echo agent needs manual startup
3. **Code Bugs**: thread_ts issue in server.js
4. **No Health Dependencies**: Services start before dependencies are ready

## Permanent Solution Implemented

### 1. Single Docker Compose File
Created `docker-compose.slack.yml` that includes:
- All three Slack services (slack-adapter, slack_mcp_gateway, echo-agent)
- Proper health checks and dependencies
- Automatic restarts on failure

### 2. Fixed Code Issues
- Removed invalid thread_ts from server.js
- Added Redis password support
- Added proper error handling

### 3. Automated Deployment Script
`deploy-slack.sh` handles:
- Environment validation
- Image building
- Service startup with health checks
- Verification of complete stack

## How to Deploy (One Command)

```bash
# Deploy everything
./deploy-slack.sh
```

This single command:
- ✅ Validates environment variables
- ✅ Builds all required images
- ✅ Starts all services in correct order
- ✅ Waits for health checks
- ✅ Verifies Slack connection

## If Issues Still Occur

### 1. Check Environment
```bash
make validate-env
```

### 2. Check Service Health
```bash
docker ps | grep -E "slack|echo"
```

### 3. View Logs
```bash
# All logs
docker compose -f docker-compose.yml -f docker-compose.slack.yml logs -f

# Specific service
docker logs slack_mcp_gateway -f
```

### 4. Test Redis Connection
```bash
docker exec redis redis-cli PING
docker exec redis redis-cli XINFO STREAM mcp.requests
```

## Making Changes Permanent

### For Code Changes
1. Edit files in `services/slack_mcp_gateway/`
2. Rebuild: `docker compose -f docker-compose.slack.yml build`
3. Redeploy: `./deploy-slack.sh`

### For Configuration Changes
1. Update `.env` file
2. Redeploy: `./deploy-slack.sh`

## Preventing Future Issues

1. **Always use deploy-slack.sh** - Don't start services manually
2. **Check logs after deployment** - Ensure "Connected to Slack" message
3. **Test after deployment** - Run `/alfred ping test`
4. **Commit working configurations** - After successful deployment

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| "dispatch_failed" | Run `./deploy-slack.sh` |
| "invalid_thread_ts" | Fixed in server.js, redeploy |
| Services not starting | Check `make validate-env` |
| Redis connection failed | Ensure Redis is on alfred-network |
| Echo agent not responding | Check `docker logs echo-agent` |

## Complete Reset

If all else fails:
```bash
# Stop everything
docker compose down

# Remove volumes
docker volume prune -f

# Clean rebuild and deploy
./deploy-slack.sh
```