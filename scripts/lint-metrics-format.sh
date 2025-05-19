#!/bin/bash
# Script to lint Prometheus metrics format from service endpoints

set -e

echo "Linting Prometheus metrics format from service endpoints..."

# Define ports for each service
declare -A SERVICE_PORTS=(
  ["agent-rag"]="9092"
  ["agent-atlas"]="9093"
  ["agent-social"]="9094"
  ["agent-financial"]="9095"
  ["agent-legal"]="9096"
  ["alfred-bot"]="9091"
)

# Lint metrics for a specific service
lint_service_metrics() {
  local service=$1
  local port=${SERVICE_PORTS[$service]}

  echo "Checking metrics format for $service on port $port..."

  # Check if service is responding
  if ! curl -s "http://localhost:$port/metrics" > /dev/null; then
    echo "❌ $service is not responding on port $port"
    return 1
  fi

  # Check for leading whitespace in metrics (common formatting issue)
  if curl -s "http://localhost:$port/metrics" | grep -E '^\s+' > /dev/null; then
    echo "❌ $service has leading whitespace in metrics, which Prometheus cannot parse"
    curl -s "http://localhost:$port/metrics" | grep -E '^\s+' | head -5
    return 1
  fi

  # Check for proper metric format
  if ! curl -s "http://localhost:$port/metrics" | grep -E '^service_health' > /dev/null; then
    echo "❌ $service does not have service_health metric"
    return 1
  fi

  # Success
  echo "✅ $service metrics format is valid"
  return 0
}

# Lint all services
failure=0

for service in "${!SERVICE_PORTS[@]}"; do
  if ! lint_service_metrics $service; then
    failure=1
  fi
done

# Check Prometheus can scrape these metrics
echo "Checking Prometheus can scrape service_health metrics..."
if curl -s "http://localhost:9090/api/v1/query?query=service_health" | grep -q '"resultType":"vector"'; then
  echo "✅ Prometheus is scraping service_health metrics"
else
  echo "❌ Prometheus is not scraping service_health metrics"
  failure=1
fi

# Final result
if [ $failure -eq 0 ]; then
  echo "🟢 All metrics format checks passed"
  exit 0
else
  echo "🔴 Some metrics format checks failed"
  exit 1
fi
