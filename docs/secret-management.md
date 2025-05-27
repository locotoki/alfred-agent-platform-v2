# Secret Management Guide

## Overview

This guide outlines how secrets are managed across different environments in the Alfred Agent Platform.

## Secret Categories

### 1. API Keys and Tokens
- **Storage**: GitHub Secrets (for CI/CD), Environment variables (for local/production)
- **Examples**: `GITLEAKS_LICENSE`, `SLACK_BOT_TOKEN`, `OPENAI_API_KEY`
- **Rotation**: Quarterly or on compromise

### 2. Database Credentials
- **Storage**: Environment variables, Kubernetes secrets
- **Examples**: `DB_PASSWORD`, `REDIS_PASSWORD`
- **Rotation**: Monthly for production

### 3. Service-to-Service Authentication
- **Storage**: Kubernetes secrets, mounted volumes
- **Examples**: JWT signing keys, mTLS certificates
- **Rotation**: Automated via cert-manager

## Environment-Specific Practices

### Local Development
```bash
# Use .env files (never commit!)
cp .env.example .env
# Edit .env with your values
```

### CI/CD (GitHub Actions)
```bash
# Add secret via GitHub CLI
gh secret set SECRET_NAME --body "secret-value"

# Or via web UI:
# Settings > Secrets > Actions > New repository secret
```

### Production
- Secrets stored in Kubernetes secrets
- Injected via environment variables or mounted volumes
- Managed by platform team only

## Best Practices

1. **Never commit secrets** to version control
2. **Use least privilege** - grant minimal required permissions
3. **Rotate regularly** - see rotation schedule above
4. **Audit access** - review who has access quarterly
5. **Use secret scanning** - GitHub secret scanning is enabled

## Adding New Secrets

### For GitHub Actions
```bash
# Example: Adding GITLEAKS_LICENSE
gh secret set GITLEAKS_LICENSE --repo "$OWNER/$REPO"
```

### For Local Development
1. Add to `.env.example` with placeholder
2. Document in this guide
3. Update setup instructions

### For Production
1. Create ticket for platform team
2. Specify secret name, purpose, and required permissions
3. Platform team will add to Kubernetes secrets

## Secret References in Code

### Good Example
```yaml
env:
  API_KEY: ${{ secrets.API_KEY }}  # GitHub Actions
```

```python
api_key = os.environ.get("API_KEY")  # Runtime
if not api_key:
    raise ValueError("API_KEY environment variable not set")
```

### Bad Example
```python
api_key = "sk-abc123..."  # NEVER DO THIS!
```

## Incident Response

If a secret is compromised:
1. Immediately rotate the secret
2. Audit usage logs
3. Notify security team
4. Update this document with lessons learned

## Validation

Run the secret validation workflow:
```bash
gh workflow run validate-secrets.yml
```

This checks that all required secrets are present (not their values).
