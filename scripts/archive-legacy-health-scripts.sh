#!/usr/bin/env bash
# Script to archive legacy health check scripts

set -eo pipefail

echo "Archiving legacy health check scripts..."

# Create archive directory if it doesn't exist
ARCHIVE_DIR="archive/legacy-health-scripts"
mkdir -p "$ARCHIVE_DIR"

# List of scripts to archive
SCRIPTS=(
  "./healthcheck.sh"
  "./scripts/bump-healthcheck.sh"
  "./update-health-endpoints.sh"
)

# Move each script to the archive
for script in "${SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    echo "Archiving $script..."
    # Create directories in archive if needed
    mkdir -p "$ARCHIVE_DIR/$(dirname "$script")"
    # Move the file
    cp "$script" "$ARCHIVE_DIR/$script"
    # Remove the original
    git rm "$script"
  else
    echo "Warning: $script not found, skipping."
  fi
done

echo "Legacy health scripts have been archived to $ARCHIVE_DIR."
echo "You can now commit the changes."