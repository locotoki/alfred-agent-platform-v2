#!/bin/bash
# Script to run synthetic load tests using Alfred CLI

if [ $# -lt 1 ]; then
    echo "Usage: $0 <namespace> [rps] [burst] [duration]"
    echo "Example: $0 alfred 50 100 30m"
    exit 1
fi

NAMESPACE=$1
RPS=${2:-50}          # Default 50 requests per second
BURST=${3:-0}         # Default no burst
DURATION=${4:-30m}    # Default 30 minutes

# Determine endpoint based on namespace
if [ "$NAMESPACE" == "local" ]; then
    ENDPOINT="http://localhost:8080"
else
    ENDPOINT="http://alfred-core.$NAMESPACE.svc.cluster.local:8080"
fi

echo "Starting synthetic load test:"
echo "- Namespace: $NAMESPACE"
echo "- Endpoint: $ENDPOINT"
echo "- RPS: $RPS"
echo "- Burst: $BURST"
echo "- Duration: $DURATION"
echo ""
echo "Load test started at $(date)"
echo "Monitor progress in Grafana dashboard: http://grafana.$NAMESPACE.svc:3000/d/metrics-synthetic/metrics-synthetic-load"
echo ""

# Run the Alfred workload command
alfred workload \
    --rps=$RPS \
    --burst=$BURST \
    --duration=$DURATION \
    --endpoint=$ENDPOINT \
    --random=true

echo ""
echo "Load test completed at $(date)"
