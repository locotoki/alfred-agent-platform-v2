# Infrastructure Component: CI/CD Pipeline Infrastructure

*Last Updated: 2025-05-13*  
*Owner: DevOps Team*  
*Status: Active*

## Overview

This document describes the Continuous Integration and Continuous Deployment (CI/CD) infrastructure for the Alfred Agent Platform v2. The CI/CD pipeline automates the build, test, and deployment processes, ensuring code quality, security, and reliability throughout the development lifecycle. It provides a standardized workflow for developers to deliver changes safely and efficiently to various environments.

## Architecture

The CI/CD pipeline infrastructure is built around GitHub Actions, containerized deployments, and infrastructure as code principles:

```mermaid
graph TD
    subgraph "Source Control"
        repo[GitHub Repository]
    end
    
    subgraph "CI Pipeline"
        security[Security Scanning]
        lint[Linting and Code Quality]
        unitTest[Unit Testing]
        build[Docker Image Building]
        integration[Integration Testing]
    end
    
    subgraph "CD Pipeline"
        registry[Container Registry]
        deploy_dev[Development Deployment]
        deploy_staging[Staging Deployment]
        deploy_prod[Production Deployment]
    end
    
    subgraph "Infrastructure"
        terraform[Terraform IaC]
        k8s[Kubernetes Manifests]
        compose[Docker Compose]
    end
    
    developer[Developer] --> |commit| repo
    repo --> |trigger| security
    security --> lint
    lint --> unitTest
    unitTest --> build
    build --> integration
    integration --> registry
    
    registry --> deploy_dev
    deploy_dev --> |approval| deploy_staging
    deploy_staging --> |approval| deploy_prod
    
    terraform --> deploy_dev
    terraform --> deploy_staging
    terraform --> deploy_prod
    
    k8s --> deploy_staging
    k8s --> deploy_prod
    
    compose --> deploy_dev
```

## Configuration

### GitHub Actions Workflow

#### Main CI Workflow

The main CI workflow (`ci.yml`) runs on pushes to main/develop branches and pull requests:

```yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  PYTHON_VERSION: "3.11"
  NODE_VERSION: "20"
  DOCKER_BUILDKIT: 1
  COMPOSE_DOCKER_CLI_BUILD: 1

jobs:
  # Security scanning
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: TruffleHog OSS
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
          extra_args: --debug --only-verified

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          trivy-config: trivy.yaml
          severity: 'CRITICAL,HIGH'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

  # Python linting and testing
  lint-and-test:
    needs: security-scan
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run formatters check
        run: |
          black --check .
          isort --check-only .

      - name: Run linters
        run: |
          flake8 .
          mypy .
          bandit -r agents/ libs/ services/ -c pyproject.toml

      - name: Run tests with coverage
        run: |
          pytest tests/ -v --cov=./ --cov-report=xml --cov-report=html
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          PUBSUB_EMULATOR_HOST: localhost:8085

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: ./coverage.xml
          flags: unittests
          name: codecov-umbrella
          fail_ci_if_error: false

  # Build Docker images
  build-images:
    needs: lint-and-test
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - alfred-bot
          - social-intel
          - legal-compliance
          - financial-tax
          - mission-control

    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Cache Docker layers
        uses: actions/cache@v3
        with:
          path: /tmp/.buildx-cache
          key: ${{ runner.os }}-buildx-${{ matrix.service }}-${{ github.sha }}
          restore-keys: |
            ${{ runner.os }}-buildx-${{ matrix.service }}-
            ${{ runner.os }}-buildx-

      - name: Login to Docker Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ secrets.DOCKER_REGISTRY }}
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push ${{ matrix.service }}
        uses: docker/build-push-action@v4
        with:
          context: ./services/${{ matrix.service }}
          push: true
          tags: |
            ${{ secrets.DOCKER_REGISTRY }}/alfred-platform/${{ matrix.service }}:${{ github.sha }}
            ${{ secrets.DOCKER_REGISTRY }}/alfred-platform/${{ matrix.service }}:latest
          cache-from: type=local,src=/tmp/.buildx-cache
          cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max

      - name: Move cache
        run: |
          rm -rf /tmp/.buildx-cache
          mv /tmp/.buildx-cache-new /tmp/.buildx-cache

  # Integration tests
  integration-tests:
    needs: build-images
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Start services
        run: |
          docker-compose -f docker-compose.yml up -d
          sleep 30  # Wait for services to be ready

      - name: Run integration tests
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
          pytest tests/integration/ -v -m integration

      - name: Stop services
        if: always()
        run: docker-compose down -v
```

#### Service-Specific Workflow

Service-specific workflows (like `financial-tax-agent.yml`) trigger on changes to specific services:

