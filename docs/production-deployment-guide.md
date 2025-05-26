# Production Deployment Guide

## Overview

This guide covers deploying Alfred Agent Platform v3.0.0 to production using either Docker Compose or Kubernetes/Helm.

## Prerequisites

- Docker Engine 20.10+ with Compose v2
- Kubernetes 1.25+ (for Helm deployment)
- Helm 3.10+ (for Kubernetes deployment)
- Domain with DNS control
- SSL certificates or Let's Encrypt setup
- Production secrets configured

## Docker Compose Deployment

### 1. Environment Setup

Create production environment file:

```bash
# Copy template
cp .env.example .env.prod

# Required environment variables
cat >> .env.prod << EOF
# Domain Configuration
DOMAIN=alfred.example.com
ACME_EMAIL=admin@alfred.example.com

# API Keys (obtain from respective services)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
SLACK_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
CREWAI_API_KEY=...
YOUTUBE_API_KEY=...

# Database Passwords (generate strong passwords)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
OPERATOR_TOKEN=$(openssl rand -base64 32)

# Database URLs
AUTH_DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db-postgres:5432/auth_db
STORAGE_DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db-postgres:5432/storage_db
MODEL_REGISTRY_DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db-postgres:5432/model_registry

# Auth Tokens
A2A_AUTH_TOKEN=$(openssl rand -base64 32)

# Monitoring
GRAFANA_PASSWORD=$(openssl rand -base64 32)
TRAEFIK_USERS=admin:$(openssl passwd -apr1)
EOF
```

### 2. Create Docker Secrets

```bash
# Create secrets from environment variables
while IFS='=' read -r key value; do
  if [[ ! -z "$value" && ! "$key" =~ ^# ]]; then
    echo "$value" | docker secret create "${key,,}" -
  fi
done < .env.prod
```

### 3. Deploy with Docker Compose

```bash
# Deploy with production overrides
docker-compose \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  -f docker-compose.tls.yml \
  --env-file .env.prod \
  up -d

# Verify deployment
docker-compose ps
docker-compose logs -f --tail=100
```

### 4. Health Check Verification

```bash
# Check all services are healthy
./scripts/run_quick_health_check.sh

# Verify endpoints
curl -k https://api.alfred.example.com/health
curl -k https://grafana.alfred.example.com/api/health
curl -k https://chat.alfred.example.com/
```

## Kubernetes/Helm Deployment

### 1. Create Namespace and Secrets

```bash
# Create namespace
kubectl create namespace alfred-prod

# Create image pull secret
kubectl create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  -n alfred-prod

# Create application secrets
kubectl create secret generic openai-api-key \
  --from-literal=OPENAI_API_KEY=$OPENAI_API_KEY \
  -n alfred-prod

kubectl create secret generic anthropic-api-key \
  --from-literal=ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  -n alfred-prod

kubectl create secret generic slack-token \
  --from-literal=SLACK_TOKEN=$SLACK_TOKEN \
  -n alfred-prod

kubectl create secret generic postgres-secret \
  --from-literal=postgres-password=$POSTGRES_PASSWORD \
  -n alfred-prod

kubectl create secret generic redis-secret \
  --from-literal=redis-password=$REDIS_PASSWORD \
  -n alfred-prod
```

### 2. Deploy with Helm

```bash
# Add cert-manager for TLS
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

# Deploy Alfred
helm upgrade --install alfred-prod ./charts/alfred \
  --namespace alfred-prod \
  --values charts/alfred/values-prod-complete.yaml \
  --set global.domain=$DOMAIN \
  --set certManager.email=$ACME_EMAIL \
  --wait

# Check deployment status
kubectl get pods -n alfred-prod
kubectl get ingress -n alfred-prod
```

### 3. Verify Deployment

```bash
# Check pod status
kubectl get pods -n alfred-prod -w

# Check service endpoints
kubectl get svc -n alfred-prod

# View logs
kubectl logs -n alfred-prod -l app.kubernetes.io/name=alfred-core -f

# Run health checks
kubectl exec -n alfred-prod deploy/alfred-core -- wget -qO- http://localhost:8080/health
```

