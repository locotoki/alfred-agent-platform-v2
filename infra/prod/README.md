# CrewAI Production Infrastructure

This directory contains Terraform configurations for the CrewAI production deployment infrastructure.

## Overview

The Terraform configuration in this directory provisions the following GCP resources:

1. **Service Account (`crewai-prod-sa`)**: A GCP service account with necessary permissions for the CrewAI production service.
2. **Workload Identity Pool (`crewai-github-pool`)**: An identity pool to enable GitHub Actions to authenticate as the CrewAI service account.
3. **Workload Identity Provider (`crewai-github-provider`)**: A provider configuration that establishes trust between GitHub Actions and GCP.

## Usage

### Prerequisites

- Terraform v1.0.0 or newer
- GCP project with required APIs enabled
- Appropriate GCP permissions to create the resources

### Applying the Configuration

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Plan the deployment:
   ```
   terraform plan -var="project_id=your-project-id"
   ```

3. Apply the configuration:
   ```
   terraform apply -var="project_id=your-project-id"
   ```

4. Note the outputs after successful application:
   - `crewai_a2a_pool`: The Workload Identity Pool name
   - `crewai_a2a_provider`: The Workload Identity Provider name
   - `crewai_client_id`: The Service Account email

### Outputs

The outputs from this configuration will be used in GitHub Actions workflows to authenticate with GCP.

## CI/CD Integration

The Service Account and Workload Identity configurations enable GitHub Actions to securely authenticate with GCP without storing long-lived credentials. This setup uses OpenID Connect (OIDC) tokens for secure authentication.

## Security Considerations

- The Service Account has minimal permissions based on the principle of least privilege
- Authentication uses short-lived OIDC tokens rather than long-lived service account keys
- Access is restricted to specific GitHub repository and workflows

## Rotation

Credentials are automatically rotated as they are short-lived OIDC tokens. No manual rotation is required.