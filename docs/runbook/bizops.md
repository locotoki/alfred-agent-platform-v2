# Agent BizOps Service Runbook

## Overview

The Agent BizOps service consolidates legal and financial workflows into a single FastAPI service. This runbook covers operational procedures, troubleshooting, and configuration management.

## Service Configuration

### Environment Variables

#### New Variables (Recommended)
```bash
# Workflow Control
WORKFLOWS_ENABLED=legal,finance          # Comma-separated list of enabled workflows

# API Keys
BIZOPS_LEGAL_API_KEY=your-legal-key      # Legal workflow API key
BIZOPS_FINANCE_API_KEY=your-finance-key  # Finance workflow API key

# Database & Infrastructure
BIZOPS_DATABASE_URL=postgresql://...     # Database connection string
BIZOPS_REDIS_URL=redis://redis:6379      # Redis connection string
BIZOPS_RAG_URL=http://agent-rag:8501     # RAG service URL
BIZOPS_MODEL_ROUTER_URL=http://model-router:8080  # Model router URL
BIZOPS_OPENAI_API_KEY=sk-...             # OpenAI API key
```

#### Legacy Variables (Deprecated - with warnings)
```bash
# These will show deprecation warnings but still work
LEGAL_COMPLIANCE_API_KEY=...             # → Use BIZOPS_LEGAL_API_KEY
FINANCIAL_TAX_API_KEY=...                # → Use BIZOPS_FINANCE_API_KEY
ALFRED_DATABASE_URL=...                  # → Use BIZOPS_DATABASE_URL
ALFRED_REDIS_URL=...                     # → Use BIZOPS_REDIS_URL
```

### Workflow Feature Flags

Control which workflows are active at runtime:

```bash
# Enable both workflows (default)
WORKFLOWS_ENABLED=legal,finance

# Enable only legal workflow
WORKFLOWS_ENABLED=legal

# Enable only finance workflow
WORKFLOWS_ENABLED=finance

# Disable all workflows
WORKFLOWS_ENABLED=
```

## Service Health Checks

### Health Endpoint
```bash
# Check service health
curl http://agent-bizops:8080/health

# Expected response
{
  "status": "healthy",
  "service": "agent-bizops",
  "workflows_enabled": ["legal", "finance"]
}
```

### Metrics Endpoint
```bash
# Prometheus metrics
curl http://agent-bizops:9102/metrics

# Key metrics to monitor:
# - bizops_request_total: Total requests by workflow
# - bizops_request_duration_seconds: Request latency histograms
# - bizops_request_failures_total: Failed requests by workflow and error type
# - bizops_workflow_operations_total: Business operations by type and status
# - bizops_active_requests: Currently processing requests
```

#### Key Metric Labels
- `bizops_workflow`: Workflow type (legal, finance, system, unknown)
- `operation_type`: Business operation (compliance_check, tax_calculation, etc.)
- `status`: Operation result (success, failure)
- `error_type`: Error classification (client_error, server_error)
- `method`: HTTP method (GET, POST, etc.)
- `endpoint`: Request path
- `status_code`: HTTP response code

#### Grafana Dashboard
- **UID**: `bizops-dashboard`
- **URL**: `http://grafana:3000/d/bizops-dashboard/agent-bizops-dashboard`

## Docker Compose Operations

### Starting the Service
```bash
# Start with default configuration
docker-compose up agent-bizops

# Start with custom workflow configuration
WORKFLOWS_ENABLED=legal docker-compose up agent-bizops
```

### Scaling and Resource Management
```bash
# Scale service (if using swarm mode)
docker service scale alfred_agent-bizops=3

# Check resource usage
docker stats agent-bizops

# View logs
docker logs -f agent-bizops
```

## Troubleshooting

### Common Issues

#### 1. Service Not Starting
```bash
# Check logs for startup errors
docker logs agent-bizops

# Common causes:
# - Missing required environment variables
# - Database connection issues
# - Port conflicts (8080 already in use)
```

#### 2. Workflow Not Responding
```bash
# Check if workflow is enabled
curl http://agent-bizops:8080/health | jq '.workflows_enabled'

# Check workflow-specific logs
docker logs agent-bizops | grep -E "(legal|finance)"

# Verify feature flag configuration
echo $WORKFLOWS_ENABLED
```

#### 3. Database Connection Issues
```bash
# Test database connectivity
docker exec agent-bizops pg_isready -h db-postgres -p 5432

# Check connection string format
echo $BIZOPS_DATABASE_URL
# Should be: postgresql://user:pass@host:port/database
```

#### 4. Legacy Environment Variable Warnings
```bash
# Look for deprecation warnings in logs
docker logs agent-bizops | grep "deprecated"

# Example output:
# WARNING: Environment variable 'LEGAL_COMPLIANCE_API_KEY' is deprecated.
# Please use 'BIZOPS_LEGAL_API_KEY' instead.
```

