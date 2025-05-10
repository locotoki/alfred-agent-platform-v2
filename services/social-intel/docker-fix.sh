#!/bin/bash
# Script to directly modify the main.py file inside the container

echo "Updating social-intel API to properly handle JSON payloads..."

# Make sure Request is imported
docker exec social-intel bash -c 'grep -q "from fastapi import FastAPI, HTTPException, Query, Request" /app/app/main.py || sed -i "s/from fastapi import FastAPI, HTTPException, Query/from fastapi import FastAPI, HTTPException, Query, Request/g" /app/app/main.py'

# Create a backup of the main.py file
docker exec social-intel bash -c 'cp /app/app/main.py /app/app/main.py.bak'
echo "Created backup at /app/app/main.py.bak"

# Replace the niche-scout route implementations with the fixed version
docker exec social-intel bash -c 'sed -i "/def run_niche_scout/,/def get_workflow_result_endpoint/ s/return await run_niche_scout(query, category, subcategory)/return await run_niche_scout(request, query, category, subcategory)/g" /app/app/main.py'
echo "Updated function calls"

# Copy the fixed implementation to a temporary file and insert it
docker cp /home/locotoki/projects/alfred-agent-platform-v2/services/social-intel/app/fixed_route.py social-intel:/app/fixed_route.py

# Find the line numbers where the niche-scout endpoint is defined
NICHE_SCOUT_LINE=$(docker exec social-intel bash -c 'grep -n "@app.post(\"/niche-scout\")" /app/app/main.py | cut -d: -f1')
SEED_TO_BLUEPRINT_LINE=$(docker exec social-intel bash -c 'grep -n "@app.post(\"/seed-to-blueprint\")" /app/app/main.py | cut -d: -f1')

echo "Niche scout endpoint found at line $NICHE_SCOUT_LINE"
echo "Next endpoint starts at line $SEED_TO_BLUEPRINT_LINE"

# Calculate the range of lines to replace
RANGE_START=$NICHE_SCOUT_LINE
RANGE_END=$(($SEED_TO_BLUEPRINT_LINE - 1))

echo "Replacing lines $RANGE_START to $RANGE_END with fixed implementation"

# Create a temporary file with the fixed implementation to insert
docker exec social-intel bash -c "sed -i '${RANGE_START},${RANGE_END}d' /app/app/main.py"
docker exec social-intel bash -c "sed -i '${RANGE_START}i\\' /app/app/main.py"
docker exec social-intel bash -c "sed -i '${RANGE_START}r /app/fixed_route.py' /app/app/main.py"

echo "Fixed implementation inserted into main.py"

# Restart the service
echo "Restarting social-intel service..."
docker restart social-intel

echo "Done! Social-intel service now properly handles JSON payloads."