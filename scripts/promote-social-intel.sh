#!/bin/bash
# Social-Intel Promotion Script
# Promotes the Social-Intel service from canary (10%) to full traffic (100%)

set -e  # Exit on error

echo "===== Social-Intel Service Promotion ====="
echo "This will promote Social-Intel from 10% to 100% traffic."
echo "Make sure you've monitored the service for at least 24 hours."
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Promotion cancelled."
  exit 1
fi

echo -e "\n[1/4] Checking current configuration..."
grep FEATURE_PROXY_ENABLED .env

echo -e "\n[2/4] Running pre-promotion load test..."
cd /home/locotoki/projects/alfred-agent-platform-v2/services/social-intel
npm run test:load:ci || {
  echo "WARNING: Load test failed. Promotion may be risky."
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Promotion cancelled."
    exit 1
  fi
}

echo -e "\n[3/4] Updating environment to 100% traffic..."
cd /home/locotoki/projects/alfred-agent-platform-v2
sed -i 's/FEATURE_PROXY_ENABLED=0.1/FEATURE_PROXY_ENABLED=1/' .env
echo "New configuration:"
grep FEATURE_PROXY_ENABLED .env

echo -e "\n[4/4] Restarting Mission Control to apply changes..."
docker compose restart mission-control

echo -e "\n===== Promotion Complete ====="
echo "Social-Intel service is now receiving 100% of traffic."
echo "Run monitoring script to verify performance:"
echo "  ./scripts/monitor-social-intel.sh"
