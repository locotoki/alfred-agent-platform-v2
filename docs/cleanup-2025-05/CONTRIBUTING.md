# Contributing to Alfred Agent Platform v2

We love your input! We want to make contributing to this project as easy and transparent as possible. This guide ensures all changes follow our lean-first, metrics-driven workflow.

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests. Our development process follows a phased approach:

- **Phase 0**: Foundational changes with basic metrics and monitoring
- **Phase 1**: Enhanced metrics with service_health gauges
- **Phase 2**: Advanced metrics with custom service-specific metrics

### Docker Compose Structure

We follow a simple pattern for Docker Compose to maintain clarity and predictability:

1. **Single Source of Truth**: `docker-compose.yml` is the canonical definition of all services
2. **Environment Overrides**: `docker-compose.dev.yml` contains all development-specific changes
3. **Personal Overrides**: `docker-compose.local.yml` (gitignored) for personal customizations
4. **Service Profiles**: Use profiles to enable/disable optional services (dev, mocks, etc.)

The files are loaded in this order, with later files overriding earlier ones:
```
docker-compose.yml ← docker-compose.dev.yml ← docker-compose.local.yml
```

Standard Docker Compose commands:
```bash
# Production-like setup
docker compose up -d

# Development environment
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev up -d

# Personal customizations
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.local.yml --profile dev up -d
```

**Important**: After dependency bumps, developers must rebuild containers to ensure consistency:
```bash
alfred up --rebuild --detach
# or
docker compose -f docker-compose.yml -f docker-compose.dev.yml build --no-cache
```

**Note**: If you encounter failing *dist-packages* guard errors, it usually means your container is stale and needs rebuilding. This check ensures development and CI environments use identical package sets (ADR-010).

### Branch Naming Convention

All branches should follow this naming pattern:
- `feat/<area>-<slug>` - For new features (e.g., `feat/metrics-exporter`)
- `fix/<area>-<slug>` - For bug fixes (e.g., `fix/dashboard-broken-panel`)
- `docs/<area>-<slug>` - For documentation updates (e.g., `docs/metrics-guide`)
- `chore/<area>-<slug>` - For maintenance tasks (e.g., `chore/bump-healthcheck-version`)

### Required Documentation Per Phase

Each phase of development requires specific documentation:

| Phase | Required Documentation |
|-------|------------------------|
| 0     | Basic README updates, implementation notes |
| 1     | Design doc, CHANGELOG.md updates, monitoring documentation |
| 2     | Full technical specification, CHANGELOG.md, metrics documentation, dashboard designs |

## Code Style

