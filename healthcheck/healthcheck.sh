#\!/bin/bash
# Simple healthcheck script for agent-core
curl -f http://localhost:8011/health || exit 1
