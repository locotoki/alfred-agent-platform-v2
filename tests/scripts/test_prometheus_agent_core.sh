#!/bin/bash
# Test script for Track E: agent-core perf harness monitoring

# Spin up agent-core perf harness (backgrounded)
echo "🚀 Starting agent-core perf harness on :8001..."
( cd perf && ./run.sh 2>&1 | sed 's/^/[HARNESS] /' ) &
HARNESS_PID=$!

# Give the harness two seconds to bind :8001
sleep 2

# Launch Prometheus with our freshly-committed config + rules
echo "🐳 Starting Prometheus container..."
docker run --rm -d --name prom-agent-core -p 9090:9090 \
  --network host \
  -v "$PWD/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  -v "$PWD/monitoring/prometheus/alerts/agent_core_latency.yml:/etc/prometheus/alerts.yml:ro" \
  prom/prometheus:v2.52.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle

echo "🟢 Prometheus is listening on http://localhost:9090"

# Wait for Prometheus to be ready
echo "⏳ Waiting for Prometheus to start..."
for i in {1..10}; do
  if curl -s http://localhost:9090/-/ready > /dev/null; then
    echo "✅ Prometheus is ready!"
    break
  fi
  sleep 1
done

# Optional: open browser tabs automatically on Linux
if command -v xdg-open >/dev/null; then
  xdg-open "http://localhost:9090/targets" 2>/dev/null &
  xdg-open "http://localhost:9090/graph?g0.expr=rag_p95_latency_ms" 2>/dev/null &
  xdg-open "http://localhost:9090/alerts" 2>/dev/null &
fi

# Install hey if not available
if ! command -v hey >/dev/null; then
  echo "📦 Installing hey load testing tool..."
  go install github.com/rakyll/hey@latest || {
    echo "⚠️  Could not install hey. Using curl loop instead..."
    USE_CURL=1
  }
fi

# Fire a 2-minute load burst to push p95 over 300 ms
echo "🔥 Starting load test..."
if [ -z "$USE_CURL" ]; then
  hey -z 2m -q 20 -m POST -H "Content-Type: application/json" \
    -d '{"query":"When is GA?"}' \
    http://localhost:8001/v1/query &
else
  # Fallback: curl loop
  for i in {1..240}; do
    curl -s -X POST -H "Content-Type: application/json" \
      -d '{"query":"When is GA?"}' \
      http://localhost:8001/v1/query > /dev/null &
    sleep 0.5
  done &
fi

cat <<'EOM'

-----------------------------------------------------------------
Next-steps (manual):
1. Watch Prometheus  ➜ Status → Targets   → agent_core_perf ✔︎
2. After ~5 min, check Alerts             → AgentCoreP95High 🔥
3. (Optional) curl http://localhost:9090/api/v1/alerts | jq
4. When done:
   docker stop prom-agent-core
   kill $HARNESS_PID
-----------------------------------------------------------------
EOM

# Keep script running to show logs
echo "📋 Showing harness logs (Ctrl+C to stop)..."
wait $HARNESS_PID
