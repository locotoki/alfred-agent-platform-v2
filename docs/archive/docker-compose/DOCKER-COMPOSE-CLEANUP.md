# Docker Compose Cleanup Strategy

This document outlines a strategy for cleaning up the Docker Compose configuration in the Alfred Agent Platform v2 to reduce complexity and improve maintainability.

## Current Issues

1. Multiple Docker Compose files with overlapping functionality
2. Legacy files that may no longer be relevant
3. Inconsistent naming between older and newer files
4. Service definitions duplicated across files

## Recommended Changes

### 1. Establish a Clear File Hierarchy

Standardize on the following structure:

```
docker-compose.yml              # Base configuration (rename from docker-compose-clean.yml)
docker-compose.override.yml     # Default override for local development
docker-compose.prod.yml         # Production override
docker-compose.dev.yml          # Development override
```

### 2. Files to Remove or Consolidate

| File | Action | Reason |
|------|--------|--------|
| `docker-compose-clean.yml` | Rename to `docker-compose.yml` | More standard naming convention |
| Current `docker-compose.yml` | Archive/Remove | Replaced by newer configuration |
| `docker-compose.override.mission-control.yml` | Consolidate into `docker-compose.override.yml` | Simplify overrides |
| `docker-compose.override.mission-control.dev.yml` | Consolidate into `docker-compose.dev.yml` | Simplify overrides |
| `docker-compose.override.simplified-mc.yml` | Keep temporarily | Needed for simplified MC |
| `docker-compose.override.storage.yml` | Evaluate necessity | May be consolidated |

### 3. Update References

Update all scripts to reference the standardized files:

1. Modify `start-platform.sh` to use `docker-compose.yml` instead of `docker-compose-clean.yml`
2. Update service-specific scripts to use the main compose file with overrides
3. Update CI/CD pipelines if they reference specific Docker Compose files

### 4. Service-Specific Compose Files

For services that need isolated development:

1. Keep individual Docker Compose files in service directories
2. Ensure they don't conflict with the main platform configuration
3. Document their purpose and usage

## Implementation Plan

1. Create backups of all Docker Compose files
2. Rename `docker-compose-clean.yml` to `docker-compose.yml`
3. Update `start-platform.sh` and other scripts
4. Test startup with the new configuration
5. Remove or archive unnecessary files after successful testing

## Additional Recommendations

1. Use Docker Compose profiles to group services logically (e.g., core, agents, ui)
2. Define common configurations using YAML anchors to reduce duplication
3. Document environment variables in a separate `.env.example` file
4. Consider using Docker Compose version 3.x for newer features