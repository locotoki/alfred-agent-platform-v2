# Financial-Tax Agent Deployment Checklist

## Pre-deployment Verification

### Code Quality
- [ ] All tests passing
  ```bash
  pytest agents/financial_tax/tests/ -v
  ```
- [ ] Code coverage >90%
  ```bash
  pytest --cov=agents/financial_tax --cov-report=html
  ```
- [ ] No security vulnerabilities
  ```bash
  bandit -r agents/financial_tax/
  ```
- [ ] Documentation complete
  - [ ] API documentation updated
  - [ ] Agent documentation reviewed
  - [ ] Changelog updated

### Infrastructure
- [ ] Docker image builds successfully
  ```bash
  docker build -t financial-tax-agent:latest services/financial-tax/
  ```
- [ ] Environment variables configured
  - [ ] `DATABASE_URL`
  - [ ] `REDIS_URL`
  - [ ] `PUBSUB_EMULATOR_HOST`
  - [ ] `OPENAI_API_KEY`
  - [ ] `LANGSMITH_API_KEY`
- [ ] Database migrations ready
  ```bash
  make db-migrate
  ```
- [ ] Health check endpoints working
  ```bash
  curl http://localhost:9003/health/health
  ```

### Integration
- [ ] A2A communication tested
  ```bash
  pytest tests/integration/financial_tax/test_integration.py -v
  ```
- [ ] API endpoints validated
  ```bash
  curl -X POST http://localhost:9003/api/v1/financial-tax/calculate-tax
  ```
- [ ] Error handling verified
- [ ] Monitoring configured
  - [ ] Prometheus scraping metrics
  - [ ] Grafana dashboard available
  - [ ] Alerts configured

### Security
- [ ] Authentication implemented
- [ ] RBAC configured
- [ ] Secrets management setup
- [ ] TLS certificates ready
- [ ] Rate limiting configured
- [ ] PII scrubbing tested

## Deployment Steps

### 1. Build and Test
```bash
# Run all tests
make test-financial-tax

# Build Docker image
docker build -t financial-tax-agent:latest services/financial-tax/

# Run integration tests
make test-integration
```

### 2. Deploy to Staging
```bash
# Deploy to staging environment
kubectl apply -f k8s/financial-tax/staging/

# Verify deployment
curl http://staging.financial-tax:9003/health/health

# Run smoke tests
./scripts/smoke-test-financial-tax.sh staging
```

### 3. Performance Testing
```bash
# Run load tests
k6 run tests/load/financial-tax-load-test.js

# Monitor metrics during test
watch 'curl -s http://staging.financial-tax:9003/health/metrics | grep financial_tax'
```

### 4. Deploy to Production
```bash
# Deploy to production
kubectl apply -f k8s/financial-tax/production/

# Verify deployment
curl https://api.alfred-platform.com/financial-tax/health

# Monitor logs
kubectl logs -f deployment/financial-tax -n production
```

## Post-deployment Monitoring

### Health Checks
- [ ] Agent responding to health endpoints
- [ ] Database connections stable
- [ ] Redis connections healthy
- [ ] Pub/Sub subscriptions active

### Metrics Monitoring
- [ ] Task processing rate normal
- [ ] Error rate < 1%
- [ ] Response times < 2s (p95)
- [ ] Memory usage stable
- [ ] CPU usage < 70%

### Log Monitoring
- [ ] No critical errors in logs
- [ ] PII scrubbing working
- [ ] Task completion events publishing

### Integration Verification
- [ ] Cross-agent communication working
- [ ] Slack integration functioning
- [ ] API endpoints accessible
- [ ] Task results storing correctly

## Rollback Plan

### Immediate Rollback
```bash
# Rollback deployment
kubectl rollout undo deployment/financial-tax -n production

# Verify rollback
kubectl rollout status deployment/financial-tax -n production
```

### Database Rollback
```bash
# Restore database from backup
./scripts/restore-db.sh --backup-id=<backup-id>
```

### Configuration Rollback
```bash
# Restore previous configuration
kubectl apply -f k8s/financial-tax/production/config-v1.yaml
```

## Troubleshooting

### Common Issues

1. **Agent Not Starting**
   - Check logs: `kubectl logs deployment/financial-tax`
   - Verify environment variables
   - Check database connectivity

2. **High Error Rate**
   - Monitor error logs
   - Check API quotas
   - Verify input validation

3. **Slow Performance**
   - Check resource allocation
   - Monitor queue length
   - Review database queries

### Emergency Contacts

- On-call Engineer: +1-XXX-XXX-XXXX
- Platform Lead: platform-lead@alfred-platform.com
- Security Team: security@alfred-platform.com

## Sign-off

- [ ] QA Engineer: _______________
- [ ] DevOps Engineer: _______________
- [ ] Platform Lead: _______________
- [ ] Product Owner: _______________

Date: _______________
Version: ______________
