#!/bin/bash
# Quick script to improve health check settings in docker-compose-clean.yml

# Make a backup of the original file
cp docker-compose-clean.yml docker-compose-clean.yml.bak-$(date +"%Y%m%d-%H%M%S")

# Modify health check settings - increase timeout, retries, and start period
sed -i 's/interval: 20s/interval: 30s/' docker-compose-clean.yml
sed -i 's/timeout: 10s/timeout: 20s/' docker-compose-clean.yml
sed -i 's/retries: 3/retries: 5/' docker-compose-clean.yml
sed -i 's/start_period: 10s/start_period: 45s/' docker-compose-clean.yml

# Optionally update specific services with longer start periods
# This will affect services that might need extra time
sed -i 's/start_period: 30s/start_period: 60s/' docker-compose-clean.yml

echo "Health check settings have been updated:"
echo "- Interval: 30s (was 20s)"
echo "- Timeout: 20s (was 10s)"
echo "- Retries: 5 (was 3)"
echo "- Start period: 45s (was 10s)"
echo "- Longer start periods: 60s (was 30s)"
echo
echo "To apply these changes, restart services with:"
echo "./start-platform.sh -a restart"
