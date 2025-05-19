#!/bin/bash
# Script to bump Helm chart version

if [ $# -lt 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1

echo "Bumping Helm chart version to $VERSION"

# Update the Chart.yaml version
yq -i ".version = \"$VERSION\"" charts/alfred/Chart.yaml

echo "Helm chart version updated to $VERSION"
