#!/bin/bash
# Script to restart mission-control in development mode

# Stop any running Next.js servers
echo "Stopping any running Next.js servers..."
fuser -k 3007/tcp 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true

# Kill any Docker containers for mission-control
echo "Stopping mission-control Docker containers..."
docker stop mission-control 2>/dev/null || true
docker stop mission-control-dev 2>/dev/null || true

# Navigate to project directory
cd "$(dirname "$0")"
echo "Working directory: $(pwd)"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Start in development mode
echo "Starting Next.js development server on port 3007..."
NODE_ENV=development npx next dev -p 3007 &

# Save PID for later reference
echo $! > /tmp/mission-control-dev.pid

echo "Development server started with PID: $(cat /tmp/mission-control-dev.pid)"
echo "Access the application at: http://localhost:3007"
