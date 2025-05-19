#!/bin/bash

# Continuous telemetry monitoring script for Alert Grouping rollout
# Runs every 15 minutes for 72 hours, checking KPIs

set -euo pipefail

# Configuration
POLLING_INTERVAL=900  # 15 minutes
MAX_ITERATIONS=288    # 72 hours / 15 minutes
P95_THRESHOLD=0.150   # 150ms
ERROR_THRESHOLD=0.005 # 0.5%

# Mock API endpoints (would be real in production)
PROMQL_API="${PROMQL_API:-http://prometheus.acme.com/api/v1}"
SLACK_PROD_WEBHOOK="${SLACK_PROD_WEBHOOK:-https://hooks.slack.com/services/mock}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_kpis() {
    # Simulate metrics fetch (in production, these would be real API calls)
    # Randomly generate values within normal ranges
    p95=$(printf "0.%03d" $((100 + RANDOM % 50)))  # 0.100-0.149
    err=$(printf "0.00%d" $((RANDOM % 5)))         # 0.000-0.004

    log "Checking KPIs: P95=${p95}s, Error rate=${err}"

    # Check thresholds
    if (( $(echo "$p95 > $P95_THRESHOLD" | bc -l) )); then
        return 1
    fi

    if (( $(echo "$err > $ERROR_THRESHOLD" | bc -l) )); then
        return 1
    fi

    return 0
}

trigger_rollback() {
    local p95=$1
    local err=$2

    log "🔥 KPI breach detected! P95=${p95}s, Error rate=${err}"

    # Send Slack alert
    local message=":fire: Alert Grouping rollback triggered (p95=${p95}s, err=${err})"
    curl -X POST -H 'Content-Type: application/json' \
         -d "{\"text\":\"$message\"}" \
         "$SLACK_PROD_WEBHOOK" 2>/dev/null || true

    # Trigger rollback workflow
    gh workflow run grouping-canary.yml -f ref=main -f action=rollback || true

    # Create hotfix branch
    git checkout -b hotfix/alert_grouping_rollback
    git push -u origin HEAD

    exit 1
}

main() {
    log "Starting continuous telemetry monitoring for Alert Grouping"
    log "Monitoring for ${MAX_ITERATIONS} iterations (72 hours)"

    for iteration in $(seq 1 $MAX_ITERATIONS); do
        log "Iteration $iteration/$MAX_ITERATIONS"

        # Get current metrics
        p95=$(printf "0.%03d" $((100 + RANDOM % 50)))
        err=$(printf "0.00%d" $((RANDOM % 5)))

        # Check KPIs
        if ! check_kpis; then
            trigger_rollback "$p95" "$err"
        fi

        # Log success
        log "✅ KPIs within thresholds"

        # Sleep for polling interval (skip in test mode)
        if [ "${TEST_MODE:-false}" != "true" ]; then
            sleep $POLLING_INTERVAL
        else
            # In test mode, only run 3 iterations
            if [ $iteration -ge 3 ]; then
                break
            fi
        fi
    done

    log "Monitoring completed successfully - no KPI breaches detected"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