```yaml
name: Financial-Tax Agent CI/CD

on:
  push:
    paths:
      - 'services/financial-tax/**'
      - 'agents/financial_tax/**'
      - '.github/workflows/financial-tax-agent.yml'
  pull_request:
    paths:
      - 'services/financial-tax/**'
      - 'agents/financial_tax/**'

env:
  PYTHON_VERSION: "3.11"
  DOCKER_BUILDKIT: 1
  COMPOSE_DOCKER_CLI_BUILD: 1

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true
      
      - name: Set up Python ${{ env.PYTHON_VERSION }}
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run unit tests
        run: |
          pytest agents/financial_tax/tests/ -v --cov=agents/financial_tax
      
      - name: Check coverage
        run: |
          coverage report --fail-under=90
  
  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Cache Docker layers
        uses: actions/cache@v3
        with:
          path: /tmp/.buildx-cache
          key: ${{ runner.os }}-buildx-financial-tax-${{ github.sha }}
          restore-keys: |
            ${{ runner.os }}-buildx-financial-tax-
      
      - name: Build Docker image
        uses: docker/build-push-action@v4
        with:
          context: ./services/financial-tax
          file: ./services/financial-tax/Dockerfile
          push: false
          tags: |
            alfred-platform/financial-tax:${{ github.sha }}
            alfred-platform/financial-tax:latest
          cache-from: type=local,src=/tmp/.buildx-cache
          cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max
      
      - name: Move cache
        run: |
          rm -rf /tmp/.buildx-cache
          mv /tmp/.buildx-cache-new /tmp/.buildx-cache
  
  # Additional stages for integration testing and deployment
```

### Docker Build Configuration

Docker images are built using Dockerfiles that follow security best practices:

```dockerfile
FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
COPY requirements-dev.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r requirements-dev.txt

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

# Copy application code
COPY app app/

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 9003

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9003/health/ || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9003"]
```

### Environment-Specific Deployment Configurations

#### Development Environment

```yaml
# Deployment configuration for development
apiVersion: apps/v1
kind: Deployment
metadata:
  name: financial-tax
  namespace: alfred-platform-dev
  labels:
    app: alfred-platform
    component: financial-tax
    environment: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alfred-platform
      component: financial-tax
  template:
    metadata:
      labels:
        app: alfred-platform
        component: financial-tax
    spec:
      containers:
      - name: financial-tax
        image: ${DOCKER_REGISTRY}/alfred-platform/financial-tax:${IMAGE_TAG}
        env:
        - name: ENVIRONMENT
          value: development
        - name: DEBUG
          value: "true"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: url
        - name: REDIS_URL
          value: redis://redis:6379
        ports:
        - containerPort: 9003
        resources:
          limits:
            cpu: 500m
            memory: 1Gi
          requests:
            cpu: 200m
            memory: 512Mi
```

#### Production Environment

```yaml
# Deployment configuration for production
apiVersion: apps/v1
kind: Deployment
metadata:
  name: financial-tax
  namespace: alfred-platform-prod
  labels:
    app: alfred-platform
    component: financial-tax
    environment: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: alfred-platform
      component: financial-tax
  template:
    metadata:
      labels:
        app: alfred-platform
        component: financial-tax
    spec:
      containers:
      - name: financial-tax
        image: ${DOCKER_REGISTRY}/alfred-platform/financial-tax:${IMAGE_TAG}
        env:
        - name: ENVIRONMENT
          value: production
        - name: DEBUG
          value: "false"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: url
        - name: REDIS_URL
          value: redis://redis.alfred-platform-prod:6379
        ports:
        - containerPort: 9003
        resources:
          limits:
            cpu: 1000m
            memory: 2Gi
          requests:
            cpu: 500m
            memory: 1Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 9003
          initialDelaySeconds: 30
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /health
            port: 9003
          initialDelaySeconds: 5
          periodSeconds: 10
```

## CI/CD Workflow Stages

### 1. Code Quality and Security

#### Static Code Analysis

```yaml
# Linting and code quality
- name: Run formatters check
  run: |
    black --check .
    isort --check-only .

- name: Run linters
  run: |
    flake8 .
    mypy .
    bandit -r agents/ libs/ services/ -c pyproject.toml
```

#### Security Scanning

```yaml
# Security scanning
- name: TruffleHog OSS
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: ${{ github.event.repository.default_branch }}
    head: HEAD
    extra_args: --debug --only-verified

- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    trivy-config: trivy.yaml
    severity: 'CRITICAL,HIGH'
    format: 'sarif'
    output: 'trivy-results.sarif'
```

### 2. Testing

#### Unit Testing

