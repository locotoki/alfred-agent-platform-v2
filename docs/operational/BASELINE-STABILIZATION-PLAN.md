# Baseline Stabilization Plan

## Overview
Following the major repository cleanup, this plan establishes security, quality, and automation baselines to maintain the clean state and improve platform stability.

## Phase 1: Repository Cleanup (COMPLETED)
- ✅ Removed 1,200+ obsolete files
- ✅ Reorganized documentation structure
- ✅ Implemented anti-sprawl CI/CD checks
- ✅ Created pre-commit hooks
- ✅ Established cleanup standards

## Phase 2: Baseline Stabilization (CURRENT)

### 1. Security Scanning
**Add SBOM & licence scan (cyclonedx + licence-guard)**
- Generate Software Bill of Materials for all dependencies
- Automated license compatibility checking
- Block PRs with incompatible licenses

Implementation:
```yaml
# .github/workflows/security-scan.yml
name: Security Scan
on: [push, pull_request]
jobs:
  sbom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Generate SBOM
        uses: CycloneDX/gh-action-sbom@v2
      - name: License Guard
        run: |
          pip install licensecheck
          licensecheck --zero
```

### 2. Continuous Testing
**Nightly compose.slim smoke via cron**
- Minimal service set for quick validation
- Runs nightly to catch regressions early
- Alerts on failures

Create `docker-compose.slim.yml`:
```yaml
# Minimal set for smoke testing
services:
  redis:
    extends:
      file: docker-compose.yml
      service: redis
  db-postgres:
    extends:
      file: docker-compose.yml
      service: db-postgres
  agent-core:
    extends:
      file: docker-compose.yml
      service: agent-core
```

### 3. Container Security
**Trivy image scan gate in docker-release.yml**
- Scan all Docker images before release
- Block on HIGH/CRITICAL vulnerabilities
- Generate security reports

Add to docker-release workflow:
```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'
```

### 4. Dependency Management
**Enable Renovate for Python and Docker deps**
- Automated dependency updates
- Grouped by type (security, minor, major)
- Auto-merge for patch updates

Create `renovate.json`:
```json
{
  "extends": [
    "config:base",
    "group:allNonMajor",
    ":automergePatch"
  ],
  "python": {
    "enabled": true
  },
  "docker": {
    "enabled": true
  },
  "pip_requirements": {
    "fileMatch": ["requirements.*\\.txt$"]
  }
}
```

### 5. Documentation Site
**Publish MkDocs site from docs/**
- Beautiful, searchable documentation
- Auto-deployed on merge to main
- Versioned documentation

Create `mkdocs.yml`:
```yaml
site_name: Alfred Agent Platform
theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - search.highlight
    
nav:
  - Home: README.md
  - Architecture:
    - Overview: architecture/system-architecture.md
    - Decisions: architecture/decisions/
  - Guides:
    - Getting Started: guides/quickstart.md
    - Development: guides/development.md
  - API: api/
  - Operations:
    - Deployment: operational/deployment.md
    - Monitoring: operational/monitoring.md
    - Runbooks: runbooks/
```

## Implementation Timeline

### Week 1
- [ ] Run cleanup PR through new CI checks
- [ ] Set up SBOM generation
- [ ] Configure license scanning

### Week 2
- [ ] Create docker-compose.slim.yml
- [ ] Set up nightly smoke tests
- [ ] Add Trivy scanning

### Week 3
- [ ] Enable Renovate
- [ ] Configure update policies
- [ ] Test dependency updates

### Week 4
- [ ] Set up MkDocs
- [ ] Configure GitHub Pages
- [ ] Document the documentation process

## Success Metrics

### Security
- Zero HIGH/CRITICAL vulnerabilities in production
- 100% license compliance
- SBOM generated for every release

### Quality
- Nightly smoke tests pass >95%
- Dependencies updated within 7 days
- Documentation always current

### Developer Experience
- Clean repository maintained
- Security issues caught pre-merge
- Self-service documentation

## Integration with Cleanup

Our cleanup work enables these improvements:
1. **Clean structure** makes documentation generation easy
2. **File hygiene checks** prevent security scan noise
3. **Organized code** enables accurate SBOM generation
4. **Standards documentation** guides Renovate configuration

## Next Phase Ideas

After baseline stabilization:
1. Performance baselines and regression detection
2. Automated changelog generation
3. Release automation with semantic versioning
4. Compliance reporting dashboard
5. Developer productivity metrics