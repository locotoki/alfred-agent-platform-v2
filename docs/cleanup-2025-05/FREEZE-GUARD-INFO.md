# Stability Freeze Guard Implementation

## Overview

The freeze-guard workflow is automatically triggered on all pull requests to the main branch during the stability freeze period (July 4-10, 2025).

## How It Works

1. **Trigger**: Activated on PR events (opened, synchronized, reopened, labeled, unlabeled)
2. **Enforcement**: Blocks PRs without `P0-fix` label during freeze window
3. **Dates**: Hardcoded July 4-10, 2025 in the workflow
4. **Simulation**: Can be manually tested with workflow_dispatch

## Testing the Freeze (Simulation Mode)

The workflow now supports simulation testing without waiting for the actual freeze dates:

```bash
# Test with a date inside the freeze window
gh workflow run freeze-guard.yml -f simulate_date=2025-07-05

# Test with a date outside the freeze window
gh workflow run freeze-guard.yml -f simulate_date=2025-06-15

# Watch the simulation run
gh run watch $(gh run list -L1 --json databaseId -q '.[0].databaseId')
```

### Full Dry-Run with Dummy PR

```bash
# Create a test branch
git checkout -b test-freeze-guard
echo "test" > test-freeze.txt
git add test-freeze.txt
git commit -m "test: freeze guard probe"
git push -u origin test-freeze-guard

# Create a dummy PR
gh pr create -B main -t "Test: Freeze Guard Probe" -b "Testing freeze guard" -d

# Run freeze guard simulation
gh workflow run freeze-guard.yml -f simulate_date=2025-07-05

# Clean up when done
gh pr close --delete-branch
```

## Real PR Behavior

When triggered by actual PRs:

## During the Freeze

Only PRs with the `P0-fix` label will be allowed to merge. To add the label:

```bash
gh pr edit <PR_NUMBER> --add-label "P0-fix"
```

## Manual Workarounds

If needed during freeze, admins can:
1. Add the P0-fix label to critical PRs
2. Use admin merge privileges to bypass the check
3. Temporarily disable the workflow (not recommended)

## Workflow Location

`.github/workflows/freeze-guard.yml`

The workflow is simple and effective, ensuring only critical fixes are merged during the stability freeze period.
