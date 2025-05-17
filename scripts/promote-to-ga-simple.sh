#!/bin/bash
# Simplified GA promotion script

GA_TAG="$1"
if [ -z "$GA_TAG" ]; then
    echo "Error: GA_TAG is required"
    echo "Usage: $0 <GA_TAG>"
    exit 1
fi

echo "Promoting to GA: $GA_TAG"

# Update Chart.yaml version
echo "Updating Chart.yaml version to ${GA_TAG#v}"
sed -i "s/^version: .*/version: ${GA_TAG#v}/" charts/alfred/Chart.yaml

# Update values.yaml image tags
echo "Updating image tags to $GA_TAG"
sed -i "s/tag: v0\.8\.1-rc[0-9]*/tag: $GA_TAG/g" charts/alfred/values.yaml

echo "GA Promotion Updates Complete"
echo ""
echo "Next steps:"
echo "1. Commit changes"
echo "2. Push to main"
echo "3. Deploy to production"