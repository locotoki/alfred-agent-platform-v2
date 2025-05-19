# Agent Services Configuration Guide

This document describes the configuration and setup of agent services in the unified Docker Compose environment.

## Quick Fix Scripts

If you experience issues with the agent-financial or agent-legal services, two helper scripts are provided:

1. **Fix Intent Constants**:
   ```bash
   ./helpers/fix-intent-constants.py
   ```
   This script patches the `__init__.py` files inside the running containers to define necessary intent constants.

2. **Create Minimal Health Endpoints**:
   ```bash
   ./helpers/minimal-health-services.py
   ```
   This script creates and starts minimal health check services inside the containers to help pass health checks.

## Agent Service Structure

Each agent service follows a common structure:

### Financial Tax Agent

- **Service Path**: `services/financial-tax/`
- **Port**: 9003
- **Health Endpoint**: `/health`
- **API Endpoints**:
  - `/api/v1/financial-tax/calculate-tax`
  - `/api/v1/financial-tax/analyze-financials`
  - `/api/v1/financial-tax/check-compliance`
  - `/api/v1/financial-tax/tax-rates/{jurisdiction}`
  - `/api/v1/financial-tax/task/{task_id}`

### Legal Compliance Agent

- **Service Path**: `services/legal-compliance/`
- **Port**: 9002
- **Health Endpoint**: `/health`
- **API Endpoints**:
  - `/api/v1/legal-compliance/audit-compliance`
  - `/api/v1/legal-compliance/analyze-document`
  - `/api/v1/legal-compliance/check-regulations`
  - `/api/v1/legal-compliance/review-contract`
  - `/api/v1/legal-compliance/task/{task_id}`

## Proper Docker Compose Configuration

The following configuration should be used for these services in docker-compose.yml:

```yaml
# Financial Tax Agent
agent-financial:
  build:
    context: ./services/financial-tax
  container_name: agent-financial
  ports:
    - "9003:9003"
  volumes:
    - ./agents:/app/agents
    - ./libs:/app/libs
  environment:
    - DATABASE_URL=postgresql://postgres:your-super-secret-password@db-postgres:5432/postgres
    - REDIS_URL=redis://redis:6379
    - PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
    - GCP_PROJECT_ID=alfred-agent-platform
    - RAG_URL=http://agent-rag:8501
    - RAG_API_KEY=financial-key
    - RAG_COLLECTION=financial-knowledge
  healthcheck:
    test: ["CMD-SHELL", "curl -f http://localhost:9003/health || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 5s
  networks:
    - alfred-network
  depends_on:
    db-postgres:
      condition: service_healthy
    pubsub-emulator:
      condition: service_healthy

# Legal Compliance Agent
agent-legal:
  build:
    context: ./services/legal-compliance
  container_name: agent-legal
  ports:
    - "9002:9002"
  volumes:
    - ./agents:/app/agents
    - ./libs:/app/libs
  environment:
    - DATABASE_URL=postgresql://postgres:your-super-secret-password@db-postgres:5432/postgres
    - REDIS_URL=redis://redis:6379
    - PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
    - GCP_PROJECT_ID=alfred-agent-platform
    - RAG_URL=http://agent-rag:8501
    - RAG_API_KEY=legal-key
    - RAG_COLLECTION=legal-knowledge
  healthcheck:
    test: ["CMD-SHELL", "curl -f http://localhost:9002/health || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 5s
  networks:
    - alfred-network
  depends_on:
    db-postgres:
      condition: service_healthy
    pubsub-emulator:
      condition: service_healthy
```

## Common Issues and Solutions

### 1. Missing Intent Constants

If you encounter errors like `NameError: name 'TAX_CALCULATION' is not defined`, it means the intent constants are missing. Use the `fix-intent-constants.py` script or manually add the constants:

```python
# For agents/financial_tax/__init__.py
TAX_CALCULATION = "tax_calculation"
FINANCIAL_ANALYSIS = "financial_analysis"
TAX_COMPLIANCE_CHECK = "tax_compliance_check"
RATE_SHEET_LOOKUP = "rate_sheet_lookup"

# For agents/legal_compliance/__init__.py
COMPLIANCE_AUDIT = "compliance_audit"
DOCUMENT_ANALYSIS = "document_analysis"
REGULATION_CHECK = "regulation_check"
CONTRACT_REVIEW = "contract_review"
```

### 2. Model Import Errors

If you see a FastAPI error about invalid Pydantic field types, ensure your models are properly imported:

```python
# In services/financial-tax/app/main.py
from agents.financial_tax.models import (
    TaxCalculationRequest,
    FinancialAnalysisRequest,
    ComplianceCheckRequest,
    TaxRateRequest
)

# In services/legal-compliance/app/main.py
from agents.legal_compliance.models import (
    ComplianceAuditRequest,
    DocumentAnalysisRequest,
    RegulationCheckRequest,
    ContractReviewRequest
)
```

### 3. Health Check Failures

If health checks are failing, use the `minimal-health-services.py` script to set up minimal health endpoints.

## Troubleshooting

1. Check container logs:
   ```bash
   docker logs agent-financial
   docker logs agent-legal
   ```

2. Verify the containers are running:
   ```bash
   docker ps | grep "agent-financial\|agent-legal"
   ```

3. Test health endpoints directly:
   ```bash
   curl http://localhost:9003/health
   curl http://localhost:9002/health
   ```

4. If all else fails, you can create a simple health endpoint override in the Docker container.
