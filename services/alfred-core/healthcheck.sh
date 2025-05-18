#!/bin/bash
# Simple healthcheck script
set -e

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed" >&2
    exit 1
fi

# Check application health
HEALTH_URL="http://localhost:8011/health"
if curl -f -s "$HEALTH_URL" > /dev/null; then
    echo "Service is healthy"
    exit 0
else
    echo "Service is unhealthy" >&2
    exit 1
fi
