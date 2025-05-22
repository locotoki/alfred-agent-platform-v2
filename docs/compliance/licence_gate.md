# Licence Gate

The Alfred platform enforces licence compliance through an automated CI gate that validates all dependencies use approved open source licences.

## Overview

**Allowed Licences:**
- Apache-2.0 / Apache Software License
- MIT / MIT License
- BSD-2-Clause, BSD-3-Clause, BSD License
- ISC License
- Python Software Foundation License

**Disallowed Licences:**
- GPL-3.0, LGPL-2.1, AGPL (copyleft licences)
- Proprietary or commercial licences
- Unknown/unspecified licences

## How It Works

1. **CI Integration**: Runs on every PR via `.github/workflows/licence-gate.yml`
2. **Pre-commit Hook**: Local validation via `licence-gate` hook in `.pre-commit-config.yaml`
3. **Dependency Scanning**: Uses `pip-licenses` to extract licence information
4. **Waiver Support**: Temporary exemptions via `.licence_waivers` file
5. **Metrics**: Prometheus metrics for monitoring compliance drift

## Local Usage

```bash
# Run licence gate manually
poetry run python -m alfred.scripts.licence_gate

# Install pip-licenses if needed
poetry run pip install pip-licenses

# Check current licences
poetry run pip-licenses --format=table
```

## Managing Waivers

To temporarily waive a disallowed licence:

1. Add entry to `.licence_waivers` (located in repository root):
   ```
   package-name==GPL-3.0
   ```

2. Create tracking issue for replacement
3. Remove waiver when dependency is replaced

**Current waiver file:** [`.licence_waivers`](../../.licence_waivers)

**Example entries:**
```
# Format: package==licence (exact match required)
problematic-package==GPL-3.0
legacy-dep==LGPL-2.1
ubuntu-package==GNU GPL
```

**Important:** The licence string must match exactly what `pip-licenses` reports. Use `poetry run pip-licenses --format=table` to verify licence names.

## Metrics

The licence gate emits Prometheus metrics:

```
alfred_licence_disallowed_total{package="pkg", licence="GPL-3.0"} 1
```

**Dashboard**: View the "Disallowed OSS licences" panel in the [Tech-Debt: Dependency Freshness](../../metrics/grafana/tech_debt_dependency_freshness.json) Grafana dashboard.

Alert fires when `alfred_licence_disallowed_total > 0` (Slack: `#alfred-alerts`).

## Troubleshooting

**Common Issues:**

1. **False positive**: Package uses BSD but detected as "BSD License"
   - Solution: Update `LICENCE_ALIASES` in `licence_gate.py`

2. **Transitive GPL dependency**: Indirect dependency has disallowed licence
   - Short-term: Add waiver entry
   - Long-term: Find alternative package

3. **Unknown licence**: Package licence not detected
   - Check `pip-licenses --with-urls` for package
   - May need manual investigation

**Bypass (Emergency Only):**
```bash
# Skip licence gate in CI (use sparingly)
git commit -m "emergency fix [skip licence-gate]"
```
