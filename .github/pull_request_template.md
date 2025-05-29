## Description
<!-- Brief description of changes -->

## Type of Change
- [ ] 🐛 Bug fix
- [ ] ✨ New feature
- [ ] 📚 Documentation
- [ ] ♻️ Refactoring
- [ ] 🧹 Cleanup
- [ ] 🔧 Configuration

## File Hygiene Checklist
- [ ] No new files added to root directory (or justified in PR)
- [ ] All documentation placed in appropriate `/docs` subdirectory
- [ ] No temporary/cache files included (`*.tmp`, `*.log`, `__pycache__`)
- [ ] Large files (>5MB) use Git LFS or justified
- [ ] No duplicate functionality introduced

## Testing
- [ ] Tests pass locally (`make test`)
- [ ] No new warnings from linters (`make lint`)
- [ ] Pre-commit hooks pass

## Documentation
- [ ] Code changes include necessary documentation updates
- [ ] New features documented in appropriate location
- [ ] API changes reflected in `/docs/api`

## Dependencies
- [ ] No unnecessary dependencies added
- [ ] Security vulnerabilities checked
- [ ] License compatibility verified

## Additional Notes
<!-- Any additional context, screenshots, or notes -->

---
<details>
<summary>PR Standards Reminder</summary>

### Root Directory Rules
Only these files allowed in root:
- README.md, CHANGELOG.md, LICENSE, Makefile, VERSION
- Config files: docker-compose.yml, pyproject.toml, package.json, etc.
- No scripts, docs, or temporary files

### Documentation Structure
```
docs/
├── api/          # API specifications
├── architecture/ # Design decisions
├── guides/       # How-to guides
├── operational/  # Deployment, status
├── runbooks/     # Incident response
└── services/     # Service-specific
```
</details>