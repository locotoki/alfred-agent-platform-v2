# Slack Integration GA Requirements

This document tracks the implementation of Slack integration as a GA requirement for the alfred-agent-platform-v2.

## Background

The `/alfred health` command via Slack is an implicit GA acceptance criterion as it provides the interactive path to prove agents work out-of-the-box.

## Implementation Status

### ✅ 1. Default Profile Inclusion
- **Status**: COMPLETE
- **Details**:
  - `slack_mcp_gateway` runs in the default docker-compose profile (no profile restrictions)
  - `echo-agent` is configured in `docker-compose.override.yml` and starts automatically
  - Both services are part of the standard `docker compose up` command

### ✅ 2. CI Smoke Test
- **Status**: IMPLEMENTED
- **File**: `.github/workflows/slack-integration-test.yml`
- **Tests**:
  - Slack MCP Gateway health endpoint check
  - `/alfred health` command simulation
  - Echo agent command processing verification
  - Runs on PR changes to Slack components

### ✅ 3. GA Checklist Documentation
- **Status**: UPDATED
- **File**: `docs/ga-release-checklist.md`
- **Added Requirements**:
  - `/alfred health` command returns success within 5 seconds
  - Slack MCP Gateway health endpoint responds with `{"status":"ok"}`
  - Echo agent processes commands from Redis stream
  - All Slack integration tests passing in CI

### ✅ 4. Helm Chart Configuration
- **Status**: ENABLED
- **File**: `charts/alfred/values.yaml`
- **Changes**:
  - `slackMcpGateway.enabled: true` (was false)
  - `slackMcpGateway.echoAgent.enabled: true` (was false)
  - Added comments indicating GA requirement

## Testing

To verify the implementation:

1. **Local Testing**:
   ```bash
   docker compose up -d
   curl http://localhost:3010/health  # Should return {"status":"ok"}
   ```

2. **CI Testing**:
   - The new workflow runs automatically on PRs
   - Tests the full Slack integration stack

3. **Helm Deployment**:
   ```bash
   helm install alfred charts/alfred/
   # Slack services will be enabled by default
   ```

## Architecture

```
Slack App → slack_mcp_gateway → Redis Streams → echo-agent → Response
     ↓                              ↓                ↓
/alfred health              mcp.requests      Process & Reply
```

## Next Steps

1. Merge this PR to enable GA requirements
2. Monitor CI for Slack integration test results
3. Update deployment documentation with Slack configuration requirements

## Configuration Requirements

The following environment variables must be set:
- `SLACK_APP_TOKEN`: Slack app-level token (xapp-...)
- `SLACK_BOT_TOKEN`: Slack bot user token (xoxb-...)
- `REDIS_PASSWORD`: Redis authentication password

See `ENV-QUICKSTART.md` for detailed setup instructions.
