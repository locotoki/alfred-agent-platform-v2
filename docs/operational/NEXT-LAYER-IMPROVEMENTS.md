# Next-Layer Improvements Plan

## Overview
Following repository cleanup and baseline stabilization, these improvements focus on operational excellence, resilience, and developer productivity.

## Improvement Layers (Ordered by ROI)

### 1. 🛡️ Operational Safety: Automated Backup/Restore

**Why It Helps**: Enables anyone to recreate staging or recover production in minutes

**Implementation Plan**:

#### Create Backup Script
`scripts/backup-all.sh`:
```bash
#!/bin/bash
set -euo pipefail

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/$DATE"
mkdir -p "$BACKUP_DIR"

echo "🔵 Starting backup: $DATE"

# PostgreSQL backup
echo "📦 Backing up PostgreSQL..."
docker compose exec -T db-postgres pg_dump -U postgres alfred_db > "$BACKUP_DIR/postgres.sql"

# Redis backup
echo "📦 Backing up Redis..."
docker compose exec -T redis redis-cli --rdb "$BACKUP_DIR/redis.rdb"

# MinIO backup (if using)
if docker compose ps | grep -q minio; then
    echo "📦 Backing up MinIO..."
    docker compose exec -T minio mc mirror /data "$BACKUP_DIR/minio/"
fi

echo "✅ Backup complete: $BACKUP_DIR"
```

#### Add Makefile Target
```makefile
.PHONY: backup restore

backup:
	@echo "Creating backup..."
	@./scripts/backup-all.sh

restore:
	@echo "Available backups:"
	@ls -la /backups/
	@read -p "Enter backup date (YYYYMMDD_HHMMSS): " DATE; \
	./scripts/restore-all.sh $$DATE
```

#### Create Restore Playbook
`docs/runbooks/disaster-recovery.md`:
```markdown
# Disaster Recovery Playbook

## Quick Restore
1. List available backups: `make list-backups`
2. Restore specific backup: `make restore DATE=20250529_120000`
3. Verify services: `make health-check`

## Manual Steps
- PostgreSQL: `psql < /backups/DATE/postgres.sql`
- Redis: `redis-cli --rdb /backups/DATE/redis.rdb`
- MinIO: `mc mirror /backups/DATE/minio/ /data`
```

---

### 2. 💥 Resilience Testing: Chaos Engineering

**Why It Helps**: Validates health checks and recovery mechanisms actually work

**Implementation Plan**:

#### Chaos Script for Local Testing
`scripts/chaos-test.sh`:
```bash
#!/bin/bash
# Mini chaos engineering - restart random container hourly

while true; do
    # Get random running service
    SERVICE=$(docker compose ps --services | shuf -n1)
    
    echo "🎲 Chaos strike: restarting $SERVICE"
    docker compose restart "$SERVICE"
    
    # Wait for recovery
    sleep 30
    
    # Check health
    if docker compose ps | grep -q "$SERVICE.*healthy"; then
        echo "✅ $SERVICE recovered successfully"
    else
        echo "❌ $SERVICE failed to recover!"
        exit 1
    fi
    
    # Wait 1 hour
    sleep 3600
done
```

#### Kubernetes Chaos CronJob
`k8s/chaos-engineering.yaml`:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: chaos-restarter
  namespace: staging
spec:
  schedule: "0 * * * *"  # Every hour
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: chaos-engineer
          containers:
          - name: chaos
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - |
              DEPLOYMENT=$(kubectl get deploy -o name | shuf -n1)
              echo "Restarting $DEPLOYMENT"
              kubectl rollout restart $DEPLOYMENT
              kubectl rollout status $DEPLOYMENT --timeout=5m
```

---

### 3. 📊 Resource Governance: CPU/Memory Limits

**Why It Helps**: Prevents resource starvation and enables cluster autoscaling

**Implementation Plan**:

#### Resources Overlay
`docker-compose.resources.yml`:
```yaml
version: '3.8'

x-small-resources: &small-resources
  deploy:
    resources:
      limits:
        cpus: '0.5'
        memory: 512M
      reservations:
        cpus: '0.1'
        memory: 128M

x-medium-resources: &medium-resources
  deploy:
    resources:
      limits:
        cpus: '1.0'
        memory: 1G
      reservations:
        cpus: '0.25'
        memory: 256M

x-large-resources: &large-resources
  deploy:
    resources:
      limits:
        cpus: '2.0'
        memory: 2G
      reservations:
        cpus: '0.5'
        memory: 512M

services:
  agent-core:
    <<: *medium-resources
  
  db-postgres:
    <<: *large-resources
  
  redis:
    <<: *small-resources
```

#### CI Resource Validation
`.github/workflows/resource-check.yml`:
```yaml
name: Resource Governance
on: [pull_request]

