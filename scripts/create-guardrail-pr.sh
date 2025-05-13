#!/bin/bash
# Script to create a PR with the guardrail system

set -e

# Create branch
BRANCH="feat/guardrail-system"
git checkout -b $BRANCH

# Add all files
git add .github/
git add docs/_templates/
git add docs/operations/maintenance/QUARTERLY_HOUSEKEEPING.md
git add monitoring/grafana/provisioning/
git add monitoring/grafana/dashboards/README.md
git add services/_template/
git add scripts/bump-healthcheck.sh
git add scripts/backup-dashboards.sh
git add CONTRIBUTING.md

# Commit
git commit -m "feat: Add guardrail system for metrics-driven workflow

- Add PR template and CI gate workflow
- Update CONTRIBUTING.md with golden path documentation
- Add repository scaffolds and templates
- Set up CODEOWNERS file
- Implement dashboard-as-code structure
- Create scripts for healthcheck version management
- Document quarterly housekeeping process
- Add auto-tagging workflow for releases

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

# Instructions
echo "Guardrail system branch created: $BRANCH"
echo ""
echo "To push and create PR:"
echo "  git push -u origin $BRANCH"
echo "  gh pr create --title \"feat: Add guardrail system for metrics-driven workflow\" --body \"## Summary
- Add PR template and CI gate workflow
- Update CONTRIBUTING.md with golden path documentation
- Add repository scaffolds and templates
- Set up CODEOWNERS file
- Implement dashboard-as-code structure
- Create scripts for healthcheck version management
- Document quarterly housekeeping process
- Add auto-tagging workflow for releases

## Implementation
This PR adds a lightweight 'guard-rail' system that ensures every future change follows the same lean-first, metrics-driven workflow we've established with the recent metrics exporter implementation.

## Components
- 📜 **CONTRIBUTING.md**: Golden path documentation with branch naming, checklists, and required docs per phase
- 🔖 **PR template**: Auto-filled sections for context, checklists, and verification
- ✅ **CI Gate**: Fail-fast checks for metrics, healthcheck version, and dashboard validation
- 📁 **Repo scaffolds**: Service template with metrics configuration and design document templates
- 🏷 **Auto-tagging**: GitHub Action that tags vX.Y.Z-phase<n> when CHANGELOG.md is updated
- 🛡 **CODEOWNERS**: Ensures the right reviewers sign off on health-check or metrics tweaks
- 📊 **Dash-as-Code**: Structured dashboard provisioning for Grafana
- 🧹 **Quarterly housekeeping**: Documentation and process for regular maintenance

## Testing Done
- Validated all scripts locally
- Ensured templates match current best practices
- Verified CI workflow checks

## To Enable
After merging, update the branch protection rules to require the ci-pipeline check to pass.

🤖 Generated with Claude Code\" --reviewers DevOps,SRE,TechWriters"