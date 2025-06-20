---
title: Deployment Guide
description: Comprehensive guide for deploying, monitoring, and maintaining the Alfred Agent Platform v2
author: Documentation Team
created: 2025-05-10
last_updated: 2025-05-10
category: operations
tags: [deployment, operations, infrastructure, monitoring, kubernetes]
version: 1.0.0
status: stable
---

# Deployment Guide

This guide provides comprehensive instructions for deploying, operating, and maintaining the Alfred Agent Platform v2 across development, staging, and production environments.

## Overview

The Alfred Agent Platform v2 follows a containerized microservices architecture deployed on Kubernetes. This guide covers the deployment process, configuration management, monitoring setup, and operational procedures to ensure reliable service operation.

## Environments

The platform supports three distinct environments:

| Environment | Purpose | Deployment Trigger | Infrastructure |
|-------------|---------|-------------------|----------------|
| Development | Local development and testing | Manual | Docker Compose |
| Staging | Integration testing and validation | Automatic (on `develop` branch push) | Kubernetes (dev cluster) |
| Production | Live user-facing services | Manual approval (on `main` branch push) | Kubernetes (prod cluster) |

## Prerequisites

### Local Development

- Docker Desktop
- Python 3.11+
- Node.js 18+
- Git
- Make

### Production Deployment

- Kubernetes cluster (GKE recommended)
- Configured cloud provider credentials
- Helm 3+
- kubectl
- Domain name with SSL certificates
- Secrets management solution

