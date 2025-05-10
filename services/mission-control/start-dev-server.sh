#!/bin/bash

# A simplified script to start the Mission Control UI in development mode
# This avoids the build step which is having issues

echo "Starting Mission Control in development mode..."

# Change to the mission-control directory
cd "$(dirname "$0")"

# Kill any existing Next.js processes
pkill -f "next" || echo "No Next.js processes running"

# Start the development server on port 3003
echo "Starting development server on port 3003..."
npm run dev