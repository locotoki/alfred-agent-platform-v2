# Spring-Clean Classification Criteria

This document outlines the specific criteria used to classify files as part of the Spring-Clean initiative.

## Classification Categories

### C-0: USED
Files actively used in the current implementation:
- Core platform code (alfred/ directory)
- Active configuration files
- Current deployment scripts
- Project documentation
- Working CI/CD scripts
- Active tests
- Core services

### C-1: ORPHAN
Files that appear to be unused or obsolete:
- Backup files and directories
- Files with extensions like .bak, .backup
- Outdated documentation
- Deprecated scripts
- Legacy configuration
- Dead code paths
- Redundant test files
- Files in backup/ or cleanup-temp/ directories

## Specific Classification Rules

1. Files in backup/ directories are ORPHAN
2. Files with .bak, .backup extensions are ORPHAN
3. Files in cleanup-temp/ are ORPHAN
4. Core framework files in alfred/ are generally USED
5. CI/CD workflow files in .github/workflows/ are generally USED
6. Docker-compose files in root are generally USED
7. Documentation in docs/ is generally USED
8. Scripts in scripts/ are generally USED
9. Tests in tests/ directory are generally USED
10. Temporary/one-off scripts in the root directory are generally ORPHAN
11. Multiple versions of the same file (with suffixes like .old, .new) generally indicate one is USED and others are ORPHAN
