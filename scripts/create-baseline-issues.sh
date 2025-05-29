#!/usr/bin/env bash
set -euo pipefail
repo="Digital-Native-Ventures/alfred-agent-platform-v2"
project="Baseline Stabilization"
milestone="Baseline Stabilization"

for t in \
  "Add SBOM & licence scan (cyclonedx + licence-guard)" \
  "Nightly compose.slim smoke via cron" \
  "Trivy image scan gate in docker-release.yml" \
  "Enable Renovate for Python and Docker deps" \
  "Publish MkDocs site from docs/"; do
  num=$(gh issue create --repo "$repo" --title "$t" \
        --label enhancement --milestone "$milestone" \
        --json number -q '.number')
  gh project item-add "$project" --issue "$num"
  echo "Opened #$num – $t"
done