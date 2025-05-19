## Summary
Implements alert enrichment capabilities for the Alfred platform, including Helm alert labels, an alert dispatcher, and Slack integration.

## Key Changes

### 1. Helm Alert Labels
- Added `severity`, `service`, and `runbook` labels to all Prometheus alerts
- Severity values: critical | warning | info
- Runbook URLs follow template: `https://github.com/alfred-agent-platform-v2/runbooks/{alert_name_snake}.md`

### 2. Alert Dispatcher Module
- Created `alfred.alerts.dispatcher` with `handle_alert()` function
- Enriches alerts with runtime metadata (GIT_SHA, POD_UID, CHART_VERSION)
- Slack webhook integration via SLACK_ALERT_WEBHOOK
- Severity-based emoji and color formatting

### 3. Testing & CI
- Comprehensive unit tests with parametrized severity levels
- Added `alerts` pytest marker
- CI workflow updated with dedicated alerts test step
- All tests achieving 100% coverage

### 4. Documentation
- Created phase documentation in `docs/phase8/phase-8.1-alerts.md`
- Added sample runbook for `alfred_core_health_critical` alert

## Testing
All tests pass locally:
```
alfred/alerts/tests/test_dispatcher.py: 13 passed in 0.12s
```

## Checklist
- [x] Helm alert labels added to all alert rules
- [x] Alert dispatcher fully typed with mypy strict compliance
- [x] Unit tests with 100% coverage
- [x] CI integration complete
- [x] Documentation and runbook examples
- [x] Pre-commit checks pass

## Next Steps
After merge:
- Deploy updated alert rules to staging
- Configure Slack webhook in environment
- Test end-to-end alert flow
- Create additional runbooks as needed

Fixes #72
