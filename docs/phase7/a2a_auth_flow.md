# Google A2A Authentication Flow

This document provides a detailed explanation of the Google Application-to-Application (A2A) authentication flow used in the CrewAI production deployment.

## Flow Diagram

```
┌───────────────────────┐                  ┌───────────────────────┐               ┌───────────────────────┐
│                       │                  │                       │               │                       │
│   GitHub Actions      │                  │   Google Cloud IAM    │               │   CrewAI Service      │
│                       │                  │                       │               │                       │
└───────────┬───────────┘                  └───────────┬───────────┘               └───────────┬───────────┘
            │                                          │                                       │
            │  1. Request OIDC token                   │                                       │
            │  with workload identity                  │                                       │
            │  provider                                │                                       │
            ├─────────────────────────────────────────►│                                       │
            │                                          │                                       │
            │  2. Return short-lived                   │                                       │
            │  identity token                          │                                       │
            │◄─────────────────────────────────────────┤                                       │
            │                                          │                                       │
            │  3. Create credential                    │                                       │
            │  configuration file                      │                                       │
            ├─────────────────────┐                    │                                       │
            │                     │                    │                                       │
            │◄────────────────────┘                    │                                       │
            │                                          │                                       │
            │  4. Upload token as                      │                                       │
            │  GitHub artifact                         │                                       │
            ├─────────────────────┐                    │                                       │
            │                     │                    │                                       │
            │◄────────────────────┘                    │                                       │
            │                                          │                                       │
            │  5. Store token as                       │                                       │
            │  Kubernetes secret                       │                                       │
            ├─────────────────────┐                    │                                       │
            │                     │                    │                                       │
            │◄────────────────────┘                    │                                       │
            │                                          │                                       │
            │  6. Deploy application                   │                                       │
            │  with mounted token                      │                                       │
            ├─────────────────────────────────────────────────────────────────────────────────►│
            │                                          │                                       │
            │                                          │  7. Read token from                   │
            │                                          │  mounted secret                       │
            │                                          │                                       │
            │                                          │                                       ├───────────┐
            │                                          │                                       │           │
            │                                          │                                       │◄──────────┘
            │                                          │                                       │
            │                                          │  8. Make authenticated API            │
            │                                          │  call with token                      │
            │                                          │◄──────────────────────────────────────┤
            │                                          │                                       │
            │                                          │  9. Validate token and                │
            │                                          │  perform requested operation          │
            │                                          ├───────────────┐                       │
            │                                          │               │                       │
            │                                          │◄──────────────┘                       │
            │                                          │                                       │
            │                                          │  10. Return operation result          │
            │                                          ├──────────────────────────────────────►│
            │                                          │                                       │
```

## Authentication Steps Explained

1. **GitHub Actions requests OIDC token**:
   - During CI/CD pipeline execution, GitHub Actions uses the `google-github-actions/auth@v2` action
   - It sends a request to Google Cloud IAM with the Workload Identity Provider configured in Terraform
   - The request includes GitHub repository identity information (repository name, workflow, etc.)

2. **Google Cloud IAM returns token**:
   - After verifying the GitHub identity through the Workload Identity Federation
   - Returns a short-lived JWT token that can act as the specified service account

3. **Create credential configuration**:
   - GitHub Actions creates a credential configuration file using `gcloud iam workload-identity-pools create-cred-config`
   - The configuration includes the token and connection details

4. **Upload token as artifact**:
   - The token is uploaded as a GitHub Actions artifact for potential use in downstream jobs

5. **Store token as Kubernetes secret**:
   - During Helm deployment, the token is stored as a Kubernetes secret
   - This allows secure access from the application pods

6. **Deploy application**:
   - The application is deployed with the token mounted from the Kubernetes secret
   - The token is accessible as a file inside the container

7. **Read token from mounted secret**:
   - When the application needs to make an authenticated API call
   - It reads the token from the mounted file at runtime

8. **Make authenticated API call**:
   - The application includes the token in the Authorization header of API requests
   - The token identifies the GCP service account being used

9. **Validate token and process request**:
   - Google Cloud IAM validates the token signature, expiration, and permissions
   - If valid, it allows the operation to proceed

10. **Return operation result**:
    - The result of the operation is returned to the application

## Security Advantages

This authentication flow provides several security advantages:

1. **No long-lived credentials**: The tokens are short-lived (typically 1 hour) and automatically rotated
2. **Limited scope**: Tokens are scoped to specific operations and service accounts
3. **Audit trail**: All token issuance and usage is logged for audit purposes
4. **No secret storage**: No need to store long-lived credentials in CI/CD systems
5. **Least privilege**: Service accounts can be restricted to only the permissions they need

## Token Rotation

Token rotation happens automatically:

1. Each deployment gets a fresh token through the Workload Identity Federation
2. The tokens have a short lifespan and expire automatically
3. New tokens are generated for each deployment or workflow run

## Troubleshooting

Common authentication issues and how to resolve them:

1. **Token validation failures**:
   - Check that the Workload Identity Pool and Provider configurations are correct
   - Verify that the GitHub repository is properly authorized in the Workload Identity configuration

2. **Permission denied errors**:
   - Ensure the service account has the necessary IAM permissions
   - Check that the mounted token is accessible to the application

3. **Token expiration issues**:
   - Make sure your application handles token expiration gracefully
   - Consider implementing token refresh logic for long-running operations