### Performance Monitoring

#### Key Metrics to Monitor
```promql
# Response time percentiles
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rates by workflow
rate(http_requests_total{status=~"5.."}[5m])

# Active workflow status
bizops_workflow_enabled{workflow="legal"}
bizops_workflow_enabled{workflow="finance"}

# Resource utilization
container_memory_usage_bytes{name="agent-bizops"}
container_cpu_usage_seconds_total{name="agent-bizops"}
```

#### Alerting Thresholds
- Response time P95 > 2 seconds
- Error rate > 5% over 5 minutes
- Memory usage > 80% of limit
- CPU usage > 80% over 10 minutes

## Migration Procedures

### From Separate Agents to BizOps

#### Pre-Migration Checklist
- [ ] Backup existing agent configurations
- [ ] Document current environment variables
- [ ] Test agent-bizops in staging environment
- [ ] Verify team access and permissions
- [ ] Schedule maintenance window

#### Migration Steps
1. **Deploy agent-bizops service**
   ```bash
   docker-compose up -d agent-bizops
   ```

2. **Verify health and functionality**
   ```bash
   curl http://agent-bizops:8080/health
   # Test legal and finance endpoints
   ```

3. **Stop old agents**
   ```bash
   docker-compose stop agent-legal agent-financial
   ```

4. **Monitor for issues**
   ```bash
   # Watch logs for errors
   docker logs -f agent-bizops

   # Monitor metrics
   curl http://agent-bizops:9091/metrics
   ```

5. **Remove old services** (after validation)
   ```bash
   docker-compose rm agent-legal agent-financial
   ```

#### Post-Migration Validation
- [ ] Legal workflow functional tests pass
- [ ] Finance workflow functional tests pass
- [ ] Integration tests pass
- [ ] Performance metrics within acceptable ranges
- [ ] Team workflows uninterrupted

### Environment Variable Migration

#### Phase 1: Add New Variables (Parallel)
```bash
# Keep old variables, add new ones
LEGAL_COMPLIANCE_API_KEY=legacy-key     # Keep
BIZOPS_LEGAL_API_KEY=legacy-key         # Add (same value)

FINANCIAL_TAX_API_KEY=legacy-key        # Keep
BIZOPS_FINANCE_API_KEY=legacy-key       # Add (same value)
```

#### Phase 2: Remove Old Variables (After validation)
```bash
# Remove legacy variables after confirming new ones work
# LEGAL_COMPLIANCE_API_KEY=legacy-key  # Remove
BIZOPS_LEGAL_API_KEY=legacy-key         # Keep

# FINANCIAL_TAX_API_KEY=legacy-key      # Remove
BIZOPS_FINANCE_API_KEY=legacy-key       # Keep
```

## Security Considerations

### API Key Management
- Store API keys in secure secret management system
- Rotate keys regularly (90-day cycle recommended)
- Use different keys for legal and finance workflows
- Monitor for unauthorized key usage

### Network Security
- Service runs on internal network only (not exposed publicly)
- Uses mTLS for internal service communication
- Database connections encrypted in transit

### Access Control
- Legal workflow data accessible only to legal team members
- Finance workflow data accessible only to finance team members
- Audit logs maintained for all workflow access

## Backup and Recovery

### Data Backup
```bash
# Database backup (automated daily)
pg_dump -h db-postgres -U postgres -d alfred > bizops-backup-$(date +%Y%m%d).sql

# Configuration backup
kubectl get configmap agent-bizops-config -o yaml > bizops-config-backup.yaml
```

### Service Recovery
```bash
# Restart service
docker-compose restart agent-bizops

# Full recovery from backup
docker-compose down agent-bizops
docker volume rm alfred_bizops_data  # If needed
docker-compose up -d agent-bizops
```

## Contact Information

### Team Responsibilities
- **Legal Team**: Legal workflow functionality and business logic
- **Finance Team**: Finance workflow functionality and business logic
- **DevOps Team**: Service infrastructure, deployment, and monitoring
- **On-Call Engineer**: 24/7 service availability and incident response

### Escalation Paths
1. **Level 1**: On-call engineer (PagerDuty)
2. **Level 2**: Team lead for affected workflow (Legal/Finance)
3. **Level 3**: Platform architecture team
4. **Level 4**: Engineering leadership

### Communication Channels
- **Incidents**: #platform-incidents Slack channel
- **Planned Maintenance**: #platform-announcements
- **Team Coordination**: #bizops-team

## Exporters
DB and Redis metrics are now scraped by Prometheus and visible in Grafana (dashboard: *Exporters / Basic*).
