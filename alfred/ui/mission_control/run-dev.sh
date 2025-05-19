#!/bin/bash

# A simple script to run the mission control server using the custom development script

echo "Starting Mission Control with custom development server..."

# Change to the mission-control directory
cd "$(dirname "$0")"

# Kill any existing Node processes running Next.js
pkill -f "node.*next" || echo "No Next.js processes running"

# Run the custom Next.js development server
echo "Starting development server on port 3007..."
node next.dev.js
