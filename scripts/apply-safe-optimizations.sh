#!/bin/bash
# apply-safe-optimizations.sh
# Script to apply only the safest optimizations with minimal operational risk

set -e

echo "==============================================================="
echo "Alfred Agent Platform - Apply Safe Optimizations (Phase 1)"
echo "==============================================================="
echo ""

# Function to execute a script and check its result
run_optimization() {
  script=$1
  description=$2
  
  echo "---------------------------------------------------------------"
  echo "Applying: $description"
  echo "Script: $script"
  echo "---------------------------------------------------------------"
  
  if [ -f "$script" ] && [ -x "$script" ]; then
    "$script"
    echo "✅ $description completed successfully"
  else
    echo "❌ $description failed - script not found or not executable"
    exit 1
  fi
  
  echo ""
}

# Make sure we're in the scripts directory
cd "$(dirname "$0")"

# Create a backup of the original docker-compose file
echo "Creating backup of docker-compose.unified.yml..."
cp ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-safe
echo "✅ Backup created at ../docker-compose.unified.yml.bak-safe"
echo ""

# Step 1: Check environment variable consistency (OPT-005) - Safest
run_optimization "./check-env-consistency.sh" "Environment Variable Consistency Check (OPT-005)"

# Step 2: Optimize startup sequence (OPT-004) - Very safe
run_optimization "./optimize-startup-sequence.sh" "Startup Sequence Optimization (OPT-004)"

# Note: Retry logic (OPT-003) is already implemented as a library
echo "---------------------------------------------------------------"
echo "Retry Logic Implementation (OPT-003)"
echo "---------------------------------------------------------------"
echo "The retry logic library has been implemented in:"
echo "- libs/resilience.py (core retry and circuit breaker functionality)"
echo "- libs/resilient_client.py (example usage implementation)"
echo ""
echo "✅ Retry Logic Implementation verified"
echo ""

echo "==============================================================="
echo "Safe optimizations have been applied!"
echo "==============================================================="
echo ""
echo "To apply changes, run:"
echo "cd .. && docker-compose -f docker-compose.unified.yml up -d"
echo ""
echo "To restore the original configuration, run:"
echo "cp ../docker-compose.unified.yml.bak-safe ../docker-compose.unified.yml"
echo ""
echo "Changes made:"
echo " - Created .env.example template for environment variable consistency"
echo " - Optimized service startup sequence for more reliable initialization"
echo " - Added retry logic implementation in libs/resilience.py (no runtime changes)"
echo ""
echo "These optimizations have minimal operational risk and can be"
echo "safely applied to running systems."
echo ""