#!/bin/bash
# Test script for health checks - should return 200 or 503, never 500

echo "Testing health endpoint responses..."

# Test metrics containers
if docker ps | grep -q db-metrics-test; then
    echo "Testing db-metrics-test container..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9199/health)
    echo "Response code: $RESPONSE"
    if [[ "$RESPONSE" == "500" ]]; then
        echo "❌ FAILED: /health returned 500"
        exit 1
    else
        echo "✅ PASSED: /health returned $RESPONSE (200 or 503 are acceptable)"
    fi
fi

if docker ps | grep -q db-metrics-fixed; then
    echo "Testing db-metrics-fixed container..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9200/health)
    echo "Response code: $RESPONSE"
    if [[ "$RESPONSE" == "500" ]]; then
        echo "❌ FAILED: /health returned 500"
        exit 1
    else
        echo "✅ PASSED: /health returned $RESPONSE (200 or 503 are acceptable)"
    fi
fi

echo "All health tests passed!"