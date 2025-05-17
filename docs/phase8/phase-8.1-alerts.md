# Phase 8.1 - Alert Enrichment Implementation

## Overview
This milestone implements alert enrichment capabilities for the Alfred platform, including Helm alert labels, an alert dispatcher, and Slack integration.

## Implementation Plan

### 1. Helm Alert Labels
Enhance `charts/alfred/templates/alerts.yaml` with standardized labels:
- `severity`: critical | warning | info
- `service`: affected service name
- `runbook`: URL template pointing to documentation

### 2. Alert Dispatcher
Create `alfred.alerts.dispatcher` module with:
- `handle_alert(alert_json: dict) -> None` function
- Enrichment with runtime metadata (git_sha, pod_uid, chart_ver)
- Slack webhook integration via `SLACK_ALERT_WEBHOOK`
- Severity-based emoji and formatting

### 3. Testing Strategy
- Unit tests with parametrized severity levels
- Mock Slack webhook calls
- Verify enrichment data in payloads

### 4. CI Integration
- Add alerts-specific test marker
- Ensure mypy strict compliance
- Run in CI workflow matrix

## Architecture Decisions

### Alert Flow
1. Prometheus fires alert based on rules
2. Alertmanager forwards to webhook endpoint
3. Alert dispatcher enriches payload
4. Formatted message posted to Slack

### Enrichment Data Sources
- `GIT_SHA`: Build-time commit hash
- `POD_UID`: Kubernetes pod identifier
- `CHART_VERSION`: Helm chart version
- Runbook URL: Generated from alert name

### Slack Message Format
```
🚨 [CRITICAL] Database Connection Pool Exhausted
Service: alfred-api
Environment: production
Runbook: https://github.com/alfred-agent-platform-v2/runbooks/database_connection_pool_exhausted.md

Details:
- Pod: api-deployment-7d9f8b6-xyz123
- Chart: alfred-0.8.2
- Commit: abc123def
```

## Success Criteria
- [ ] All alerts have severity, service, and runbook labels
- [ ] Alert dispatcher handles all severity levels
- [ ] Slack messages include all enrichment data
- [ ] Tests achieve 100% coverage
- [ ] CI runs alerts tests in isolation
- [ ] Documentation complete

## Timeline
- Helm labels: 1 day
- Alert dispatcher: 2 days
- Tests and CI: 1 day
- Documentation: 0.5 day

Total: ~4.5 days
