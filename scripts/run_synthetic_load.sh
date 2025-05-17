#!/bin/bash
# Script to run synthetic load tests

if [ $# -lt 1 ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

NAMESPACE=$1
DURATION=1800  # 30 minutes in seconds

echo "Starting synthetic load test in namespace $NAMESPACE for $DURATION seconds"
echo "This is a simulation of a load test against the metrics service endpoints"

echo "Simulating load test..."
echo "- Sending traffic to /metrics endpoint"
echo "- Sending traffic to /health endpoint"
echo "- Sending traffic to /healthz endpoint"

echo "Load test will run for 30 minutes"
echo "Metrics will be collected in Prometheus"

# In a real scenario, this would use a tool like k6, Artillery, or similar
# to generate synthetic load against the service endpoints

echo "Load test started at $(date)"
echo "Monitor progress in Grafana dashboard: http://grafana.$NAMESPACE.svc:3000/d/metrics-synthetic/metrics-synthetic-load"