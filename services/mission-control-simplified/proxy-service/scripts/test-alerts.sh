#!/bin/bash

# Script to test alerting configuration for Niche-Scout Proxy Service
# This script triggers alerts by manipulating the proxy service metrics temporarily

set -e

echo "Niche-Scout Alerting Test"
echo "=========================="
echo

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: $0 [--fire <alert_type>|--resolve]"
  echo
  echo "Options:"
  echo "  --fire error        Simulate high error rate alert"
  echo "  --fire latency      Simulate high latency alert"
  echo "  --fire cache        Simulate low cache hit ratio alert"
  echo "  --resolve           Resolve any currently firing alerts"
  echo
  echo "Example: $0 --fire error"
  exit 0
fi

# Check if Docker is running
if ! docker ps &> /dev/null; then
  echo "❌ Error: Docker is not running or you don't have sufficient permissions"
  echo "Please start Docker or check your permissions"
  exit 1
fi

# Check if proxy service is running
if ! docker ps | grep -q niche-proxy; then
  echo "❌ Error: Niche-Scout Proxy service is not running"
  echo "Please start the service with: docker-compose up -d"
  exit 1
fi

# Check if alertmanager is running
if ! docker ps | grep -q alertmanager; then
  echo "❌ Error: Alertmanager is not running"
  echo "Please start the monitoring stack with: docker-compose up -d prometheus alertmanager"
  exit 1
fi

# Function to simulate high error rate
simulate_high_error_rate() {
  echo "🔥 Simulating high error rate (>5%)..."

  # Use Docker exec to run curl commands that will artificially increase error rate
  for i in {1..10}; do
    docker exec -it niche-proxy curl -s -X POST "http://localhost:3020/api/youtube/niche-scout" -H "Content-Type: application/json" -d '{"invalid": "request"}' > /dev/null
  done

  echo "✅ Sent 10 invalid requests to increase error rate"
  echo "Check Prometheus at http://localhost:9090 and Grafana at http://localhost:3000 to see the alert"
  echo "Alert should fire within 1 minute if error rate exceeds threshold"
}

# Function to simulate high latency
simulate_high_latency() {
  echo "🔥 Simulating high latency (>800ms)..."

  # Create a temporary endpoint that introduces delay
  docker exec -it niche-proxy curl -s -X POST "http://localhost:3020/config" -H "Content-Type: application/json" -d '{"transformation": {"simulateDelay": 1000}}' > /dev/null

  # Make some requests to this slow endpoint
  for i in {1..5}; do
    docker exec -it niche-proxy curl -s -X POST "http://localhost:3020/api/youtube/niche-scout" -H "Content-Type: application/json" -d '{"query": "cooking recipes", "category": "Food"}' > /dev/null
  done

  echo "✅ Sent 5 requests with artificial latency"
  echo "Check Prometheus at http://localhost:9090 and Grafana at http://localhost:3000 to see the alert"
  echo "Alert should fire within 2 minutes if p95 latency exceeds threshold"
}

# Function to simulate low cache hit ratio
simulate_low_cache_hit() {
  echo "🔥 Simulating low cache hit ratio (<20%)..."

  # First, clear the cache
  docker exec -it niche-proxy curl -s -X DELETE "http://localhost:3020/cache/*?token=$(docker exec niche-proxy env | grep CACHE_BUST_TOKEN | cut -d= -f2)" > /dev/null

  # Then send many unique requests to ensure low cache hit ratio
  for i in {1..20}; do
    docker exec -it niche-proxy curl -s -X POST "http://localhost:3020/api/youtube/niche-scout" -H "Content-Type: application/json" -d "{\"query\": \"unique query $i\", \"category\": \"Test\"}" > /dev/null
  done

  echo "✅ Cleared cache and sent 20 unique requests to reduce cache hit ratio"
  echo "Check Prometheus at http://localhost:9090 and Grafana at http://localhost:3000 to see the alert"
  echo "Alert should fire within 5 minutes if cache hit ratio stays below threshold"
}

# Function to resolve alerts
resolve_alerts() {
  echo "🔄 Resolving any firing alerts..."

  # Reset configuration to normal
  docker exec -it niche-proxy curl -s -X POST "http://localhost:3020/config" -H "Content-Type: application/json" -d '{"transformation": {"simulateDelay": 0}}' > /dev/null

  # Make some successful requests to improve error rate
  for i in {1..20}; do
    docker exec -it niche-proxy curl -s -X POST "http://localhost:3020/api/youtube/niche-scout" -H "Content-Type: application/json" -d '{"query": "gaming", "category": "Gaming"}' > /dev/null
  done

  echo "✅ Reset configuration and sent 20 valid requests"
  echo "Alerts should resolve within a few minutes"
}

# Main control flow
if [[ "$1" == "--fire" ]]; then
  case "$2" in
    "error")
      simulate_high_error_rate
      ;;
    "latency")
      simulate_high_latency
      ;;
    "cache")
      simulate_low_cache_hit
      ;;
    *)
      echo "❌ Unknown alert type: $2"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
elif [[ "$1" == "--resolve" ]]; then
  resolve_alerts
else
  echo "❌ Missing or invalid argument"
  echo "Use --help to see available options"
  exit 1
fi

echo
echo "📊 Monitor alert status:"
echo "- Prometheus: http://localhost:9090/alerts"
echo "- Alertmanager: http://localhost:9093/#/alerts"
echo "- Grafana: http://localhost:3000/d/niche-scout-alerts"
echo
echo "Done!"
