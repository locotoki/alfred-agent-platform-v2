#!/bin/bash
# Bump version script

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

# Update VERSION file
echo "$VERSION" > VERSION

# Update Chart.yaml
sed -i "s/^version: .*/version: $VERSION/" charts/alfred/Chart.yaml
sed -i "s/^appVersion: .*/appVersion: \"$VERSION\"/" charts/alfred/Chart.yaml

echo "Version bumped to $VERSION"