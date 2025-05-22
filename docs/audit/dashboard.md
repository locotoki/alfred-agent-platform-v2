# 📊 Dependency Audit Dashboard

*Last updated: 2025-05-22 13:07 UTC*

## 🛡️ Status Badges

[![Dependency Inventory](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/deps-inventory-cron.yml/badge.svg)](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/deps-inventory-cron.yml)
[![Vulnerability Scan](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/vuln-scan-cron.yml/badge.svg)](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/vuln-scan-cron.yml)
[![License Scan](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/license-scan-cron.yml/badge.svg)](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/license-scan-cron.yml)

![Vulnerability Status](https://img.shields.io/badge/Vulnerabilities-0-success)
![License Compliance](https://img.shields.io/badge/Unknown%20Licenses-39.4%25-warning)

## 📈 Summary Statistics

### Dependencies
- **Total Packages**: 391
- **Unique Packages**: 149
- **Requirements.txt**: 296
- **Pyproject.toml**: 36
- **Import-only**: 59

### Security
- **Total Vulnerabilities**: 0
- **Critical**: 0
- **High**: 0
- **Medium**: 0
- **Low**: 0

### License Compliance
- **Total Entries**: 391
- **Permissive**: 231
- **Weak Copyleft**: 6
- **Copyleft**: 0
- **Unknown/Other**: 154 (39.4%)

## 📋 Data Sources

- **Dependency Inventory**: [`metrics/dependency_inventory.csv`](../../metrics/dependency_inventory.csv)
- **Vulnerability Report**: [`metrics/vulnerability_report.csv`](../../metrics/vulnerability_report.csv)
- **License Report**: [`metrics/license_report.csv`](../../metrics/license_report.csv)

## 🔄 Automation

This dashboard is automatically updated every Monday at 08:25 UTC via GitHub Actions.
Manual updates can be triggered by running `make audit-dashboard`.
