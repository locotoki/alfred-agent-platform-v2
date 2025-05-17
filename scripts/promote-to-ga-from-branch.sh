#!/bin/bash
# Script to promote release candidate to GA from any branch

set -e

# Parse arguments
DRY_RUN=false
GA_TAG=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            GA_TAG="$1"
            shift
            ;;
    esac
done

if [ -z "$GA_TAG" ]; then
    echo "Error: GA_TAG is required"
    echo "Usage: $0 [--dry-run] <GA_TAG>"
    exit 1
fi

# Ensure we're in the repository root
cd "$(git rev-parse --show-toplevel)"

echo "Promoting to GA: $GA_TAG"
echo "Dry run: $DRY_RUN"
echo ""

if [ "$DRY_RUN" == "true" ]; then
    echo "=== DRY RUN MODE ==="
    echo ""
fi

echo "1. Updating Helm chart version to ${GA_TAG#v}"
if [ "$DRY_RUN" == "false" ]; then
    sed -i ".version = \"${GA_TAG#v}\"" charts/alfred/Chart.yaml
else
    echo "Would update charts/alfred/Chart.yaml version to ${GA_TAG#v}"
fi

echo ""
echo "2. Updating image tags to $GA_TAG"
if [ "$DRY_RUN" == "false" ]; then
    sed -i ".dbMetrics.image.tag = \"$GA_TAG\"" charts/alfred/values.yaml
else
    echo "Would update dbMetrics.image.tag to $GA_TAG"
fi

echo ""
echo "3. Verifying changes"
if [ "$DRY_RUN" == "false" ]; then
    echo "Chart version: $(yq '.version' charts/alfred/Chart.yaml)"
    echo "Image tag: $(yq '.dbMetrics.image.tag' charts/alfred/values.yaml)"
else
    echo "Would verify chart and image tag updates"
fi

echo ""
if [ "$DRY_RUN" == "true" ]; then
    echo "=== DRY RUN COMPLETE ==="
else
    echo "=== GA Promotion Updates Complete ==="
fi

echo ""
echo "Next steps:"
echo "1. Update CHANGELOG.md"
echo "2. Commit changes"
echo "3. Wait for Coordinator sign-off"
echo "4. Push to main and create GA tag"
echo "5. Deploy to production"