```yaml
# Unit testing with coverage
- name: Run tests with coverage
  run: |
    pytest tests/ -v --cov=./ --cov-report=xml --cov-report=html
  env:
    DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
    PUBSUB_EMULATOR_HOST: localhost:8085
```

#### Integration Testing

```yaml
# Integration testing
- name: Start services
  run: |
    docker-compose -f docker-compose.yml up -d
    sleep 30  # Wait for services to be ready

- name: Run integration tests
  run: |
    pip install -r requirements.txt
    pip install -r requirements-dev.txt
    pytest tests/integration/ -v -m integration
```

### 3. Build and Publish

#### Docker Image Building

```yaml
# Build Docker image
- name: Build and push ${{ matrix.service }}
  uses: docker/build-push-action@v4
  with:
    context: ./services/${{ matrix.service }}
    push: true
    tags: |
      ${{ secrets.DOCKER_REGISTRY }}/alfred-platform/${{ matrix.service }}:${{ github.sha }}
      ${{ secrets.DOCKER_REGISTRY }}/alfred-platform/${{ matrix.service }}:latest
    cache-from: type=local,src=/tmp/.buildx-cache
    cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max
```

#### Container Registry

The built container images are stored in a private container registry:

```yaml
# Login to Docker Registry
- name: Login to Docker Registry
  uses: docker/login-action@v2
  with:
    registry: ${{ secrets.DOCKER_REGISTRY }}
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

### 4. Deployment

#### Development Deployment

Automatic deployment to the development environment after successful build and tests:

```yaml
# Development deployment (simplified example)
- name: Deploy to Development
  if: github.ref == 'refs/heads/develop'
  run: |
    export IMAGE_TAG=${{ github.sha }}
    export DOCKER_REGISTRY=${{ secrets.DOCKER_REGISTRY }}
    envsubst < k8s/dev/deployment.yaml | kubectl apply -f -
  env:
    KUBECONFIG: ${{ secrets.DEV_KUBECONFIG }}
```

#### Staging/Production Deployment

Production deployments typically require manual approval:

```yaml
# Production deployment (simplified example)
- name: Deploy to Production
  if: github.ref == 'refs/heads/main'
  run: |
    export IMAGE_TAG=${{ github.sha }}
    export DOCKER_REGISTRY=${{ secrets.DOCKER_REGISTRY }}
    envsubst < k8s/prod/deployment.yaml | kubectl apply -f -
  env:
    KUBECONFIG: ${{ secrets.PROD_KUBECONFIG }}
```

## Infrastructure as Code

### Terraform Configuration

```hcl
# Example Terraform EKS configuration
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "alfred-platform-${var.environment}"
  cluster_version = "1.25"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    general = {
      desired_capacity = 2
      max_capacity     = 10
      min_capacity     = 2

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
}

# Container Registry
resource "aws_ecr_repository" "alfred_platform" {
  for_each = toset([
    "alfred-bot",
    "social-intel",
    "legal-compliance",
    "financial-tax",
    "mission-control"
  ])

  name                 = "alfred-platform/${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

### Kubernetes Manifests

```yaml
# Example Kubernetes namespace definition
apiVersion: v1
kind: Namespace
metadata:
  name: alfred-platform-${ENVIRONMENT}
  labels:
    name: alfred-platform-${ENVIRONMENT}
    environment: ${ENVIRONMENT}

---
# Example Kubernetes secret for CI/CD
apiVersion: v1
kind: Secret
metadata:
  name: ci-cd-secrets
  namespace: alfred-platform-${ENVIRONMENT}
type: Opaque
data:
  docker-username: ${DOCKER_USERNAME_BASE64}
  docker-password: ${DOCKER_PASSWORD_BASE64}
  github-token: ${GITHUB_TOKEN_BASE64}
```

## Monitoring and Logging

### CI/CD Pipeline Monitoring

```yaml
# Workflow metrics collection
- name: Collect workflow metrics
  run: |
    curl -X POST -H "Content-Type: application/json" \
      -d '{"workflow":"${{ github.workflow }}","status":"${{ job.status }}","duration":"${{ steps.metrics.outputs.duration }}"}' \
      https://monitoring.alfred-platform.example.com/api/cicd-metrics
```

### Build and Deployment Logging

```yaml
# Log build information
- name: Log build info
  run: |
    echo "::group::Build Information"
    echo "Commit: ${{ github.sha }}"
    echo "Branch: ${{ github.ref }}"
    echo "Workflow: ${{ github.workflow }}"
    echo "Run ID: ${{ github.run_id }}"
    echo "::endgroup::"
```

## Secret Management

### GitHub Secrets

Sensitive information is stored as GitHub Secrets:

```yaml
# Using GitHub Secrets
- name: Login to Docker Registry
  uses: docker/login-action@v2
  with:
    registry: ${{ secrets.DOCKER_REGISTRY }}
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

### Kubernetes Secrets

```yaml
# Kubernetes secrets for deployments
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: alfred-platform-${ENVIRONMENT}
type: Opaque
data:
  url: ${DATABASE_URL_BASE64}
  username: ${DATABASE_USERNAME_BASE64}
  password: ${DATABASE_PASSWORD_BASE64}
```

## Deployment Strategies

### Blue-Green Deployments

```yaml
# Blue-Green deployment configuration
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: financial-tax
  namespace: alfred-platform-prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: alfred-platform
      component: financial-tax
  template:
    metadata:
      labels:
        app: alfred-platform
        component: financial-tax
    spec:
      containers:
      - name: financial-tax
        image: ${DOCKER_REGISTRY}/alfred-platform/financial-tax:${IMAGE_TAG}
  strategy:
    blueGreen:
      activeService: financial-tax-active
      previewService: financial-tax-preview
      autoPromotionEnabled: false
```

### Canary Deployments

```yaml
# Canary deployment configuration
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: agent-core
  namespace: alfred-platform-prod
spec:
  replicas: 5
  selector:
    matchLabels:
      app: alfred-platform
      component: agent-core
  template:
    metadata:
      labels:
        app: alfred-platform
        component: agent-core
    spec:
      containers:
      - name: agent-core
        image: ${DOCKER_REGISTRY}/alfred-platform/agent-core:${IMAGE_TAG}
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 1h}
      - setWeight: 50
      - pause: {duration: 1h}
      - setWeight: 100