## Local Development Setup

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/alfred-agent-platform-v2.git
   cd alfred-agent-platform-v2
   ```

2. Initialize the development environment:
   ```bash
   make init
   ```

3. Start services:
   ```bash
   make dev
   ```

### Configuration

Local development uses `.env` files for configuration:

1. Copy the template:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file to configure:
   - API keys for external services
   - Database connection details
   - Feature flags
   - Local ports

## Staging Deployment

Staging deployment is automatically triggered when code is pushed to the `develop` branch through CI/CD pipelines.

### Configuration

1. Configure GitHub secrets:
   - `STAGING_SUPABASE_URL`
   - `STAGING_SUPABASE_KEY`
   - `STAGING_OPENAI_API_KEY`
   - `STAGING_SLACK_BOT_TOKEN`

2. Update staging configuration in `infra/terraform/environments/staging/terraform.tfvars`

3. Staging-specific environment variables are stored in GitHub Environment `staging`

### Deployment Process

1. Code pushed to `develop` branch triggers the CI/CD pipeline
2. Pipeline runs tests, builds container images, and tags them with the commit SHA
3. Pipeline updates Kubernetes manifests with new image tags
4. Changes are applied to the staging Kubernetes cluster
5. Pipeline runs smoke tests and integration tests
6. Deployment status is reported back to GitHub

## Production Deployment

Production deployment requires manual approval and is triggered when code is pushed to the `main` branch.

### Prerequisites

1. Access to production Kubernetes cluster
2. Required secrets and environment variables
3. Production domain configuration
4. Approval from authorized personnel

### Deployment Steps

1. Configure Kubernetes secrets:
   ```bash
   kubectl create secret generic alfred-secrets \
     --from-literal=database-url=$DATABASE_URL \
     --from-literal=openai-api-key=$OPENAI_API_KEY \
     --from-literal=slack-bot-token=$SLACK_BOT_TOKEN
   ```

2. Deploy infrastructure using Terraform:
   ```bash
   cd infra/terraform/environments/prod
   terraform init
   terraform plan
   terraform apply
   ```

3. Deploy application services using Kubernetes manifests:
   ```bash
   kubectl apply -k infra/k8s/overlays/prod
   ```

4. Verify deployment status:
   ```bash
   kubectl get pods
   kubectl get services
   ```

### Deployment Checklist

Before completing a production deployment:

1. Run the deployment checklist script:
   ```bash
   ./scripts/deployment-checklist.sh
   ```

2. The script verifies:
   - All tests are passing
   - Code coverage meets thresholds
   - Security scans are clean
   - Documentation is up-to-date
   - Environment variables are configured
   - Health checks are passing

## Service Configuration

### Environment Variables

Each service requires specific environment variables:

1. Core Service:
   - `DATABASE_URL`
   - `REDIS_URL`
   - `PORT`
   - `LOG_LEVEL`
   - `NODE_ENV`

2. Agent Services:
   - `OPENAI_API_KEY`
   - `MODEL_NAME`
   - `VECTOR_DB_URL`
   - `AGENT_PORT`

3. Mission Control:
   - `SOCIAL_INTEL_HOST`
   - `SOCIAL_INTEL_PORT`
   - `ENABLE_MOCK_FALLBACK`
   - `API_TIMEOUT`

### Feature Flags

Feature flags are managed through environment variables with the `FEATURE_` prefix:

- `FEATURE_NEW_AGENT_FRAMEWORK`
- `FEATURE_ENHANCED_SEARCH`
- `FEATURE_COLLABORATIVE_AGENTS`

## Monitoring and Observability

### Health Checks

All services expose the following health endpoints:

- `/health/live` - Liveness probe (is the service running?)
- `/health/ready` - Readiness probe (is the service ready to accept traffic?)
- `/health/metrics` - Prometheus metrics
- `/api/health` - Overall service health status

### Metrics

The platform collects the following metrics:

1. Service-level metrics:
   - Request count
   - Request latency
   - Error rates
   - Resource utilization

2. Business metrics:
   - Agent executions
   - Workflow completions
   - User interactions

### Alerting

Configure alerting rules in `monitoring/prometheus/alerts/`:

1. High error rates:
   - >1% 5xx errors in 5 minutes
   - >5% 4xx errors in 15 minutes

2. Service downtime:
   - Any service unavailable for >2 minutes

3. Resource exhaustion:
   - >85% CPU utilization for >5 minutes
   - >85% memory utilization for >5 minutes

4. Task processing delays:
   - Agent task queue >100 items
   - Message processing latency >5 seconds

### Dashboards

Pre-configured Grafana dashboards:

1. Platform Overview:
   - Service health status
   - Request volume and latency
   - Error rates

2. Agent Performance:
   - Agent execution count
   - Agent execution time
   - Agent error rates

3. Database Metrics:
   - Connection count
   - Query performance
   - Index usage

4. Message Queue Stats:
   - Queue depth
   - Message processing time
   - Dead letter queue size

## Scaling

### Horizontal Scaling

Services are configured for horizontal scaling based on metrics:

1. Configure Horizontal Pod Autoscaler (HPA):
   ```yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: alfred-bot
   spec:
     scaleTargetRef:
       apiVersion: apps/v1
       kind: Deployment
       name: alfred-bot
     minReplicas: 2
     maxReplicas: 10
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
   ```

2. Scaling thresholds:
   - CPU utilization >70% for 2 minutes
   - Memory utilization >80% for 2 minutes
   - Custom metrics: >10 concurrent requests per instance

### Resource Allocation

Base resource allocation for services:

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| Alfred Bot | 250m | 500m | 512Mi | 1Gi |
| Social Intelligence | 500m | 1000m | 1Gi | 2Gi |
| Financial Tax | 250m | 500m | 512Mi | 1Gi |
| Legal Compliance | 250m | 500m | 512Mi | 1Gi |
| Mission Control | 250m | 500m | 512Mi | 1Gi |

## Backup and Recovery

### Database Backups

1. Automated backups:
   - Daily full backups (retained for 30 days)
   - Point-in-time recovery enabled
   - Transaction logs backed up every 5 minutes

2. Manual backup before major changes:
   ```bash
   ./scripts/backup-database.sh pre-deployment-$(date +%Y%m%d)
   ```

### Recovery Procedures

1. In case of data corruption:
   ```bash
   ./scripts/restore-database.sh <backup-name>
   ```

2. In case of service failure, rolling back to a previous version:
   ```bash
   kubectl rollout undo deployment/<service-name>
   ```

## Rollback Procedures

### Application Rollback

If a deployment causes issues:

1. Identify the last known good version:
   ```bash
   kubectl rollout history deployment/<service-name>
   ```

2. Update image tags in Kubernetes manifests:
   ```bash
   kubectl set image deployment/<service-name> <container-name>=<registry>/<image>:<previous-tag>
   ```

3. Apply the rollback:
   ```bash
   kubectl rollout undo deployment/<service-name>
   ```

### Infrastructure Rollback

If infrastructure changes cause issues:

1. Revert to the previous Terraform state:
   ```bash
   cd infra/terraform/environments/prod
   terraform plan -target=<problematic-resource> -out=rollback.plan
   terraform apply rollback.plan
   ```

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Check database credentials in environment variables
   - Verify network connectivity between services and database
   - Check connection pool settings (max connections, idle timeout)
   - Verify database service is running and accessible

2. **Message Queue Issues**
   - Check subscription backlog in Redis or Pub/Sub
   - Verify service scaling is appropriate for message volume
   - Check for processing errors in consumer services
   - Verify message schema matches consumer expectations

3. **High Memory Usage**
   - Review container memory limits
   - Check for memory leaks using profiling tools
   - Consider scaling horizontally instead of vertically
   - Implement memory optimization techniques

4. **Service Startup Failures**
   - Check for missing environment variables
   - Verify dependent services are available
   - Check logs for startup errors
   - Verify service health endpoint status

### Debug Commands

```bash
# View service logs
kubectl logs -f deployment/<service-name>

