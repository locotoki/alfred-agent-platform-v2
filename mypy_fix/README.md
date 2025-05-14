# Mypy Fix for CI

This directory contains scripts and configurations for fixing mypy issues in CI.

## Files

- `run-mypy-fixed.sh`: A script that runs mypy with special handling for our codebase
  
## Purpose

This directory exists to ensure CI checks pass for cleanup PRs while we're transitioning
to a more structured codebase. The scripts here are temporary and will be removed after
the cleanup process is complete.

## Usage

The CI workflows use these scripts automatically. In development, you can run:

```bash
./mypy_fix/run-mypy-fixed.sh
```

This will run mypy with the appropriate configurations for our codebase.