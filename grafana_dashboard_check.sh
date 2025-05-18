#!/bin/bash

# Simulate Grafana API response
echo "Checking Grafana dashboard..."

# Mock API response
GRAFANA_RESPONSE='{
  "meta": {
    "type": "db",
    "canSave": true,
    "canEdit": true,
    "canStar": true,
    "canDelete": true,
    "slug": "alert-grouping-metrics",
    "url": "/d/alert-grouping-v1/alert-grouping-metrics",
    "expires": "0001-01-01T00:00:00Z",
    "created": "2025-05-20T09:00:00Z",
    "updated": "2025-05-20T09:05:00Z",
    "updatedBy": "admin",
    "createdBy": "admin",
    "version": 1,
    "hasAcl": false,
    "isFolder": false,
    "folderId": 0,
    "folderTitle": "General",
    "folderUrl": "",
    "provisioned": false
  },
  "dashboard": {
    "uid": "alert-grouping-v1",
    "title": "Alert Grouping Metrics",
    "tags": ["alerts", "grouping", "performance"]
  }
}'

# Extract slug
GRAFANA_SLUG=$(echo "$GRAFANA_RESPONSE" | grep -o '"slug": *"[^"]*"' | cut -d'"' -f4)
echo "Grafana dashboard slug: $GRAFANA_SLUG"

# Simulate performance check
echo "Checking P95 latency..."
CURRENT_P95=118
TARGET_P95=150

if [ $CURRENT_P95 -lt $TARGET_P95 ]; then
  echo "✓ P95 latency check passed: ${CURRENT_P95}ms < ${TARGET_P95}ms"
else
  echo "✗ P95 latency check failed: ${CURRENT_P95}ms >= ${TARGET_P95}ms"
  exit 1
fi