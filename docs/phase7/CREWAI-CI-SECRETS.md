# CrewAI CI Secrets Configuration

This document outlines the GitHub Actions secrets required for the CrewAI production deployment pipeline.

## Required Secrets

The following secrets must be configured in the GitHub repository settings:

| Secret Name | Environment | Description |
|-------------|-------------|-------------|
| `CREWAI_A2A_PROVIDER` | prod | The Workload Identity Provider name from Terraform output |
| `CREWAI_A2A_CLIENT_ID` | prod | The service account email from Terraform output |
| `CREWAI_ENDPOINT_PROD` | prod | The endpoint URL for the CrewAI service |

## Setting Up Secrets

1. Navigate to the GitHub repository settings
2. Go to "Secrets and variables" > "Actions"
3. Click on "New repository secret" to add each secret

### Obtaining Secret Values

#### After Terraform Deployment

After applying the Terraform configuration, you can obtain the values using:

```bash
terraform output crewai_a2a_pool
terraform output crewai_a2a_provider
terraform output crewai_client_id
```

Use these outputs to set the corresponding GitHub secrets.

## Environment Configuration

The secrets are scoped to the `prod` environment to ensure they are only used during production deployments. This provides an additional layer of security by restricting access to production credentials.

## Secret Rotation

These secrets do not require regular rotation as they are used to obtain short-lived OIDC tokens through the Workload Identity Federation process. The actual authentication tokens used in requests are automatically rotated.

If you need to rotate the service account or Workload Identity Pool:

1. Update the Terraform configuration
2. Apply the changes
3. Update the GitHub secrets with the new values

## Troubleshooting

If you encounter authentication issues:

1. Verify the secrets are correctly set in GitHub
2. Check the Workload Identity Federation configuration in GCP
3. Ensure the service account has the necessary permissions
4. Look for error messages in the GitHub Actions logs

For additional support, contact the DevOps team.