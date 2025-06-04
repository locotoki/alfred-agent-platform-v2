# Secret Management Guide 🔐

> **Updated for v0.9.14 Security Hardening**  
> **Scope:** Hardened 11-service baseline  
> **Audience:** Devs, DevOps, Security

## 1. Storage & Encryption

| Environment | Storage Backend | Encryption-at-rest | Rotation | Access Control |
|-------------|----------------|-------------------|----------|----------------|
| Local dev | .env files | ❌ None | Manual | File system permissions |
| CI/CD | GitHub Actions Secrets | AES-256 (GitHub) | Manual | Repository access |
| Staging | Doppler + GitHub Secrets | AES-256 | 90-day forced | Team-based RBAC |
| Production | Kubernetes Secrets + Vault | AES-256 + KMS | 30-day automated | Service account isolation |

### Security-Hardened Secrets

**Database Credentials**:
- ✅ PostgreSQL 16 with security hardening
- ✅ Trust authentication for CI (development only)
- ✅ Strong passwords in staging/production
- ✅ Connection encryption (TLS 1.3)

**API Keys & Tokens**:
- ✅ GitHub PAT with minimal scopes
- ✅ Slack tokens with workspace isolation
- ✅ LLM service API keys (encrypted in transit)

## 2. Rotation Workflows

### Automated Rotation (Production)
```bash
# PostgreSQL credentials (30-day cycle)
./scripts/security/rotate_secret.sh postgres_password

# Redis AUTH tokens (30-day cycle)  
./scripts/security/rotate_secret.sh redis_auth

# API tokens (90-day cycle)
./scripts/security/rotate_secret.sh slack_bot_token
```

### Manual Rotation (Staging/Development)
```bash
# Using runbook procedures
docs/runbooks/credential-rotation-postgres.md
docs/runbooks/credential-rotation-redis.md

# GitHub Secrets rotation
gh secret set DATABASE_PASSWORD --body "$(openssl rand -base64 32)"
```

### Rollback Strategy
```bash
# Emergency credential rollback
kubectl rollout undo deployment/agent-core
./scripts/security/restore_backup_secrets.sh --date 2025-06-04
```

## 3. Environment-Specific Security

### CI/CD Security (GitHub Actions)
- ✅ Secrets scoped to environments
- ✅ Required reviewers for production secrets
- ✅ Audit logging enabled
- ✅ No secrets in logs or artifacts

### Kubernetes Security
```yaml
# Secret deployment with encryption
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: <base64-encoded>
  password: <base64-encoded>
---
# Service account with minimal permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: agent-core-sa
```

### Development Security
```bash
# Use CORE_NO_LLM for minimal credential exposure
export CORE_NO_LLM=true
export DATABASE_URL="postgresql://postgres:devpass@localhost:5432/alfred_dev"

# Never commit real credentials
echo "*.env" >> .gitignore
echo "secrets.yaml" >> .gitignore
```

## 4. Security Monitoring

### Secret Scanning
```bash
# Daily automated scans
.github/workflows/security-scan.yml

# Manual security sweep
./scripts/security-sweep.sh
```

### Audit & Compliance
- 📊 **Access Logs**: All secret access logged and monitored
- 🔄 **Rotation Tracking**: Automated alerts for expired secrets
- 🚨 **Breach Detection**: Automated credential revocation on compromise
- 📋 **Compliance**: SOC 2, ISO 27001 compatible procedures

## 5. Incident Response

### Secret Compromise Protocol
1. **Immediate**: Revoke compromised credentials
2. **Assessment**: Determine scope of exposure
3. **Containment**: Rotate all related secrets
4. **Recovery**: Deploy new credentials
5. **Post-Incident**: Review and improve procedures

### Emergency Contacts
- **Security Team**: Create GitHub issue with `security` label
- **Critical Incidents**: Use `high-priority` label
- **After Hours**: Follow organization escalation procedures

## 6. Best Practices

### Do ✅
- Use environment-specific secrets
- Rotate credentials regularly
- Monitor secret usage and access
- Use minimal privilege principles
- Encrypt secrets in transit and at rest

### Don't ❌
- Commit secrets to repositories
- Share credentials via insecure channels
- Use default or weak passwords
- Log secret values
- Skip rotation schedules

## 7. Historical Cleanup Status

### Completed Security Measures
- ✅ **BFG Purge**: All historical secrets <2025-05-27 removed (issues #532-#534)
- ✅ **Base Image Hardening**: 34+ CVEs fixed in PostgreSQL
- ✅ **Automated Scanning**: Daily Trivy scans for credential exposure
- ✅ **Secret Standardization**: Consistent naming and rotation policies

### Next Security Milestones
- 🔄 **Vault Integration**: Centralized secret management
- 🔄 **Certificate Management**: Automated TLS certificate rotation
- 🔄 **Zero-Trust**: Service mesh with mutual TLS
- 🔄 **Hardware Security**: HSM integration for production

---

**Last Updated**: 2025-06-04  
**Next Review**: 2025-09-04  
**Security Baseline**: v0.9.14-beta1
