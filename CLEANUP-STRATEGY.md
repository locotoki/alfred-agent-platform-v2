# Repository Cleanup and Anti-Sprawl Strategy

## 1. Committing the Cleanup

### Phase 1: Archive Legacy Code
```bash
# Create a branch for the cleanup
git checkout -b cleanup/major-repository-cleanup

# Stage the archive directory
git add .archive/

# Commit the archive
git commit -m "chore: archive legacy code and documentation

- Moved 52 legacy directories to .archive/legacy-2025-05-29/
- Preserved 4.2GB of historical code for reference
- Directories include old phases, unused features, and obsolete implementations"
```

### Phase 2: Remove Obsolete Files
```bash
# Stage all deletions
git add -u

# Commit deletions in logical groups
git commit -m "chore: remove obsolete documentation and status files

- Removed 130+ outdated status reports from root
- Removed old sprint documents and phase tracking files
- Removed duplicate PR body templates"
```

### Phase 3: Add New Structure
```bash
# Stage new documentation structure
git add docs/

# Stage updated files
git add .gitignore PROJECT-STRUCTURE.md CLEANUP-STRATEGY.md

# Commit new structure
git commit -m "feat: reorganize documentation structure

- Created organized docs structure: architecture/, guides/, api/, services/, operational/, runbooks/
- Added PROJECT-STRUCTURE.md documenting clean layout
- Updated .gitignore with proper patterns for Python, Node, and IDE files"
```

## 2. CI/CD Guardrails

### A. GitHub Actions Workflow for File Hygiene

Create `.github/workflows/file-hygiene.yml`:

```yaml
name: File Hygiene Check

on:
  pull_request:
    paths:
      - '**'
  push:
    branches:
      - main

jobs:
  check-file-sprawl:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check root directory files
        run: |
          # Count markdown files in root (should be minimal)
          ROOT_MD_COUNT=$(find . -maxdepth 1 -name "*.md" -type f | wc -l)
          if [ $ROOT_MD_COUNT -gt 5 ]; then
            echo "❌ Too many markdown files in root: $ROOT_MD_COUNT (max: 5)"
            echo "Move documentation to docs/ directory"
            exit 1
          fi
          
      - name: Check for temporary files
        run: |
          # Find common temporary files
          TEMP_FILES=$(find . -name "*.tmp" -o -name "*.temp" -o -name "*.bak" \
                              -o -name "*.log" -o -name "*~" -o -name ".DS_Store" \
                              -not -path "./.git/*" | head -20)
          if [ -n "$TEMP_FILES" ]; then
            echo "❌ Temporary files found:"
            echo "$TEMP_FILES"
            exit 1
          fi
          
      - name: Check for build artifacts
        run: |
          # Check for Python caches
          if find . -name "__pycache__" -type d | grep -q .; then
            echo "❌ Python cache directories found"
            exit 1
          fi
          
      - name: Validate documentation location
        run: |
          # Ensure docs are in proper directories
          for pattern in "*-STATUS.md" "*-COMPLETE.md" "*-SUMMARY.md"; do
            if ls $pattern 2>/dev/null | grep -v "^docs/"; then
              echo "❌ Status/summary files should be in docs/operational/"
              exit 1
            fi
          done
```

### B. Pre-commit Hooks

Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-added-large-files
        args: ['--maxkb=1000']  # Warn on files >1MB
      - id: check-case-conflict
      - id: check-merge-conflict
      - id: detect-private-key
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-yaml
      - id: check-json
      
  - repo: local
    hooks:
      - id: no-root-sprawl
        name: Prevent root directory sprawl
        entry: scripts/check-root-sprawl.sh
        language: script
        pass_filenames: false
        
      - id: doc-location
        name: Check documentation location
        entry: scripts/check-doc-location.sh
        language: script
        files: '\.md$'
```

### C. Root Sprawl Check Script

Create `scripts/check-root-sprawl.sh`:

```bash
#!/bin/bash
# Prevent root directory sprawl

# Allowed files in root (customize as needed)
ALLOWED_ROOT_FILES=(
  "README.md"
  "CHANGELOG.md"
  "LICENSE"
  "Makefile"
  "VERSION"
  ".gitignore"
  ".dockerignore"
  "docker-compose*.yml"
  "pyproject.toml"
  "poetry.lock"
  "requirements.txt"
  "package.json"
  "go.mod"
  "go.sum"
)

# Check for unauthorized files in root
for file in *.md *.txt *.log *.sh; do
  if [[ -f "$file" ]] && [[ ! " ${ALLOWED_ROOT_FILES[@]} " =~ " ${file} " ]]; then
    echo "❌ Unauthorized file in root: $file"
    echo "   Move to appropriate directory:"
    echo "   - Documentation → docs/"
    echo "   - Scripts → scripts/"
    echo "   - Configs → config/"
    exit 1
  fi
done

exit 0
```

## 3. Cleanup Standards Documentation

Create `docs/operational/CLEANUP-STANDARDS.md`:

```markdown
# Repository Cleanup Standards

## File Organization Rules

### Root Directory
- **MUST contain**: README.md, CHANGELOG.md, LICENSE, Makefile, VERSION
- **MAY contain**: Essential config files (docker-compose.yml, pyproject.toml, etc.)
- **MUST NOT contain**: Status reports, temporary files, test outputs, logs

### Documentation
- **All docs MUST go in `docs/`** with appropriate subdirectory
- **Service docs**: `docs/services/<service-name>/`
- **Operational docs**: `docs/operational/`
- **Architecture docs**: `docs/architecture/`

### Scripts
- **All scripts MUST go in `scripts/`**
- **No loose shell scripts in root**

## Automated Cleanup

### Daily Cleanup (via cron or CI)
```bash
# Remove Python caches
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

# Remove temporary files
find . -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -exec rm -f {} + 2>/dev/null
```

## PR Checklist
- [ ] No new files in root (unless updating allowed list)
- [ ] Documentation in proper `/docs` subdirectory
- [ ] No temporary or cache files
- [ ] No large files (>1MB) without justification
```

## 4. PR Template

Create `.github/pull_request_template.md`:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactoring
- [ ] Cleanup

## File Hygiene Checklist
- [ ] No new files added to root directory
- [ ] All documentation placed in `/docs`
- [ ] No temporary/cache files included
- [ ] Large files (>1MB) justified or moved to LFS
- [ ] No duplicate functionality introduced

## Testing
- [ ] Tests pass locally
- [ ] No new warnings from linters
```

## 5. Implementation Steps

1. **Create cleanup branch**
2. **Commit changes in logical groups**
3. **Add CI/CD checks**
4. **Install pre-commit hooks**
5. **Create monitoring dashboard**

## 6. Monitoring and Metrics

Track these metrics monthly:
- Root directory file count
- Total repository size
- Documentation organization score
- CI hygiene check pass rate