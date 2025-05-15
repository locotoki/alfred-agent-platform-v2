#\!/bin/bash
set -e

echo "🚀 Starting orchestration PoC validation..."

# Tear down any existing setup
docker compose -f ci/compose/orchestration-poc.yml down -v 2>/dev/null || true

# Use different ports to avoid conflicts
export N8N_PORT=7678
export CREWAI_PORT=7080
export SLACK_PORT=7010

# Start with custom port mapping
echo "📦 Starting containers with custom ports..."
N8N_PORT=$N8N_PORT CREWAI_PORT=$CREWAI_PORT SLACK_PORT=$SLACK_PORT \
  docker compose -f ci/compose/orchestration-poc.yml up -d

# Wait for n8n to start
echo "⏳ Waiting for n8n to start..."
for i in {1..20}; do 
  if curl -s http://localhost:$N8N_PORT/healthz &>/dev/null; then
    echo "✅ n8n is running"
    break
  fi
  echo "  Waiting ($i/20)..."
  sleep 3
  if [ $i -eq 20 ]; then
    echo "❌ n8n failed to start"
    docker compose -f ci/compose/orchestration-poc.yml logs
    docker compose -f ci/compose/orchestration-poc.yml down -v
    exit 1
  fi
done

# Send test alert
echo "🔔 Sending test alert to webhook..."
curl -s -X POST http://localhost:$N8N_PORT/webhook/alertmanager \
  -H 'Content-Type: application/json' \
  -d '{"alerts":[{"labels":{"namespace":"default","deployment":"api"}}]}'

# Check if CrewAI responded properly
echo "🔍 Checking CrewAI response..."
if docker compose -f ci/compose/orchestration-poc.yml logs crewai  < /dev/null |  grep -q '"action":"restart"'; then
  echo "✅ CrewAI responded with restart action"
else
  echo "❌ CrewAI failed to respond correctly"
  docker compose -f ci/compose/orchestration-poc.yml logs crewai
  docker compose -f ci/compose/orchestration-poc.yml down -v
  exit 1
fi

# Success - clean up
echo "🧹 Cleaning up..."
docker compose -f ci/compose/orchestration-poc.yml down -v

echo "✅ Orchestration PoC validation successful\!"
exit 0
