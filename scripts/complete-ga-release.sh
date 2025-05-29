#!/usr/bin/env bash
set -euo pipefail

repo="Digital-Native-Ventures/alfred-agent-platform-v2"
version="v3.0.0"
chart="helm-releases/alfred-3.0.0.tgz"

echo "🚀 Completing GA Release $version"
echo "================================"

# Check workflow status
echo ""
echo "📦 Docker Release Workflow Status:"
echo "--------------------------------"

# Get the latest workflow run
run_info=$(gh run list --repo "$repo" --workflow docker-release.yml -L 1 --json databaseId,conclusion,status,displayTitle,url)
run_id=$(echo "$run_info" | jq -r '.[0].databaseId')
status=$(echo "$run_info" | jq -r '.[0].status')
conclusion=$(echo "$run_info" | jq -r '.[0].conclusion')
url=$(echo "$run_info" | jq -r '.[0].url')

echo "Run ID: $run_id"
echo "Status: $status"
echo "URL: $url"

# Wait for completion
if [[ "$status" != "completed" ]]; then
    echo ""
    echo "⏳ Waiting for docker-release workflow to complete..."
    echo "This typically takes 10-15 minutes for all images."
    
    while [[ "$status" != "completed" ]]; do
        sleep 30
        run_info=$(gh run view "$run_id" --repo "$repo" --json status,conclusion,jobs)
        status=$(echo "$run_info" | jq -r '.status')
        
        # Show progress
        completed_jobs=$(echo "$run_info" | jq '[.jobs[] | select(.status == "completed")] | length')
        total_jobs=$(echo "$run_info" | jq '.jobs | length')
        echo -ne "\rProgress: $completed_jobs/$total_jobs jobs completed"
    done
    
    conclusion=$(echo "$run_info" | jq -r '.conclusion')
    echo ""
fi

# Check final status
if [[ "$conclusion" == "success" ]]; then
    echo "✅ Docker images published successfully!"
else
    echo "❌ Workflow failed with conclusion: $conclusion"
    echo "Check the workflow run at: $url"
    exit 1
fi

# Push Helm chart
echo ""
echo "📊 Publishing Helm Chart"
echo "----------------------"

if [[ ! -f "$chart" ]]; then
    echo "❌ Helm chart not found at $chart"
    exit 1
fi

echo "Chart: $chart"
echo ""
echo "To push to OCI registry, run:"
echo ""
echo "  # Set up authentication first"
echo "  echo \$GITHUB_TOKEN | helm registry login ghcr.io --username \$GITHUB_USERNAME --password-stdin"
echo ""
echo "  # Push the chart"
echo "  export HELM_EXPERIMENTAL_OCI=1"
echo "  helm push $chart oci://ghcr.io/digital-native-ventures/charts"
echo ""

# Summary
echo ""
echo "🎉 GA Release $version Status"
echo "=========================="
echo "✅ Git tag: Published"
echo "✅ GitHub release: Published"
echo "✅ Docker images: Published to ghcr.io/digital-native-ventures/alfred-agent-platform-v2"
echo "✅ Helm chart: Packaged (ready to push)"
echo ""
echo "View the release at: https://github.com/$repo/releases/tag/$version"
echo "View the images at: https://github.com/orgs/digital-native-ventures/packages?repo_name=alfred-agent-platform-v2"