# Agent Integration Issues and Solutions

This document outlines the issues encountered with the agent-financial and agent-legal services in the unified Docker Compose setup, and provides solutions to fix them.

## Issues Identified

1. **Missing Intent Constants**: Both agent services use intent constants in their code that are not defined at the point of usage.

2. **Invalid Model Imports**: The FastAPI routes are trying to import models directly from the agent modules, but the models are defined in a separate model.py file.

3. **Stub Services in docker-compose.yml**: The docker-compose.yml file was using stub implementations with Alpine images instead of the actual services.

## Solutions

### Fix 1: Intent Constants

In both `agents/financial_tax/__init__.py` and `agents/legal_compliance/__init__.py`, intent constants need to be defined before they are used:

```python
# In agents/financial_tax/__init__.py
# Intent constants
TAX_CALCULATION = "tax_calculation"
FINANCIAL_ANALYSIS = "financial_analysis"
TAX_COMPLIANCE_CHECK = "tax_compliance_check"
RATE_SHEET_LOOKUP = "rate_sheet_lookup"
```

```python
# In agents/legal_compliance/__init__.py
# Intent constants
COMPLIANCE_AUDIT = "compliance_audit"
DOCUMENT_ANALYSIS = "document_analysis"
REGULATION_CHECK = "regulation_check"
CONTRACT_REVIEW = "contract_review"
```

### Fix 2: Model Imports

Import models from the correct module:

```python
# In services/financial-tax/app/main.py
from agents.financial_tax.models import (
    TaxCalculationRequest,
    FinancialAnalysisRequest,
    ComplianceCheckRequest,
    TaxRateRequest
)
```

```python
# In services/legal-compliance/app/main.py
from agents.legal_compliance.models import (
    ComplianceAuditRequest,
    DocumentAnalysisRequest,
    RegulationCheckRequest,
    ContractReviewRequest
)
```

### Fix 3: Docker Compose Configuration

Update the docker-compose.yml to use the actual service implementations:

```yaml
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
```

```yaml
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
```

## Implementation Steps

1. **Fix Intent Constants**:
   - Ensure intent constants are defined in both `__init__.py` files
   - Update imports in service main.py to import these constants

2. **Fix Model Imports**:
   - Ensure the right Pydantic models are imported from models.py
   - Update FastAPI route handlers to use the correct model types

3. **Update Docker Compose**:
   - Replace stub services with real services
   - Add proper volume mounts for code access
   - Set correct environment variables
   - Configure appropriate health checks

4. **Building and Deployment**:
   - Build the Docker images: `docker-compose build agent-financial agent-legal`
   - Start the services: `docker-compose up -d agent-financial agent-legal`

## Additional Notes

If the above solutions are implemented but the services still don't start correctly, it may be necessary to create custom implementation files in each Docker container. Since Docker mounts volumes at runtime, changes to the host files do not directly affect the built images, which may require a rebuild of the images if any source files are modified.

For a quicker solution during development, consider creating a simple health-check implementation for both services that meets the minimal requirements to pass health checks.
