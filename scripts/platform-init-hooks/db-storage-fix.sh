#!/bin/bash
# DB Storage Fix Hook - runs before db-storage service is started
# This script is automatically called by start-platform.sh when starting db-storage

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "[DB Storage Fix] Running pre-start fixes..."

# Check if we need to fix db-storage
if [ -f "$PLATFORM_DIR/.db_storage_fixed" ]; then
    echo "[DB Storage Fix] Fix already applied, skipping"
    exit 0
fi

# Run the fix script
echo "[DB Storage Fix] Applying fixes to database..."
docker run --rm --network alfred-network \
    -v "$PLATFORM_DIR/scripts/fix-db-storage.sh:/fix-script.sh" \
    postgres:15-alpine sh -c "apk add --no-cache postgresql-client && chmod +x /fix-script.sh && /fix-script.sh"

# Mark as fixed
touch "$PLATFORM_DIR/.db_storage_fixed"
echo "[DB Storage Fix] Fixes applied successfully"