## Post-Deployment Steps

### 1. Database Migrations

```bash
# Run migrations for each database
docker exec alfred-db-postgres-1 psql -U postgres -d alfred_prod -f /migrations/schema.sql

# Verify db-auth schema (if using Supabase Auth)
docker exec alfred-db-auth-1 cat /tmp/init-auth-schema.sql
```

### 2. Configure Monitoring

```bash
# Access Grafana
# URL: https://grafana.alfred.example.com
# User: admin
# Password: $GRAFANA_PASSWORD

# Import dashboards
curl -X POST https://grafana.alfred.example.com/api/dashboards/import \
  -H "Authorization: Bearer $GRAFANA_API_KEY" \
  -H "Content-Type: application/json" \
  -d @grafana/dashboards/alfred-overview.json
```

### 3. Setup Alerts

```bash
# Configure Prometheus alerts
kubectl apply -f monitoring/alerts/production-alerts.yaml

# Configure Slack webhook for alerts
kubectl create secret generic alertmanager-slack \
  --from-literal=webhook-url=$SLACK_WEBHOOK_URL \
  -n alfred-prod
```

### 4. Enable Backups

```bash
# For Docker Compose
docker run --rm -v alfred_postgres_data_prod:/data \
  -v /backup:/backup \
  alpine tar czf /backup/postgres-$(date +%Y%m%d).tar.gz -C /data .

# For Kubernetes
kubectl apply -f backup/cronjob.yaml
```

## Security Checklist

- [ ] All secrets are stored in Docker secrets or Kubernetes secrets
- [ ] TLS/SSL enabled on all public endpoints
- [ ] Network policies configured to restrict traffic
- [ ] Resource limits set on all containers
- [ ] Security contexts configured (non-root, read-only filesystem)
- [ ] Regular security scanning enabled
- [ ] Audit logging configured
- [ ] Backup and disaster recovery tested

## Troubleshooting

### Service Not Starting

```bash
# Check logs
docker-compose logs <service-name>
kubectl logs -n alfred-prod deploy/<service-name>

# Check resource usage
docker stats
kubectl top pods -n alfred-prod

# Verify secrets
docker secret ls
kubectl get secrets -n alfred-prod
```

### Health Check Failures

```bash
# Manual health check
curl http://localhost:8080/health

# Check dependencies
docker-compose exec alfred-core ping db-postgres
kubectl exec -n alfred-prod deploy/alfred-core -- nslookup postgres
```

### Performance Issues

```bash
# Check resource limits
docker-compose ps --format "table {{.Name}}\t{{.Status}}"
kubectl describe pod -n alfred-prod

# Monitor metrics
curl http://prometheus:9090/api/v1/query?query=up
```

## Rollback Procedure

### Docker Compose

```bash
# Stop current deployment
docker-compose down

# Restore previous version
docker-compose \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  --env-file .env.prod \
  up -d --force-recreate
```

### Kubernetes

```bash
# Rollback to previous release
helm rollback alfred-prod -n alfred-prod

# Or deploy specific version
helm upgrade alfred-prod ./charts/alfred \
  --namespace alfred-prod \
  --values charts/alfred/values-prod.yaml \
  --set global.imageTag=v2.9.0 \
  --wait
```

## Maintenance

### Regular Tasks

1. **Daily**
   - Monitor health endpoints
   - Check error logs
   - Verify backup completion

2. **Weekly**
   - Review resource usage
   - Update dependencies
   - Security scan

3. **Monthly**
   - Performance analysis
   - Cost optimization
   - Disaster recovery test

### Upgrade Procedure

```bash
# 1. Backup current state
./scripts/backup-prod.sh

# 2. Test in staging
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d

# 3. Deploy to production
docker-compose pull
docker-compose up -d --no-deps --build

# 4. Verify
./scripts/run_quick_health_check.sh
```

## Support

- Documentation: https://docs.alfred.example.com
- Issues: https://github.com/locotoki/alfred-agent-platform-v2/issues
- Slack: #alfred-support
