# Alert Enrichment Rollback Plan

## Pre-deployment Checklist
- [ ] Record current Helm revision: `helm list -n <namespace>`
- [ ] Backup current alert rules: `kubectl get configmap prometheus-alerts -o yaml > alerts-backup.yaml`
- [ ] Ensure monitoring access to #alfred-alerts-dev channel

## Deployment Commands
```bash
# Deploy with alert enrichment
helm upgrade --install alfred ./charts/alfred -n staging \
  --set alerts.enrichment.enabled=true \
  --set alerts.slack.webhook=${SLACK_ALERT_WEBHOOK}

# Verify deployment
kubectl rollout status deployment/prometheus -n staging
kubectl logs -l app=prometheus -n staging | grep "loading config file"
```

## Rollback Procedure

### Option 1: Disable Feature
```bash
# Quick disable without rollback
helm upgrade alfred ./charts/alfred -n staging \
  --set alerts.enrichment.enabled=false
```

### Option 2: Full Rollback
```bash
# Get current revision
CURRENT_REV=$(helm list -n staging | grep alfred | awk '{print $3}')

# Get previous revision  
PREV_REV=$((CURRENT_REV - 1))

# Rollback to previous revision
helm rollback alfred $PREV_REV -n staging

# Verify rollback
helm status alfred -n staging
kubectl get pods -n staging
```

## Monitor for Issues
1. Check #alfred-alerts-dev for excessive noise
2. Monitor Prometheus targets: `curl prometheus:9090/api/v1/targets`
3. Check alert dispatcher logs: `kubectl logs -l app=alert-dispatcher`

## Common Issues

### Too Many Alerts
- Temporarily increase alert thresholds
- Disable specific alert rules via ConfigMap

### Webhook Failures
- Verify SLACK_ALERT_WEBHOOK is set correctly
- Check Slack webhook URL is not rate-limited
- Review dispatcher logs for HTTP errors

### Missing Enrichment Data
- Ensure GIT_SHA, POD_UID, CHART_VERSION are set
- Check pod environment variables: `kubectl describe pod <pod-name>`

## Emergency Contacts
- Platform Team: @alfred-platform/core
- Observability: @alfred-platform/observability
- Slack Webhook Admin: @slack-admin