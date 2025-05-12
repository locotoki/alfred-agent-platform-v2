#!/bin/bash
# fix-compose-file.sh
# Script to fix duplicate depends_on sections in the docker-compose.unified.yml file

set -e

echo "Fixing Docker Compose file syntax issues..."

# Backup the current file
cp ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-fix

# The problem is that there are duplicate 'depends_on:' sections in some services
# Let's fix this by keeping only one depends_on section per service

# First, identify the services with the issue
services_with_issues=$(grep -n "condition: service_" ../docker-compose.unified.yml | grep -v "depends_on" | cut -d':' -f1)

# For each line with an issue, find the service it belongs to and fix it
for line in $services_with_issues; do
  # Get the current line content
  current_line=$(sed "${line}q;d" ../docker-compose.unified.yml)
  
  # Extract service name by looking backwards for the service definition
  service_start_line=$(grep -n "^  [a-zA-Z0-9_-]\+:" ../docker-compose.unified.yml | 
                      awk -F: '$1 < '$line' {print $1}' | 
                      tail -1)
  
  service_name=$(sed "${service_start_line}q;d" ../docker-compose.unified.yml | 
                grep -o "^  [a-zA-Z0-9_-]\+:" | 
                tr -d ' :')
  
  echo "Fixing service: $service_name"
  
  # Remove the invalid condition line and properly format the file
  sed -i "${line}d" ../docker-compose.unified.yml
done

# Now check if there are any lingering condition lines without depends_on
while true; do
  orphaned_conditions=$(grep -n "condition: service_" ../docker-compose.unified.yml | grep -v "depends_on" | wc -l)
  
  if [ "$orphaned_conditions" -eq 0 ]; then
    break
  fi
  
  orphaned_line=$(grep -n "condition: service_" ../docker-compose.unified.yml | grep -v "depends_on" | head -1 | cut -d':' -f1)
  sed -i "${orphaned_line}d" ../docker-compose.unified.yml
  echo "Removed orphaned condition at line $orphaned_line"
done

echo "✅ Docker Compose file fixed."
echo ""
echo "The original file is backed up at ../docker-compose.unified.yml.bak-fix"
echo "To apply the changes, run:"
echo "cd .. && docker-compose -f docker-compose.unified.yml up -d"