jobs:
  check-limits:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check Docker Compose Resources
        run: |
          # Verify all services have resource limits
          docker compose -f docker-compose.yml -f docker-compose.resources.yml config | \
          yq eval '.services.* | select(.deploy.resources.limits == null) | path | .[1]' | \
          while read service; do
            echo "❌ Service '$service' missing resource limits"
            exit 1
          done
      
      - name: Run kube-score
        if: always()
        run: |
          helm template charts/alfred | kube-score score - \
            --ignore-test pod-networkpolicy \
            --ignore-test container-security-context
```

---

### 4. 🔍 Service Quality: OpenTelemetry Tracing

**Why It Helps**: Root-cause latency spikes in seconds with distributed tracing

**Implementation Plan**:

#### Update agent-core Dockerfile
```dockerfile
FROM python:3.11-slim

# Install OpenTelemetry
RUN pip install opentelemetry-distro opentelemetry-exporter-otlp

# Auto-instrument the application
ENV OTEL_SERVICE_NAME=agent-core
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
ENV OTEL_TRACES_EXPORTER=otlp

ENTRYPOINT ["opentelemetry-instrument", "uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

#### Add OpenTelemetry Collector
`docker-compose.observability.yml`:
```yaml
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
    volumes:
      - ./config/otel-collector.yaml:/etc/otel/config.yaml
    command: ["--config", "/etc/otel/config.yaml"]

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"  # Jaeger UI
    environment:
      - COLLECTOR_OTLP_ENABLED=true
```

#### Propagate Trace Context
```python
# In agent-core and all services
from opentelemetry import trace
from opentelemetry.propagate import inject

tracer = trace.get_tracer(__name__)

async def call_downstream_service(request):
    with tracer.start_as_current_span("call_downstream") as span:
        headers = {}
        inject(headers)  # Inject trace context
        
        response = await httpx.get(
            "http://downstream-service",
            headers=headers
        )
        span.set_attribute("response.status", response.status_code)
        return response
```

---

### 5. 🚀 Developer Velocity: Live Reload Development

**Why It Helps**: Instant feedback loop without container rebuilds

**Implementation Plan**:

#### Enhanced Dev Compose
`docker-compose.dev.yml`:
```yaml
version: '3.8'

services:
  agent-core:
    volumes:
      - ./alfred/core:/app
      - ./requirements:/requirements:ro
    environment:
      - RELOAD=true
    command: ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--reload"]

  agent-social:
    volumes:
      - ./services/social-intel:/app
    environment:
      - FLASK_ENV=development
    command: ["flask", "run", "--host=0.0.0.0", "--reload"]
```

#### Tiltfile for Advanced Workflows
`Tiltfile`:
```python
# Tilt configuration for live development
docker_compose('./docker-compose.yml')
docker_compose('./docker-compose.dev.yml')

# Live reload for Python services
local_resource(
  'agent-core-sync',
  'rsync -av ./alfred/core/ $(docker compose ps -q agent-core):/app/',
  deps=['./alfred/core/'],
  trigger_mode=TRIGGER_MODE_AUTO
)

# Automatic test runs
local_resource(
  'test-on-change',
  'docker compose exec -T agent-core pytest -xvs',
  deps=['./alfred/core/', './tests/'],
  auto_init=False
)
```

#### Quick Start Commands
Update `Makefile`:
```makefile
.PHONY: dev dev-tilt

dev:  ## Start development environment with live reload
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up

dev-tilt:  ## Start Tilt development environment
	tilt up

dev-shell:  ## Shell into a service with mounted code
	@read -p "Service name: " SERVICE; \
	docker compose exec $$SERVICE bash
```

## Implementation Roadmap

### Sprint 1: Operational Safety
- [ ] Implement backup/restore scripts
- [ ] Test disaster recovery playbook
- [ ] Document recovery procedures

### Sprint 2: Resilience
- [ ] Deploy chaos testing in staging
- [ ] Document failure scenarios
- [ ] Create incident response templates

### Sprint 3: Resource Governance
- [ ] Apply resource limits to all services
- [ ] Set up monitoring alerts
- [ ] Create scaling playbooks

### Sprint 4: Observability
- [ ] Deploy OpenTelemetry
- [ ] Instrument critical paths
- [ ] Create performance dashboards

### Sprint 5: Developer Experience
- [ ] Set up live reload for all services
- [ ] Document development workflows
- [ ] Create onboarding guide

## Success Metrics

### Operational Safety
- Recovery time < 15 minutes
- Backup success rate > 99%
- Monthly DR drill completed

### Resilience
- All services recover from restart
- Zero customer impact during chaos tests
- MTTR < 5 minutes

### Resources
- No OOM kills in production
- CPU utilization < 80%
- Predictable scaling behavior

### Observability
- P95 latency attribution available
- Trace sampling at 1%
- Alert-to-root-cause < 10 minutes

### Developer Velocity
- Code-to-feedback < 10 seconds
- New developer productive in < 1 day
- Development environment setup < 5 minutes