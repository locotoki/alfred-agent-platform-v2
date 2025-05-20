# PostgreSQL Version Migration Guide

## Issue Overview

The Alfred Agent Platform uses PostgreSQL for its database services. The data directory in the volume was originally initialized with PostgreSQL 15, but some Docker configurations were attempting to use PostgreSQL 14, causing an incompatibility error:

```
FATAL: database files are incompatible with server
DETAIL: The data directory was initialized by PostgreSQL version 15, which is not compatible with this version 14.18
```

## Solutions

### 1. Ensuring PostgreSQL 15 Images

We've updated our Docker configuration to explicitly use PostgreSQL 15 for all database services. This ensures compatibility with existing data volumes.

### 2. Resetting Data Volumes (for development environments only)

If you're working in a development environment and don't need to preserve your data, you can reset the volume:

```bash
# Stop all containers
make down

# Remove the PostgreSQL data volume
docker volume rm alfred-db-postgres-data

# Start the stack again
make up
```

This will create a fresh database with the correct schema initialization.

### 3. For Existing Installations

If you have existing data that was initialized with PostgreSQL 15 and need to migrate to a different version, use PostgreSQL's official tools:

```bash
# 1. Create a backup of your data
docker exec db-postgres pg_dump -U postgres -c postgres > postgres_backup.sql

# 2. Remove the incompatible volume
docker volume rm alfred-db-postgres-data

# 3. Start the database with the desired version
make up

# 4. Import your data
cat postgres_backup.sql | docker exec -i db-postgres psql -U postgres -d postgres
```

## Prevention

To avoid similar issues in the future:

1. Always use explicit version tags in your Docker images
2. Document the PostgreSQL version being used in the project
3. Include version checks in the health monitoring scripts

## Note on Docker Caching

If you've previously pulled or built PostgreSQL images with different version tags, Docker may have cached these images. To ensure you're using the correct version:

```bash
# Pull the correct version explicitly
docker pull postgres:15-alpine

# Rebuild your images with --no-cache
docker-compose build --no-cache db-postgres
```