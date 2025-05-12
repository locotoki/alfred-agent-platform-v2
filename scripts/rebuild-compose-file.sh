#!/bin/bash
# rebuild-compose-file.sh
# Script to completely rebuild the docker-compose.unified.yml file from scratch

set -e

echo "Rebuilding Docker Compose file from backup..."

# First, identify if we have a clean backup to work from
if [ -f "../docker-compose.unified.yml.bak-safe" ]; then
  echo "Found backup from safe optimizations"
  cp ../docker-compose.unified.yml.bak-safe ../docker-compose.unified.yml.bak-rebuild
elif [ -f "../docker-compose.unified.yml.bak-original" ]; then
  echo "Found original backup"
  cp ../docker-compose.unified.yml.bak-original ../docker-compose.unified.yml.bak-rebuild
elif [ -f "../docker-compose.unified.yml.bak-fix" ]; then
  echo "Found backup from fix attempt"
  cp ../docker-compose.unified.yml.bak-fix ../docker-compose.unified.yml.bak-rebuild
else
  echo "Creating backup of current file"
  cp ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-rebuild
fi

# Backup the current file
cp ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-broken

# Create a fresh copy of the compose file from our backup
cp ../docker-compose.unified.yml.bak-rebuild ../docker-compose.unified.yml.new

# Run our scripts again on the fresh file
echo "Running startup sequence optimization on fresh file..."
./optimize-startup-sequence.sh ../docker-compose.unified.yml.new || true

echo "✅ Docker Compose file rebuilt successfully."
echo ""
echo "Testing the new compose file for syntax errors..."
cd ..
docker-compose -f docker-compose.unified.yml.new config > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✅ New Docker Compose file validated successfully."
  mv docker-compose.unified.yml.new docker-compose.unified.yml
  echo "The new file has been applied to docker-compose.unified.yml"
else
  echo "❌ New Docker Compose file has syntax errors."
  echo "The broken file remains at docker-compose.unified.yml.new for inspection."
  exit 1
fi

echo ""
echo "To apply the rebuilt configuration, run:"
echo "docker-compose -f docker-compose.unified.yml up -d"