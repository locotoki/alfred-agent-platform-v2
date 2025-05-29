#\!/usr/bin/env bash
set -euo pipefail

repo="Digital-Native-Ventures/alfred-agent-platform-v2"
run_id="15311948087"          # last docker-release workflow run
version="v3.0.0"
chart="helm-releases/alfred-3.0.0.tgz"

# 1️⃣  Block until the docker-release workflow completes successfully
echo "⏳ Waiting for docker-release workflow $run_id to finish…"
gh run watch "$run_id" --repo "$repo" --exit-status

# 2️⃣  Verify conclusion
conclusion=$(gh run view "$run_id" --repo "$repo" --json conclusion -q .conclusion)
[[ "$conclusion" == "success" ]] || { echo "❌ Workflow failed: $conclusion"; exit 1; }
echo "✅ Images for $version published to GHCR."

# 3️⃣  Push Helm chart to OCI registry
echo "$GITHUB_TOKEN"  < /dev/null |  helm registry login ghcr.io \\
  --username "${GITHUB_USERNAME:-github}" --password-stdin
export HELM_EXPERIMENTAL_OCI=1
helm push "$chart" oci://ghcr.io/digital-native-ventures/charts

echo "🎉 v3.0.0 GA release fully published (images + chart)."
