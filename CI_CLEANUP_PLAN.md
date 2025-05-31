# CI Status Check Cleanup Plan

This plan fixes the branch protection mismatch that's blocking PR #632 and prevents future issues.

## 🎯 Canonical Status Checks

| Category | Canonical Name | Purpose |
|----------|---------------|---------|
| Build + Tests | `build` | Proves code compiles and unit tests pass |
| Style/Linting | `lint-python` | Black + isort + flake8 combined |
| Baseline Health | `core-health` | 9-service core slice must stay green |
| Audit Drift | `ci-summary` | Fails if deterministic audit hash changes |

## 📝 Required Workflow Updates

### 1. Find and rename the build workflow

```bash
# Find which workflow runs pytest/unit tests
grep -r "pytest\|test" .github/workflows/*.yml
```

Update that workflow to have:
```yaml
jobs:
  build:
    name: build  # ← canonical name
    runs-on: ubuntu-latest
    steps:
      # ... existing test steps ...
```

### 2. Create unified lint-python workflow

Create `.github/workflows/lint-python.yml`:
```yaml
name: Python Linting
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint-python:
    name: lint-python  # ← canonical name
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install dependencies
        run: |
          pip install black isort flake8
          
      - name: Run Black
        run: black --check .
        
      - name: Run isort
        run: isort --check-only .
        
      - name: Run flake8
        run: flake8 .
```

### 3. Update core-health workflow

Already correct in `.github/workflows/core-health-gate.yml`:
```yaml
jobs:
  core-health:
    name: core-health  # ← already canonical
```

### 4. Verify ci-summary workflow

Check that it has the correct name:
```yaml
jobs:
  ci-summary:
    name: ci-summary  # ← should already be canonical
```

## 🛡️ Add Check Name Guardian

Create `.github/workflows/check-name-collision.yml`:
```yaml
name: Forbid Unknown Checks
on: 
  pull_request:
    paths:
      - '.github/workflows/*.yml'

jobs:
  validate-check-names:
    name: validate-check-names
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Install yq
        run: |
          wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
          chmod +x /usr/local/bin/yq
          
      - name: Ensure only approved status names
        run: |
          APPROVED="build|lint-python|core-health|ci-summary|validate-check-names"
          
          # Get changed workflow files
          git fetch origin ${{ github.base_ref }}
          CHANGED=$(git diff --name-only origin/${{ github.base_ref }}...HEAD -- '.github/workflows/*.yml' || true)
          
          if [ -z "$CHANGED" ]; then
            echo "No workflow changes detected"
            exit 0
          fi
          
          for f in $CHANGED; do
            if [ -f "$f" ]; then
              echo "Checking $f..."
              BAD=$(yq '.jobs.*.name' "$f" | grep -v '^null$' | grep -Ev "^($APPROVED)$" || true)
              if [ -n "$BAD" ]; then
                echo "::error file=$f::Found unapproved job name(s): $BAD"
                echo "Only approved names are: $APPROVED"
                exit 1
              fi
            fi
          done
          
          echo "✅ All job names are approved"
```

## 🔧 Admin Actions Required

### 1. Update Branch Protection (via UI)

1. Go to: Settings → Branches → main → Edit
2. Under "Require status checks to pass":
   - **Remove all current checks**
   - **Add only these 5**:
     - `build`
     - `lint-python`
     - `core-health`
     - `ci-summary`
     - `validate-check-names`
3. Keep enabled:
   - ✅ Require branches to be up to date
   - ✅ Require linear history
   - ✅ Include administrators
4. Save changes

### 2. Or Update via GitHub CLI

```bash
# Replace Digital-Native-Ventures with your org name
gh api -X PATCH \
  repos/Digital-Native-Ventures/alfred-agent-platform-v2/branches/main/protection \
  -f required_status_checks.contexts='["build","lint-python","core-health","ci-summary","validate-check-names"]' \
  -f required_status_checks.strict=true \
  -f required_linear_history=true
```

## 🚀 Implementation Steps

1. **First**: Admin updates branch protection to the 5 canonical checks
2. **Then**: Merge PR #632 (it has core-health passing)
3. **Next**: Create new PR with:
   - Workflow renames to canonical names
   - New lint-python.yml
   - New check-name-collision.yml
4. **Finally**: All future PRs will have consistent, predictable CI

## 📊 Current Status of PR #632

- ✅ `core-health` - PASSING
- ✅ `ci-summary` - PASSING  
- ❌ `build` - Missing (needs workflow rename)
- ❌ `lint-python` - Missing (needs unified workflow)

Once branch protection is updated to these canonical names, we can:
1. Create the missing workflows in a new PR
2. Or temporarily remove `build` and `lint-python` from required checks to unblock #632

## 🎯 End Result

- Every PR shows exactly 5 status checks
- No more "waiting for status to be reported"
- No more mismatched check names
- CI becomes predictable and maintainable