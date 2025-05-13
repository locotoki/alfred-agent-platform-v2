# Contributing to Alfred Agent Platform v2

We love your input! We want to make contributing to this project as easy and transparent as possible. This guide ensures all changes follow our lean-first, metrics-driven workflow.

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests. Our development process follows a phased approach:

- **Phase 0**: Foundational changes with basic metrics and monitoring
- **Phase 1**: Enhanced metrics with service_health gauges
- **Phase 2**: Advanced metrics with custom service-specific metrics

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

## Metrics and Monitoring Standards

All services MUST implement:
- `/health` endpoint with detailed status
- `/healthz` endpoint for simple health probes
- `/metrics` endpoint in Prometheus format

New or modified services MUST:
- Use the latest healthcheck binary (currently v0.4.0)
- Expose metrics on port 9091
- Include the `service_health` gauge metric
- Follow standard metric naming conventions
- Update Grafana dashboards when adding metrics

## Pull Request Process

Before creating a pull request, ensure you've completed the CI Sanity Checklist:

| Check | Command / URL | Pass Criteria |
|-------|--------------|---------------|
| Local metrics reach Prometheus | `curl -s http://localhost:9090/api/v1/query?query=service_health` | JSON returns data.series > 0 for every service |
| Grafana panels populated | Open Dashboard | Panels show green ✓ for each service |
| Metrics lint script green | `./scripts/lint-metrics-format.sh` | No errors |
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
