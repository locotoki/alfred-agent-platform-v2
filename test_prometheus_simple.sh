#!/bin/bash
# Simple test for Prometheus configuration

echo "🐳 Starting Prometheus with agent-core config..."

# Start Prometheus with our config
docker run --rm -d --name prom-agent-core \
  -p 9091:9090 \
  -v "$PWD/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  -v "$PWD/monitoring/prometheus/alerts:/etc/prometheus/alerts:ro" \
  prom/prometheus:v2.52.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle

# Wait for Prometheus to start
echo "⏳ Waiting for Prometheus to start..."
sleep 5

# Check configuration
echo "📋 Checking loaded configuration..."
echo ""
echo "✅ Configured jobs:"
curl -s http://localhost:9091/api/v1/targets | jq -r '.data.activeTargets[].job' | sort | uniq

echo ""
echo "✅ Agent-core perf target details:"
curl -s http://localhost:9091/api/v1/targets | jq '.data.activeTargets[] | select(.job == "agent_core_perf")'

echo ""
echo "✅ Loaded alert rules:"
curl -s http://localhost:9091/api/v1/rules | jq '.data.groups[].rules[] | select(.name == "AgentCoreP95High")'

echo ""
echo "📍 Prometheus UI: http://localhost:9091"
echo "📍 To stop: docker stop prom-agent-core"