# Check pod status
kubectl get pods -l app=<service-name>

# Describe pod for detailed status
kubectl describe pod <pod-name>

# Execute into container for debugging
kubectl exec -it <pod-name> -- /bin/bash

# Check service connectivity
kubectl run -it --rm debug --image=curlimages/curl -- curl <service-name>:<port>/health

# Check environment variables
kubectl exec <pod-name> -- env

# Monitor resource usage
kubectl top pods
kubectl top nodes
```

## Security Considerations

### Secret Management

1. Kubernetes Secrets:
   - Store sensitive information in Kubernetes Secrets
   - Access secrets as environment variables in pods
   - Rotate secrets regularly

2. External Secret Management:
   - For production, use a dedicated secret management solution
   - Options: Hashicorp Vault, AWS Secrets Manager, GCP Secret Manager
   - Integrate with CI/CD for secure deployment

### Network Policies

Implement Kubernetes Network Policies to restrict service-to-service communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: alfred-bot-network-policy
spec:
  podSelector:
    matchLabels:
      app: alfred-bot
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: mission-control
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

## Continuous Integration

### CI/CD Pipeline

The platform uses GitHub Actions for CI/CD:

1. On feature branch:
   - Run tests, linting, and security scans
   - Build Docker images
   - Deploy to preview environment
   - Comment preview URL on PR

2. On develop branch:
   - Deploy to staging environment
   - Run integration tests
   - Record test results

3. On main branch:
   - Require manual approval
   - Deploy to production with canary strategy
   - Monitor metrics during deployment
   - Rollback automatically if health checks fail

## Mission Control Deployment

The Mission Control service has specific deployment requirements:

1. Production Build:
   ```bash
   ./services/mission-control/start-container.sh
   ```

2. Development Mode:
   ```bash
   ./services/mission-control/start-container.sh development
   ```

3. Integration with Services:
   - Connect to Social Intelligence at `http://architect-api:9000`
   - Connect to Financial Tax at `http://financial-tax:9003`
   - Connect to Legal Compliance at `http://legal-compliance:9002`

4. Port Configuration:
   - Internal port: 3000
   - Host mapping: 3007
   - Access URL: http://localhost:3007

## Deployment FAQ

### How do I deploy a single service?

To deploy only a specific service:

```bash
kubectl apply -f infra/k8s/overlays/prod/<service-name>-deployment.yaml
```

### How do I monitor deployment progress?

Monitor the rollout status:

```bash
kubectl rollout status deployment/<service-name>
```

### How do I verify a successful deployment?

1. Check that all pods are running:
   ```bash
   kubectl get pods -l app=<service-name>
   ```

2. Verify health endpoints:
   ```bash
   curl http://<service-url>/health/ready
   ```

3. Check service metrics:
   ```bash
   curl http://<service-url>/health/metrics
   ```

## Conclusion

This deployment guide provides comprehensive instructions for deploying, operating, and maintaining the Alfred Agent Platform v2. Follow these guidelines to ensure reliable service operation across development, staging, and production environments.

For further assistance or to report issues, contact the platform operations team at operations@example.com.

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Alerting Guide](https://prometheus.io/docs/alerting/latest/configuration/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Docker Documentation](https://docs.docker.com/)
