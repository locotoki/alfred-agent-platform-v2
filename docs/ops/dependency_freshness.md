# Dependency Freshness Audit (DA-010)

The Dependency Freshness Audit system monitors the age of dependencies and alerts when packages become significantly outdated, helping maintain security and compatibility.

## Overview

- **Automated weekly audits** run every Monday at 05:00 UTC
- **Prometheus metrics** for monitoring outdated dependencies
- **Grafana dashboard** with Tech-Debt visualization
- **Slack alerts** for high-severity outdated packages (1+ years old)

## Components

### 1. Audit Script
- **Location**: `alfred/scripts/dependency_freshness.py`
- **Purpose**: Analyzes installed packages against PyPI for freshness
- **Output**: Prometheus metrics and console summary

### 2. Metrics Module
- **Location**: `alfred/metrics/dependency_freshness.py`
- **Metrics**:
  - `alfred_dependency_outdated_total{severity}` - Count by severity level
  - `alfred_dependency_latest_age_days{package}` - Age in days for top 20 oldest packages

### 3. GitHub Workflow
- **Location**: `.github/workflows/freshness-audit.yml`
- **Trigger**: Weekly on Mondays at 05:00 UTC, manual dispatch
- **Dependencies**: Python 3.11, pip-audit 2.7.*

### 4. Grafana Dashboard
- **Location**: `metrics/grafana/tech_debt_dependency_freshness.json`
- **Panels**:
  - High-severity outdated dependencies gauge
  - Outdated dependencies by severity over time
  - Package ages table (top 20 oldest)

### 5. Slack Integration
- **Script**: `scripts/slack_dependency_alert.py`
- **Channel**: `#alfred-alerts`
- **Trigger**: When `alfred_dependency_outdated_total{severity="high"} > 0`

## Severity Levels

| Severity | Criteria | Action Required |
|----------|----------|-----------------|
| **High** | Package is 1+ years behind latest version | Immediate review and update planning |
| **Medium** | Package is 6+ months behind latest version | Include in next quarterly update cycle |
| **Low** | Package has newer version available | Monitor for security updates |

## Usage

### Manual Audit
```bash
# Run dependency freshness audit
python alfred/scripts/dependency_freshness.py

# Check for alert conditions
python scripts/slack_dependency_alert.py
```

### Metrics Integration
```python
from alfred.metrics.dependency_freshness import update_metrics, should_alert

# Update Prometheus metrics
outdated_counts = update_metrics()

# Check if alerts should be triggered
if should_alert():
    print("High-severity outdated dependencies found!")
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SLACK_ALFRED_WEBHOOK` | Slack webhook URL for alerts | No (alerts disabled if missing) |

## Workflow Integration

The dependency freshness audit integrates with the existing Alfred monitoring pipeline:

1. **Weekly Execution**: Runs as part of Monday maintenance window
2. **Metrics Export**: Updates Prometheus metrics for Grafana dashboards
3. **Alert Routing**: High-severity findings trigger Slack notifications
4. **Report Generation**: Creates `metrics/prometheus/dependency_freshness.prom`

## Maintenance

### Adding New Package Filters
To exclude additional system packages from analysis, edit the skip list in:
- `alfred/scripts/dependency_freshness.py`
- `alfred/metrics/dependency_freshness.py`

### Adjusting Severity Thresholds
Modify severity categorization in `categorize_severity()` function:
```python
def categorize_severity(age_days: int, has_newer_version: bool) -> str:
    if not has_newer_version:
        return "low"
    elif age_days >= 365:  # Adjust threshold here
        return "high"
    elif age_days >= 180:  # Adjust threshold here
        return "medium"
    else:
        return "low"
```

### Dashboard Customization
- Edit `metrics/grafana/tech_debt_dependency_freshness.json`
- Import into Grafana instance
- Adjust thresholds and colors as needed

## Testing

Run the smoke tests to verify functionality:
```bash
pytest -m smoke_dependency tests/smoke/test_dependency_freshness.py -v
```

## Troubleshooting

### Common Issues

**No metrics generated**
- Check pip-audit installation: `pip install pip-audit==2.7.*`
- Verify Python environment has packages to analyze
- Check network connectivity to PyPI

**Slack alerts not working**
- Verify `SLACK_ALFRED_WEBHOOK` environment variable
- Test webhook URL manually
- Check alert channel permissions

**Grafana dashboard not updating**
- Confirm Prometheus is scraping metrics endpoint
- Verify metrics file location: `metrics/prometheus/dependency_freshness.prom`
- Check Grafana data source configuration

## Related Documentation

- [Tech Debt Monitoring](../monitoring/tech-debt.md)
- [Prometheus Metrics](../monitoring/prometheus.md)
- [Slack Integration](../slack/alerts.md)
