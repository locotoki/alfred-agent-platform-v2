# Phase 7C: CrewAI Production Deployment

## Overview

Phase 7C focuses on deploying the CrewAI service to production with secure Google A2A authentication. This document outlines the architecture, authentication flow, and implementation details.

## A2A Authentication Flow

The Authentication-to-Authentication (A2A) flow using Google Workload Identity Federation works as follows:

```
┌───────────────┐         ┌───────────────────┐         ┌──────────────┐
│               │         │                   │         │              │
│  GitHub       │ Request │ Google Workload   │ Issue   │  CrewAI      │
│  Actions      ├────────►│ Identity          ├────────►│  Service     │
│               │ Token   │ Federation        │ Token   │              │
└───────────────┘         └───────────────────┘         └──────────────┘
       │                                                       ▲
       │                                                       │
       │                  ┌─────────────────┐                  │
       └──────────────────► GCP Service     │                  │
                          │ Account         ├──────────────────┘
                          └─────────────────┘
```

1. GitHub Actions requests a token from Google Workload Identity Federation
2. Google issues a short-lived OIDC token for the specified service account
3. The token is used to authenticate API calls to the CrewAI service
4. The CrewAI service validates the token before processing requests

## Implementation Components

### 1. Terraform Configuration

The `infra/prod/crew_ai.tf` file sets up:
- A GCP Service Account for CrewAI (`crewai-prod-sa`)
- Workload Identity Federation for GitHub Actions
- IAM permissions for the service account

### 2. Helm Chart

The `charts/crewai` directory contains the Kubernetes deployment configuration:
- Deployment, Service, and Secret resources
- Configuration for the JWT token mount
- Health check and resource limits

### 3. Client Wrapper

The `alfred_agent/crewai/client.py` file provides:
- A Python client for sending tasks to CrewAI
- JWT token handling from mounted Kubernetes secrets
- Error handling and validation

### 4. GitHub Actions Workflow

The `.github/workflows/main.yml` file includes:
- A2A token minting steps for production deployments
- Creation of token configuration file
- Artifact upload for downstream job use

## How to Rotate the Workload Identity Pool

If you need to rotate the Workload Identity Pool credentials:

1. Update the Terraform configuration (optional):
   ```bash
   # If changing pool or provider names
   cd infra/prod
   terraform apply
   ```

2. Get the new values:
   ```bash
   terraform output crewai_a2a_pool
   terraform output crewai_a2a_provider
   terraform output crewai_client_id
   ```

3. Update GitHub secrets:
   - Go to repository Settings → Secrets → Actions
   - Update `CREWAI_A2A_PROVIDER` and `CREWAI_A2A_CLIENT_ID`

## Local Testing

To test with local credential generation:

1. Install the Google Cloud SDK
2. Authenticate with GCP:
   ```bash
   gcloud auth login
   ```

3. Create test credentials:
   ```bash
   gcloud iam workload-identity-pools create-cred-config \
     projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID \
     --service-account=SERVICE_ACCOUNT_EMAIL \
     --output-file=/tmp/crewai-token.json
   ```

4. Run integration tests:
   ```bash
   CREWAI_ENDPOINT=https://crewai-staging.example.com \
   CREWAI_A2A_JWT=/tmp/crewai-token.json \
   pytest tests/integration/test_crewai_prod.py
   ```

## Using the CrewAI Client

### Basic Usage

```python
from alfred_agent.crewai import send_task

# Send a task to CrewAI
response = send_task({
    "task_type": "remediation",
    "service_name": "model-router",
    "error_details": {
        "error_message": "Connection refused",
        "probe_status_code": 500
    },
    "priority": "high"
})

# Process the response
task_id = response["task_id"]
status = response["status"]
print(f"Task {task_id} status: {status}")
```

### Error Handling

```python
from alfred_agent.crewai import send_task
import requests
import logging

logger = logging.getLogger(__name__)

try:
    response = send_task({
        "task_type": "remediation",
        "service_name": "model-router",
        "priority": "high"
    })
    # Handle successful response
except requests.RequestException as e:
    logger.error(f"Error sending task to CrewAI: {e}")
    # Implement fallback or retry logic
```

## Security Considerations

1. **Token Management**: 
   - Tokens are short-lived (15 minutes) and automatically rotated
   - Tokens are stored as Kubernetes secrets
   - The client reads tokens from read-only file mounts
   - Artifacts containing tokens are automatically deleted after deployment
   
2. **Authentication**: 
   - Each request is authenticated with a JWT token
   - Tokens include audience and scope restrictions
   - GitHub Actions environment restrictions limit access
   - Token retention policy limits exposure time

3. **Authorization**:
   - Service account has minimal required permissions
   - Workload Identity Federation limits token usage to specific GitHub repository
   - Artifact cleanup ensures tokens are not persisted in GitHub Actions

## Troubleshooting

### Common Issues

1. **Authentication Failures**:
   - Verify GitHub secrets are properly configured
   - Check that the service account has proper permissions
   - Ensure Workload Identity Federation is correctly set up

2. **Token Issues**:
   - Validate that token mounting in Kubernetes is working
   - Check Kubernetes logs for permission issues
   - Verify the token is accessible to the container

3. **API Call Failures**:
   - Check for network connectivity issues
   - Verify the CrewAI endpoint URL is correct
   - Confirm that the request payload is valid

### Debugging Tools

1. View Kubernetes logs:
   ```bash
   kubectl logs -n production -l app.kubernetes.io/name=crewai
   ```

2. Check Kubernetes secret:
   ```bash
   kubectl describe secret -n production crewai-a2a-token
   ```

3. Test connectivity:
   ```bash
   kubectl exec -n production -l app.kubernetes.io/name=crewai -- curl -v https://crewai.prod.internal/health
   ```

## References

- [Google Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Helm Charts Best Practices](https://helm.sh/docs/chart_best_practices/)