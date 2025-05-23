#!/bin/bash
# Test Prometheus with host network

echo "🐳 Starting Prometheus with host network..."

# Start Prometheus with host network so it can reach localhost:8001
docker run --rm -d --name prom-agent-core \
  --network host \
  -v "$PWD/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  -v "$PWD/monitoring/prometheus/alerts:/etc/prometheus/alerts:ro" \
  prom/prometheus:v2.52.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle \
  --web.listen-address=:9091

# Wait for Prometheus
echo "⏳ Waiting for Prometheus..."
sleep 5

# Check targets
echo "📊 Agent-core perf target status:"
curl -s http://localhost:9091/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job == "agent_core_perf") | {health, lastError, scrapeUrl}'

echo ""
echo "📈 Current metric value:"
curl -s http://localhost:9091/api/v1/query?query=rag_p95_latency_ms | jq '.data.result[0].value[1]' 2>/dev/null || echo "Waiting for first scrape..."

echo ""
echo "🚨 Alert status:"
curl -s http://localhost:9091/api/v1/rules | jq '.data.groups[].rules[] | select(.name == "AgentCoreP95High") | {name, state, alerts}'

echo ""
echo "📍 Prometheus UI: http://localhost:9091"
echo ""
echo "⏰ Alert should fire in ~5 minutes (p95 is at 350ms)"
echo "📍 Check with: curl -s http://localhost:9091/api/v1/alerts | jq"
