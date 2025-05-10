# Deployment Guide

## Local Development

### Prerequisites

- Docker Desktop
- Python 3.11+
- Git

### Setup

1. Clone and configure:
   ```bash
   git clone https://github.com/your-org/alfred-agent-platform-v2.git
   cd alfred-agent-platform-v2
   make init
   ```

2. Start services:
   ```bash
   make dev
   ```

## Staging Deployment

Staging deployment is automatically triggered when code is pushed to the `develop` branch.

### Configuration

1. Configure GitHub secrets:
   - `STAGING_SUPABASE_URL`
   - `STAGING_SUPABASE_KEY`
   - `STAGING_OPENAI_API_KEY`
   - `STAGING_SLACK_BOT_TOKEN`

2. Update staging configuration in `infra/terraform/environments/staging/terraform.tfvars`

## Production Deployment

Production deployment requires manual approval and is triggered when code is pushed to the `main` branch.

### Prerequisites

- Kubernetes cluster (GKE recommended)
- Configured cloud provider credentials
- Domain name with SSL certificates

### Steps

1. Configure secrets:
   ```bash
   kubectl create secret generic alfred-secrets \
     --from-literal=database-url=$DATABASE_URL \
     --from-literal=openai-api-key=$OPENAI_API_KEY \
     --from-literal=slack-bot-token=$SLACK_BOT_TOKEN
   ```

2. Deploy infrastructure:
   ```bash
   cd infra/terraform/environments/prod
   terraform init
   terraform plan
   terraform apply
   ```

3. Deploy application:
   ```bash
   kubectl apply -k infra/k8s/overlays/prod
   ```

## Monitoring

### Health Checks

All services expose health endpoints:
- `/health/live` - Liveness probe
- `/health/ready` - Readiness probe
- `/health/metrics` - Prometheus metrics

### Alerts

Configure alert notifications in `monitoring/prometheus/alerts/`:
- High error rates
- Service downtime
- Resource exhaustion
- Task processing delays

### Dashboards

Pre-configured Grafana dashboards:
- Platform Overview
- Agent Performance
- Database Metrics
- Message Queue Stats

## Rollback Procedure

1. Identify the last known good version
2. Update image tags in Kubernetes manifests
3. Apply the rollback:
   ```bash
   kubectl rollout undo deployment/alfred-bot
   ```

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Check database credentials
   - Verify network connectivity
   - Check connection pool settings

2. **Pub/Sub Message Delays**
   - Check subscription backlog
   - Verify service scaling
   - Check for processing errors

3. **High Memory Usage**
   - Review container limits
   - Check for memory leaks
   - Scale horizontally

### Debug Commands

```bash
# View logs
kubectl logs -f deployment/alfred-bot

# Check pod status
kubectl get pods -l app=alfred-bot

# Describe pod
kubectl describe pod alfred-bot-xxxxx

# Execute into container
kubectl exec -it alfred-bot-xxxxx -- /bin/bash
```
