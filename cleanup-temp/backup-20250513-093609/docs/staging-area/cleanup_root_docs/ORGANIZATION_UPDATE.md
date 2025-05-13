# Alfred Agent Platform v2 - Project Organization Update

## Overview

This document summarizes the reorganization of the project directory structure to improve maintainability and reduce clutter in the root directory.

### Date: May 12, 2025

## New Directory Structure

The project has been reorganized with the following directory structure:

```
alfred-agent-platform-v2/
├── docker-compose-clean.yml     # Primary Docker Compose configuration
├── docker-compose-optimized.yml # Optimized Docker Compose configuration
├── docker-compose/              # Environment-specific overrides
│   ├── docker-compose.dev.yml   # Development environment settings
│   └── docker-compose.prod.yml  # Production environment settings
├── start-platform.sh            # Main platform management script
├── check-env-vars.sh            # Environment variable validation
├── verify-platform.sh           # Platform verification tool
├── scripts/                     # Organized script directories
│   ├── db/                      # Database-related scripts and SQL files
│   ├── setup/                   # Setup and initialization scripts
│   ├── tests/                   # Test scripts 
│   └── utils/                   # Utility scripts
│       └── llm/                 # LLM-specific utilities
├── tests/                       # Test directory
│   └── integration/             # Integration tests
└── [other project directories]
```

## Files Organized

The following types of files have been organized:

1. **Docker Compose Files**:
   - Consolidated to `docker-compose-clean.yml` and environment-specific overrides in `docker-compose/`
   - 30+ individual Docker Compose files were backed up and removed from the root directory

2. **Scripts**:
   - Test scripts moved to `scripts/tests/`
   - Setup scripts moved to `scripts/setup/`
   - Utility scripts moved to `scripts/utils/`
   - LLM-specific utilities moved to `scripts/utils/llm/`
   - Database scripts and SQL files moved to `scripts/db/`

3. **Integration Tests**:
   - Integration test files moved to `tests/integration/`

## Backup

All moved files were backed up before removal to:
```
./cleanup_backup_20250512/
```

This ensures that no files were lost during the reorganization process.

## Working with the New Structure

### Managing the Platform

Use the main platform management script:
```bash
# Start all services in development mode
./start-platform.sh

# Start in production mode
./start-platform.sh -e prod

# Stop all services
./start-platform.sh -a down

# Show logs for a specific service
./start-platform.sh -a logs redis
```

### Accessing Utility Scripts

Utility scripts are now organized in the `scripts/` directory:
```bash
# Run a database script
./scripts/db/check-db-ready.sh

# Run a setup script
./scripts/setup/setup-ollama-models.sh

# Run an LLM utility
./scripts/utils/llm/direct-chat.py
```

## Benefits of the New Organization

1. **Cleaner Root Directory**: Easier to find important files
2. **Logical Organization**: Scripts grouped by function
3. **Better Maintainability**: Related files kept together
4. **Easier Onboarding**: Clear structure for new developers
5. **Improved Focus**: Essential platform files highlighted

## Next Steps

Consider further organization:

1. Create a clear README that reflects the new organization
2. Create script index documentation for each script directory
3. Standardize script naming conventions
4. Consider automating common tasks further