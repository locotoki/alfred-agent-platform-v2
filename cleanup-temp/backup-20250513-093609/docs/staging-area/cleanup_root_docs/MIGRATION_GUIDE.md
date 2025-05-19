# Alfred Agent Platform v2 - Migration Guide

This guide walks you through migrating from the older Alfred Agent Platform configuration to the new unified structure.

## Overview of Changes

The Alfred Agent Platform has been refactored to provide:

1. **Unified Docker Compose Configuration**: All services are defined in a single base file with targeted overrides
2. **Standardized Service Naming**: Consistent naming convention for services
3. **Component-Based Organization**: Services grouped by logical components
4. **Environment-Specific Configurations**: Clear separation between development and production settings
5. **Unified Management Script**: Single `alfred.sh` script for all operations

## Migration Steps

### 1. Backup Your Current Configuration

Before starting the migration, create a backup of your current configuration:

```bash
# Run the installation script with backup option
./install.sh --backup
```

This will create a time-stamped backup of your Docker Compose files, scripts, and .env file.

### 2. Install the New Configuration

Run the installation script to copy the new configuration files to your environment:

```bash
# Install the new configuration
./install.sh
```

This will:
- Create the new directory structure if needed
- Copy all Docker Compose files
- Copy the alfred.sh management script
- Create a new .env.example file
- Setup initial service directories

### 3. Update Your Environment Variables

1. Compare your existing .env file with the new .env.example:

```bash
diff -u .env.backup .env.example
```

2. Update your .env file with any new required variables:

```bash
# Example: Add the new ALFRED_ prefixed variables
echo "ALFRED_ENVIRONMENT=development" >> .env
echo "ALFRED_DEBUG=true" >> .env
echo "ALFRED_PROJECT_ID=alfred-agent-platform" >> .env
```

### 4. Migrate Service Implementations

For each of your existing services:

1. Create a directory in the new `services/` directory if it doesn't already exist
2. Copy your service code to the appropriate directory
3. Create a Dockerfile and Dockerfile.dev using the templates in SERVICE_IMPLEMENTATION_GUIDE.md
4. Update the service definition in docker-compose.yml if needed

Example:
```bash
# Create service directory
mkdir -p services/my-custom-agent/app

# Copy service code
cp -r old-location/my-custom-agent/* services/my-custom-agent/

# Create Dockerfiles from templates
cp services/alfred-core/Dockerfile services/my-custom-agent/
cp services/alfred-core/Dockerfile.dev services/my-custom-agent/

# Update paths and ports in the Dockerfiles
```

### 5. Test the New Configuration

Start with the core services to verify the basic infrastructure is working:

```bash
# Start core services
./alfred.sh start --env=dev --components=core

# Check status
./alfred.sh status
```

Then add your migrated services:

```bash
# Start a specific service
./alfred.sh start --env=dev --service=my-custom-agent
```

### 6. Update Deployment Scripts

If you have CI/CD pipelines or deployment scripts, update them to use the new `alfred.sh` script.

Example:
```bash
# Old deployment command
docker-compose -f docker-compose.prod.yml up -d

# New deployment command
./alfred.sh start --env=prod --components=all
```

## Common Issues

### Service Name Changes

If you have external tools or scripts that reference the old service names, you'll need to update them to use the new standardized names.

Old: `my_agent_service`
New: `agent-myagent`

### Volume Path Changes

The new configuration standardizes volume paths. If you had custom volume mappings, you may need to migrate data:

```bash
# Example: Copy data from old volume to new volume
docker run --rm -v old_volume_name:/old -v new_volume_name:/new alpine cp -r /old/* /new/
```

### Environment Variable Changes

Many environment variables have been standardized with the `ALFRED_` prefix. Update any scripts or tools that set these variables:

Old: `DEBUG=true`
New: `ALFRED_DEBUG=true`

### Network Changes

All services now use the `alfred-network` Docker network. If you had custom network configurations, update them:

```bash
# Create the new network if needed
docker network create alfred-network

# Update any container to use the new network
docker network connect alfred-network my-container
```

## Rollback Procedure

If you need to rollback to the previous configuration:

```bash
# Restore from backup
cp -r backup_directory/* .

# Start using old configuration
docker-compose -f your-original-docker-compose.yml up -d
```

## Getting Help

If you encounter any issues during migration:

1. Check the VALIDATION.md file for known issues and solutions
2. Reference the SERVICE_IMPLEMENTATION_GUIDE.md for implementation details
3. Open an issue in the project repository
