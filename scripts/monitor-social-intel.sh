#!/bin/bash
# Social-Intel Monitoring Script
# This script helps monitor the Social-Intel service during canary deployment

echo "===== Social-Intel Service Monitoring ====="
echo "Starting monitoring checks..."

# Check service health
echo -e "\n[1/4] Checking service health..."
curl -s http://localhost:9000/health/ && echo "" || echo "WARNING: Health check failed"

# Check metrics
echo -e "\n[2/4] Checking Prometheus metrics (latency)..."
curl -s http://localhost:9000/health/metrics | grep -E "si_latency_seconds|si_requests_total" | sort

# Check logs for errors
echo -e "\n[3/4] Checking for errors in logs (last 10 minutes)..."
docker compose logs --since 10m social-intel | grep -i -E "error|exception|fail" | tail -10 || echo "No errors found"

# Check proxy settings
echo -e "\n[4/4] Checking proxy configuration..."
grep FEATURE_PROXY_ENABLED .env

echo -e "\n===== Monitoring Complete ====="
echo "For full monitoring, visit the following dashboards:"
echo "  - Grafana: http://localhost:3002 (admin/admin)"
echo "  - Prometheus: http://localhost:9090"
echo "  - Social-Intel API: http://localhost:9000/docs"
echo ""
echo "To run k6 load test:"
echo "  cd services/social-intel && npm run test:load"
