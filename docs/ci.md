# CI/CD Documentation

## Canonical Status Checks

The Alfred platform uses a standardized set of status checks for all pull requests. These checks are enforced by branch protection rules and must pass before merging.

### Required Checks

| Check Name | Purpose | Workflow File |
|------------|---------|---------------|
| `build` | Runs unit tests and verifies code compiles | `.github/workflows/ci-tier0.yml` |
| `lint-python` | Enforces code style with Black and isort | `.github/workflows/lint.yml` |
| `core-health` | Verifies the 10 core services start and pass health checks | `.github/workflows/core-health-gate.yml` |
| `ci-summary` | Ensures no configuration drift from baseline | `.github/workflows/ci-tier0.yml` |
| `validate-check-names` | Prevents unauthorized check names | `.github/workflows/check-name-collision.yml` |

### Adding New Checks

To add a new required status check:

1. Choose a canonical name that clearly describes the check's purpose
2. Update the workflow to use `name: <canonical-name>` in the job definition
3. Add the new name to the `APPROVED` list in `.github/workflows/check-name-collision.yml`
4. Request an admin to add it to branch protection rules

### Workflow Standards

All CI workflows must:
- Use one of the approved canonical job names
- Complete within reasonable time limits (see timeout settings)
- Provide clear error messages when checks fail
- Run on `ubuntu-latest` or `ubuntu-22.04` for consistency

### Debugging CI Failures

1. Click on the failing check in the PR
2. Review the logs for the specific step that failed
3. Common issues:
   - Environment variables not set (check workflow env section)
   - Service dependencies not starting (check docker-compose logs)
   - Flaky tests (re-run the workflow)

### Local CI Testing

To test CI checks locally before pushing:

```bash
# Run style checks
make lint

# Run unit tests  
make test

# Run core health check
docker compose --profile core up -d
./scripts/check-core-health.sh
```