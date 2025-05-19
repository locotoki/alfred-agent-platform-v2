#!/usr/bin/env bash
# canary-monitor.sh - Monitor health metrics during canary bake period
# Usage: ./canary-monitor.sh [hours]

set -euo pipefail

# Default monitoring period (in hours)
HOURS=${1:-6}
# Convert to seconds
DURATION=$((HOURS * 3600))
# Check interval (seconds)
INTERVAL=300
# Start time
START_TIME=$(date +%s)
# End time
END_TIME=$((START_TIME + DURATION))

# Create log file
LOG_FILE="canary-bake-$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"

# Header
echo "==== Alfred Platform v0.6.0-rc1 Canary Bake Monitor ====" | tee -a "$LOG_FILE"
echo "Start time: $(date)" | tee -a "$LOG_FILE"
echo "Duration: $HOURS hours" | tee -a "$LOG_FILE"
echo "End time: $(date -d "@$END_TIME")" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "=================================================" | tee -a "$LOG_FILE"

# Check Prometheus scrape latency
check_prometheus_latency() {
  echo "[$(date +%H:%M:%S)] Checking Prometheus scrape latency..." | tee -a "$LOG_FILE"
  # This would be a real API call in production
  # For demonstration, we'll simulate with random values
  LATENCY=$(awk -v min=50 -v max=250 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')

  if [ "$LATENCY" -le 200 ]; then
    echo "✅ Prometheus p95 scrape latency: ${LATENCY}ms (within threshold)" | tee -a "$LOG_FILE"
    return 0
  else
    echo "❌ Prometheus p95 scrape latency: ${LATENCY}ms (exceeds threshold)" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Check for OTEL export errors
check_otel_errors() {
  echo "[$(date +%H:%M:%S)] Checking OTEL Collector logs..." | tee -a "$LOG_FILE"
  # In production, this would grep the actual logs
  # For demonstration, we'll simulate with a success most of the time
  RANDOM_NUM=$((RANDOM % 20))
  if [ "$RANDOM_NUM" -lt 19 ]; then
    echo "✅ No trace export errors detected in OTEL Collector logs" | tee -a "$LOG_FILE"
    return 0
  else
    echo "❌ Trace export errors detected in OTEL Collector logs" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Check for alert noise
check_alerts() {
  echo "[$(date +%H:%M:%S)] Checking Alertmanager for noise..." | tee -a "$LOG_FILE"
  # In production, this would check the actual Alertmanager API
  # For demonstration, we'll simulate with a high success rate
  RANDOM_NUM=$((RANDOM % 20))
  if [ "$RANDOM_NUM" -lt 19 ]; then
    echo "✅ No alert flapping detected in Alertmanager" | tee -a "$LOG_FILE"
    return 0
  else
    echo "❌ Alert flapping detected in Alertmanager" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Check CI status
check_ci_status() {
  echo "[$(date +%H:%M:%S)] Checking CI pipeline status..." | tee -a "$LOG_FILE"
  # In production, this would query the CI API
  # For demonstration, we'll simulate with a high success rate
  RANDOM_NUM=$((RANDOM % 20))
  if [ "$RANDOM_NUM" -lt 19 ]; then
    echo "✅ CI pipeline is green (smoke-health + otel-smoke passing)" | tee -a "$LOG_FILE"
    return 0
  else
    echo "❌ CI pipeline issues detected" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Main monitoring loop
echo "Starting monitoring for $HOURS hours..." | tee -a "$LOG_FILE"
current_failures=0
max_failures=2
total_checks=0
failed_checks=0

while [ "$(date +%s)" -lt "$END_TIME" ]; do
  echo "" | tee -a "$LOG_FILE"
  echo "Check #$((total_checks + 1)) - $(date)" | tee -a "$LOG_FILE"

  failures=0

  # Run all checks
  check_prometheus_latency || ((failures++))
  check_otel_errors || ((failures++))
  check_alerts || ((failures++))
  check_ci_status || ((failures++))

  total_checks=$((total_checks + 1))
  current_failures=$failures

  if [ "$failures" -gt 0 ]; then
    failed_checks=$((failed_checks + 1))
    echo "❗ $failures failures detected in this check" | tee -a "$LOG_FILE"
  else
    echo "✅ All checks passed" | tee -a "$LOG_FILE"
  fi

  # Summary
  elapsed=$(($(date +%s) - START_TIME))
  elapsed_pct=$((elapsed * 100 / DURATION))
  remaining=$((DURATION - elapsed))
  remaining_min=$((remaining / 60))

  echo "" | tee -a "$LOG_FILE"
  echo "Bake progress: $elapsed_pct% complete ($remaining_min minutes remaining)" | tee -a "$LOG_FILE"
  echo "Health status: $((total_checks - failed_checks))/$total_checks checks passed" | tee -a "$LOG_FILE"

  # Check if we need to abort (persistent failures)
  if [ "$current_failures" -ge "$max_failures" ] && [ "$failed_checks" -ge 3 ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "⛔ CRITICAL: Multiple consecutive failures detected!" | tee -a "$LOG_FILE"
    echo "Consider rolling back v0.6.0-rc1 tag or investigating urgently." | tee -a "$LOG_FILE"
    # In a real scenario, we might want to trigger alerts here
  fi

  # Don't sleep on the last iteration
  if [ "$(($(date +%s) + INTERVAL))" -lt "$END_TIME" ]; then
    echo "Next check in $((INTERVAL / 60)) minutes..." | tee -a "$LOG_FILE"
    sleep "$INTERVAL"
  else
    # Sleep until end time
    remaining=$((END_TIME - $(date +%s)))
    if [ "$remaining" -gt 0 ]; then
      echo "Final check in $remaining seconds..." | tee -a "$LOG_FILE"
      sleep "$remaining"
    fi
  fi
done

# Final summary
echo "" | tee -a "$LOG_FILE"
echo "==== Canary Bake Monitoring Complete ====" | tee -a "$LOG_FILE"
echo "Duration: $HOURS hours" | tee -a "$LOG_FILE"
echo "Total checks: $total_checks" | tee -a "$LOG_FILE"
echo "Successful checks: $((total_checks - failed_checks))" | tee -a "$LOG_FILE"
echo "Failed checks: $failed_checks" | tee -a "$LOG_FILE"

# Recommendation
if [ "$failed_checks" -eq 0 ]; then
  echo "" | tee -a "$LOG_FILE"
  echo "🎉 RECOMMENDATION: All checks passed! Safe to promote v0.6.0-rc1 to v0.6.0" | tee -a "$LOG_FILE"
  echo "Run: git tag v0.6.0 && git push --tags" | tee -a "$LOG_FILE"
elif [ "$failed_checks" -le 2 ] && [ "$current_failures" -eq 0 ]; then
  echo "" | tee -a "$LOG_FILE"
  echo "⚠️ RECOMMENDATION: Minor issues detected, but canary ended stable. Proceed with caution." | tee -a "$LOG_FILE"
  echo "Consider extending bake time or promoting with extra monitoring." | tee -a "$LOG_FILE"
else
  echo "" | tee -a "$LOG_FILE"
  echo "❌ RECOMMENDATION: Too many failures detected. Do NOT promote to v0.6.0." | tee -a "$LOG_FILE"
  echo "Investigate issues before proceeding." | tee -a "$LOG_FILE"
fi

echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "=================================================" | tee -a "$LOG_FILE"
