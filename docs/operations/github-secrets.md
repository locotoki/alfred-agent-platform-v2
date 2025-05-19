# GitHub Secrets Configuration Guide

This document outlines the GitHub Secrets required for the CI/CD pipeline of the Alfred Agent Platform v2.

## Environment-Specific Secrets

The CI/CD pipeline uses environment-specific secrets to ensure proper isolation between environments.

### Staging Environment

| Secret Name | Purpose | Source |
|-------------|---------|--------|
| `SLACK_BOT_TOKEN` | Authenticate Slack API calls | Slack App → OAuth & Permissions → Bot User OAuth Token |
| `SLACK_APP_TOKEN` | Enable Socket Mode for Slack | Slack App → Basic Information → App-Level Tokens → Generate (with `connections:write` scope) |
| `SLACK_SIGNING_SECRET` | Verify Slack request signatures | Slack App → Basic Information → App Credentials → Signing Secret |

### Production Environment

| Secret Name | Purpose | Source |
|-------------|---------|--------|
| `CREWAI_ENDPOINT_PROD` | Production CrewAI service URL | Set to `https://crewai.prod.internal` |
| `CREWAI_A2A_CLIENT_ID` | Google A2A authentication client ID | GCP Workload Identity Pool |
| `CREWAI_A2A_CLIENT_SECRET` | Google A2A authentication client secret | GCP A2A client secret |

## Setting Up GitHub Secrets

1. Navigate to the repository settings
2. Go to Secrets & variables → Actions
3. Select the appropriate environment (staging or prod)
4. Click "New repository secret"
5. Enter the secret name and value
6. Click "Add secret"

## Environment Protection Rules

The production environment should be configured with required reviewers to add an additional layer of protection:

1. Go to Settings → Environments
2. Select or create the "prod" environment
3. Enable "Required reviewers"
4. Add appropriate reviewers
5. Save protection rules

## Validating Secrets

The CI/CD pipeline includes a validation step to ensure all required secrets are available. If any secrets are missing, the pipeline will fail with a clear error message.

To manually validate secrets locally (requires GitHub CLI with appropriate permissions):

```bash
gh secret list -e staging
gh secret list -e prod
```

## Secret Rotation

Production secrets should be rotated periodically according to the organization's security policy. When rotating secrets:

1. Generate new credentials from the source system
2. Update the corresponding GitHub Secret with the new value
3. Verify the pipeline continues to work with the new credentials
4. Revoke the old credentials
