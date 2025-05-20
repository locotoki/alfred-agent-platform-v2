# Black Standardization

This change standardizes Black formatter configuration across the codebase to ensure consistent formatting in both CI and local development environments.

## Changes Made

1. **Version Standardization**: Upgraded all scripts and workflows to use Black 24.4.2 (previously had a mix of 24.1.1 and 24.4.2)
2. **Configuration Centralization**: All tools now use the configuration from `pyproject.toml` rather than duplicate exclude patterns
3. **Documentation Updates**: Updated the standards documentation to reflect these changes

## Files Modified

- `.github/workflows/black-check.yml` - Updated version and removed duplicate exclude patterns
- `.github/workflows/apply-black.yml` - Updated version and removed duplicate exclude patterns
- `.github/workflows/ci.yml` - Updated to use Black 24.4.2 for consistency
- `.github/workflows/ci-tier0.yml` - Updated to use Black 24.4.2 for consistency
- `apply-black.sh` - Updated version and removed duplicate exclude patterns
- `scripts/apply-black-formatting.sh` - Updated version and removed duplicate exclude patterns
- `format-with-black.sh` - Updated version and removed duplicate exclude patterns
- `scripts/format-codebase.sh` - Updated version and removed duplicate exclude patterns
- `docs/formatting/BLACK-FORMATTING-STANDARDS.md` - Updated version and documentation
- `.pre-commit-config.yaml` - Removed duplicate exclude patterns (already had correct version)
- `fix-formatting.sh` - New script with standardized configuration

## Benefits

- Eliminates configuration drift between CI and local development
- Reduces maintenance overhead by centralizing configuration in `pyproject.toml`
- Ensures consistent code formatting across all environments
- Simplifies future version upgrades
- Fixes CI regression (SC-230) by ensuring all CI workflows use the same Black version
