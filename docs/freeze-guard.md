# Freeze Guard Documentation

## Overview

The freeze-guard workflow enforces stability freeze periods by blocking non-critical PRs from merging to main during designated freeze windows.

## How It Works

1. Runs on all PRs targeting the main branch
2. Checks if the current date falls within a freeze window
3. Blocks PRs unless they have the `P0-fix` label
4. Allows all PRs outside of freeze windows

## Freeze Windows

- **v3.0.0 GA Freeze**: July 4-10, 2025

## Bypass for Critical Fixes

To merge during a freeze, add the `P0-fix` label to your PR.

### Simulation mode

Dry-run the guard at any time:

```bash
gh workflow run freeze-guard.yml \
  -f simulate_date=2025-07-05 \
  -r $(git rev-parse --short HEAD)
```

The job will report "Stability Freeze active" and would block PRs lacking the P0-fix label.
