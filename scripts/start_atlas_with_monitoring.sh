#!/usr/bin/env bash
set -e

# Load environment variables
if [ -f ".env.dev" ]; then
  export $(grep -v '^#' .env.dev | xargs)
fi

# Make sure directories exist
mkdir -p monitoring/prometheus/rules
mkdir -p monitoring/grafana/dashboards
mkdir -p monitoring/grafana/provisioning/datasources
mkdir -p monitoring/grafana/provisioning/dashboards

# Check if essential files exist
if [ ! -f "monitoring/prometheus/prometheus.yml" ]; then
  echo "Creating Prometheus configuration..."
  cat > monitoring/prometheus/prometheus.yml << 'EOF'
# Prometheus configuration for Atlas monitoring
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Load rules from files in the 'rules' directory
rule_files:
  - "rules/*.yml"

# Scrape configurations
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "atlas-worker"
    static_configs:
      - targets: ["atlas-worker:8000"]

  - job_name: "atlas-rag-gateway"
    static_configs:
      - targets: ["atlas-rag-gateway:8501"]

  - job_name: "atlas-pubsub"
    static_configs:
      - targets: ["pubsub:8681"]
EOF
fi

if [ ! -f "monitoring/prometheus/rules/atlas.yml" ]; then
  echo "Creating Prometheus alert rules..."
  cat > monitoring/prometheus/rules/atlas.yml << 'EOF'
groups:
- name: atlas.rules
  rules:
  - alert: AtlasTokenBudget80
    expr: (atlas_tokens_total / atlas_daily_token_budget) > 0.8
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Atlas token usage > 80%"
      description: "Atlas has used more than 80% of its daily token budget"

  - alert: AtlasSlowP95
    expr: histogram_quantile(0.95, rate(atlas_run_seconds_bucket[5m])) > 10
    for: 10m
    labels:
      severity: critical
    annotations:
      summary: "Atlas p95 latency > 10s"
      description: "Atlas is experiencing slow response times (p95 > 10s)"

  - alert: AtlasRAGUnavailable
    expr: atlas_rag_reachable == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Atlas RAG service unreachable"
      description: "Atlas cannot reach the RAG service"

  - alert: AtlasOpenAIUnavailable
    expr: atlas_openai_reachable == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "OpenAI API unreachable"
      description: "Atlas cannot reach the OpenAI API"
EOF
fi

if [ ! -f "monitoring/grafana/provisioning/datasources/prometheus.yml" ]; then
  echo "Creating Grafana datasource configuration..."
  cat > monitoring/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF
fi

if [ ! -f "monitoring/grafana/provisioning/dashboards/atlas.yml" ]; then
  echo "Creating Grafana dashboard configuration..."
  cat > monitoring/grafana/provisioning/dashboards/atlas.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'atlas'
    orgId: 1
    folder: 'Atlas'
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
EOF
fi

# Start Atlas with monitoring
echo "Starting Atlas with monitoring..."
docker-compose -f docker-compose.dev.yml -f docker-compose.monitoring.yml up -d

echo "Setup Supabase tables for Atlas..."
./scripts/setup_supabase.sh

echo "Waiting for services to be ready..."
sleep 10

echo "Atlas is running with monitoring!"
echo ""
echo "Access:"
echo "  - Atlas RAG Gateway: http://localhost:8501"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3000 (admin/admin)"
echo ""
echo "To index documents, run:"
echo "  ./scripts/process_docs.py /path/to/docs"
echo ""
echo "To send a task to Atlas, run:"
echo "  ./scripts/publish_task.sh \"Your architecture request\""
echo ""
echo "To monitor the worker, run:"
echo "  docker logs -f \$(docker-compose -f docker-compose.dev.yml -f docker-compose.monitoring.yml ps -q atlas-worker)"