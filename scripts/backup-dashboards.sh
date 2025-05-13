#!/bin/bash
# Script to backup Grafana dashboards to the repository

set -e

BACKUP_DIR="monitoring/grafana/dashboards/backup"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Backing up Grafana dashboards..."

# Backup health dashboard
echo "Backing up Platform Health Dashboard..."
curl -s -X GET "http://admin:admin@localhost:3005/api/dashboards/uid/platform-health-dashboard" | jq '.dashboard' > "$BACKUP_DIR/platform-health-dashboard-$TIMESTAMP.json"

# Additional dashboards can be added here

echo "✅ Dashboard backups completed and saved to $BACKUP_DIR"
echo "To commit these backups, run:"
echo "  git add $BACKUP_DIR"
echo "  git commit -m \"chore: Backup Grafana dashboards - $TIMESTAMP\""

# If you want to skip manual curl and prefer to export through the UI:
echo ""
echo "Alternative manual export steps:"
echo "1. Open Grafana at http://localhost:3005"
echo "2. Navigate to the dashboard you want to backup"
echo "3. Click Share button (top right) → Export → Export for sharing externally (JSON)"
echo "4. Save the JSON to $BACKUP_DIR/dashboard-name-$TIMESTAMP.json"
echo "5. Commit the file to the repository"