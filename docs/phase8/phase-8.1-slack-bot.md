# Phase 8.1 - Slack Bot Setup Guide

## Slack App Configuration

### Create Slack App

1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. Name: "Alfred Diagnostics"
4. Workspace: Select your workspace

### Configure Slash Commands

1. Navigate to "Slash Commands" in the app settings
2. Click "Create New Command"
3. Add these commands:

#### Health Command
- Command: `/diag`
- Request URL: `https://your-domain/slack/commands`
- Short Description: `System diagnostics`
- Usage Hint: `health | metrics`

### Configure OAuth & Permissions

1. Navigate to "OAuth & Permissions"
2. Add Bot Token Scopes:
   - `chat:write`
   - `commands`
3. Install to workspace
4. Copy the Bot User OAuth Token

### Environment Configuration

1. Add to GitHub Secrets (staging/prod):
   ```
   SLACK_BOT_TOKEN=xoxb-...
   SLACK_ALERT_WEBHOOK=https://hooks.slack.com/services/...
   ```

2. Update Helm values for staging:
   ```yaml
   slack:
     enabled: true
     diagnostics:
       enabled: true
   ```

3. Deploy to cluster:
   ```bash
   helm upgrade alfred ./charts/alfred -n staging
   ```

## Testing Commands

After deployment, test in Slack:

```
/diag health
/diag metrics
```

Expected responses:
- Health: Shows service status with ✅/❌ indicators
- Metrics: Shows request rates, latency, error rates

## Troubleshooting

1. Check pod logs:
   ```bash
   kubectl logs -n staging deployment/alfred-slack
   ```

2. Verify secrets are mounted:
   ```bash
   kubectl describe pod -n staging -l app=alfred-slack
   ```

3. Test connectivity to Prometheus:
   ```bash
   kubectl exec -n staging deployment/alfred-slack -- curl http://prometheus:9090/api/v1/query
   ```