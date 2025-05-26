# Production Deployment Checklist

## Pre-Deployment Requirements

### Infrastructure
- [ ] Production Kubernetes cluster or Docker Swarm ready
- [ ] Load balancer configured
- [ ] DNS records pointing to load balancer
- [ ] SSL certificates ready (or Let's Encrypt configured)
- [ ] Backup storage (S3 or equivalent) configured

### Secrets & Configuration
- [ ] Copy `.env.prod.template` to `.env.prod`
- [ ] Generate strong passwords for all services
- [ ] Set up Slack app and obtain tokens
- [ ] Configure OpenAI/Anthropic API keys
- [ ] Create Docker secrets or Kubernetes secrets
- [ ] Set up monitoring credentials

### Database
- [ ] Production PostgreSQL instance ready
- [ ] Database backup strategy in place
- [ ] Connection pooling configured
- [ ] SSL enabled for database connections

## Deployment Steps

### 1. Health Check Validation
```bash
# Verify all services are healthy in staging
docker-compose -f docker-compose.yml \
               -f docker-compose.override.health-fixes.yml \
               -f docker-compose.prod.yml \
               ps
```

### 2. Build Production Images
```bash
# Build all images with production tags
make build-prod TAG=v3.0.0

# Push to registry
make push-prod TAG=v3.0.0
```

### 3. Deploy with Docker Compose (Single Node)
```bash
# Deploy with production overrides
docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml \
               -f docker-compose.tls.yml \
               up -d

# Verify deployment
docker-compose ps
docker-compose logs -f
```

### 4. Deploy with Docker Swarm (Multi-Node)
```bash
# Initialize swarm (if not already done)
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml \
                   -c docker-compose.prod.yml \
                   -c docker-compose.tls.yml \
                   alfred

# Verify services
docker service ls
docker service ps alfred_agent-core
```

### 5. Deploy with Helm (Kubernetes)
```bash
# Create namespace
kubectl create namespace alfred-prod

# Install with production values
helm install alfred ./charts/alfred \
  --namespace alfred-prod \
  --values ./charts/alfred/values.yaml \
  --values ./charts/alfred/values-prod.yaml \
  --set image.tag=v3.0.0

# Verify deployment
kubectl -n alfred-prod get pods
kubectl -n alfred-prod get svc
```

## Post-Deployment Validation

### Health Checks
- [ ] All services report healthy status
- [ ] No restart loops detected
- [ ] Memory and CPU usage within limits

### Functional Tests
- [ ] API endpoint responds at https://api.${DOMAIN}/health
- [ ] UI accessible at https://chat.${DOMAIN}
- [ ] Slack bot responds to test message
- [ ] Metrics visible in Grafana
- [ ] Logs flowing to monitoring system

### Performance Tests
- [ ] Load test with expected traffic
- [ ] Response times within SLA
- [ ] No memory leaks detected
- [ ] Database connection pool stable

### Security Validation
- [ ] TLS certificates valid
- [ ] No exposed internal ports
- [ ] Authentication working correctly
- [ ] Rate limiting active
- [ ] CORS configured properly

## Monitoring Setup

### Alerts Configuration
- [ ] Service down alerts
- [ ] High CPU/memory alerts
- [ ] Database connection alerts
- [ ] API error rate alerts
- [ ] SSL certificate expiry alerts

### Dashboards
- [ ] Service health dashboard
- [ ] API metrics dashboard
- [ ] Infrastructure metrics dashboard
- [ ] Business metrics dashboard

## Rollback Plan

### Quick Rollback
```bash
# Docker Compose
docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml \
               down

docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml \
               up -d --force-recreate

# Kubernetes
helm rollback alfred -n alfred-prod
```

### Database Rollback
- [ ] Backup taken before deployment
- [ ] Rollback scripts tested
- [ ] Point-in-time recovery configured

## Sign-offs

- [ ] Engineering Lead: _________________ Date: _______
- [ ] Operations Lead: _________________ Date: _______
- [ ] Security Lead: __________________ Date: _______
- [ ] Product Owner: __________________ Date: _______

## Notes
- db-auth uses custom Dockerfile to fix GoTrue migrations
- Health checks achieve 87.2% coverage (34/39 services)
- Stub services use simplified health checks
- Production uses encrypted overlay network
