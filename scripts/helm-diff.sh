#!/bin/bash
# Script to simulate helm diff for GA deployment

NS=${1:-metrics}
GA_TAG=${2:-v0.8.1}

echo "Helm diff for upgrade to $GA_TAG in namespace $NS"
echo "==========================================="
echo ""
echo "Changes to be applied:"
echo ""
echo "--- Current Production Values"
echo "+++ New GA Values"
echo ""
echo "@@ -1,5 +1,5 @@"
echo "  image:"
echo "    repository: ghcr.io/alfred/db-metrics"
echo "-   tag: v0.8.0"
echo "+   tag: v0.8.1"
echo "    pullPolicy: IfNotPresent"
echo ""
echo "@@ -10,7 +10,9 @@"
echo "  environment:"
echo "    DB_USER: postgres"
echo "    DB_NAME: postgres"
echo "+   DEBUG_MODE: \"false\""
echo ""
echo "Summary:"
echo "- Image tag update: v0.8.0 -> v0.8.1"
echo "- Added DEBUG_MODE environment variable"
echo "- No other configuration changes"