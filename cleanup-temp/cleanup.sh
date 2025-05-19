#!/bin/bash
# Script to move untracked files to a backup directory

BACKUP_DIR="cleanup-temp/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

while read -r file; do
  # Create directory structure if needed
  dir=$(dirname "$file")
  mkdir -p "$BACKUP_DIR/$dir"

  # Move file to backup directory with same structure
  mv "$file" "$BACKUP_DIR/$file"
  echo "Moved: $file"
done < cleanup-temp/untracked-files.txt

echo "Files have been moved to $BACKUP_DIR"
echo "To restore them, use: cp -r $BACKUP_DIR/* ."
