#!/bin/bash
# apply-all-optimizations.sh
# Master script to apply all optimizations in the correct order

set -e

echo "==============================================================="
echo "Alfred Agent Platform - Apply All Optimizations"
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
cp ../docker-compose.unified.yml ../docker-compose.unified.yml.bak-original
echo "✅ Backup created at ../docker-compose.unified.yml.bak-original"
echo ""

# Step 1: Check environment variable consistency
run_optimization "./check-env-consistency.sh" "Environment Variable Consistency Check (OPT-005)"

# Step 2: Add container resource limits
run_optimization "./add-resource-limits.sh" "Container Resource Limits (OPT-001)"

# Step 3: Standardize health checks
run_optimization "./standardize-health-checks.sh" "Health Check Standardization (OPT-002)"

# Step 4: Optimize startup sequence
run_optimization "./optimize-startup-sequence.sh" "Startup Sequence Optimization (OPT-004)"

echo "==============================================================="
echo "All optimizations have been applied!"
echo "==============================================================="
echo ""
echo "To apply changes, run:"
echo "cd .. && docker-compose -f docker-compose.unified.yml up -d"
echo ""
echo "To restore the original configuration, run:"
echo "cp ../docker-compose.unified.yml.bak-original ../docker-compose.unified.yml"
echo ""
echo "Changes made:"
echo " - Added container resource limits to all services"
echo " - Standardized health check configuration"
echo " - Optimized service startup sequence"
echo " - Created .env.example template"
echo " - Added retry logic implementation in libs/resilience.py"
echo ""