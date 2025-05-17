# Containerization Documentation

This directory contains documentation for the containerization strategy of the Alfred Agent Platform v2.

## Core Documentation

- [Docker Compose Guide](./docker-compose-guide.md) - Main guide for Docker Compose configuration

## Related Documentation

These files in the project root provide additional context:

- `DOCKER-COMPOSE-GUIDE.md` - Quick reference guide for developers
- `COMPOSE-CLEANUP-SUMMARY.md` - Summary of the Docker Compose structure simplification

## Additional Resources

For historical context, see the archived documentation in `/docs/archive/docker-compose/`.

## Usage Examples

### Basic Development Environment

```bash
# Start with development profile
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev up -d
```

### With Mock Services

```bash
# Development with mocks for testing
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev --profile mocks up -d
```

### Production Configuration

```bash
# Production-optimized settings
docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile prod up -d
```

### Using the Convenience Script

```bash
# Start in development mode
./start-platform.sh -e dev

# Start with mock services
./start-platform.sh -e dev mock

# Start in production mode
./start-platform.sh -e prod

# Stop all services and clean volumes
./start-platform.sh -a down -c
```