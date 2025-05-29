#!/usr/bin/env bash
set -euo pipefail

repo="Digital-Native-Ventures/alfred-agent-platform-v2"
version="v3.0.0"

echo "⏳ Monitoring docker-release workflow for $version..."
echo "Started at: $(date)"

while true; do
    # Get the latest run status
    status_json=$(gh run list --repo "$repo" --workflow docker-release.yml -L 1 --json databaseId,conclusion,status,displayTitle,name)
    
    # Extract fields
    status=$(echo "$status_json" | jq -r '.[0].status')
    conclusion=$(echo "$status_json" | jq -r '.[0].conclusion')
    run_id=$(echo "$status_json" | jq -r '.[0].databaseId')
    
    # Display current status
    echo -ne "\r[$(date +%H:%M:%S)] Status: $status"
    
    # Check if completed
    if [[ "$status" == "completed" ]]; then
        echo ""
        if [[ "$conclusion" == "success" ]]; then
            echo "✅ Docker images published successfully!"
            echo "View run: https://github.com/$repo/actions/runs/$run_id"
            exit 0
        else
            echo "❌ Workflow failed with conclusion: $conclusion"
            echo "View run: https://github.com/$repo/actions/runs/$run_id"
            exit 1
        fi
    fi
    
    # Wait before next check
    sleep 10
done