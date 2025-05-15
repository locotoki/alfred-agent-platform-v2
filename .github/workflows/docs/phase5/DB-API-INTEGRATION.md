# DB-API Health Check Integration

This document outlines the implementation of standardized health checks for the db-api service as part of Phase 5.

## Current State

The db-api service currently:
- Does not have a standardized health check
- Does not expose metrics on port 9091
- Does not have a proper Docker health check
- Is missing the Prometheus metrics.port label

## Implementation Plan

1. Create a new Dockerfile with the standard health check pattern
2. Configure the PostgreSQL container to support health checks
3. Update docker-compose.yml with proper health check configuration
4. Test the new configuration
5. Document the changes

## Dockerfile Changes

The new Dockerfile follows the standard pattern:

```dockerfile
FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM postgres:14

# Copy healthcheck binary from builder
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

# Set default environment variables
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=postgres
ENV PGPORT=5432

# Copy PostgreSQL configuration files (if any)
COPY ./config/postgresql.conf /etc/postgresql/postgresql.conf

# Create directory for custom scripts (if needed)
RUN mkdir -p /docker-entrypoint-initdb.d

# Copy initialization scripts
COPY ./init-db-api.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL, metrics, and health ports
EXPOSE 5432
EXPOSE 9091

# Use healthcheck wrapper to run PostgreSQL server
CMD ["healthcheck", "--export-prom", ":9091", "--", "docker-entrypoint.sh", "postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]

# Health check configuration
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
  CMD pg_isready -U postgres || exit 1
```

## Docker Compose Changes

The docker-compose.yml changes:

```yaml
db-api:
  image: ${REGISTRY}db-api:${TAG}
  build:
    context: ./services/db-api
    dockerfile: Dockerfile.new
  container_name: db-api
  restart: always
  environment:
    POSTGRES_PASSWORD: ${DB_API_PASSWORD}
    POSTGRES_USER: ${DB_API_USER}
    POSTGRES_DB: api
  volumes:
    - db-api-data:/var/lib/postgresql/data
  ports:
    - "5432:5432"
    - "9451:9091"  # Expose metrics port
  networks:
    - alfred-net
  healthcheck:
    test: ["CMD", "pg_isready", "-U", "postgres"]
    interval: 10s
    timeout: 5s
    retries: 3
    start_period: 30s
  labels:
    <<: *service-labels
    prometheus.metrics.port: "9091"
```

## Testing

To test the db-api health check:

1. Build the new container:
   ```bash
   docker-compose build --no-cache db-api
   ```

2. Start the container:
   ```bash
   docker-compose up -d db-api
   ```

3. Verify the health check:
   ```bash
   docker inspect --format='{{.State.Health.Status}}' db-api
   ```

4. Verify PostgreSQL connectivity:
   ```bash
   psql -h localhost -U postgres -d postgres -c "SELECT 1;"
   ```

5. Check metrics endpoint:
   ```bash
   curl -s http://localhost:9451/metrics | grep service_health
   ```

## Notes

- PostgreSQL health checks should use pg_isready instead of curl
- Ensure database initialization scripts are properly handled
- Consider data persistence implications when rebuilding the container