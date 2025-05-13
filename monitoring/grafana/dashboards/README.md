# Grafana Dashboards

This directory contains all Grafana dashboards used by the Alfred Agent Platform.

## Directory Structure

```
dashboards/
├── platform/           # Platform health and metrics dashboards
│   ├── health-dashboard.json
│   └── metrics-dashboard.json
├── agents/             # Agent-specific dashboards
│   ├── financial-tax-dashboard.json
│   ├── legal-compliance-dashboard.json
│   └── social-intel-dashboard.json
├── infrastructure/     # Infrastructure dashboards
│   ├── postgres-dashboard.json
│   └── redis-dashboard.json
└── backup/             # Backup of dashboards 
    └── platform-health-dashboard-20250513-120000.json
```

## Dashboard Management

All dashboards are stored as code in this repository. To make changes to a dashboard:

1. Make changes in the Grafana UI
2. Export the dashboard to JSON (Share > Export > Export for sharing externally)
3. Save the JSON to the appropriate directory
4. Commit the changes to the repository

## Adding a New Dashboard

To add a new dashboard:

1. Create the dashboard in Grafana UI
2. Export the dashboard to JSON
3. Save the JSON to the appropriate directory
4. Update this README.md if necessary
5. Commit the changes to the repository

## Dashboard Backups

Dashboard backups are automatically created by the `backup-dashboards.sh` script. These backups
should not be deleted as they provide a history of dashboard changes.

## Dashboard Naming Convention

Dashboard JSON files should be named as follows:
- `<service-name>-dashboard.json` - For service-specific dashboards
- `<metric-category>-dashboard.json` - For metric category dashboards

## Dashboard Tags

All dashboards should include appropriate tags:
- `platform` - For platform-wide dashboards
- `agent` - For agent-specific dashboards
- `infrastructure` - For infrastructure dashboards
- `<service-name>` - For service-specific dashboards