#!/bin/bash
# Script to bump image tags in services

if [ $# -lt 2 ]; then
    echo "Usage: $0 <service-name> <tag>"
    exit 1
fi

SERVICE=$1
TAG=$2

echo "Bumping image tag for service $SERVICE to $TAG"

# Use yq to update the dbMetrics image tag
if [ "$SERVICE" == "metrics" ] || [ "$SERVICE" == "db-metrics" ]; then
    echo "Updating dbMetrics.image.tag in charts/alfred/values.yaml"
    yq -i ".dbMetrics.image.tag = \"$TAG\"" charts/alfred/values.yaml
    echo "Updated dbMetrics image tag to $TAG"
else
    echo "Service $SERVICE not recognized"
    exit 1
fi

echo "Image tag bump complete"
