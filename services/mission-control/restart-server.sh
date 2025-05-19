#!/bin/bash

# Restart Mission Control server script
echo "Restarting Mission Control server..."

# Find and kill any existing Next.js processes
echo "Stopping existing server..."
pkill -f "next start" || echo "No running Next.js server found."

# Clear Next.js cache to ensure changes take effect
echo "Clearing Next.js cache..."
rm -rf .next/cache

# Build the application
echo "Building application..."
npm run build

# Start the server on port 3007
echo "Starting server on port 3007..."
nohup npm run start > server.log 2>&1 &

# Wait for server to start
echo "Waiting for server to start..."
sleep 3

# Print startup message
echo -e "\n======================="
echo "Server restarted successfully!"
echo "Access the application at: http://localhost:3007"
echo "Check server.log for details"
echo "======================="
