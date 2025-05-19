#!/bin/bash
set -e

echo "Starting storage-api service with patched migrations..."

# Apply the migration patch to disable hash validation
node /app/patch-migrations.js

# Set environment variables for storage-api
export SKIP_MIGRATIONS=false
export PGRST_JWT_SECRET=${JWT_SECRET:-super-secret-jwt-token}

# Start the storage-api service
echo "Starting storage-api service..."
exec node dist/server.js
