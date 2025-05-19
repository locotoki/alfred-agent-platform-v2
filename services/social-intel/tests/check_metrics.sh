#!/bin/bash
# Script to verify the SI_LATENCY_SECONDS_bucket metric

set -e

HOST=${1:-localhost}
PORT=${2:-9000}
ENDPOINT="/health/metrics"
METRIC="si_latency_seconds_bucket{le=\"0.4\"}"

echo "Checking for metric: $METRIC at $HOST:$PORT$ENDPOINT"
echo "-----------------------------------------------"

# Try to get the metrics
RESPONSE=$(curl -s "http://$HOST:$PORT$ENDPOINT" | grep "$METRIC")

if [ $? -eq 0 ]; then
  echo "✅ Success! Found metric: $METRIC"
  echo "$RESPONSE"
  exit 0
else
  echo "❌ Error: Metric $METRIC not found"
  exit 1
fi