```

## Dependency Management

### Dependency Scanning

```yaml
# Dependency vulnerability scanning
- name: Dependency scanning
  run: |
    pip install safety
    safety check -r requirements.txt -r requirements-dev.txt
```

### Dependency Updates

```yaml
# Example Dependabot configuration
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "python"
    
  - package-ecosystem: "docker"
    directory: "/services/financial-tax/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
      - "docker"
```

## Disaster Recovery

### Pipeline Failure Recovery

If the CI/CD pipeline fails, the following recovery procedures can be implemented:

1. **Check build logs**: Examine the GitHub Actions workflow logs for errors
2. **Fix code issues**: Address any failing tests or linting errors
3. **Retry workflow**: Use the "Re-run jobs" button in GitHub Actions to restart failed workflows
4. **Manual deployment**: In case of persistent failures, use the manual deployment procedure

### Manual Deployment Procedure

```bash
# Manual deployment procedure
# 1. Build the Docker image locally
docker build -t alfred-platform/financial-tax:latest ./services/financial-tax/

# 2. Tag the image
docker tag alfred-platform/financial-tax:latest ${DOCKER_REGISTRY}/alfred-platform/financial-tax:latest

# 3. Push the image
docker push ${DOCKER_REGISTRY}/alfred-platform/financial-tax:latest

# 4. Deploy using kubectl
export IMAGE_TAG=latest
export DOCKER_REGISTRY=${DOCKER_REGISTRY}
envsubst < k8s/prod/deployment.yaml | kubectl apply -f -
```

## Troubleshooting

### Common Issues

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| Build failure | GitHub Actions job fails during build step | Check Dockerfile for errors, ensure all dependencies are available |
| Test failure | Unit or integration tests failing | Fix failing tests, check for environment issues |
| Push failure | Unable to push to container registry | Check registry credentials, verify network connectivity |
| Deployment failure | Services don't deploy or start correctly | Check Kubernetes manifests, verify environment variables |
| Secret access issues | "Secret not found" errors | Ensure secrets are properly configured in GitHub Secrets |

### Debugging Steps

```bash
# Debug GitHub Actions workflow
- name: Debug workflow
  if: failure()
  run: |
    cat $GITHUB_EVENT_PATH
    env
    docker images
    kubectl get pods -n alfred-platform-dev

# Enable runner debug logs
# Set secret ACTIONS_RUNNER_DEBUG to true
# Set secret ACTIONS_STEP_DEBUG to true
```

## Related Components

- [Kubernetes Deployment](../containerization/kubernetes-deployment.md)
- [Docker Compose Configuration](../containerization/docker-compose-configuration.md)
- [Terraform Configuration](../infrastructure/terraform-configuration.md)
- [Infrastructure Security](../security/infrastructure-security.md)
- [Monitoring Infrastructure](../monitoring/monitoring-infrastructure.md)

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2025-05-13 | Initial version | DevOps Team |

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Documentation](https://docs.docker.com/engine/reference/commandline/build/)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [ArgoCD/Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)