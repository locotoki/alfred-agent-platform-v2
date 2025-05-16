#!/bin/bash
# Script to announce deployments in Slack

if [ $# -lt 1 ]; then
    echo "Usage: $0 <message>"
    exit 1
fi

MESSAGE=$1

echo "Would send the following message to Slack channel #alfred-deployments:"
echo "$MESSAGE"
echo
echo "Deployment details:"
echo "- Version: v0.8.1-rc2"
echo "- Services: db-metrics"
echo "- Environment: staging"
echo "- Deployed at: $(date)"
echo "- Metrics dashboard: http://grafana.metrics.svc:3000/d/metrics-health/metrics-health-dashboard"