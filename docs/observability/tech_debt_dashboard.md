# Tech Debt Dashboard

The Tech Debt Dashboard provides visibility into technical debt across the Alfred platform, including dependency freshness, license compliance, and operational health metrics.

## Dashboard Panels

### Dependency Management

1. **High-Severity Outdated Dependencies** (Gauge)
   - Shows count of packages with high-severity vulnerabilities or critical updates
   - Thresholds: Green (0), Yellow (1-4), Red (5+)

2. **Outdated Dependencies by Severity** (Time Series)
   - Tracks trends of outdated dependencies across severity levels
   - Helps identify when dependency debt is accumulating

3. **Package Ages** (Table)
   - Lists top 20 oldest packages by days since last update
   - Thresholds: Green (<180 days), Yellow (180-365 days), Red (>365 days)

### License Compliance

4. **Disallowed OSS Licenses** (Stat)
   - Count of packages with GPL/LGPL/AGPL licenses
   - Target: Must be 0 for compliance

### Operational Health

5. **Request Latency (p95)** (Stat)
   - 95th percentile request latency across all Alfred services
   - SLO Target: ≤300ms
   - Thresholds: Green (≤300ms), Red (>300ms)

6. **Error Budget Burn** (Gauge)
   - 30-day rolling success rate against SLO
   - SLO Target: 99.9% success rate (0.1% error budget)
   - Thresholds: Green (≥99.9%), Yellow (99.8-99.9%), Red (<99.8%)

## SLO Targets

| Metric | Target | Measurement Window |
|--------|--------|-------------------|
| Request Latency (p95) | ≤300ms | Real-time |
| Success Rate | ≥99.9% | 30-day rolling |
| License Compliance | 0 disallowed | Real-time |
| High-Severity Dependencies | 0 | Real-time |

## Usage

This dashboard should be reviewed:
- Daily by on-call engineers
- Weekly during tech debt reviews
- Before major releases
- When planning dependency updates

## Alerts

Related alerts are configured in:
- `charts/alerts/alfred-core.yaml` - Latency and error rate alerts
- `alfred/scripts/licence_gate.py` - License compliance checks
