#!/bin/bash
# Script to clean up all Grafana dashboards except the Platform Health Dashboard
#
# This script is used to clean up Grafana's database and remove any dashboards
# that were previously created but are no longer needed. This helps maintain
# a clean, well-organized Grafana instance.
#
# Usage: ./cleanup-dashboards.sh

KEEP_UID="platform-health-dashboard"
GRAFANA_URL="http://localhost:3005"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

# Get all dashboard UIDs
UIDS=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/search?type=dash-db" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)

echo "Cleaning up Grafana dashboards..."
echo "--------------------------------"
echo "Keeping dashboard with UID: $KEEP_UID"
echo

# Delete all dashboards except the one we want to keep
for uid in $UIDS; do
  if [ "$uid" != "$KEEP_UID" ]; then
    echo "Deleting dashboard with UID: $uid"
    curl -s -X DELETE -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/dashboards/uid/$uid" > /dev/null
  fi
done

echo
echo "Cleaning up dashboard folders..."

# Get all folder UIDs
FOLDER_UIDS=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/folders" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)

# Only keep the Platform folder
for uid in $FOLDER_UIDS; do
  if [ "$uid" != "platform" ]; then
    echo "Deleting folder with UID: $uid"
    curl -s -X DELETE -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/folders/$uid" > /dev/null
  fi
done

echo
echo "Dashboard cleanup complete!"