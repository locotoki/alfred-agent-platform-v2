# Workflow Automation Tools

This directory contains automation tools and scripts for the alfred-agent-platform-v2 repository.

## Scripts Inventory

The repository maintains an automated inventory of all script files to support the Spring-Clean Initiative (SC-250).

### Scripts Inventory System

The scripts inventory system automatically tracks all script files (`.sh`, `.py`, `.ps1`, `.js`, `.ts`) across the repository and generates a CSV report with metadata.

**Files:**
- `scripts/gen_scripts_inventory.py` - Generator script that scans the repository
- `metrics/scripts_inventory.csv` - Generated CSV with script metadata

**Usage:**
```bash
# Generate fresh inventory
make scripts-inventory

# Manual generation
python scripts/gen_scripts_inventory.py > metrics/scripts_inventory.csv
```

**CSV Format:**
- `path` - Relative path from repository root
- `ext` - File extension (e.g., `.py`, `.sh`)
- `size_bytes` - File size in bytes

**Excluded Directories:**
- `.git/`, `node_modules/`, `__pycache__/`, `.venv/`, `.env/`
- `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`
- Any directory starting with `backup`

**Pre-commit Integration:**
The inventory is automatically regenerated and validated during pre-commit hooks. If the inventory is out of date, the commit will fail with instructions to run `make scripts-inventory`.

This ensures the inventory always reflects the current state of the repository and supports maintenance activities like identifying unused scripts, tracking script growth, and maintaining clean directory structures.

## Board Sync Automation

Automated GitHub project board synchronization tools.

**Usage:**
```bash
make board-sync ISSUE_URL=<issue-number>
```

See `cli/board_sync.sh` for implementation details.

**Phase C-1 — Script usage triage**

* `status` column values
  * **USED**   referenced by CI, Makefile, or imported by code
  * **ORPHAN** not called anywhere & slated for deletion
  * **UNKNOWN** default; must be triaged in upcoming slices

The pre-commit hook blocks new rows without a `status`.

**Phase C-2 — Orphan tagging**

*Mark rows whose scripts are no longer imported or called anywhere as **ORPHAN**.*
Pre-commit will now block if an ORPHAN file is still referenced.
Removal happens in Phase C-3 after one release cycle.

**Phase C-3 — Prune ORPHAN scripts & static lint**

* ORPHAN-tagged files are removed one release later.
* New CI job **lint** runs `shellcheck` on all shell scripts and `vulture`
  on Python code (excluding tests/migrations).
* Build fails on any new ShellCheck error or vulture-detected dead code.

**Phase C-4 — Tier-0 lint & dead-code gating**

* `lint` workflow is now **required**.
* `vulture` runs at confidence ≥ 90; symbols used dynamically should be added to `vulture_whitelist.txt`.
* Any file tagged **ORPHAN** must be deleted before the next release cycle.

**Phase C-5 — Close-out**

* tech-debt velocity CSV auto-updates weekly
* badge shows SC-250 complete; milestone closed

## Dependency-Audit Initiative

The repository maintains an automated inventory of all Python dependencies to support vulnerability scanning, license compliance, and dependency management.

### Dependency Inventory System

The dependency inventory system automatically scans all `requirements*.txt` and `pyproject.toml` files across the repository, analyzes import usage patterns, and generates a comprehensive CSV report.

**Files:**
- `scripts/gen_dependency_inventory.py` - Generator script that scans dependency files and imports
- `metrics/dependency_inventory.csv` - Generated CSV with dependency metadata

**Usage:**
```bash
# Generate fresh inventory
make deps-inventory

# Manual generation
python scripts/gen_dependency_inventory.py
```

**CSV Format:**
- `package` - Package name as declared or imported
- `declared_version` - Version constraint from requirements files (if any)
- `latest_pinned` - Latest available version from PyPI (when accessible)
- `location` - Source file path or 'import-only' for undeclared imports

**Features:**
- Scans all `requirements*.txt` and `pyproject.toml` files
- Analyzes Python imports to find undeclared dependencies
- Queries PyPI for latest version information
- Excludes backup directories and temporary files
- Supports multiple dependency declaration formats (pip, Poetry, PEP 621)

**Pre-commit Integration:**
The inventory is automatically regenerated and validated during pre-commit hooks. If the inventory is out of date, the commit will fail with instructions to run `make deps-inventory`.

**Weekly Badge Plan:**
A weekly automation will update project badges to reflect:
- Total dependencies tracked
- Percentage with version constraints
- Number of outdated dependencies
- Security vulnerability status
