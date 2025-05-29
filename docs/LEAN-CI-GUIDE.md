# Lean CI/CD Guide

## Overview

This CI/CD setup prioritizes developer productivity while maintaining essential safety checks. The philosophy is simple: catch breaking changes quickly, run comprehensive checks nightly.

## CI Layers

| Layer | Purpose | When | Target Time | Blocks PR? |
|-------|---------|------|-------------|------------|
| **Fast Dev Build** | Build & boot check | Every PR | ≤ 3 min | ✅ Yes |
| **Lint** | Python formatting | Every PR with .py changes | ≤ 30s | ✅ Yes |
| **SBOM + Trivy** | Security scanning | Nightly + main pushes | Variable | ❌ No |
| **Full Smoke Test** | Complete stack test | Nightly | 5 min | ❌ No |
| **Flake Catcher** | E2E stability check | PRs touching services | Variable | ❌ No |
| **Weekly Cleanup** | Cache & artifact cleanup | Weekly | N/A | ❌ No |

## Required Checks (Branch Protection)

Only these checks are required for merge:
- `build` (from dev-build.yml)
- `lint` (from lint.yml) - optional but recommended

## Workflow Details

### 1. Fast Dev Build (`dev-build.yml`)
**Purpose**: Ensure code builds and core services start
- Builds `agent-core` as representative image
- Starts minimal services (Redis, Postgres, agent-core)
- Validates health endpoints
- **Must pass in ≤ 3 minutes**

### 2. Python Lint (`lint.yml`)
**Purpose**: Maintain code formatting consistency
- Only runs on Python file changes
- Checks Black formatting
- Validates import ordering with isort
- **Must pass in ≤ 30 seconds**

### 3. Nightly Security (`nightly-security.yml`)
**Purpose**: Comprehensive vulnerability scanning
- Trivy scan on built images
- SBOM generation for compliance
- License compatibility checks
- **Failures create alerts, don't block**

### 4. Nightly Smoke (`nightly-smoke.yml`)
**Purpose**: Full stack validation
- Builds all service images
- Starts complete docker-compose stack
- Runs basic API health checks
- **Failures create issues for investigation**

### 5. Flake Catcher (`flake-catcher.yml`)
**Purpose**: Identify unstable tests
- Runs E2E tests 3 times
- If ≥2 fail, adds `flaky-test` label
- **Helps identify but doesn't block**

### 6. Weekly Cleanup (`weekly-cleanup.yml`)
**Purpose**: Maintain runner hygiene
- Prunes Docker images >7 days old
- Cleans build caches
- Reports stale branches
- **Runs Sunday 2 AM UTC**

## Developer Workflow

### Standard PR Flow
1. Make changes on feature branch
2. Push to GitHub
3. Wait ~3.5 minutes for required checks
4. Merge when green

### When Checks Fail

**Dev Build Failure**:
```bash
# Check locally
docker-compose -f docker-compose.slim.yml up -d
curl http://localhost:8011/health
```

**Lint Failure**:
```bash
# Auto-fix locally
black **/*.py
isort --profile black **/*.py
```

### Debugging Nightly Failures

Check workflow artifacts:
- Security scan: `sbom-nightly-*`
- Smoke test logs: `smoke-test-logs-*`

## Configuration

### Branch Protection Settings
```yaml
Required status checks:
  - build
  - lint (optional but recommended)
  
Settings:
  - Require branches to be up to date: true
  - Include administrators: false
```

### Pre-commit Hooks
- Large file check (>1MB)
- YAML/JSON validation
- Python formatting (local only)

## Migration Path

As optional jobs stabilize:
1. Monitor success rate for 2 weeks
2. If >95% success, promote to required
3. Update branch protection rules

## Maintenance

### Monthly Review
- Check flake statistics
- Review nightly failure rate
- Adjust timeouts if needed

### Quarterly Cleanup
- Archive old workflow logs
- Update tool versions
- Review and update ignore patterns

## FAQ

**Q: Why isn't security scanning required?**
A: It can fail on new CVEs outside your control. Better as an alert than a blocker.

**Q: Can I run nightly tests on demand?**
A: Yes, use `workflow_dispatch` on any nightly workflow.

**Q: How do I add a new required check?**
A: Add to branch protection only after 2 weeks of >95% success rate.

## Support

- CI issues: Check artifacts and logs
- Flaky tests: Look for `flaky-test` label
- Performance: Review workflow timings in Actions tab