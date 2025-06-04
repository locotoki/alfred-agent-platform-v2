# Alfred Platform Security Guide

This document outlines the security measures, hardening practices, and vulnerability management for the Alfred Agent Platform.

## Security Overview

The Alfred platform implements defense-in-depth security measures across multiple layers:

- **Container Security**: Hardened base images, minimal attack surface
- **Vulnerability Management**: Automated scanning and patching
- **Access Control**: Non-root containers, least privilege principles  
- **Network Security**: Isolated container networks, minimal exposed ports
- **Monitoring**: Security event logging and alerting

## Security-Hardened Base Images

### Python Services: `alfred-python-secure`

**Location**: `base-images/python-secure/Dockerfile`

**Security Features**:
- ✅ Updated Python 3.11 with latest security patches
- ✅ Upgraded setuptools (≥75.0.0) to address CVE-2024-6345, CVE-2025-47273
- ✅ Updated pip (≥24.3.0) for latest security fixes
- ✅ Non-root user execution (alfred:alfred)
- ✅ Minimal package installation
- ✅ Secure file permissions (go-rwx)
- ✅ Common dependencies pre-installed for layer reuse

**Usage**:
```dockerfile
FROM alfred-python-secure:latest AS runtime
# Your application code here
```

### PostgreSQL: `alfred-postgres-secure`

**Location**: `base-images/postgres-secure/Dockerfile`

**Security Features**:
- ✅ PostgreSQL 16 (latest stable) instead of 15
- ✅ Replaced vulnerable gosu with su-exec (addresses 34+ CVEs)
- ✅ Updated Alpine packages to latest patch versions
- ✅ Fixed libxml2 vulnerabilities (CVE-2025-32414, CVE-2025-32415)
- ✅ Secure data directory permissions (700)
- ✅ Custom entrypoint without vulnerable binaries

**Usage**:
```yaml
services:
  db-postgres:
    image: alfred-postgres-secure:latest
    # PostgreSQL configuration
```

## Vulnerability Management

### Automated Scanning

**Daily Security Scans**: `.github/workflows/security-scan.yml`
- Runs Trivy vulnerability scanner daily at 1 AM UTC
- Scans all base images and custom application images
- Reports HIGH and CRITICAL vulnerabilities
- Uploads results to GitHub Security Dashboard
- Creates issues for vulnerabilities requiring attention

**Manual Security Sweep**: `scripts/security-sweep.sh`
- Comprehensive security report generation
- Vulnerability counts and recommendations
- Can be run locally or in CI/CD pipelines

### Vulnerability Response Process

1. **Detection**: Automated scans identify new vulnerabilities
2. **Assessment**: Security team reviews impact and exploitability  
3. **Prioritization**: Critical/High severity issues get immediate attention
4. **Remediation**: Update base images, patch dependencies
5. **Testing**: Validate fixes in staging environment
6. **Deployment**: Roll out security updates to production
7. **Verification**: Confirm vulnerabilities are resolved

## Current Security Status

### Known Issues Addressed

| CVE | Severity | Component | Status | Mitigation |
|-----|----------|-----------|--------|------------|
| CVE-2024-6345 | HIGH | setuptools | ✅ Fixed | Upgraded to ≥75.0.0 |
| CVE-2025-47273 | HIGH | setuptools | ✅ Fixed | Upgraded to ≥75.0.0 |
| CVE-2025-32414 | HIGH | libxml2 | ✅ Fixed | Updated Alpine packages |
| CVE-2025-32415 | HIGH | libxml2 | ✅ Fixed | Updated Alpine packages |
| CVE-2023-45853 | CRITICAL | zlib | ✅ Fixed | Updated system packages |
| CVE-2025-4802 | HIGH | glibc | 🔄 Monitoring | Alpine base images used |

### Gosu Vulnerabilities (PostgreSQL)

The original `postgres:15-alpine-hardened` image contains 34 vulnerabilities in the gosu binary (3 critical, 31 high severity). Our hardened PostgreSQL image addresses this by:

- ✅ Replacing gosu with su-exec (more secure alternative)
- ✅ Custom entrypoint script without vulnerable binaries
- ✅ Updated to PostgreSQL 16 for latest security patches

## Security Best Practices

### Container Security

```dockerfile
# ✅ DO: Use security-hardened base images
FROM alfred-python-secure:latest

# ✅ DO: Run as non-root user  
USER alfred

# ✅ DO: Set secure file permissions
RUN chmod 700 /app && chown alfred:alfred /app

# ❌ DON'T: Install unnecessary packages
# RUN apt-get install -y build-essential  # Only in build stage

# ❌ DON'T: Run as root
# USER root
```

### Docker Compose Security

```yaml
services:
  app:
    # ✅ Use hardened images
    image: alfred-python-secure:latest
    
    # ✅ Drop capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if needed
    
    # ✅ Read-only root filesystem
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    
    # ✅ Resource limits
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

### Kubernetes Security

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      securityContext:
        # ✅ Run as non-root
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        
      containers:
      - name: app
        securityContext:
          # ✅ Security hardening
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
              - ALL
        
        # ✅ Resource limits
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi" 
            cpu: "100m"
```

## Security Monitoring

### Metrics and Alerting

- **Vulnerability counts**: Tracked per image and over time
- **Security scan results**: Exported to monitoring dashboards
- **Failed security checks**: Generate alerts and issues
- **Update compliance**: Monitor patch application rates

### Security Dashboards

Access security metrics through:
- GitHub Security Dashboard (vulnerability alerts)
- Workflow artifacts (detailed scan reports)
- Issue tracking (vulnerability remediation status)

## Incident Response

### Security Incident Procedure

1. **Detection**: Automated alerts or manual discovery
2. **Assessment**: Determine scope and impact
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threat and patch vulnerabilities
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Update security measures

### Emergency Contacts

- **Security Team**: Create GitHub issue with `security` label
- **Critical Issues**: Use `high-priority` label for immediate attention
- **After Hours**: Follow organization escalation procedures

## Compliance and Auditing

### Security Audit Trail

All security-related activities are logged:
- ✅ Vulnerability scan results (GitHub Actions)
- ✅ Security updates and patches (Git commits)
- ✅ Issue creation and resolution (GitHub Issues)
- ✅ Access control changes (IAM audit logs)

### Regular Security Reviews

- **Weekly**: Review new vulnerability alerts
- **Monthly**: Security posture assessment
- **Quarterly**: Security architecture review
- **Annually**: Comprehensive security audit

## Getting Help

### Resources

- **Security Guide**: This document (`SECURITY.md`)
- **Security Scripts**: `scripts/security-sweep.sh`
- **Base Images**: `base-images/*/Dockerfile`
- **Workflows**: `.github/workflows/security-scan.yml`

### Reporting Security Issues

1. **Create GitHub Issue**: Use `security` label
2. **Provide Details**: Include CVE numbers, affected components
3. **Suggest Fixes**: Link to patches or updated versions
4. **Monitor Progress**: Track resolution in issue comments

---

**Last Updated**: $(date +"%Y-%m-%d")  
**Next Review**: $(date -d "+3 months" +"%Y-%m-%d")  
**Document Owner**: Platform Security Team