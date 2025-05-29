# PostgreSQL Credential Rotation

## Overview
This runbook covers the process of rotating PostgreSQL credentials in the Alfred platform.

## Impact
- Temporary database connection interruptions
- Services will need to reconnect with new credentials
- Brief API unavailability during rotation

## Prerequisites
- Access to Kubernetes cluster
- PostgreSQL admin credentials
- GitHub Actions secrets access

## Rotation Steps

### 1. Generate New Credentials
```bash
# Generate secure password
NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
echo "New password generated (save securely)"
```

### 2. Update PostgreSQL User
```bash
# Connect to PostgreSQL
kubectl exec -it postgres-0 -- psql -U postgres

# Update password
ALTER USER alfred_user WITH PASSWORD 'new_secure_password';

# Verify connection
\q
```

### 3. Update Kubernetes Secrets
```bash
# Delete existing secret
kubectl delete secret postgres-credentials

# Create new secret
kubectl create secret generic postgres-credentials \
  --from-literal=username=alfred_user \
  --from-literal=password="${NEW_PASSWORD}" \
  --from-literal=database=alfred_db
```

### 4. Update GitHub Secrets
1. Navigate to GitHub repository settings
2. Go to Secrets and variables > Actions
3. Update `DB_PASSWORD_PROD` with new password
4. Update `DB_PASSWORD_STAGING` if rotating staging

### 5. Restart Services
```bash
# Restart services that use PostgreSQL
kubectl rollout restart deployment alfred-core
kubectl rollout restart deployment contact-ingest
kubectl rollout restart deployment model-registry

# Monitor rollout
kubectl rollout status deployment alfred-core
```

### 6. Verification
```bash
# Check service health
kubectl get pods -l tier=backend
kubectl logs -l app=alfred-core --tail=50

# Test database connectivity
kubectl exec -it deployment/alfred-core -- /healthcheck
```

## Rollback Procedure
1. Revert to previous password in PostgreSQL
2. Restore previous Kubernetes secret from backup
3. Revert GitHub secrets
4. Restart all affected services

## Schedule
- Production: Quarterly rotation
- Staging: Monthly rotation
- After any security incident: Immediate

## Security Notes
- Never log passwords in plain text
- Use secure communication channels
- Delete command history after rotation
- Audit access logs post-rotation

## Automation
Consider using HashiCorp Vault or AWS Secrets Manager for automated rotation.

## Related Links
- [PostgreSQL Security Best Practices](../docs/security/postgres-hardening.md)
- [Secret Management Guide](../docs/secret-management.md)
- [Database Architecture](../docs/architecture/database.md)
