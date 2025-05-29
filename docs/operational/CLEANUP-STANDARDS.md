# Repository Cleanup Standards

## Purpose
Maintain a clean, organized repository structure to improve developer experience and prevent technical debt.

## File Organization Rules

### Root Directory Standards

#### MUST Contain
- `README.md` - Project overview
- `CHANGELOG.md` - Version history
- `LICENSE` - License information
- `Makefile` - Build commands
- `VERSION` - Current version

#### MAY Contain
- Configuration files:
  - `docker-compose*.yml` - Docker orchestration
  - `pyproject.toml`, `poetry.lock` - Python dependencies
  - `package.json`, `package-lock.json` - Node dependencies
  - `requirements.txt` - Python requirements
  - `go.mod`, `go.sum` - Go modules
  - `.gitignore`, `.dockerignore` - Ignore patterns
  - `.*rc`, `*.ini`, `*.yaml` - Tool configurations

#### MUST NOT Contain
- Status reports (`*-STATUS.md`, `*-COMPLETE.md`)
- Temporary files (`*.tmp`, `*.log`, `*.bak`)
- Test outputs or artifacts
- Scripts (use `scripts/` directory)
- Documentation (use `docs/` directory)

### Directory Structure

```
alfred-agent-platform-v2/
├── .github/           # GitHub Actions and templates
├── adapters/          # External adapters (Slack, Telegram)
├── agents/            # Agent implementations
├── alfred/            # Core platform namespace
├── charts/            # Helm charts
├── ci/                # CI-specific configurations
├── config/            # Service configurations
├── docker-compose/    # Docker compose variants
├── docs/              # All documentation
│   ├── api/          # API specifications
│   ├── architecture/ # Design decisions, ADRs
│   ├── guides/       # How-to guides
│   ├── operational/  # Deployment, monitoring docs
│   ├── runbooks/     # Incident response
│   └── services/     # Service-specific docs
├── k8s/               # Kubernetes manifests
├── migrations/        # Database migrations
├── monitoring/        # Monitoring configurations
├── prometheus/        # Prometheus rules
├── requirements/      # Dependency specifications
├── scripts/           # Utility scripts
├── services/          # Microservices
├── templates/         # Service templates
├── terraform/         # Infrastructure as code
└── tests/            # Test suites
```

## Documentation Standards

### Location Rules
1. **All documentation MUST be in `docs/`** with appropriate subdirectory
2. **Service-specific docs** go in `docs/services/<service-name>/`
3. **Only README.md allowed** in service directories for basic info
4. **Status reports** must go in `docs/operational/`

### Naming Conventions
- Use kebab-case for filenames: `my-document.md`
- Be descriptive but concise
- Avoid timestamps in filenames (use git history)

## Code Hygiene

### What NOT to Commit
- Python caches (`__pycache__/`, `*.pyc`)
- Node modules (`node_modules/`)
- IDE files (`.vscode/`, `.idea/`)
- OS files (`.DS_Store`, `Thumbs.db`)
- Temporary files (`*.tmp`, `*.bak`, `*~`)
- Log files (`*.log`)
- Large binaries (>5MB, use Git LFS)

### Pre-commit Checks
1. No new files in root without justification
2. Documentation in correct location
3. No temporary/cache files
4. No large files without LFS
5. Proper file naming conventions

## Automated Cleanup

### CI/CD Checks
- File hygiene workflow runs on every PR
- Blocks merge if violations found
- Provides clear error messages

### Local Cleanup Commands
```bash
# Remove Python caches
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
find . -name "*.pyc" -exec rm -f {} + 2>/dev/null

# Remove temporary files
find . -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -exec rm -f {} + 2>/dev/null

# Check root directory hygiene
./scripts/check-root-sprawl.sh
```

## PR Requirements

### Before Submitting
- [ ] Run pre-commit hooks
- [ ] No files added to root (unless updating allowed list)
- [ ] Documentation in proper subdirectory
- [ ] No temporary files
- [ ] Large files use Git LFS

### Review Checklist
- [ ] File organization follows standards
- [ ] No duplicate functionality
- [ ] Documentation updated if needed
- [ ] Tests pass

## Metrics and Monitoring

### Track Monthly
- Root directory file count (target: <50)
- Total repository size
- Documentation organization compliance
- CI hygiene check pass rate

### Red Flags
- Root directory files increasing
- Multiple "fix" or "cleanup" commits
- Failed hygiene checks
- Large uncommitted files

## Enforcement

1. **Pre-commit hooks** catch issues locally
2. **CI/CD blocks** PRs with violations
3. **Regular audits** identify trends
4. **Team education** on standards

## Questions?
- Check examples in healthy repositories
- Ask in #engineering-standards channel
- Review recent PRs for patterns