- We use [Black](https://github.com/psf/black) for Python code formatting
- Line length is 100 characters
- We use [isort](https://pycqa.github.io/isort/) for import sorting
- Type hints are required for all new code
- Docstrings follow [Google style](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings) with flake8-docstring rules D400, D401, and D403 enforced
  - See [Docstring Templates](docs/dev/docstring_template.rst) for examples

**Formatting Baseline**: As of [chore/black-24.4.2-standardise-formatting branch], the entire codebase has been formatted with Black v24.4.2 and isort to establish a consistent baseline. All future PRs must maintain this formatting standard.

You can easily apply formatting to your code by running:
```bash
pre-commit run --all-files
```
or install the hooks to run automatically on commit:
```bash
pre-commit install
```

For a detailed overview of our Python formatting standards and implementation, see [Black Formatting Standards](docs/formatting/BLACK-FORMATTING-STANDARDS.md). All Python files in the codebase are formatted using Black v24.4.2 with these settings.

## Metrics and Monitoring Standards

All services MUST implement:
- `/health` endpoint with detailed status
- `/healthz` endpoint for simple health probes
- `/metrics` endpoint in Prometheus format

### Healthcheck Standard Pattern

All Dockerfiles MUST follow this standard pattern for health checks:

```dockerfile
FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM <base-image>
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

# Service-specific content...

# Expose application and metrics ports
EXPOSE <app-port>
EXPOSE 9091

# Use healthcheck wrapper for application
CMD ["healthcheck", "--export-prom", ":9091", "--", "<command>", "<args>"]
```

In docker-compose.yml:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:<PORT>/health"]
  <<: *basic-health-check
labels:
  <<: *service-labels
  prometheus.metrics.port: "9091"
```

A pre-commit hook (`pre-commit-healthcheck`) enforces these standards for all Dockerfile changes.

New or modified services MUST:
- Use the latest healthcheck binary (currently v0.4.0)
- Expose metrics on port 9091
- Include the `service_health` gauge metric
- Follow standard metric naming conventions
- Update Grafana dashboards when adding metrics

## CI Self-Healing System

The Alfred Agent Platform includes an automated CI self-healing system to handle transient failures in Engineer PRs while escalating persistent issues to human attention.

### How It Works

The system automatically monitors all `engineer-task-*` PRs and implements a two-tier failure handling approach:

#### First Failure (Attempt 0 → 1)
When an Engineer PR fails CI for the first time:
1. **Automatic Retry**: The system closes the failed PR and nudges the task queue
2. **Label Update**: Changes `attempt:0` to `attempt:1` 
3. **Fresh Implementation**: The engineer generates a completely new implementation approach
4. **No Human Intervention**: Fully automated recovery for transient issues

#### Second Failure (Attempt 1 → 2)
When an Engineer PR fails CI for the second time:
1. **Human Escalation**: Adds `needs-human` and `attempt:2` labels
2. **Escalation Issue**: Creates a detailed issue for human review
3. **PR Preservation**: Keeps the PR open for manual investigation
4. **Root Cause Analysis**: Requires human engineer to analyze persistent failures

### Labels Used

- `attempt:0` - First attempt at the task (added automatically)
- `attempt:1` - First retry after CI failure
- `attempt:2` - Second retry, human intervention required
- `needs-human` - Escalated to human engineer for review
- `automerge` - Enables automatic merging when CI passes
- `ci-escalation` - Applied to escalation issues

### Engineer PR Lifecycle

```
Task Created → Engineer PR (attempt:0) → CI Pass → Auto-merge ✅
                           ↓ CI Fail
                      Close & Retry (attempt:1) → CI Pass → Auto-merge ✅  
                                      ↓ CI Fail
                                 Human Review (attempt:2, needs-human) 🚨
```

### Escalation Criteria

The system escalates to human review when:
- Two consecutive CI failures on the same task
- Patterns suggest non-transient issues (code quality, logic errors)
- Infrastructure problems requiring human diagnosis

### Benefits

- **Resilience**: Handles transient CI failures automatically
- **Fresh Perspectives**: Each retry gets a completely new implementation approach  
- **Human Focus**: Engineers only handle genuinely problematic cases
- **Transparency**: Full audit trail via labels and comments
- **Metrics**: Tracks retry patterns for system improvement

## Pull Request Process

Before creating a pull request, ensure you've completed the CI Sanity Checklist:

| Check | Command / URL | Pass Criteria |
|-------|--------------|---------------|
| Local metrics reach Prometheus | `curl -s http://localhost:9090/api/v1/query?query=service_health` | JSON returns data.series > 0 for every service |
| Grafana panels populated | Open Dashboard | Panels show green ✓ for each service |
| Metrics lint script green | `./scripts/lint-metrics-format.sh` | No errors |
| Health checks pass locally | `docker compose -f ci/compose/health-smoke.yml up` | All services exit with code 0 |
| CI pipeline passes | GitHub Actions | All checks pass |
| CHANGELOG updated | View CHANGELOG.md | Version bumped with your changes listed |

Pull request steps:
1. Ensure any install or build dependencies are removed before the end of the layer when doing a build.
2. Update relevant documentation (README.md, CHANGELOG.md, etc.).
3. Increase version numbers according to [Semantic Versioning](https://semver.org/).
4. Complete the full PR template checklist.
5. Get review from at least two team members from relevant teams.
6. CI checks must pass before merging.

## Any contributions you make will be under the MIT Software License

When you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project.

## Report bugs using GitHub's [issue tracker](https://github.com/your-org/alfred-agent-platform-v2/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/your-org/alfred-agent-platform-v2/issues/new).

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## License

By contributing, you agree that your contributions will be licensed under its MIT License.
