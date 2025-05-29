# Slack Bot Migration Plan

## Overview
Migrate from the fragile multi-service architecture (`slack_mcp_gateway` + `echo_agent` + shared Redis) to a single, self-contained `slack-bot` service.

## Current Architecture (Problematic)
```
Slack → slack_mcp_gateway → Redis → echo_agent → Redis → slack_mcp_gateway → Slack
```
**Issues:** Multiple points of failure, version drift, complex dependencies

## New Architecture (Proposed)
```
Slack → slack-bot (with embedded Redis) → Slack
```
**Benefits:** Single container, versioned images, no external dependencies

## Migration Steps

### Phase 1: Parallel Deployment (Safe)
1. Deploy new `slack-bot` service alongside existing services
2. Use different Slack app (dev/staging) for testing
3. Validate all commands work correctly
4. Monitor for 24-48 hours

### Phase 2: Feature Parity
Implement in new bot:
- [ ] All existing commands from echo_agent
- [ ] Redis stream compatibility (if needed for other services)
- [ ] Metrics/monitoring endpoints
- [ ] Error handling and logging

### Phase 3: Gradual Cutover
1. Update Slack app to point to new service
2. Keep old services running (fallback)
3. Monitor error rates and response times
4. Document any issues

### Phase 4: Cleanup
1. Remove old services from docker-compose
2. Archive old code to `legacy/` directory
3. Update documentation
4. Remove unnecessary Redis streams

## Rollback Plan
If issues arise:
```bash
# Quick rollback to previous architecture
./scripts/slack-integration-safeguard.sh restore
docker-compose -f docker-compose.yml -f docker-compose.slack.yml up -d

# Update Slack app URLs back to old endpoints
```

## Configuration Changes

### Environment Variables
```bash
# Old (multiple services)
SLACK_APP_TOKEN=xapp-...
SLACK_BOT_TOKEN=xoxb-...
REDIS_PASSWORD=...

# New (single service)
SLACK_BOT_TOKEN=xoxb-...
SLACK_SIGNING_SECRET=...
# No REDIS_PASSWORD needed (embedded)
```

### Docker Compose
```yaml
# Old
services:
  slack_mcp_gateway:
    image: slack-mcp-gateway:latest  # Unversioned!
  echo-agent:
    image: echo-agent:latest          # Unversioned!
  redis:
    image: redis:7-alpine

# New
services:
  slack-bot:
    image: ghcr.io/.../slack-bot:v3.1.0  # Versioned!
    environment:
      - SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}
      - SLACK_SIGNING_SECRET=${SLACK_SIGNING_SECRET}
```

## Benefits Summary

1. **Reliability**: Single service = fewer failure points
2. **Versioning**: Proper tags prevent unexpected breakage
3. **Simplicity**: No Redis auth complexity
4. **Portability**: Self-contained, works anywhere
5. **CI/CD**: Automatically included in build matrix

## Timeline
- Week 1: Deploy parallel service, begin testing
- Week 2: Achieve feature parity, load testing
- Week 3: Gradual production cutover
- Week 4: Complete migration, remove old services

## Success Metrics
- Zero "dispatch_failed" errors
- Response time < 200ms for all commands
- 99.9% uptime over 30 days
- No manual interventions required