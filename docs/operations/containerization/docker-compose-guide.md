# Docker Compose Structure Guide

This document explains the Docker Compose configuration architecture for the Alfred Agent Platform.

## Core Principles

1. **Simplified Inheritance**: One canonical file + one layer of overrides only
2. **Profiles Over Files**: Use service profiles instead of multiple override files
3. **Personal Configuration**: Local developer settings via gitignored file
4. **Clear Documentation**: Well-documented structure for new team members

## File Structure

The platform uses these Docker Compose files:

| File | Purpose | Usage |
|------|---------|-------|
| `docker-compose.yml` | Core services and configuration | Base configuration for all environments |
| `docker-compose.dev.yml` | Development overrides | Development settings including hot reloading |
| `docker-compose.prod.yml` | Production optimizations | Production settings including resource limits |
| `docker-compose.local.yml` | Personal developer customizations | Local settings (not in version control) |

Files are loaded in this order, with later files overriding earlier ones:
```
docker-compose.yml ← docker-compose.dev.yml ← docker-compose.local.yml
```

## Using Profiles

The platform uses Docker Compose profiles to conditionally enable services:

- `dev` - Development services and configuration
- `prod` - Production-optimized services
- `mocks` - Mock services for local development

Examples:

```bash
# Start with development profile
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev up -d

# Add mock services for testing without real dependencies
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev --profile mocks up -d

# Start only specific services
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev up -d mission-control social-intel
```

## Personal Developer Customizations

Create your own local overrides file:

```bash
cp docker-compose.local.yml.template docker-compose.local.yml
# Edit as needed - this file is gitignored
```

Common customizations:
- Changing port mappings to avoid conflicts
- Adding debug tools or personal preferences
- Setting environment-specific configuration
- Adjusting resource limits for your machine

## Start Platform Script

The `start-platform.sh` script provides a convenient wrapper for Docker Compose commands:

```bash
# Development with mocks
./start-platform.sh -e dev mock

# Production mode
./start-platform.sh -e prod

# Down with volume cleanup
./start-platform.sh -a down -c

# Only specific services
./start-platform.sh mission-control social-intel
```

## Best Practices

1. **Use Profiles**: Use profiles instead of creating new override files
2. **Development Settings**: Keep development settings in `docker-compose.dev.yml`
3. **Local Customizations**: Use `docker-compose.local.yml` for personal settings
4. **Service Dependencies**: Define dependencies with `depends_on`
5. **Environment Variables**: Use `.env` for environment-specific variables
6. **Volume Management**: Use named volumes for persistent data
