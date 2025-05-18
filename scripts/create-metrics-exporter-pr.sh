#!/bin/bash
# Script to create a PR for the metrics exporter changes

set -e

# Create a new branch
git checkout -b feat/phase1-metrics-exporter

# Stage the files
git add services/rag-service/Dockerfile
git add services/financial-tax/Dockerfile
git add services/legal-compliance/Dockerfile
git add services/social-intel/Dockerfile
git add services/alfred-bot/Dockerfile
git add rag-gateway/Dockerfile
git add monitoring/prometheus/prometheus.yml
git add monitoring/grafana/dashboards/platform/health-dashboard.json
git add docker-compose-clean.yml
git add scripts/update-healthcheck-binary.sh
git add scripts/lint-metrics-format.sh
git add scripts/test-metrics-ports.sh
git add docs/METRICS_EXPORTER_UPGRADE.md
git add CHANGELOG.md
git add README.md

# Commit the changes
git commit -m "feat: Implement Phase 1 metrics exporter

- Upgrade healthcheck binary to v0.4.0
- Add metrics port exposure (9091) to all services
- Configure healthcheck binary to export Prometheus metrics
- Update Prometheus configuration to collect service_health metrics
- Update Grafana dashboard to visualize service_health metrics
- Tighten health check timings for different service classes
- Add metrics linting and testing scripts
- Update documentation and version to v0.2.0-phase1

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to remote (uncomment when ready)
# git push -u origin feat/phase1-metrics-exporter

echo "Created branch 'feat/phase1-metrics-exporter' and committed changes."
echo "To push to remote and create a PR, run:"
echo "  git push -u origin feat/phase1-metrics-exporter"
echo ""
echo "After PR is approved and merged, tag the release:"
echo "  ./scripts/tag-release.sh"
echo "  gh pr create --title \"feat: Implement Phase 1 metrics exporter\" --body \"## Summary
- Upgrade healthcheck binary to v0.4.0
- Add metrics port exposure (9091) to all services
- Configure healthcheck binary to export Prometheus metrics
- Update Prometheus configuration to collect service_health metrics
- Update Grafana dashboard to visualize service_health metrics
- Tighten health check timings for different service classes
- Add metrics linting and testing scripts
- Update documentation and version to v0.2.0-phase1

## Documentation
See detailed documentation in [METRICS_EXPORTER_UPGRADE.md](docs/METRICS_EXPORTER_UPGRADE.md).

## Test plan
1. Apply changes with ./scripts/update-healthcheck-binary.sh
2. Rebuild and restart services
3. Check metrics endpoints with ./scripts/test-metrics-ports.sh
4. Validate metrics format with ./scripts/lint-metrics-format.sh
5. Verify Grafana dashboard at http://localhost:3005/d/platform-health-dashboard

## Checklist
- [ ] Build passes in GitHub Actions
- [ ] Lint checks pass
- [ ] Monitoring validation passes
- [ ] All services expose metrics on port 909x
- [ ] Grafana dashboard shows service_health metrics

## Merge Strategy
Squash-merge into main and tag the merge commit as v0.2.0-phase1.

🤖 Generated with Claude Code\" --reviewers DevOps,QA"
