# Docker Compose Documentation Archive

This directory contains historical Docker Compose documentation that has been superseded 
by newer documents:

- **DOCKER-COMPOSE-GUIDE.md** (in project root)
- **COMPOSE-CLEANUP-SUMMARY.md** (in project root)

These archived documents were created during the Docker Compose structure simplification
project completed on May 14, 2025.

## Archived Documents

- **DOCKER-COMPOSE-CLEANUP.md** - Initial cleanup strategy document
- **DOCKER-COMPOSE-TESTING.md** - Testing procedures for Docker Compose configurations
- **DOCKER-COMPOSE-HEALTH-FIXES.md** - Health check implementation for containers
- **CONTAINERIZATION-PLAN.md** - Initial containerization strategy
- **CONTAINERIZATION-RECOMMENDATIONS.md** - Recommendations for containerization

## Current Docker Compose Structure

The platform now uses a simplified structure:
- `docker-compose.yml` - Core configuration
- `docker-compose.dev.yml` - Development overrides with profiles
- `docker-compose.prod.yml` - Production settings
- `docker-compose.local.yml` - (Optional) Personal developer settings

## Usage

See the current **DOCKER-COMPOSE-GUIDE.md** in the project root for up-to-date
instructions on using the Docker Compose configuration.