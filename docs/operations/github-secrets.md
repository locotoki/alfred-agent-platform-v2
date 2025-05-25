# GitHub Secrets Configuration Guide

This document outlines the GitHub Secrets required for the CI/CD pipeline of the Alfred Agent Platform v2.

## Environment-Specific Secrets

The CI/CD pipeline uses environment-specific secrets to ensure proper isolation between environments.

### Staging Environment

| Secret Name | Purpose | Source | Rotation Schedule |
|-------------|---------|--------|-------------------|
| `SLACK_BOT_TOKEN` | Authenticate Slack API calls | Slack App → OAuth & Permissions → Bot User OAuth Token | 90 days |
| `SLACK_APP_TOKEN` | Enable Socket Mode for Slack | Slack App → Basic Information → App-Level Tokens → Generate (with `connections:write` scope) | 90 days |
| `SLACK_SIGNING_SECRET` | Verify Slack request signatures | Slack App → Basic Information → App Credentials → Signing Secret | 180 days |
| `OPENAI_API_KEY` | OpenAI API access | OpenAI Dashboard → API Keys | 90 days |
| `ANTHROPIC_API_KEY` | Anthropic Claude API | Anthropic Console → API Keys | 90 days |
| `DB_PASSWORD` | PostgreSQL database password | Generated securely | 180 days |
| `REDIS_PASSWORD` | Redis authentication | Generated securely | 180 days |

### Production Environment

| Secret Name | Purpose | Source | Rotation Schedule |
|-------------|---------|--------|-------------------|
| `CREWAI_ENDPOINT_PROD` | Production CrewAI service URL | Set to `https://crewai.prod.internal` | N/A |
| `CREWAI_A2A_CLIENT_ID` | Google A2A authentication client ID | GCP Workload Identity Pool | 365 days |
| `CREWAI_A2A_CLIENT_SECRET` | Google A2A authentication client secret | GCP A2A client secret | 90 days |
| `GHCR_PAT` | GitHub Container Registry access | GitHub → Settings → Developer settings → Personal access tokens | 90 days |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin credentials | Generated securely | 90 days |
| `VECTOR_DB_KEY` | Vector database API key | Provider dashboard | 180 days |

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

## Secret Generation Best Practices

### Generating Secure Passwords

For database and service passwords, use a cryptographically secure generator:

```bash
# Generate a 32-character password
openssl rand -base64 32

# Alternative using Python
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### API Key Management

1. **Principle of Least Privilege**: Request only the minimum required scopes
2. **Environment Isolation**: Never share keys between environments
3. **Audit Trail**: Document when keys are created and by whom
4. **Secure Storage**: Use GitHub Secrets or a dedicated secret manager

## Secret Rotation

Production secrets should be rotated periodically according to the organization's security policy. When rotating secrets:

1. Generate new credentials from the source system
2. Update the corresponding GitHub Secret with the new value
3. Verify the pipeline continues to work with the new credentials
4. Revoke the old credentials

### Automated Rotation Script

Use the provided rotation helper:

```bash
# Rotate all API tokens for an environment
./scripts/rotate-secrets.sh --env production --type api-tokens

# Rotate a specific secret
./scripts/rotate-secrets.sh --env staging --secret SLACK_BOT_TOKEN
```

### Emergency Rotation

In case of suspected compromise:

1. **Immediate Actions**:
   - Revoke compromised credentials immediately
   - Generate new credentials
   - Update GitHub Secrets
   - Trigger a new deployment

2. **Follow-up**:
   - Review audit logs for unauthorized access
   - Update security incident log
   - Consider reducing rotation intervals

## Monitoring Secret Usage

### GitHub Audit Log

Monitor secret access through GitHub's audit log:

```bash
# View secret access events
gh api "/repos/{owner}/{repo}/audit-log" \
  --jq '.[] | select(.action | contains("secret"))'
```

### CI/CD Pipeline Validation

The pipeline includes automatic validation of required secrets:

1. Pre-deployment check for secret availability
2. Runtime validation of secret format
3. Alerting on authentication failures
